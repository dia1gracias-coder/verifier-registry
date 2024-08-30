// Generated from the verified Tact contract ABI.
contract HashedTimeLockTON {
    storage: HashedTimeLockTONData
    incomingMessages: HashedTimeLockTONIncomingMessage
    thrownErrors: HashedTimeLockTONErrors
}

struct (0x946a98b6) HashedTimeLockTONDeploy {
    queryId: uint64
}

struct HashedTimeLockTONPHTLC {
    dstAddress: string
    dstChain: string
    tactContinuation: Cell<HashedTimeLockTONPHTLCContinuation>
}

struct HashedTimeLockTONPHTLCContinuation {
    dstAsset: string
    srcAsset: string
    sender: address
    senderPubKey: int257
    srcReceiver: address
    tactContinuation: Cell<HashedTimeLockTONPHTLCContinuation2>
}

struct HashedTimeLockTONPHTLCContinuation2 {
    timelock: int257
    amount: int257
    messenger: address
    locked: bool
    uncommitted: bool
}

struct HashedTimeLockTONHTLC {
    dstAddress: string
    dstChain: string
    tactContinuation: Cell<HashedTimeLockTONHTLCContinuation>
}

struct HashedTimeLockTONHTLCContinuation {
    dstAsset: string
    srcAsset: string
    sender: address
    srcReceiver: address
    hashlock: int257
    tactContinuation: Cell<HashedTimeLockTONHTLCContinuation2>
}

struct HashedTimeLockTONHTLCContinuation2 {
    secret: int257
    amount: int257
    timelock: int257
    redeemed: bool
    unlocked: bool
}

struct (0x1b564d91) HashedTimeLockTONCommit {
    data: HashedTimeLockTONCommitData
}

struct HashedTimeLockTONCommitData {
    dstChain: string
    dstAsset: string
    tactContinuation: Cell<HashedTimeLockTONCommitDataContinuation>
}

struct HashedTimeLockTONCommitDataContinuation {
    dstAddress: string
    srcAsset: string
    srcReceiver: address
    timelock: int257
    messenger: address
    tactContinuation: Cell<HashedTimeLockTONCommitDataContinuation2>
}

struct HashedTimeLockTONCommitDataContinuation2 {
    senderPubKey: int257
    hopChains: map<int257, Cell<HashedTimeLockTONStringImpl>>
    hopAssets: map<int257, Cell<HashedTimeLockTONStringImpl>>
    hopAddresses: map<int257, Cell<HashedTimeLockTONStringImpl>>
}

struct (0x5cdd41d9) HashedTimeLockTONLockCommitment {
    data: HashedTimeLockTONLockCommitmentData
}

struct HashedTimeLockTONLockCommitmentData {
    commitId: int257
    hashlock: int257
    timelock: int257
}

struct (0xa958ac23) HashedTimeLockTONUncommit {
    data: HashedTimeLockTONUncommitData
}

struct HashedTimeLockTONUncommitData {
    commitId: int257
}

struct (0x12e78cb1) HashedTimeLockTONLock {
    data: HashedTimeLockTONLockData
}

struct HashedTimeLockTONLockData {
    hashlock: int257
    timelock: int257
    srcReceiver: address
    srcAsset: string
    dstChain: string
    tactContinuation: Cell<HashedTimeLockTONLockDataContinuation>
}

struct HashedTimeLockTONLockDataContinuation {
    dstAddress: string
    dstAsset: string
    commitId: int257?
    messenger: address?
}

struct (0x758db085) HashedTimeLockTONRedeem {
    data: HashedTimeLockTONRedeemData
}

struct HashedTimeLockTONRedeemData {
    lockId: int257
    secret: int257
}

struct (0xad821ef9) HashedTimeLockTONUnlock {
    data: HashedTimeLockTONUnlockData
}

struct HashedTimeLockTONUnlockData {
    hashlock: int257
}

struct HashedTimeLockTONStringImpl {
    data: string
}

struct HashedTimeLockTONData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    locks: map<int257, Cell<HashedTimeLockTONHTLC>>
    tactContinuation: Cell<HashedTimeLockTONDataContinuation>
}

struct HashedTimeLockTONDataContinuation {
    commits: map<int257, Cell<HashedTimeLockTONPHTLC>>
    commitIdToLockId: map<int257, int257>
    contractNonce: int257
    seed: int257
}

type HashedTimeLockTONIncomingMessage =
    | HashedTimeLockTONCommit
    | HashedTimeLockTONUncommit
    | HashedTimeLockTONLockCommitment
    | HashedTimeLockTONLock
    | HashedTimeLockTONRedeem
    | HashedTimeLockTONUnlock
    | HashedTimeLockTONDeploy

enum HashedTimeLockTONErrors {
    /// Stack underflow
    StackUnderflow = 2
    /// Stack overflow
    StackOverflow = 3
    /// Integer overflow
    IntegerOverflow = 4
    /// Integer out of expected range
    IntegerOutOfExpectedRange = 5
    /// Invalid opcode
    InvalidOpcode = 6
    /// Type check error
    TypeCheckError = 7
    /// Cell overflow
    CellOverflow = 8
    /// Cell underflow
    CellUnderflow = 9
    /// Dictionary error
    DictionaryError = 10
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Null reference exception
    NullReferenceException = 128
    /// Invalid serialization prefix
    InvalidSerializationPrefix = 129
    /// Invalid incoming message
    InvalidIncomingMessage = 130
    /// Constraints error
    ConstraintsError = 131
    /// Access denied
    AccessDenied = 132
    /// Contract stopped
    ContractStopped = 133
    /// Invalid argument
    InvalidArgument = 134
    /// Code of a contract was not found
    CodeOfAContractWasNotFound = 135
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// Already Unlocked
    AlreadyUnlocked = 1503
    /// Funds Not Sent
    FundsNotSent = 4670
    /// Lock Already Exists
    LockAlreadyExists = 6007
    /// Lock Does Not Exist
    LockDoesNotExist = 6272
    /// Commitment does not exist
    CommitmentDoesNotExist = 20173
    /// Not Future Timelock
    NotFutureTimelock = 21683
    /// Commit Already Exists
    CommitAlreadyExists = 22150
    /// Commit Does Not Exist
    CommitDoesNotExist = 30789
    /// No Allowance
    NoAllowance = 31687
    /// Not Passed Timelock
    NotPassedTimelock = 38239
    /// Already Uncommitted
    AlreadyUncommitted = 42324
    /// Already Locked
    AlreadyLocked = 46722
    /// Already Redeemed
    AlreadyRedeemed = 46887
    /// Invalid signature
    InvalidSignature = 48401
    /// Hashlock Not Match
    HashlockNotMatch = 50918
}

get fun getLockCDetails(hashlock: int257): HashedTimeLockTONHTLC? {
    throw 0;
}

get fun getCommitDetails(commitId: int257): HashedTimeLockTONPHTLC? {
    throw 0;
}

get fun commitsLength(): int257 {
    throw 0;
}

get fun locksLength(): int257 {
    throw 0;
}

get fun lockIdToCommitIdLength(): int257 {
    throw 0;
}

get fun getCommits(senderAddr: address): map<int257, int257> {
    throw 0;
}

get fun getLocks(senderAddr: address): map<int257, int257> {
    throw 0;
}

get fun getLockIdByCommitId(commitId: int257): int257? {
    throw 0;
}
