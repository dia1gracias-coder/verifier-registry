// Generated from the verified Tact contract ABI.
contract TONLiquidStaking {
    storage: TONLiquidStakingData
    incomingMessages: TONLiquidStakingIncomingMessage
    thrownErrors: TONLiquidStakingErrors
}

struct (0x946a98b6) TONLiquidStakingDeploy {
    queryId: uint64
}

struct (0xf408ae47) TONLiquidStakingAddProfit {
    amount: coins
}

struct (0xff633be1) TONLiquidStakingUnstake {
    amount: coins
}

struct (0xbf0737ea) TONLiquidStakingSecurityFreeze {
    target: address
}

struct (0x66afc459) TONLiquidStakingSecurityUnfreeze {
    target: address
}

struct (0x25567bd8) TONLiquidStakingTokenTransfer {
    from: address
    to: address
    amount: coins
}

struct (0x14cbd11a) TONLiquidStakingTokenBurn {
    target: address
    amount: coins
}

struct (0x28cf1082) TONLiquidStakingTokenMint {
    target: address
    amount: coins
}

struct (0x98873e9f) TONLiquidStakingBurnNotification {
    amount: coins
    owner: address
}

struct TONLiquidStakingData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalTON: coins
    totalSupply: coins
    wallet_code: cell
    owner: address
    unstakeRequestId: uint64
    frozen: map<address, bool>
}

type TONLiquidStakingIncomingMessage =
    | TONLiquidStakingAddProfit
    | TONLiquidStakingUnstake
    | TONLiquidStakingSecurityFreeze
    | TONLiquidStakingSecurityUnfreeze
    | TONLiquidStakingTokenTransfer
    | TONLiquidStakingTokenBurn
    | TONLiquidStakingTokenMint
    | TONLiquidStakingBurnNotification
    | TONLiquidStakingDeploy

enum TONLiquidStakingErrors {
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
    /// Invalid sender
    InvalidSender = 4429
    /// Not enough TON in the pool
    NotEnoughTONInThePool = 26410
    /// Not enough TON sent
    NotEnoughTONSent = 28284
    /// Wallet is frozen
    WalletIsFrozen = 33427
    /// Not authorized
    NotAuthorized = 42435
    /// Insufficient balance
    InsufficientBalance = 54615
    /// No profit sent
    NoProfitSent = 62811
}

get fun owner(): address {
    throw 0;
}
