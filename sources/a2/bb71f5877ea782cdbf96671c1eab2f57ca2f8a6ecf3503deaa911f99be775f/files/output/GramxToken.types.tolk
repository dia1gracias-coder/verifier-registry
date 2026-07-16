// Generated from the verified Tact contract ABI.
contract GramxToken {
    storage: GramxTokenData
    incomingMessages: GramxTokenIncomingMessage
    thrownErrors: GramxTokenErrors
}

struct (0x30adbc3b) GramxTokenInitializeFixedSupply {
    queryId: uint64
}

struct (0x80bb6173) GramxTokenProposeOwner {
    newOwner: address
}

struct (0xb712ccbb) GramxTokenAcceptOwner {
}

struct GramxTokenJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    walletCode: cell
}

struct GramxTokenFixedSupplyData {
    fixedSupply: int257
    initialReceiver: address
    initialized: bool
    pendingOwner: address?
}

struct (0x7bdd97de) GramxTokenTokenBurnNotification {
    queryId: uint64
    amount: coins
    owner: address
    response_destination: address?
}

struct GramxTokenData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    owner: address
    pendingOwner: address?
    content: cell
    mintable: bool
    fixedSupply: coins
    tactContinuation: Cell<GramxTokenDataContinuation>
}

struct GramxTokenDataContinuation {
    initialReceiver: address
    initialized: bool
}

type GramxTokenIncomingMessage =
    | GramxTokenInitializeFixedSupply
    | GramxTokenProposeOwner
    | GramxTokenAcceptOwner
    | GramxTokenTokenBurnNotification

enum GramxTokenErrors {
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
    /// Not Owner
    NotOwner = 3734
    /// Insufficient TON for transfer
    InsufficientTONForTransfer = 4121
    /// Invalid sender
    InvalidSender = 4429
    /// Invalid burn amount
    InvalidBurnAmount = 8723
    /// Not pending owner
    NotPendingOwner = 10407
    /// Insufficient TON for burn
    InsufficientTONForBurn = 14417
    /// Unexpected bounce
    UnexpectedBounce = 15056
    /// Invalid total supply
    InvalidTotalSupply = 16233
    /// Insufficient forwarded value
    InsufficientForwardedValue = 18161
    /// Invalid bounced supply
    InvalidBouncedSupply = 20975
    /// No pending owner
    NoPendingOwner = 29918
    /// Supply already initialized
    SupplyAlreadyInitialized = 30449
    /// Invalid wallet
    InvalidWallet = 36088
    /// Invalid bounced amount
    InvalidBouncedAmount = 46616
    /// Already owner
    AlreadyOwner = 46988
    /// Fixed supply must be positive
    FixedSupplyMustBePositive = 47318
    /// Insufficient jetton balance
    InsufficientJettonBalance = 51863
    /// Amount must be positive
    AmountMustBePositive = 61135
}

get fun get_jetton_data(): GramxTokenJettonData {
    throw 0;
}

get fun get_wallet_address(walletOwner: address): address {
    throw 0;
}

get fun get_fixed_supply_data(): GramxTokenFixedSupplyData {
    throw 0;
}

get fun owner(): address {
    throw 0;
}
