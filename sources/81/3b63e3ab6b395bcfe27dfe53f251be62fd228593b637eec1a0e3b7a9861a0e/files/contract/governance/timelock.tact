// SPDX-License-Identifier: MIT
// Timelock — delay between proposal success and on-chain execution (P5-3-1-3).

import "./governance-messages";

/// Minimum delay for non-emergency actions (24h).
const TIMELOCK_MIN_DELAY_SEC: Int = 86400;

/// Opcode of `Treasury.TreasurySpend` (treasury.tact). Treasury-spend actions need a
/// much larger downstream gas budget (jetton-wallet excluded gate + recipient wallet
/// deploy) than a plain parameter call, so they get a dedicated relay path below.
const TREASURY_SPEND_METHOD: Int = 0x5a1c9010;

/// Opcode of `Vesting.VestEmergencyRevoke` (vesting.tact). Needs ≥ Vesting.ReleaseTon
/// (3.5 TON) for the outbound excluded jetton transfer — same relay pattern as treasury
/// spend so default TIMELOCK_TARGET_GAS is not raised for every target (IMP-TNFS-F03).
const VEST_EMERGENCY_REVOKE_METHOD: Int = 0x5a060002;

/// Fixed budget for `ProposalMarkExecuted` back to the Proposal contract.
const TIMELOCK_MARK_EXECUTED_GAS: Int = ton("0.04");

/// Default attach for ordinary target actions (parameter/feature/other emergency),
/// preserved from the original behaviour. Not used for treasury-spend or vesting revoke.
const TIMELOCK_TARGET_GAS: Int = ton("0.12");

/// TON kept on the Timelock when relaying the executor-provided budget to a
/// high-value target (covers Timelock storage rent for the pending map).
const TIMELOCK_STORAGE_RESERVE: Int = ton("0.05");

/// Executor TON floor for a high-value `TimelockExecutePending` (IMP-MNAUD-F08).
/// The re-arm path below relies on the bounce of a failed dispatch actually
/// arriving: a bounce is dropped when the failed target transaction has too
/// little value left to pay the bounce forward fee. This floor guarantees the
/// dispatched message always carries enough headroom (target gates throw within
/// ~0.01 TON of compute), so "failure => bounce" holds. Honest executors attach
/// far more anyway (Treasury MIN_SPEND_FORWARD 2.3 TON, Vesting ReleaseTon 3.5 TON).
const TIMELOCK_HIGH_VALUE_EXEC_MIN: Int = ton("0.1");

struct PendingAction {
    proposalId: Int as uint64;
    proposalContract: Address;
    target: Address;
    method: Int as uint32;
    args: Cell;
    scheduledTime: Int as uint64;
    executed: Bool;
}

contract Timelock(
    governor: Address,
    /// Delay floor (seconds) enforced on high-value TimelockQueue methods (TreasurySpend /
    /// VestEmergencyRevoke): their delay must be > 0 AND >= this floor, so the zero-delay
    /// emergency path can never carry a treasury drain or vesting revoke (IMP-MNAUD-F03,
    /// owner decision 2026-07-27). Init parameter — NOT a compile-time constant — because a
    /// hard-coded 24h floor would make live lab regression of treasury-spend impossible:
    /// mainnet deploys pass 172800 (48h — owner PARAMETERS_DECISION §1), lab short-timer
    /// deploys pass a short floor (same pattern as LAB_GOV_SHORT_TIMERS in bootstrap.ts).
    highValueDelayFloorSec: Int as uint32,
    pendingActions: map<Int as uint64, PendingAction>,
) {
    /// Plain TON from Governor (queue / execute cashback) must not bounce back —
    /// that caused Timelock↔Governor loops (IMP-RELAY-02 / RC-A).
    receive() {
        if (sender() != self.governor) {
            cashback(sender());
        }
    }

    receive(msg: TimelockQueue) {
        require(sender() == self.governor, "Only governor");
        require(self.pendingActions.get(msg.proposalId) == null, "Already queued");
        if (msg.method == TREASURY_SPEND_METHOD || msg.method == VEST_EMERGENCY_REVOKE_METHOD) {
            /// High-value actions must stay publicly visible (and cancellable) for at least
            /// the init-time floor before execution; delay == 0 is forbidden outright
            /// (IMP-MNAUD-F03 / audit MNAUD-3/H-2).
            require(
                msg.delay > 0 && msg.delay >= self.highValueDelayFloorSec,
                "High-value delay below floor",
            );
        } else {
            require(msg.delay == 0 || msg.delay >= TIMELOCK_MIN_DELAY_SEC, "Delay too short");
        }

        self.pendingActions.set(
            msg.proposalId,
            PendingAction {
                proposalId: msg.proposalId,
                proposalContract: msg.proposalContract,
                target: msg.target,
                method: msg.method,
                args: msg.args,
                scheduledTime: now() + msg.delay,
                executed: false,
            },
        );
        /// Absorb queue relay remainder — cashback to Governor ping-ponged via receive()
        /// (IMP-RELAY-02 / RC-A).
    }

    receive(msg: TimelockExecutePending) {
        let actionOpt = self.pendingActions.get(msg.proposalId);
        require(actionOpt != null, "Not queued");
        let action = actionOpt!!;
        require(now() >= action.scheduledTime, "Not yet executable");
        require(!action.executed, "Already executed");

        if (action.method == TREASURY_SPEND_METHOD || action.method == VEST_EMERGENCY_REVOKE_METHOD) {
            /// Bounce-payability floor — see TIMELOCK_HIGH_VALUE_EXEC_MIN.
            require(context().value >= TIMELOCK_HIGH_VALUE_EXEC_MIN, "Execute budget too low");

            /// IMP-MNAUD-F08 (audit MNAUD-7/A-2): a high-value pending action is KEPT
            /// in the map, flagged `executed` (dispatched), instead of being deleted.
            /// If the target aborts, the bounce of the dispatch below re-arms the
            /// entry (`bounced()` receiver), so an approved treasury spend / vesting
            /// revoke can never end up "executed but not performed" with no recovery
            /// path. On success no bounce arrives and the entry stays a
            /// non-re-executable tombstone (governor may TimelockCancel it away).
            action.executed = true;
            self.pendingActions.set(msg.proposalId, action);

            /// Mark the proposal executed at dispatch time (fixed small budget from
            /// the combined balance). On a re-armed retry this is re-sent and the
            /// Proposal rejects it with "Not succeeded" — harmless (bounce:false):
            /// proposal-side PS_EXECUTED means "execution authorized & dispatched";
            /// the Timelock pending map is the source of truth for completion.
            message(MessageParameters {
                to: action.proposalContract,
                value: TIMELOCK_MARK_EXECUTED_GAS,
                mode: SendPayGasSeparately,
                bounce: false,
                body: ProposalMarkExecuted { queryId: msg.queryId }.toCell(),
            });

            /// A bounce only preserves the first 256 bits of the original body, so
            /// rewrite the args' queryId field (bits 32..96) to the proposalId —
            /// the bounce then self-identifies the entry to re-arm. High-value args
            /// are op-prefixed message bodies (TreasurySpend / VestEmergencyRevoke),
            /// enforced here; malformed args fail fast keeping the entry intact.
            let argsSlice = action.args.beginParse();
            let targetOp = argsSlice.loadUint(32);
            require(targetOp == action.method, "Args method mismatch");
            argsSlice.skipBits(64);
            let outBody = beginCell()
                .storeUint(targetOp, 32)
                .storeUint(action.proposalId, 64)
                .storeSlice(argsSlice)
                .endCell();

            /// High-value targets cannot run on a fixed 0.12 TON:
            /// - TreasurySpend: MIN_SPEND_FORWARD (2.3 TON) — post-IMP-MNAUD-F11 the
            ///   claimed-excluded transfer resolves via master with the fee-path gate
            ///   (`minTonFeePath`, governance default 1.0 after F17/F22) + recipient deploy
            /// - VestEmergencyRevoke: Vesting.ReleaseTon (3.5 TON) for excluded transfer
            /// Relay the executor-provided budget end-to-end instead of paying from
            /// Timelock's (storage-only) balance. `SendIgnoreErrors` is intentionally
            /// dropped here so a failed dispatch is not masked, and `bounce: true`
            /// feeds the re-arm path above.
            nativeReserve(TIMELOCK_STORAGE_RESERVE, ReserveAtMost);
            message(MessageParameters {
                to: action.target,
                value: 0,
                mode: SendRemainingBalance,
                bounce: true,
                body: outBody,
            });
            return;
        }

        /// Ordinary targets (parameter / feature / other emergency) keep the original
        /// fire-and-forget semantics: free storage, mark, dispatch with a fixed budget.
        self.pendingActions.del(msg.proposalId);

        message(MessageParameters {
            to: action.proposalContract,
            value: TIMELOCK_MARK_EXECUTED_GAS,
            mode: SendPayGasSeparately,
            bounce: false,
            body: ProposalMarkExecuted { queryId: msg.queryId }.toCell(),
        });

        message(MessageParameters {
            to: action.target,
            value: TIMELOCK_TARGET_GAS,
            mode: SendPayGasSeparately | SendIgnoreErrors,
            bounce: false,
            body: action.args,
        });

        cashback(sender());
    }

    /// IMP-MNAUD-F08: bounced high-value dispatch → re-arm the pending action.
    /// The only bounceable messages this contract ever sends are the high-value
    /// dispatches above (mark / ordinary dispatch / cashback are bounce:false),
    /// and their queryId was rewritten to the proposalId, so the truncated bounce
    /// body carries `op(32) + proposalId(64)`. A bounce is generated by validators
    /// only when the target transaction actually failed, so re-arming here can
    /// never enable double execution of a succeeded action.
    bounced(msg: Slice) {
        if (msg.bits() < 96) {
            return;
        }
        let op = msg.loadUint(32);
        if (op != TREASURY_SPEND_METHOD && op != VEST_EMERGENCY_REVOKE_METHOD) {
            return;
        }
        let proposalId = msg.loadUint(64);
        let actionOpt = self.pendingActions.get(proposalId);
        if (actionOpt == null) {
            return;
        }
        let action = actionOpt!!;
        if (sender() != action.target || !action.executed) {
            return;
        }
        action.executed = false;
        self.pendingActions.set(proposalId, action);
        /// Absorb the bounced-back relay budget into the Timelock balance — the
        /// executor of the retry provides a fresh budget.
    }

    receive(msg: TimelockCancel) {
        require(sender() == self.governor, "Only governor");
        let actionOpt = self.pendingActions.get(msg.proposalId);
        require(actionOpt != null, "Not queued");
        /// IMP-MNAUD-F08: cancelling a dispatched (`executed`) entry is allowed —
        /// it is the governor's storage-cleanup / explicit-disposal path now that
        /// successful high-value dispatches keep their map entry as a tombstone.
        self.pendingActions.del(msg.proposalId);
        /// Absorb cancel relay remainder (IMP-RELAY-02 / RC-A).
    }

    get fun get_pending(id: Int): PendingAction? {
        return self.pendingActions.get(id);
    }

    get fun get_all_pending(): map<Int as uint64, PendingAction> {
        return self.pendingActions;
    }

    get fun get_governor(): Address {
        return self.governor;
    }

    get fun get_high_value_delay_floor(): Int {
        return self.highValueDelayFloorSec;
    }
}
