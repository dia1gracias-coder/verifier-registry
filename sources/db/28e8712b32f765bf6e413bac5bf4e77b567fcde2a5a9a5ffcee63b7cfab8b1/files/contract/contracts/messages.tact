message CreateDistributor {
    queryId: Int as uint64;
    token: Address;
    vault: Address;
    merkleRoot: Int as uint256;
    unlockPeriods: map<Int, UnlockPeriod>;
    totalAmount: Int as uint256;
    refundDate: Int as uint32;
}

message SetAdmin {
    queryId: Int as uint64;
    address: Address;
    value: Bool;
}

message InitDistributor  {
    queryId: Int as uint64;
    creator: Address;
    token: Address;
    vault: Address;
    merkleRoot: Int as uint256;
    unlockPeriods: map<Int, UnlockPeriod>;
    totalAmount: Int as uint256;
    refundDate: Int as uint32;
}

message Claim {
    queryId: Int as uint64;
    index: Int;
    merkleProof: Cell;
}

message RequestRefund {
    queryId: Int as uint64;
    index: Int;
    merkleProof: Cell;
}

message RevokeRefund {
    queryId: Int as uint64;
    index: Int;
    merkleProof: Cell;
}

message StopVesting {
    queryId: Int as uint64;
    balance: Int as uint256;
}

message Withdraw {
    queryId: Int as uint64;
    amount: Int as uint256;
}

message UpdateMerkleRoot {
    queryId: Int as uint64;
    merkleRoot: Int as uint256;
}

message UpdateVault {
    queryId: Int as uint64;
    vault: Address;
}

message UpdateRefundDate {
    queryId: Int as uint64;
    refundDate: Int as uint32;
}

message ChangeWallet {
    queryId: Int as uint64;
    index: Int;
    merkleProof: Cell;
    newWallet: Address;
}

message SetRefunded {
    queryId: Int as uint64;
    refunded: map<Address, Bool>;
}

message UpgradeCode {
    newCode: Cell;
}

message UpgradeData {
    newData: Cell;
}


struct CreateDistributorEvent {
    queryId: Int as uint64;
    type: String;
    id: Int as uint32;
    address: Address;
}

struct SetAdminEvent {
    queryId: Int as uint64;
    type: String;
    address: Address;
    value: Bool;
}

struct InitDistributorEvent {
    queryId: Int as uint64;
    type: String;
    id: Int as uint32;
}

struct ClaimEvent {
    queryId: Int as uint64;
    type: String;
    address: Address;
    amount: Int;
}

struct ClaimRollbackEvent {
    queryId: Int as uint64;
    type: String;
    address: Address;
    amount: Int;
}

struct RequestRefundEvent {
    queryId: Int as uint64;
    type: String;
    address: Address;
}

struct RevokeRefundEvent {
    queryId: Int as uint64;
    type: String;
    address: Address;
}

struct StopVestingEvent {
    queryId: Int as uint64;
    type: String;
    stoppedTime: Int as uint32;
    withdrawnAmount: Int as uint256;
}

struct WithdrawEvent {
    queryId: Int as uint64;
    type: String;
    amount: Int as uint256;
}

struct UpdateMerkleRootEvent {
    queryId: Int as uint64;
    type: String;
    merkleRoot: Int as uint256;
}

struct UpdateVaultEvent {
    queryId: Int as uint64;
    type: String;
    vault: Address;
}

struct UpdateRefundDateEvent {
    queryId: Int as uint64;
    type: String;
    refundDate: Int as uint32;
}

struct SetRefundedEvent {
    queryId: Int as uint64;
    type: String;
}

struct ChangeWalletEvent {
    queryId: Int as uint64;
    type: String;
    oldWallet: Address;
    newWallet: Address;
}

struct DistributorDetails {
    id: Int as uint32;
    token: Address;
    vault: Address;
    merkleRoot: Int as uint256;
    unlockPeriods: map<Int, UnlockPeriod>;
    totalAmount: Int as uint256;
    totalClaimedAmount: Int as uint256;
    refundDate: Int as uint32;
    stoppedTime: Int as uint32;
}

struct UnlockPeriod {
    percentage: Int as uint64;
    start: Int as uint32;
    end: Int as uint32;
    duration: Int as uint32;
    airdrop: Bool;
}

struct Entry {
    address: Address;
    amount: Int;
    originalAddress: Address;
}