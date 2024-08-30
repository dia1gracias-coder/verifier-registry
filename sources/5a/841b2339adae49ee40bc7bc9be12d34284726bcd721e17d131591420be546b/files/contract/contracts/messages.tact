message CreateDistributor {
    token: Address;
    merkleRoot: Int as uint256;
    unlockPeriods: map<Int, UnlockPeriod>;
    totalAmount: Int as uint256;
    refundDate: Int as uint32;
}

message CreateDistributorInternal  {
    creator: Address;
    token: Address;
    merkleRoot: Int as uint256;
    unlockPeriods: map<Int, UnlockPeriod>;
    totalAmount: Int as uint256;
    refundDate: Int as uint32;
}


message Claim {
    index: Int;
    merkleProof: Cell;
}

message RequestRefund {
    index: Int;
    merkleProof: Cell;
}

message RevokeRefund {
    index: Int;
    merkleProof: Cell;
}

message StopVesting {
    balance: Int as uint256;
}

message Withdraw {
    amount: Int as uint256;
}

message UpdateMerkleRoot {
    merkleRoot: Int as uint256;
}

message UpdateVault {
    vault: Address;
}

message UpdateRefundDate {
    refundDate: Int as uint32;
}

message ChangeWallet {
    index: Int;
    merkleProof: Cell;
    newWallet: Address;
}

message SetRefunded {
    refunded: map<Address, Bool>;
}

message UpgradeCode {
    newCode: Cell;
}

message UpgradeData {
    newData: Cell;
}


struct DistributorCreatedEvent {
    id: Int as uint32;
}

struct ClaimEvent {
    address: Address;
    amount: Int;
}

struct RequestRefundEvent {
    address: Address;
}

struct RevokeRefundEvent {
    address: Address;
}

struct StopVestingEvent {
    stoppedTime: Int as uint32;
    withdrawnAmount: Int as uint256;
}

struct WithdrawEvent {
    amount: Int as uint256;
}

struct UpdateMerkleRootEvent {
    merkleRoot: Int as uint256;
}

struct UpdateVaultEvent {
    vault: Address;
}

struct UpdateRefundDateEvent {
    refundDate: Int as uint32;
}

struct ChangeWalletEvent {
    oldWallet: Address;
    newWallet: Address;
}

struct DistributorDetails {
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