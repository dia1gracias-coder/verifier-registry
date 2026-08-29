// SPDX-License-Identifier: MIT
// Single-proposal child contract: voting, finalize, timelock queue, execute via Timelock / off-chain-only Feature path.

import "./governance-messages";
import "../treasury/treasury-messages";

inline fun assertVoteRelayer(senderAddr: Address, voteRelayer: Address) {
    require(senderAddr == voteRelayer, "Only vote relay");
}

inline fun zeroAddr(): Address {
    return address("EQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c");
}

/// Active voting.
const PS_ACTIVE: Int = 0;
/// Passed quorum + threshold; waiting timelock execution.
const PS_SUCCEEDED: Int = 1;
const PS_DEFEATED: Int = 2;
const PS_QUEUED: Int = 3;
const PS_EXECUTED: Int = 4;
const PS_CANCELLED: Int = 5;

/// Canonical TreasurySpend opcode — must match `message(0x5a1c9010) TreasurySpend`
/// in `treasury/treasury.tact` (and the shared definition in `treasury-messages.tact`).
const TREASURY_SPEND_OPCODE: Int = 0x5a1c9010;

contract Proposal(
    id: Int as uint64,
    governor: Address,
    voteRelayer: Address,
    proposer: Address,
    proposalType: Int as uint32,
    payload: Cell,
    startTime: Int as uint64,
    endTime: Int as uint64,
    forVotes: Int,
    againstVotes: Int,
    totalVpSnapshot: Int,
    quorumRequired: Int,
    thresholdBps: Int as uint16,
    state: Int as uint8,
    succeededAt: Int as uint64,
    timelockDelaySec: Int as uint64,
    timelockAddr: Address,
    voted: map<Address, Int as uint8>,
) {
    /// Skip cashback for governance relay partners — plain TON ping-pong caused
    /// Proposal↔StakingMaster loops (IMP-GOVOTE-08) and Proposal↔Governor /
    /// Proposal↔Timelock execution loops (IMP-RELAY-02 / RC-A).
    receive() {
        let s = sender();
        if (s != self.voteRelayer && s != self.governor && s != self.timelockAddr) {
            cashback(s);
        }
    }

    inline fun assertGov() {
        require(sender() == self.governor, "Only governor");
    }

    inline fun assertActiveVoteWindow() {
        let t = now();
        require(t >= self.startTime, "Not started");
        require(t <= self.endTime, "Voting ended");
    }

    fun reportStateEx(
        ns: Int,
        queueDelay: Int,
        queueTarget: Address,
        queueMethod: Int,
        queueArgs: Cell,
        queueActive: Bool,
    ) {
        message(MessageParameters {
            to: self.governor,
            value: ton("0.03"),
            mode: SendPayGasSeparately,
            bounce: false,
            body: ProposalStateReportToGovernor {
                proposalId: self.id,
                newState: ns,
                queueDelay: queueDelay,
                queueTarget: queueTarget,
                queueMethod: queueMethod,
                queueArgs: queueArgs,
                queueActive: queueActive,
            }.toCell(),
        });
    }

    receive(msg: ProposalVoteRelay) {
        assertVoteRelayer(sender(), self.voteRelayer);
        require(self.state == PS_ACTIVE, "Not active");

        let t = now();
        require(t >= self.startTime, "Not started");
        require(t <= self.endTime, "Voting ended");
        require(msg.vp > 0, "Zero vp");

        let prior = self.voted.get(msg.voter);
        require(prior == null, "Already voted");
        self.voted.set(msg.voter, 1);

        if (msg.support) {
            self.forVotes = self.forVotes + msg.vp;
        } else {
            self.againstVotes = self.againstVotes + msg.vp;
        }
        /// Return vote-relay remainder to the voter, not vote relayer — terminal cashback to
        /// StakingMaster ping-ponged with Proposal.receive() until out-of-gas (IMP-GOVOTE-08).
        message(MessageParameters {
            to: msg.voter,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: false,
            body: beginCell().endCell(),
        });
    }

    receive(msg: ProposalFinalize) {
        require(now() > self.endTime, "Still voting");
        require(self.state == PS_ACTIVE, "Not active");

        let total = self.forVotes + self.againstVotes;
        if (total < self.quorumRequired) {
            self.state = PS_DEFEATED;
            self.reportStateEx(PS_DEFEATED, 0, zeroAddr(), 0, beginCell().endCell(), false);
            cashback(sender());
            return;
        }

        if (total == 0) {
            self.state = PS_DEFEATED;
            self.reportStateEx(PS_DEFEATED, 0, zeroAddr(), 0, beginCell().endCell(), false);
            cashback(sender());
            return;
        }

        require(self.thresholdBps >= 0 && self.thresholdBps <= 10000, "Bad threshold");
        let pass = self.forVotes * 10000 >= self.thresholdBps * total;

        if (!pass) {
            self.state = PS_DEFEATED;
            self.reportStateEx(PS_DEFEATED, 0, zeroAddr(), 0, beginCell().endCell(), false);
            cashback(sender());
            return;
        }

        self.state = PS_SUCCEEDED;
        self.succeededAt = now();

        let qDelay: Int = self.timelockDelaySec;
        let qTarget: Address = zeroAddr();
        let qMethod: Int = 0;
        let qArgs: Cell = beginCell().endCell();
        let qActive: Bool = false;

        let ty = self.proposalType;
        if (ty == 0) {
            let s = self.payload.beginParse();
            qTarget = s.loadAddress();
            qMethod = s.loadUint(32);
            qArgs = s.loadRef();
            qActive = true;
        } else if (ty == 1) {
            qActive = false;
        } else if (ty == 2) {
            let s = self.payload.beginParse();
            qTarget = s.loadAddress();
            let recipient = s.loadAddress();
            let amt = s.loadCoins();
            /// Payload carries `reason` as a snake-string ref; cast back to String
            /// so it re-serializes via storeStringRefTail exactly as Treasury expects.
            let reason = s.loadRef().asSlice().asString();
            qArgs = TreasurySpend {
                queryId: 0,
                recipient: recipient,
                amount: amt,
                reason: reason,
                proposalId: self.id,
            }.toCell();
            qMethod = TREASURY_SPEND_OPCODE;
            qActive = true;
        } else if (ty == 3) {
            let s = self.payload.beginParse();
            qTarget = s.loadAddress();
            qMethod = s.loadUint(32);
            qArgs = s.loadRef();
            let _reason = s.loadRef();
            qActive = true;
        }

        self.reportStateEx(PS_SUCCEEDED, qDelay, qTarget, qMethod, qArgs, qActive);
        cashback(sender());
    }

    /// FeaturePriority (off-chain signal): Governor may mark executed without Timelock.
    /// Parameter / Treasury / Emergency proposals must complete via `TimelockExecutePending` → `ProposalMarkExecuted`.
    receive(msg: ProposalExecute) {
        self.assertGov();
        require(self.state == PS_SUCCEEDED, "Not succeeded");
        require(self.proposalType == 1, "Use timelock path");

        self.state = PS_EXECUTED;
        self.reportStateEx(PS_EXECUTED, 0, zeroAddr(), 0, beginCell().endCell(), false);
        /// Absorb relay remainder — cashback to Governor ping-ponged via receive()
        /// (IMP-RELAY-02 / RC-A).
    }

    receive(msg: ProposalMarkExecuted) {
        require(sender() == self.timelockAddr, "Only timelock");
        require(self.state == PS_SUCCEEDED, "Not succeeded");

        self.state = PS_EXECUTED;
        self.reportStateEx(PS_EXECUTED, 0, zeroAddr(), 0, beginCell().endCell(), false);
        /// Absorb relay remainder — cashback to Timelock ping-ponged via receive()
        /// (IMP-RELAY-02 / RC-A).
    }

    /// Proposer-only cancellation, allowed solely in the pre-vote window
    /// `[creation, startTime)`. `startTime = creation + CANCEL_LAG` is set by the
    /// Governor (IMP-PREMNT-08), so this window is reachable; once voting opens
    /// (`now() >= startTime`) cancellation returns "Too late".
    receive(msg: ProposalCancel) {
        require(sender() == self.proposer, "Only proposer");
        require(now() < self.startTime, "Too late");
        require(self.state == PS_ACTIVE, "Not active");

        self.state = PS_CANCELLED;
        self.reportStateEx(PS_CANCELLED, 0, zeroAddr(), 0, beginCell().endCell(), false);
        cashback(sender());
    }

    get fun get_id(): Int {
        return self.id;
    }

    get fun get_governor(): Address {
        return self.governor;
    }

    get fun get_vote_relayer(): Address {
        return self.voteRelayer;
    }

    get fun get_proposer(): Address {
        return self.proposer;
    }

    get fun get_state(): Int {
        return self.state;
    }

    get fun get_for_votes(): Int {
        return self.forVotes;
    }

    get fun get_against_votes(): Int {
        return self.againstVotes;
    }

    get fun get_total_vp_snapshot(): Int {
        return self.totalVpSnapshot;
    }

    get fun get_start_time(): Int {
        return self.startTime;
    }

    get fun get_end_time(): Int {
        return self.endTime;
    }

    get fun get_quorum_required(): Int {
        return self.quorumRequired;
    }

    get fun get_threshold_bps(): Int {
        return self.thresholdBps;
    }

    get fun get_succeeded_at(): Int {
        return self.succeededAt;
    }

    get fun get_timelock_delay(): Int {
        return self.timelockDelaySec;
    }

    get fun get_timelock_addr(): Address {
        return self.timelockAddr;
    }

    get fun get_payload(): Cell {
        return self.payload;
    }

    get fun get_proposal_type(): Int {
        return self.proposalType;
    }

    get fun has_voted(voter: Address): Bool {
        let v = self.voted.get(voter);
        if (v == null) {
            return false;
        }
        return v!! >= 1;
    }
}
