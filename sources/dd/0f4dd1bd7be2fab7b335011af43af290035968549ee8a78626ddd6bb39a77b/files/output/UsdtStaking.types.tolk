// Generated from the verified Tact contract ABI.
contract UsdtStaking {
    storage: UsdtStakingData
    incomingMessages: UsdtStakingIncomingMessage
    thrownErrors: UsdtStakingErrors
}

struct (0x946a98b6) UsdtStakingDeploy {
    queryId: uint64
}

struct (0x6e5fedb1) UsdtStakingJettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct UsdtStakingStake {
    amount: coins
    timestamp: uint64
}

struct UsdtStakingUserStake {
    total: coins
    count: uint32
    stakes: map<uint32, Cell<UsdtStakingStake>>
}

struct UsdtStakingData {
    tactDeploymentCompleted: bool
    owner: address
    usdtMaster: address
    usdtWalletCode: cell
    usdtWallet: address
    stakes: map<address, Cell<UsdtStakingUserStake>>
}

type UsdtStakingIncomingMessage =
    | UsdtStakingJettonTransferNotification
    | UsdtStakingDeploy

enum UsdtStakingErrors {
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
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
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
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
}

get fun get_stake_count(user: address): int257 {
    throw 0;
}

get fun get_total_staked(user: address): int257 {
    throw 0;
}

get fun get_stake_info(user: address, index: int257): UsdtStakingStake? {
    throw 0;
}

get fun get_usdt_wallet(): address {
    throw 0;
}
