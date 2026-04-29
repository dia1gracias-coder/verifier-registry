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

    // Compiled StakePosition bytecode — for record-keeping and AdminUpgradePositionCode
    stakePositionCode: Cell;

    // ─── Phase 2 fields — present in storage, no logic in Phase 1 ────────────
    // TON rewards will use newAddress(0, 0) as sentinel key in Phase 2
    rewardPerWeightX128: map<Address, Int>;
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
    // initOf is resolved at compile time using the original StakePosition code,
    // so existing positions remain verifiable even after AdminUpgradePositionCode.
    fun verifyStakePosition(ownerAddress: Address, stakeIndex: Int): Bool {
        let expected: Address = contractAddress(initOf StakePosition(myAddress(), ownerAddress, stakeIndex));
        return expected == sender();
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
        let posInit: StateInit = initOf StakePosition(myAddress(), originalSender, stakeIndex);
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

        message(MessageParameters {
            to: self.stakedJettonWallet!!,
            value: SEND_JETTON_GAS,
            bounce: true,
            mode: SendPayFwdFeesSeparately,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.ownerAddress,
                responseDestination: msg.ownerAddress,
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
    }

    // ─── Admin operations (owner only) ────────────────────────────────────────

    // Sets the Jetton wallet address for this contract (called once after deploy)
    receive(msg: AdminSetStakedJettonWallet) {
        self.requireOwner();
        self.stakedJettonWallet = msg.wallet;
        cashback(sender());
    }

    // Adds a new staking period
    receive(msg: AdminAddPeriod) {
        self.requireOwner();
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
        let posInit: StateInit = initOf StakePosition(myAddress(), msg.ownerAddress, msg.stakeIndex);
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
        let posInit: StateInit = initOf StakePosition(myAddress(), msg.ownerAddress, msg.stakeIndex);
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

    // Updates the recorded StakePosition code used for new deployments
    receive(msg: AdminUpgradePositionCode) {
        self.requireOwner();
        self.stakePositionCode = msg.newCode;
        cashback(sender());
    }

    // Releases a stuck claimInFlight lock on a StakePosition (admin emergency).
    // Use when ClaimRewardConfirmed was lost and the position can no longer claim.
    receive(msg: AdminForceReleaseLock) {
        self.requireOwner();
        let posInit: StateInit = initOf StakePosition(myAddress(), msg.ownerAddress, msg.stakeIndex);
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
        return contractAddress(initOf StakePosition(myAddress(), ownerAddr, stakeIndex));
    }

    get fun get_next_stake_index(ownerAddr: Address): Int {
        let maybeIndex: Int? = self.nextStakeIndex.get(ownerAddr);
        return maybeIndex != null ? maybeIndex!! : 0;
    }

    get fun get_storage_version(): Int {
        return self.storageVersion;
    }
}
