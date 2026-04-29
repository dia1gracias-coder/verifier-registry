import "./messages";

contract StakePosition {
    // ─── Storage ──────────────────────────────────────────────────────────────
    storageVersion: Int as uint32;

    // Identification fields — determine the contract address (part of init data)
    masterAddress: Address;
    ownerAddress: Address;
    stakeIndex: Int as uint64;

    // Set by PositionInit message
    amount: Int as coins;
    periodId: Int as uint8;
    multiplierX100: Int as uint16;
    weight: Int as uint256;
    startTime: Int as uint32;
    endTime: Int as uint32;

    // Status lifecycle: 0 = active | 1 = vesting | 2 = fully_withdrawn
    status: Int as uint2;

    // Populated when finish_stake is called
    vestingStart: Int as uint32;
    withdrawnAmount: Int as coins;

    // Guards against double-init (PositionInit accepted only once)
    initialized: Bool;

    // Phase 2 fields — present in storage layout for forward-compatibility.
    // In Phase 1 these maps are always empty; Phase 2 master activates the logic.
    rewardDebtX128: map<Address, Int>;
    pendingRewards: map<Address, Int>;

    // Prevents double-claim race: set to true when ClaimRewards is sent to master,
    // cleared when ClaimRewardConfirmed (or ClaimFailed / ReleaseLock) is received.
    claimInFlight: map<Address, Bool>;

    // ─── Constructor ──────────────────────────────────────────────────────────

    init(masterAddress: Address, ownerAddress: Address, stakeIndex: Int) {
        self.storageVersion = 1;
        self.masterAddress = masterAddress;
        self.ownerAddress = ownerAddress;
        self.stakeIndex = stakeIndex;
        self.amount = 0;
        self.periodId = 0;
        self.multiplierX100 = 0;
        self.weight = 0;
        self.startTime = 0;
        self.endTime = 0;
        self.status = 0;
        self.vestingStart = 0;
        self.withdrawnAmount = 0;
        self.initialized = false;
    }

    // ─── Vesting helpers ──────────────────────────────────────────────────────

    // Returns how many tranches are unlocked right now (1-based; first tranche unlocked immediately)
    fun vestedTranches(): Int {
        let elapsed: Int = now() - self.vestingStart;
        let t: Int = elapsed / TRANCHE_INTERVAL + 1;
        if (t > TOTAL_TRANCHES) {
            return TOTAL_TRANCHES;
        }
        return t;
    }

    // Returns total vested coin amount at the current moment
    fun vestedAmount(): Int {
        return self.amount * self.vestedTranches() / TOTAL_TRANCHES;
    }

    // Returns the amount available to withdraw right now
    fun availableToWithdraw(): Int {
        return self.vestedAmount() - self.withdrawnAmount;
    }

    // ─── Receivers ────────────────────────────────────────────────────────────

    // Initialisation message sent by StakingMaster together with the deploy state_init.
    // Phase 2: stores the rpw snapshot so reward debt starts at the correct value.
    // Phase 1: snapshot is always an empty map, so debt effectively starts at 0.
    receive(msg: PositionInit) {
        require(sender() == self.masterAddress, "Only master can init");
        require(!self.initialized, "Already initialized");

        self.amount = msg.amount;
        self.periodId = msg.periodId;
        self.multiplierX100 = msg.multiplierX100;
        self.weight = msg.weight;
        self.startTime = msg.startTime;
        self.endTime = msg.endTime;
        self.rewardDebtX128 = msg.rewardDebtSnapshot;
        self.initialized = true;

        // Reserve minimum balance for rent, return the rest to master
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: self.masterAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // Moves the stake from active → vesting once the staking period has elapsed.
    // Phase 2: rewardDebt is included in PositionFinished so master can snapshot
    //   pending rewards and send PositionFinishedAck back.
    // Phase 1: rewardDebt is always an empty map; master ignores it.
    receive(msg: FinishStake) {
        let s: Address = sender();
        require(s == self.ownerAddress || s == self.masterAddress, "Unauthorized");
        require(self.initialized, "Not initialized");
        require(self.status == STATUS_ACTIVE, "Not active");
        require(now() >= self.endTime, "Staking period not over");

        self.status = STATUS_VESTING;
        self.vestingStart = now();

        // Notify master to decrement totalActiveWeight.
        // Phase 2 master will also compute pending rewards from rewardDebt and
        // reply with PositionFinishedAck to store them in pendingRewards.
        message(MessageParameters {
            to: self.masterAddress,
            value: FINISH_STAKE_GAS,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: PositionFinished {
                ownerAddress: self.ownerAddress,
                stakeIndex: self.stakeIndex,
                weight: self.weight,
                rewardDebt: self.rewardDebtX128,
            }.toCell(),
        });

        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: s,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // Withdraws available vested tokens.
    // State (withdrawnAmount) is updated before the outgoing message to master,
    // which prevents a double-withdraw race: a second Withdraw processed before
    // the Jetton transfer completes will see available = 0 and be rejected.
    receive(msg: Withdraw) {
        let s: Address = sender();
        require(s == self.ownerAddress || s == self.masterAddress, "Unauthorized");
        require(self.initialized, "Not initialized");
        require(self.status == STATUS_VESTING, "Not in vesting");

        let available: Int = self.availableToWithdraw();
        require(available > 0, "Nothing to withdraw");

        // Update state first — prevents any concurrent Withdraw from double-spending.
        self.withdrawnAmount = self.withdrawnAmount + available;
        if (self.withdrawnAmount >= self.amount) {
            self.status = STATUS_FULLY_WITHDRAWN;
        }

        // Ask master to transfer the staked tokens back to the owner.
        // If the transfer fails, master will send WithdrawFailed to roll back the state.
        message(MessageParameters {
            to: self.masterAddress,
            value: SEND_JETTON_GAS,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: SendStakedJettonToOwner {
                ownerAddress: self.ownerAddress,
                stakeIndex: self.stakeIndex,
                amount: available,
                queryId: msg.queryId,
            }.toCell(),
        });

        // Reserve minimum for rent, return the rest. Contract stays alive after full
        // withdrawal so Phase 2 reward claiming remains possible.
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: s,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // ─── Phase 2 reward handlers (stubs active in Phase 1) ────────────────────

    // Initiates a reward claim for a single token. Guarded by claimInFlight to
    // prevent a double-claim race: master processes ClaimRewardRequest asynchronously,
    // so a second ClaimRewards arriving before ClaimRewardConfirmed would read stale
    // debt/pending and cause master to pay out twice.
    // Phase 1: ClaimRewardRequest is unknown to master and will bounce; the lock
    //   will remain set until ReleaseLock or ClaimFailed is received.
    receive(msg: ClaimRewards) {
        let s: Address = sender();
        require(s == self.ownerAddress || s == self.masterAddress, "Unauthorized");
        require(self.initialized, "Not initialized");

        let maybePending: Int? = self.pendingRewards.get(msg.token);
        let pending: Int = maybePending != null ? maybePending!! : 0;
        require(self.status != STATUS_FULLY_WITHDRAWN || pending > 0, "Nothing to claim");

        let maybeInFlight: Bool? = self.claimInFlight.get(msg.token);
        require(!(maybeInFlight != null && maybeInFlight!!), "Claim already in progress for this token");
        self.claimInFlight.set(msg.token, true);

        // Finished positions no longer contribute to totalActiveWeight in master.
        // Sending weight = 0 ensures master computes earned = 0 and returns only pendingFixed.
        let effectiveWeight: Int = (self.status == STATUS_ACTIVE) ? self.weight : 0;
        let maybeDebt: Int? = self.rewardDebtX128.get(msg.token);
        let debt: Int = maybeDebt != null ? maybeDebt!! : 0;

        message(MessageParameters {
            to: self.masterAddress,
            value: CLAIM_REWARD_GAS,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: ClaimRewardRequest {
                ownerAddress: self.ownerAddress,
                stakeIndex: self.stakeIndex,
                token: msg.token,
                rewardDebt: debt,
                weight: effectiveWeight,
                pendingFixed: pending,
            }.toCell(),
        });
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: s,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // Confirms reward payout and updates debt so the next claim starts from here.
    receive(msg: ClaimRewardConfirmed) {
        require(sender() == self.masterAddress, "Only master");
        self.rewardDebtX128.set(msg.token, msg.newDebt);
        self.pendingRewards.del(msg.token);
        self.claimInFlight.del(msg.token);
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: self.masterAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // Stores pending rewards snapshotted by master when the position finished.
    // Phase 1: never invoked — Phase 1 master does not send PositionFinishedAck.
    receive(msg: PositionFinishedAck) {
        require(sender() == self.masterAddress, "Only master");
        foreach (token, amount in msg.pendingRewards) {
            let maybeExisting: Int? = self.pendingRewards.get(token);
            let existing: Int = maybeExisting != null ? maybeExisting!! : 0;
            self.pendingRewards.set(token, existing + amount);
        }
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: self.masterAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // Releases a stuck in-flight claim lock. Called by master on admin request
    // (AdminForceReleaseLock) when ClaimRewardConfirmed is lost due to network issues.
    receive(msg: ReleaseLock) {
        require(sender() == self.masterAddress, "Only master");
        self.claimInFlight.del(msg.token);
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: self.masterAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // Notifies that the reward payout failed (e.g. reward pool drained by admin).
    // Releases the lock without changing debt or pending so the user can retry.
    receive(msg: ClaimFailed) {
        require(sender() == self.masterAddress, "Only master");
        self.claimInFlight.del(msg.token);
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: self.masterAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // Notifies that the Jetton withdraw transfer failed (e.g. insufficient balance).
    // Reverts withdrawnAmount so the user can retry the withdrawal.
    receive(msg: WithdrawFailed) {
        require(sender() == self.masterAddress, "Only master");
        self.withdrawnAmount = self.withdrawnAmount - msg.amount;
        // Revert fully-withdrawn status if it was set during this withdraw
        if (self.status == STATUS_FULLY_WITHDRAWN) {
            self.status = STATUS_VESTING;
        }
        nativeReserve(POSITION_MIN_BALANCE, 0);
        message(MessageParameters {
            to: self.masterAddress,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: null,
        });
    }

    // ─── Get methods ──────────────────────────────────────────────────────────

    get fun get_info(): StakePositionInfo {
        return StakePositionInfo {
            masterAddress: self.masterAddress,
            ownerAddress: self.ownerAddress,
            stakeIndex: self.stakeIndex,
            amount: self.amount,
            periodId: self.periodId,
            multiplierX100: self.multiplierX100,
            weight: self.weight,
            startTime: self.startTime,
            endTime: self.endTime,
            status: self.status,
            vestingStart: self.vestingStart,
            withdrawnAmount: self.withdrawnAmount,
            initialized: self.initialized,
            storageVersion: self.storageVersion,
        };
    }

    get fun get_status(): Int {
        return self.status;
    }

    get fun get_available_to_withdraw(): Int {
        if (self.status != STATUS_VESTING) {
            return 0;
        }
        let a: Int = self.availableToWithdraw();
        if (a < 0) {
            return 0;
        }
        return a;
    }

    get fun get_vested_amount(): Int {
        if (self.status != STATUS_VESTING) {
            return 0;
        }
        return self.vestedAmount();
    }

    get fun get_storage_version(): Int {
        return self.storageVersion;
    }
}
