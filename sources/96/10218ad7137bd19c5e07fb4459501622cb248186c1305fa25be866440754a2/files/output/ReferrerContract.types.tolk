// Generated from the verified Tact contract ABI.
contract ReferrerContract {
    storage: ReferrerContractData
    incomingMessages: ReferrerContractIncomingMessage
    thrownErrors: ReferrerContractErrors
}

struct (0x946a98b6) ReferrerContractDeploy {
    queryId: uint64
}

struct ReferrerContractReferrerStats {
    referredUserCount: int257
    totalRewards: int257
    lastRewardTime: int257
}

struct ReferrerContractUserReferral {
    referrer: address
    referralTime: int257
}

struct (0x12345678) ReferrerContractBindReferrer {
    queryId: uint64
    referrer: address
}

struct (0x23456789) ReferrerContractAddReward {
    queryId: uint64
    referrer: address
    amount: coins
}

struct (0x78901234) ReferrerContractRemoveReward {
    queryId: uint64
    referrer: address
    amount: coins
}

struct (0x45678901) ReferrerContractGetReferrerStats {
    queryId: uint64
    referrer: address
}

struct ReferrerContractData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    userReferrers: map<address, Cell<ReferrerContractUserReferral>>
    referrerStats: map<address, Cell<ReferrerContractReferrerStats>>
    owner: address
}

type ReferrerContractIncomingMessage =
    | ReferrerContractBindReferrer
    | ReferrerContractAddReward
    | ReferrerContractRemoveReward
    | ReferrerContractGetReferrerStats
    | ReferrerContractDeploy

enum ReferrerContractErrors {
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
}

get fun getUserReferrer(user: address): address? {
    throw 0;
}

get fun version(): string {
    throw 0;
}
