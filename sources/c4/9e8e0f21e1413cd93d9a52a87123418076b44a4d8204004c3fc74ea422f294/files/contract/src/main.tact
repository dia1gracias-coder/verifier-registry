import "@stdlib/ownable";
import "./messages";
import "./stake_position";

// SETCODE opcode — replaces this contract's code in the next transaction
asm fun setContractCode(code: Cell) { SETCODE }

contract StakingMaster with Ownable {
    // ─── Ownable ──────────────────────────────────────────────────────────────
    owner: Address;

    // ─── Versioning ───────────────────────────────────────────────────────────
    storageVersion: Int as uint32;

    // ─── Administration ───────────────────────────────────────────────────────
    newOwnerAddress: Address?;
    isPaused: Bool;

    // ─── Staking configuration ────────────────────────────────────────────────
    stakedJettonMaster: Address;
    stakedJettonWallet: Address?; // set by admin after deploy
    periods: map<Int, PeriodConfig>;
    nextPeriodId: Int as uint8;

    // ─── Stake state ──────────────────────────────────────────────────────────
    nextStakeIndex: map<Address, Int>;
    totalActiveWeight: Int as uint256;
    totalStakedTokens: Int as uint256;

    // Compiled StakePosition bytecode — used for all new StakePosition deploys and address computation
    stakePositionCode: Cell;

    // ─── Pending withdrawals ──────────────────────────────────────────────────
    // Tracks in-flight JettonTransfers keyed by queryId.
    // Cleaned up on JettonExcesses (success) or bounced JettonTransfer (failure).
    pendingWithdrawals: map<Int, PendingWithdrawal>;

    // ─── Pending position inits ───────────────────────────────────────────────
    // Tracks in-flight PositionInit deploys keyed by StakePosition address.
    // Cleaned up on PositionInitSuccess (success) or bounced PositionInit (failure).
    pendingPositionInits: map<Address, PendingPositionInit>;

    // ─── Phase 2 fields — present in storage, no logic in Phase 1 ────────────
    // TON rewards will use newAddress(0, 0) as sentinel key in Phase 2
    rewardPerWeightX128: map<Address, Int as uint256>;
    trustedSenders: map<Address, Bool>;
    allowedRewardJettons: map<Address, Bool>;
    rewardJettonWallets: map<Address, Address>;
    tonRewardEnabled: Bool;
    totalClaimed: map<Address, Int as uint256>;
    totalRewardDeposited: map<Address, Int as uint256>;

    // ─── Constructor ──────────────────────────────────────────────────────────

    init(stakedJettonMaster: Address, stakePositionCode: Cell) {
        self.owner = sender();
        self.storageVersion = 1;
        self.newOwnerAddress = null;
        self.isPaused = false;
        self.stakedJettonMaster = stakedJettonMaster;
        self.stakedJettonWallet = null;
        self.nextPeriodId = 0;
        self.totalActiveWeight = 0;
        self.totalStakedTokens = 0;
        self.stakePositionCode = stakePositionCode;
        self.tonRewardEnabled = false;
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    // Verifies that the current sender is the expected StakePosition contract.
    fun verifyStakePosition(ownerAddress: Address, stakeIndex: Int): Bool {
        let expected: Address = contractAddress(self.stakePositionStateInit(ownerAddress, stakeIndex));
        return expected == sender();
    }

    // Builds a StateInit for a StakePosition using self.stakePositionCode.
    // initOf supplies only the data cell (serialized init storage for the given args)
    fun stakePositionStateInit(ownerAddress: Address, stakeIndex: Int): StateInit {
        return StateInit {
            code: self.stakePositionCode,
            data: initOf StakePosition(myAddress(), ownerAddress, stakeIndex).data,
        };
    }

    // Accepts the initial deployment message
    receive() {}

    // ─── Core staking flow ────────────────────────────────────────────────────

    // TEP-74 transfer_notification — receives staked Jetton tokens from users
    receive(msg: JettonTransferNotification) {
        // Critical: accept only from our registered Jetton wallet
        require(self.stakedJettonWallet != null, "Jetton wallet not configured");
        require(sender() == self.stakedJettonWallet!!, "Unauthorized: not staked jetton wallet");
        require(!self.isPaused, "Staking is paused");
        require(msg.amount > 0, "Zero stake not permitted");

        // Prevent stuck tokens from empty forward payloads
        require(msg.forwardPayload.bits() >= 8, "Missing period_id in payload");
        let periodId: Int = msg.forwardPayload.loadUint(8);

        let period: PeriodConfig? = self.periods.get(periodId);
        require(period != null, "Period does not exist");
        require(period!!.isActive, "Period is not active");

        let originalSender: Address = msg.sender;
        let maybeIndex: Int? = self.nextStakeIndex.get(originalSender);
        let stakeIndex: Int = maybeIndex != null ? maybeIndex!! : 0;
        let weight: Int = msg.amount * period!!.multiplierX100 / 100;

        // Deploy StakePosition and send PositionInit in one message
        let posInit: StateInit = self.stakePositionStateInit(originalSender, stakeIndex);
        self.pendingPositionInits.set(contractAddress(posInit), PendingPositionInit {
            ownerAddress: originalSender,
            stakeIndex,
            amount: msg.amount,
            weight,
            queryId: msg.queryId,
        });
        deploy(DeployParameters {
            init: posInit,
            value: DEPLOY_STAKE_POSITION_GAS,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: PositionInit {
                amount: msg.amount,
                periodId,
                multiplierX100: period!!.multiplierX100,
                weight,
                startTime: now(),
                endTime: now() + period!!.durationSeconds,
                totalTranches: TOTAL_TRANCHES,
                trancheInterval: TRANCHE_INTERVAL,
                // Phase 2: populate with current rewardPerWeightX128 snapshot so new
                // positions start earning from the correct baseline.
                // Phase 1: empty map — positions start with zero reward debt.
                rewardDebtSnapshot: emptyMap(),
            }.toCell(),
        });

        self.totalActiveWeight = self.totalActiveWeight + weight;
        self.totalStakedTokens = self.totalStakedTokens + msg.amount;
        self.nextStakeIndex.set(originalSender, stakeIndex + 1);

        // Return any excess TON to the original user — master is admin-maintained
        // and should not accumulate gas paid by users.
        cashback(originalSender);
    }

    // Called by StakePosition when the staking period ends; decrements active weight.
    // Phase 2: use msg.rewardDebt to compute pending rewards per token, then send
    //   PositionFinishedAck back so the position can store them in pendingRewards.
    // Phase 1: msg.rewardDebt is always an empty map — nothing extra to do here.
    receive(msg: PositionFinished) {
        require(self.verifyStakePosition(msg.ownerAddress, msg.stakeIndex), "Invalid StakePosition sender");
        require(self.totalActiveWeight >= msg.weight, "Weight underflow");
        self.totalActiveWeight = self.totalActiveWeight - msg.weight;

        // Return the forwarded gas to the position so it can maintain its rent reserve.
        cashback(sender());
    }

    // Called by StakePosition on withdraw; sends staked Jetton tokens back to the owner
    receive(msg: SendStakedJettonToOwner) {
        require(self.verifyStakePosition(msg.ownerAddress, msg.stakeIndex), "Invalid StakePosition sender");
        require(self.stakedJettonWallet != null, "Jetton wallet not configured");

        // Guard: never pay out more than the tracked staked total.
        // In normal operation this cannot trigger, but protects against storage
        // corruption or upgrade bugs where totalStakedTokens drifts below the
        // position's recorded amount. Return gas to the position so it can retry.
        if (msg.amount > self.totalStakedTokens) {
            message(MessageParameters {
                to: sender(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue,
                body: WithdrawFailed { amount: msg.amount }.toCell(),
            });
            return;
        }

        self.totalStakedTokens = self.totalStakedTokens - msg.amount;
        self.pendingWithdrawals.set(msg.queryId, PendingWithdrawal {
            ownerAddress: msg.ownerAddress,
            stakeIndex: msg.stakeIndex,
            amount: msg.amount,
        });

        message(MessageParameters {
            to: self.stakedJettonWallet!!,
            value: SEND_JETTON_GAS,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.ownerAddress,
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
    }

    // Jetton wallet reports excess TON after a successful transfer — clean up the
    // in-flight record so pendingWithdrawals does not grow unbounded.
    receive(msg: JettonExcesses) {
        self.pendingWithdrawals.del(msg.queryId);
        cashback(sender());
    }

    // StakePosition confirms PositionInit was applied — clean up the pending-init record.
    receive(msg: PositionInitSuccess) {
        self.pendingPositionInits.del(sender());
        cashback(sender());
    }

    // PositionInit bounced — the StakePosition rejected the init message.
    // Revert totalActiveWeight, totalStakedTokens, nextStakeIndex, and return tokens to user.
    // We cannot parse PositionInit fields from the bounce (224-bit truncation),
    // so we look up the pending record by the StakePosition address (= sender()).
    bounced(msg: bounced<PositionInit>) {
        let pending: PendingPositionInit? = self.pendingPositionInits.get(sender());
        if (pending == null) {
            return;
        }
        self.pendingPositionInits.del(sender());

        self.totalActiveWeight = self.totalActiveWeight - pending!!.weight;
        self.totalStakedTokens = self.totalStakedTokens - pending!!.amount;
        self.nextStakeIndex.set(pending!!.ownerAddress, pending!!.stakeIndex);

        // Return staked tokens to the user using the existing JettonTransfer path.
        self.pendingWithdrawals.set(pending!!.queryId, PendingWithdrawal {
            ownerAddress: pending!!.ownerAddress,
            stakeIndex: pending!!.stakeIndex,
            amount: pending!!.amount,
        });
        message(MessageParameters {
            to: self.stakedJettonWallet!!,
            value: SEND_JETTON_GAS,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: JettonTransfer {
                queryId: pending!!.queryId,
                amount: pending!!.amount,
                destination: pending!!.ownerAddress,
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: 1,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
    }

    // JettonTransfer bounced — restore totalStakedTokens and notify the position
    // so it can roll back withdrawnAmount and allow the user to retry.
    bounced(msg: bounced<JettonTransfer>) {
        // Defense-in-depth: bounces of our outgoing JettonTransfers must come from stakedJettonWallet.
        // The pendingWithdrawals lookup below is the primary guard; this is an early exit for
        // messages arriving from unexpected sources.
        if (self.stakedJettonWallet == null || sender() != self.stakedJettonWallet!!) {
            return;
        }
        let pending: PendingWithdrawal? = self.pendingWithdrawals.get(msg.queryId);
        if (pending == null) {
            return;
        }
        self.totalStakedTokens = self.totalStakedTokens + pending!!.amount;
        self.pendingWithdrawals.del(msg.queryId);

        let posInit: StateInit = self.stakePositionStateInit(pending!!.ownerAddress, pending!!.stakeIndex);
        message(MessageParameters {
            to: contractAddress(posInit),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: WithdrawFailed { amount: pending!!.amount }.toCell(),
        });
    }

    // Phase 1 stub: immediately confirms reward claim with unchanged debt so the position's
    // claimInFlight lock is released. Prevents users from permanently locking their position
    // when ClaimRewards is called before Phase 2 master logic is active.
    receive(msg: ClaimRewardRequest) {
        require(self.verifyStakePosition(msg.ownerAddress, msg.stakeIndex), "Invalid StakePosition sender");
        message(MessageParameters {
            to: sender(),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: ClaimRewardConfirmed {
                token: msg.token,
                newDebt: msg.rewardDebt,
            }.toCell(),
        });
    }

    // ─── Admin operations (owner only) ────────────────────────────────────────

    // Sets the Jetton wallet address for this contract (called once after deploy)
    receive(msg: AdminSetStakedJettonWallet) {
        self.requireOwner();
        require(self.stakedJettonWallet == null, "Jetton wallet already configured");
        self.stakedJettonWallet = msg.wallet;
        cashback(sender());
    }

    // Adds a new staking period
    receive(msg: AdminAddPeriod) {
        self.requireOwner();
        require(self.nextPeriodId < 255, "Maximum number of periods reached");
        require(msg.durationSeconds > 0, "Period duration must be positive");
        require(msg.multiplierX100 > 0, "Period multiplier must be positive");
        let id: Int = self.nextPeriodId;
        self.periods.set(id, PeriodConfig {
            periodId: id,
            durationSeconds: msg.durationSeconds,
            multiplierX100: msg.multiplierX100,
            isActive: true,
        });
        self.nextPeriodId = self.nextPeriodId + 1;
        cashback(sender());
    }

    // Enables or disables an existing staking period
    receive(msg: AdminUpdatePeriodStatus) {
        self.requireOwner();
        let existing: PeriodConfig? = self.periods.get(msg.periodId);
        require(existing != null, "Period not found");
        self.periods.set(msg.periodId, PeriodConfig {
            periodId: existing!!.periodId,
            durationSeconds: existing!!.durationSeconds,
            multiplierX100: existing!!.multiplierX100,
            isActive: msg.isActive,
        });
        cashback(sender());
    }

    // Pauses or unpauses acceptance of new stakes
    receive(msg: AdminSetPause) {
        self.requireOwner();
        self.isPaused = msg.isPaused;
        cashback(sender());
    }

    // Forcibly moves an active position to vesting (emergency use)
    receive(msg: AdminForceFinishPosition) {
        self.requireOwner();
        let posInit: StateInit = self.stakePositionStateInit(msg.ownerAddress, msg.stakeIndex);
        // Forward enough TON for the position to pay gas and send its own PositionFinished sub-message
        message(MessageParameters {
            to: contractAddress(posInit),
            value: ton("0.1"),
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: FinishStake { queryId: msg.queryId }.toCell(),
        });
        cashback(sender());
    }

    // Forcibly withdraws available vested tokens on behalf of the owner (emergency use)
    receive(msg: AdminForceWithdrawPosition) {
        self.requireOwner();
        let posInit: StateInit = self.stakePositionStateInit(msg.ownerAddress, msg.stakeIndex);
        // Forward enough TON for the position to pay SEND_JETTON_GAS and its own gas
        message(MessageParameters {
            to: contractAddress(posInit),
            value: ton("0.15"),
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: Withdraw { queryId: msg.queryId }.toCell(),
        });
        cashback(sender());
    }

    // Withdraws TON (Phase 1) to the specified destination (admin is responsible for amounts)
    receive(msg: AdminEmergencyWithdraw) {
        self.requireOwner();
        message(MessageParameters {
            to: msg.destination,
            value: msg.amount,
            bounce: false,
            mode: SendPayFwdFeesSeparately,
            body: null,
        });
        cashback(sender());
    }

    // Step 1 of two-step ownership transfer: records the pending new owner
    receive(msg: AdminTransferOwnership) {
        self.requireOwner();
        self.newOwnerAddress = msg.newOwner;
        cashback(sender());
    }

    // Step 2 of two-step ownership transfer: must be called by the pending new owner
    receive(msg: AdminAcceptOwnership) {
        require(self.newOwnerAddress != null, "No pending ownership transfer");
        require(sender() == self.newOwnerAddress!!, "Not the pending new owner");
        self.owner = self.newOwnerAddress!!;
        self.newOwnerAddress = null;
        cashback(sender());
    }

    // Replaces this contract's code (storage is preserved)
    receive(msg: AdminUpgradeMasterCode) {
        self.requireOwner();
        setContractCode(msg.newCode);
        cashback(sender());
    }

    // Releases a stuck claimInFlight lock on a StakePosition (admin emergency).
    // Use when ClaimRewardConfirmed was lost and the position can no longer claim.
    receive(msg: AdminForceReleaseLock) {
        self.requireOwner();
        let posInit: StateInit = self.stakePositionStateInit(msg.ownerAddress, msg.stakeIndex);
        message(MessageParameters {
            to: contractAddress(posInit),
            value: ton("0.05"),
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: ReleaseLock { token: msg.token }.toCell(),
        });
        cashback(sender());
    }

    // Updates the storage version marker (used after a storage migration)
    receive(msg: AdminMigrateStorage) {
        self.requireOwner();
        self.storageVersion = msg.newVersion;
        cashback(sender());
    }

    // ─── Get methods ──────────────────────────────────────────────────────────

    get fun get_config(): MasterConfig {
        return MasterConfig {
            owner: self.owner,
            isPaused: self.isPaused,
            stakedJettonMaster: self.stakedJettonMaster,
            stakedJettonWallet: self.stakedJettonWallet,
            totalActiveWeight: self.totalActiveWeight,
            totalStakedTokens: self.totalStakedTokens,
            nextPeriodId: self.nextPeriodId,
            storageVersion: self.storageVersion,
        };
    }

    get fun get_period_config(periodId: Int): PeriodConfig {
        let p: PeriodConfig? = self.periods.get(periodId);
        require(p != null, "Period not found");
        return p!!;
    }

    get fun get_all_periods(): map<Int, PeriodConfig> {
        return self.periods;
    }

    get fun get_total_weight(): Int {
        return self.totalActiveWeight;
    }

    get fun get_total_staked_tokens(): Int {
        return self.totalStakedTokens;
    }

    get fun get_stake_position_address(ownerAddr: Address, stakeIndex: Int): Address {
        return contractAddress(self.stakePositionStateInit(ownerAddr, stakeIndex));
    }

    get fun get_next_stake_index(ownerAddr: Address): Int {
        let maybeIndex: Int? = self.nextStakeIndex.get(ownerAddr);
        return maybeIndex != null ? maybeIndex!! : 0;
    }

    get fun get_storage_version(): Int {
        return self.storageVersion;
    }

    get fun get_pending_withdrawal(queryId: Int): PendingWithdrawal? {
        return self.pendingWithdrawals.get(queryId);
    }
}
