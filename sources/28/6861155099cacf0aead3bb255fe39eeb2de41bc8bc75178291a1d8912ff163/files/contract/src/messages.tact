// ─── Vesting constants ───────────────────────────────────────────────────────
const TOTAL_TRANCHES: Int = 10;
const TRANCHE_INTERVAL: Int = 300; // 7 * 24 * 3600 seconds

// ─── Stake status ────────────────────────────────────────────────────────────
const STATUS_ACTIVE: Int = 0;
const STATUS_VESTING: Int = 1;
const STATUS_FULLY_WITHDRAWN: Int = 2;

// ─── Gas forwarding budgets (tune with printTransactionFees in tests) ─────────
const DEPLOY_STAKE_POSITION_GAS: Int = ton("0.1");
const SEND_JETTON_GAS: Int = ton("0.08");
const FINISH_STAKE_GAS: Int = ton("0.05");
const CLAIM_REWARD_GAS: Int = ton("0.12");

// Minimum TON kept in every StakePosition for storage rent.
// nativeReserve(POSITION_MIN_BALANCE, 0) locks this before each cashback so the
// contract survives indefinitely (needed for Phase 2 reward claiming after withdrawal).
const POSITION_MIN_BALANCE: Int = ton("0.05");

// ─── Shared structs ──────────────────────────────────────────────────────────

struct PeriodConfig {
    periodId: Int as uint8;
    durationSeconds: Int as uint32;
    multiplierX100: Int as uint16;
    isActive: Bool;
}

struct MasterConfig {
    owner: Address;
    isPaused: Bool;
    stakedJettonMaster: Address;
    stakedJettonWallet: Address?;
    totalActiveWeight: Int as uint256;
    totalStakedTokens: Int as uint256;
    nextPeriodId: Int as uint8;
    storageVersion: Int as uint32;
}

struct StakePositionInfo {
    masterAddress: Address;
    ownerAddress: Address;
    stakeIndex: Int as uint64;
    amount: Int as coins;
    periodId: Int as uint8;
    multiplierX100: Int as uint16;
    weight: Int as uint256;
    startTime: Int as uint32;
    endTime: Int as uint32;
    status: Int as uint2;
    vestingStart: Int as uint32;
    withdrawnAmount: Int as coins;
    initialized: Bool;
    storageVersion: Int as uint32;
}

// ─── TEP-74 Jetton messages ───────────────────────────────────────────────────

// Arrives from the Jetton wallet when someone sends tokens to this contract
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

// Sent from StakingMaster to its Jetton wallet to transfer tokens to a recipient
message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// Sent by the Jetton wallet to responseDestination after a successful transfer
message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

// Stored in master while a JettonTransfer is in-flight; removed on success or bounce
struct PendingWithdrawal {
    ownerAddress: Address;
    stakeIndex: Int as uint64;
    amount: Int as coins;
}

// ─── Internal messages: Master ↔ StakePosition ───────────────────────────────

// Master → StakePosition: sent together with the deploy state_init.
// rewardDebtSnapshot: Phase 2 master populates this with current rewardPerWeightX128;
//   Phase 1 master sends an empty map so positions start with zero reward debt.
message(0x1) PositionInit {
    amount: Int as coins;
    periodId: Int as uint8;
    multiplierX100: Int as uint16;
    weight: Int as uint256;
    startTime: Int as uint32;
    endTime: Int as uint32;
    rewardDebtSnapshot: map<Address, Int as uint256>; // Phase 2: rpw snapshot at stake time; empty in Phase 1
}

// StakePosition → Master: notifies master that the staking period has ended.
// rewardDebt: Phase 2 master uses this to compute pending rewards before
//   sending PositionFinishedAck. Phase 1 master ignores it (always empty map).
message(0x2) PositionFinished {
    ownerAddress: Address;
    stakeIndex: Int as uint64;
    weight: Int as uint256;
    rewardDebt: map<Address, Int as uint256>; // Phase 2: position's rewardDebtX128 at finish; empty in Phase 1
}

// StakePosition → Master: requests transfer of staked tokens back to the owner
message(0x3) SendStakedJettonToOwner {
    ownerAddress: Address;
    stakeIndex: Int as uint64;
    amount: Int as coins;
    queryId: Int as uint64;
}

// User/Master → StakePosition: request to move from active to vesting
message(0x4) FinishStake {
    queryId: Int as uint64;
}

// User/Master → StakePosition: request to withdraw available vested amount
message(0x5) Withdraw {
    queryId: Int as uint64;
}

// ─── Phase 2 reward messages ──────────────────────────────────────────────────
// These messages are defined in Phase 1 so deployed StakePositions can handle
// them without a code upgrade when master is upgraded to Phase 2.

// User/Master → StakePosition: initiates a reward claim for a single token.
// TON rewards use newAddress(0, 0) as the token sentinel address.
message(0x6) ClaimRewards {
    queryId: Int as uint64;
    token: Address;
}

// StakePosition → Master: carries position state needed to compute the payout.
// weight is 0 for non-active positions so master computes earned = 0 and returns
// only pendingFixed (which was snapshotted at PositionFinished time).
message(0x30) ClaimRewardRequest {
    ownerAddress: Address;
    stakeIndex: Int as uint64;
    token: Address;
    rewardDebt: Int as uint256; // rewardDebtX128[token] ?? 0
    weight: Int as uint256; // self.weight if ACTIVE, else 0
    pendingFixed: Int as coins; // pendingRewards[token] ?? 0
}

// Master → StakePosition: confirms reward payout; carries the new debt value.
message(0x31) ClaimRewardConfirmed {
    token: Address;
    newDebt: Int as uint256; // current rewardPerWeightX128[token] from master
}

// Master → StakePosition (Phase 2 only): delivers the pending rewards snapshot
// computed by master at PositionFinished time. Never sent in Phase 1.
message(0x32) PositionFinishedAck {
    pendingRewards: map<Address, Int as coins>; // token → rewards earned during active period
}

// Master → StakePosition: releases a stuck in-flight claim lock (admin emergency).
// Sent via AdminForceReleaseLock if ClaimRewardConfirmed is lost and the position is frozen.
message(0x33) ReleaseLock {
    token: Address;
}

// Master → StakePosition: notifies that the reward payout failed (e.g. pool drained).
// Position releases the lock so the user can retry without losing their pending rewards.
message(0x34) ClaimFailed {
    token: Address;
}

// Master → StakePosition: notifies that the Jetton withdraw transfer failed
// (e.g. insufficient staked token balance on master). Position reverts withdrawnAmount
// so the user can retry the withdrawal.
message(0x35) WithdrawFailed {
    amount: Int as coins; // the amount to roll back
}

// StakePosition → Master: confirms PositionInit was applied successfully.
// Triggers cleanup of the in-flight pendingPositionInits entry in master.
message(0x36) PositionInitSuccess {}

// Stored in master while a PositionInit deploy is in-flight; removed on success or bounce.
struct PendingPositionInit {
    ownerAddress: Address;
    stakeIndex: Int as uint64;
    amount: Int as coins;
    weight: Int as uint256;
    queryId: Int as uint64; // original JettonTransferNotification queryId
}

// ─── Admin messages (owner-only, StakingMaster) ───────────────────────────────

message(0x10) AdminSetStakedJettonWallet {
    wallet: Address;
}

message(0x11) AdminAddPeriod {
    durationSeconds: Int as uint32;
    multiplierX100: Int as uint16;
}

message(0x12) AdminUpdatePeriodStatus {
    periodId: Int as uint8;
    isActive: Bool;
}

message(0x13) AdminSetPause {
    isPaused: Bool;
}

message(0x14) AdminForceFinishPosition {
    queryId: Int as uint64;
    ownerAddress: Address;
    stakeIndex: Int as uint64;
}

message(0x15) AdminEmergencyWithdraw {
    amount: Int as coins;
    destination: Address;
}

message(0x16) AdminTransferOwnership {
    newOwner: Address;
}

// Sent by the pending new owner to accept ownership
message(0x17) AdminAcceptOwnership {}

message(0x18) AdminUpgradeMasterCode {
    newCode: Cell;
}

message(0x1a) AdminMigrateStorage {
    newVersion: Int as uint32;
}

message(0x1b) AdminForceWithdrawPosition {
    queryId: Int as uint64;
    ownerAddress: Address;
    stakeIndex: Int as uint64;
}

// Releases a stuck claimInFlight lock on a specific StakePosition (admin emergency).
message(0x1c) AdminForceReleaseLock {
    ownerAddress: Address;
    stakeIndex: Int as uint64;
    token: Address;
}
