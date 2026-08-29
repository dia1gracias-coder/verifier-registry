// SPDX-License-Identifier: MIT
// Governor — deploys Proposal children, relays votes via Staking (VP cap), executes after timelock.

import "./governance-types";
import "./governance-messages";
import "./governance-payload";
import "./proposal";

/// Snapshot written on create / Proposal callbacks (`Proposal.state`).
const GV_ACTIVE: Int = 0;
/// Mirrors `Proposal.PS_CANCELLED` — reserved id whose phase-1 snapshot round-trip bounced.
const GV_CANCELLED: Int = 5;

/// Vote gas budget (IMP-GOVOTE-04 / AD-2). Source of truth — mirror in `Governor.ts` and
/// `frontend/src/ton/transactionBuilder.ts`.
/// Minimum voter attachment for `CastVote`: full relay chain (Governor → StakingMaster →
/// Proposal) via `SendRemainingValue`, plus compute on each hop and terminal voter refund.
const GasVoteAttach: Int = ton("0.18");

/// Pre-vote window between proposal creation and voting start (IMP-PREMNT-08).
/// During `[creation, creation + cancelLagSec)` the proposer may cancel the
/// proposal (`Proposal.receive(ProposalCancel)` requires `now() < startTime`);
/// once it elapses, voting opens and cancellation is no longer possible.
/// Without this lag `startTime == creation`, which makes the cancel window
/// unreachable (every cancel returns "Too late"). Mirrors the standard Governor
/// `votingDelay`: it shifts voting start but keeps the voting period length
/// (`endTime = startTime + cfg.period`) intact.
/// Production / shared tip init: 3600. Lab tip may pass a shorter value at
/// `Governor.init` (IMP-TNFS-F02) — not mutable via `TimelockSetProposalConfig`.
contract Governor(
    proposalCount: Int as uint64,
    proposals: map<Int as uint64, Address>,
    proposalStateById: map<Int as uint64, Int as uint8>,
    /// Voting-window end time per proposal id — same value written into Proposal.init
    /// (`now() + cancelLagSec + period`). Carried into `GovernorVoteRelay.voteEndTime` so
    /// StakingMaster can gate vote weight by lock without reading Proposal storage
    /// (IMP-FAUDIT-F01 / F-2).
    proposalEndTimeById: map<Int as uint64, Int as uint64>,
    /// O(1) reverse index Address → registered Proposal (IMP-MNAUD-F07 cheap half).
    /// Updated in phase 2 alongside `proposals.set`; replaces O(n) foreach scan that
    /// OOGed plain-TON cashback when the proposals map grew large.
    knownProposals: map<Address, Bool>,
    proposalConfigs: map<Int as uint32, ProposalConfig>,
    minProposalVp: Int,
    stakingMaster: Address,
    stakingLock: Address,
    timelock: Address,
    timelockDelaySec: Int as uint64,
    /// Pre-vote cancel window (seconds). Immutable after init.
    cancelLagSec: Int as uint64,
    treasury: Address,
) {
    /// Skip cashback for governance relay partners — plain TON ping-pong caused
    /// Governor↔StakingMaster (IMP-GOVOTE-02), Governor↔Timelock / Governor↔Proposal
    /// execution loops (IMP-RELAY-02 / RC-A). O(1) membership via `knownProposals`.
    inline fun isKnownProposal(addr: Address): Bool {
        return self.knownProposals.get(addr) != null;
    }

    receive() {
        let s = sender();
        if (s != self.stakingMaster && s != self.timelock && !self.isKnownProposal(s)) {
            cashback(s);
        }
    }

    inline fun quorumAbsFromSnapshot(totalVp: Int, quorumPct: Int): Int {
        return totalVp * quorumPct / 100;
    }

    /// Phase 1 of proposal creation (IMP-AUDIT-02). The Governor reserves a proposal id,
    /// then asks the StakingMaster for the authoritative total voting power. The Proposal
    /// is only deployed in phase 2 (`TotalVpSnapshotReply`), with a quorum denominator
    /// that the proposer cannot inflate or deflate.
    receive(msg: CreateProposal) {
        validateProposalPayloadShape(msg.proposalType, msg.payload, self.treasury);

        let cfgOpt = self.proposalConfigs.get(msg.proposalType);
        require(cfgOpt != null, "Unknown proposal cfg");
        let cfg = cfgOpt!!;

        require(cfg.thresholdPercent >= 0 && cfg.thresholdPercent <= 100, "Bad threshold pct");
        let thresholdBps = cfg.thresholdPercent * 100;
        require(thresholdBps <= 10000 && thresholdBps >= 0, "Bad threshold bps");

        require(msg.claimedVp >= self.minProposalVp, "Insufficient proposal vp");

        let ctx = context();
        require(ctx.value >= ton("0.45"), "Need TON for deploy");

        /// Reserve the id now so concurrent creations never collide; the proposal entry
        /// itself is recorded in phase 2 once the trusted snapshot returns (and proposer
        /// on-chain VP clears minProposalVp — IMP-MNAUD-F07).
        let id = self.proposalCount;
        self.proposalCount = id + 1;

        /// Forward the remaining value through the snapshot round-trip so phase 2 can
        /// fund the Proposal deploy. No cashback here — the value must keep flowing.
        message(MessageParameters {
            to: self.stakingMaster,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: RequestTotalVpSnapshot {
                queryId: msg.queryId,
                proposalId: id,
                proposer: sender(),
                proposalType: msg.proposalType,
                payload: msg.payload,
                period: cfg.period,
                quorumPercent: cfg.quorumPercent,
                thresholdBps: thresholdBps,
                timelockDelay: cfg.timelockDelay,
            }.toCell(),
        });
    }

    /// IMP-AUDIT-18 — phase-1 snapshot request bounced (StakingMaster rejected or OOG).
    /// The id was already reserved in `CreateProposal`; mark it cancelled so tooling does
    /// not treat the gap as a live proposal. `proposalId` is within the ~224-bit bounce
    /// prefix; `proposer` is not — see decision log for why value cannot be refunded to
    /// the initiator on-chain.
    bounced(msg: bounced<RequestTotalVpSnapshot>) {
        self.proposalStateById.set(msg.proposalId, GV_CANCELLED);
    }

    /// Phase 2 of proposal creation (IMP-AUDIT-02). Authenticated reply from the
    /// StakingMaster carrying the on-chain total VP and proposer eligibility VP.
    /// Deploys the Proposal with a quorum barrier derived from this trusted denominator.
    /// IMP-MNAUD-F07: reject under-staked proposers even if `claimedVp` was inflated —
    /// mark the reserved id cancelled (same tooling path as IMP-AUDIT-18 bounce).
    receive(msg: TotalVpSnapshotReply) {
        require(sender() == self.stakingMaster, "Bad snapshot source");
        require(msg.totalVp > 0, "Bad totalVp snapshot");

        let id = msg.proposalId;

        /// Soft-fail (no `require`): state must persist as CANCELLED; a failed require
        /// would revert this write and leave a silent proposalCount gap.
        if (msg.proposerVp < self.minProposalVp) {
            self.proposalStateById.set(id, GV_CANCELLED);
            return;
        }

        /// Must be able to form a positive quorum barrier (integer VP units).
        let quorumRequired = self.quorumAbsFromSnapshot(msg.totalVp, msg.quorumPercent);
        require(quorumRequired > 0, "Vp snapshot too low for quorum");

        /// Fresh empty vote map — `initOf` requires explicit empty containers.
        let emptyVotes: map<Address, Int as uint8> = emptyMap();

        /// Single `now()` so Proposal.init endTime and the Governor-side lock-gate
        /// map stay bit-identical (IMP-FAUDIT-F01).
        let createdAt = now();
        let startTime = createdAt + self.cancelLagSec;
        let endTime = startTime + msg.period;

        let ini =
            initOf Proposal(
                id,
                myAddress(),
                self.stakingMaster,
                msg.proposer,
                msg.proposalType,
                msg.payload,
                startTime,
                endTime,
                0,
                0,
                msg.totalVp,
                quorumRequired,
                msg.thresholdBps,
                GV_ACTIVE,
                0,
                msg.timelockDelay,
                self.timelock,
                emptyVotes,
            );

        let propAddr = contractAddress(ini);
        self.proposals.set(id, propAddr);
        self.proposalStateById.set(id, GV_ACTIVE);
        self.proposalEndTimeById.set(id, endTime);
        /// Reverse index for O(1) cashback partner skip (IMP-MNAUD-F07).
        self.knownProposals.set(propAddr, true);

        deploy(DeployParameters {
            value: ton("0.18"),
            bounce: false,
            mode: SendPayGasSeparately,
            body: beginCell().endCell(),
            init: ini,
        });
    }

    receive(msg: CastVote) {
        require(msg.claimedVp > 0, "Zero vp");
        require(context().value >= GasVoteAttach, "Need TON for vote");

        let addrOpt = self.proposals.get(msg.proposalId);
        require(addrOpt != null, "Unknown proposal");
        let propAddr = addrOpt!!;

        let endOpt = self.proposalEndTimeById.get(msg.proposalId);
        require(endOpt != null, "Unknown proposal end");
        let voteEndTime = endOpt!!;

        message(MessageParameters {
            to: self.stakingMaster,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: GovernorVoteRelay {
                queryId: msg.queryId,
                proposal: propAddr,
                voter: sender(),
                support: msg.support,
                claimedVp: msg.claimedVp,
                voteEndTime: voteEndTime,
            }.toCell(),
        });
    }

    /// IMP-GOVOTE-03 / AD-1 — StakingMaster rejected `GovernorVoteRelay` (Only governor, Zero effective vp).
    /// Bounce prefix carries `queryId` and `proposal` only — `voter` is not available; value stays on
    /// Governor (see decision log). No `cashback(sender())` — that would ping StakingMaster (RC-2).
    bounced(msg: bounced<GovernorVoteRelay>) {
        /// Absorb bounce value on Governor; voter cannot be targeted from the truncated bounce
        /// body — value stays here until manually recovered off-chain.
    }

    receive(msg: ExecuteProposal) {
        let addrOpt = self.proposals.get(msg.proposalId);
        require(addrOpt != null, "Unknown proposal");

        message(MessageParameters {
            to: addrOpt!!,
            value: ton("0.07"),
            mode: SendPayGasSeparately,
            bounce: true,
            body: ProposalExecute {}.toCell(),
        });

        cashback(sender());
    }

    receive(msg: ProposalStateReportToGovernor) {
        let stored = self.proposals.get(msg.proposalId);
        require(stored != null && sender() == stored!!, "Bad caller");

        self.proposalStateById.set(msg.proposalId, msg.newState);

        /// On-chain execution path: queue Timelock after voting success (P5-3-1-3).
        if (msg.newState == 1 && msg.queueActive) {
            require(msg.queueDelay == 0 || msg.queueDelay >= 86400, "Bad queue delay");
            message(MessageParameters {
                to: self.timelock,
                value: ton("0.15"),
                mode: SendPayGasSeparately,
                bounce: true,
                body: TimelockQueue {
                    queryId: 0,
                    proposalId: msg.proposalId,
                    proposalContract: stored!!,
                    target: msg.queueTarget,
                    method: msg.queueMethod,
                    args: msg.queueArgs,
                    delay: msg.queueDelay,
                }.toCell(),
            });
        }

        /// Absorb relay remainder — cashback to Proposal ping-ponged via receive()
        /// until out-of-gas (IMP-RELAY-02 / RC-A).
    }

    receive(msg: TimelockSetProposalConfig) {
        require(sender() == self.timelock, "Only timelock");
        /// Anti-brick guards (TECH_NOTES minimums).
        require(msg.config.quorumPercent >= 5 && msg.config.quorumPercent <= 100, "Cfg quorum");
        require(msg.config.thresholdPercent >= 51 && msg.config.thresholdPercent <= 100, "Cfg thresh");
        require(msg.config.period > 0, "Cfg period");
        /// timelockDelay may be zero (Emergency class configs).
        self.proposalConfigs.set(msg.proposalType, msg.config);
        cashback(sender());
    }

    get fun get_proposal(id: Int): Address? {
        return self.proposals.get(id);
    }

    /// O(1) membership in the maintained Proposal reverse index (IMP-MNAUD-F07).
    get fun get_is_known_proposal(addr: Address): Bool {
        return self.isKnownProposal(addr);
    }

    get fun get_proposal_count(): Int {
        return self.proposalCount;
    }

    get fun get_proposal_state(id: Int): Int {
        /// `255` means snapshot missing — should not happen for valid ids ≤ count−1 after create.
        if (id >= self.proposalCount) {
            return 255;
        }
        let s = self.proposalStateById.get(id);
        if (s == null) {
            return 255;
        }
        return s!!;
    }

    /// Canonical on-chain getters for VP math live on StakingMaster (`get_voting_power` / `get_total_voting_power`).
    /// Governor stores `stakingMaster` for tooling to chain run_get_method calls off-chain.

    get fun get_proposal_config(proposalType: Int): ProposalConfig {
        let c = self.proposalConfigs.get(proposalType);
        require(c != null, "Missing config");
        return c!!;
    }

    get fun get_min_proposal_vp(): Int {
        return self.minProposalVp;
    }

    get fun get_staking_master(): Address {
        return self.stakingMaster;
    }

    get fun get_staking_lock(): Address {
        return self.stakingLock;
    }

    get fun get_timelock_addr(): Address {
        return self.timelock;
    }

    get fun get_timelock_delay(): Int {
        return self.timelockDelaySec;
    }

    get fun get_cancel_lag(): Int {
        return self.cancelLagSec;
    }

    get fun get_treasury(): Address {
        return self.treasury;
    }
}
