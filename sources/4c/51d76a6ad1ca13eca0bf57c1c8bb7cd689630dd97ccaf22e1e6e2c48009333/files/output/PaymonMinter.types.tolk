// Generated from the verified Tact contract ABI.
contract PaymonMinter {
    storage: PaymonMinterData
    incomingMessages: PaymonMinterIncomingMessage
    thrownErrors: PaymonMinterErrors
}

struct (0x00000004) PaymonMinterJettonUpdateContent {
    queryId: uint64
    content: cell
}

struct (0x7362d09c) PaymonMinterJettonNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7bdd97de) PaymonMinterJettonBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0x2c76b973) PaymonMinterProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x0393b1ce) PaymonMinterClaimTON {
    receiver: address
}

struct (0x031cf1be) PaymonMinterUpdateTaxFee {
    queryId: uint64
    fee: coins
}

struct PaymonMinterJettonMinterState {
    totalSupply: coins
    mintable: bool
    adminAddress: address
    jettonContent: cell
    jettonWalletCode: cell
}

struct PaymonMinterState {
    minterState: PaymonMinterJettonMinterState
    usdtWalletAddress: address
    usdtBalance: coins
    priceInUsdt: coins
    tactContinuation: Cell<PaymonMinterStateContinuation>
}

struct PaymonMinterStateContinuation {
    lockedUsdt: coins
    taxRate: coins
}

struct (0xe5b7df79) PaymonMinterTransferOwnership {
    owner: address
}

struct (0xbfc3c021) PaymonMinterSetUsdtWallet {
    usdtWalletAddress: address
    taxRate: coins
}

struct (0x1ef02429) PaymonMinterClaimAccumulatedTax {
    queryId: uint64
    amount: coins
    to: address
}

struct (0x501129cf) PaymonMinterUpdateUsdtPrice {
    newPrice: coins
}

struct (0xc44281bf) PaymonMinterEmergencyWithdraw {
    queryId: uint64
    to: address
}

struct (0xe071eb6a) PaymonMinterReveokeOwnership {
    queryId: uint64
}

struct PaymonMinterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    queryId: uint64
    totalSupply: coins
    owner: address
    manager: address
    jettonContent: cell
    mintable: bool
    stopped: bool
    usdtWalletAddress: address
    tactContinuation: Cell<PaymonMinterDataContinuation>
}

struct PaymonMinterDataContinuation {
    priceInUsdt: coins
    usdtBalance: coins
    lockedUsdt: coins
    taxRate: coins
}

type PaymonMinterIncomingMessage =
    | PaymonMinterSetUsdtWallet
    | PaymonMinterClaimAccumulatedTax
    | PaymonMinterEmergencyWithdraw
    | PaymonMinterClaimTON
    | PaymonMinterProvideWalletAddress
    | PaymonMinterJettonUpdateContent
    | PaymonMinterTransferOwnership
    | PaymonMinterReveokeOwnership
    | PaymonMinterUpdateUsdtPrice
    | PaymonMinterJettonBurnNotification
    | PaymonMinterJettonNotification
    | PaymonMinterUpdateTaxFee

enum PaymonMinterErrors {
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
    /// Incorrect manager
    IncorrectManager = 1318
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Token amount is negative
    TokenAmountIsNegative = 6925
    /// Incorrect sender
    IncorrectSender = 9215
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Unsufficient amount of TON attached
    UnsufficientAmountOfTONAttached = 15606
    /// Overdraw
    Overdraw = 28262
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Invalid forward payload
    InvalidForwardPayload = 37560
    /// Insufficient TON balance to cover gas fees
    InsufficientTONBalanceToCoverGasFees = 53022
    /// Contract not stopped
    ContractNotStopped = 53296
    /// Insufficient gas for discovery
    InsufficientGasForDiscovery = 63406
}

get fun getUsdtWalletAddress(): address {
    throw 0;
}

get fun get_paymon_data(): PaymonMinterState {
    throw 0;
}

get fun balance(): int257 {
    throw 0;
}

get fun get_jetton_data(): PaymonMinterJettonMinterState {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}

get fun usdtBalance(): int257 {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}

get fun taxFee(): int257 {
    throw 0;
}
