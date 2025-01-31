// Generated from the verified Tact contract ABI.
contract TrainJetton {
    storage: TrainJettonData
    incomingMessages: TrainJettonIncomingMessage
    thrownErrors: TrainJettonErrors
}

struct (0x946a98b6) TrainJettonDeploy {
    queryId: uint64
}

struct (0x7362d09c) TrainJettonTokenNotification {
    queryId: uint64
    amount: coins
    from: address
    forward_payload: RemainingBitsAndRefs
}

struct TrainJettonHTLC {
    sender: address
    senderPubKey: int257
    srcReceiver: address
    tactContinuation: Cell<TrainJettonHTLCContinuation>
}

struct TrainJettonHTLCContinuation {
    secret: int257
    hashlock: int257
    amount: int257
    tactContinuation: Cell<TrainJettonHTLCContinuation2>
}

struct TrainJettonHTLCContinuation2 {
    timelock: int257
    claimed: int257
    jettonMasterAddress: address
    tactContinuation: Cell<TrainJettonHTLCContinuation3>
}

struct TrainJettonHTLCContinuation3 {
    htlcJettonWalletAddress: address
}

struct TrainJettonReward {
    amount: int257
    timelock: int257
}

struct (0x5cdd41d9) TrainJettonAddLock {
    Id: int257
    hashlock: int257
    timelock: int257
}

struct (0x758db085) TrainJettonRedeem {
    Id: int257
    secret: int257
}

struct (0xad821ef9) TrainJettonRefund {
    Id: int257
}

struct TrainJettonData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    contracts: map<int257, Cell<TrainJettonHTLC>>
    rewards: map<int257, Cell<TrainJettonReward>>
}

type TrainJettonIncomingMessage =
    | TrainJettonTokenNotification
    | TrainJettonAddLock
    | TrainJettonRedeem
    | TrainJettonRefund
    | TrainJettonDeploy

enum TrainJettonErrors {
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
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
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
    /// Funds Not Sent
    FundsNotSent = 4670
    /// Hashlock Already Set
    HashlockAlreadySet = 8650
    /// Contract Already Exists
    ContractAlreadyExists = 11493
    /// Not Future Timelock
    NotFutureTimelock = 21683
    /// Invalid Reward Timelock
    InvalidRewardTimelock = 21809
    /// No Allowance
    NoAllowance = 31687
    /// Not Passed Timelock
    NotPassedTimelock = 38239
    /// Invalid signature
    InvalidSignature = 48401
    /// Hashlock Not Match
    HashlockNotMatch = 50918
    /// Contract Does Not Exist
    ContractDoesNotExist = 58417
    /// Already Claimed
    AlreadyClaimed = 61302
}

get fun getHTLCDetails(Id: int257): TrainJettonHTLC? {
    throw 0;
}

get fun getContractsLength(): int257 {
    throw 0;
}

get fun getRewardDetails(Id: int257): TrainJettonReward? {
    throw 0;
}

get fun getRewardsLength(): int257 {
    throw 0;
}
