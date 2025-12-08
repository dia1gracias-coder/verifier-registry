// Generated from the verified Tact contract ABI.
contract GovernanceJettonMinter {
    storage: GovernanceJettonMinterData
    incomingMessages: GovernanceJettonMinterIncomingMessage
    thrownErrors: GovernanceJettonMinterErrors
}

struct GovernanceJettonMinterJettonData {
    totalSupply: int257
    mintable: bool
    owner: address
    content: cell
    jettonWalletCode: cell
}

struct (0xd53276db) GovernanceJettonMinterJettonExcesses {
    queryId: uint64
}

struct (0x178d4519) GovernanceJettonMinterJettonTransferInternal {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7bdd97de) GovernanceJettonMinterJettonBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0x7bdd97df) GovernanceJettonMinterJettonBurnNotificationWithSale {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
    sellerAddress: address
    tactContinuation: Cell<GovernanceJettonMinterJettonBurnNotificationWithSaleContinuation>
}

struct GovernanceJettonMinterJettonBurnNotificationWithSaleContinuation {
    tonToPayOut: coins
    finalDestination: address?
}

struct (0x2c76b973) GovernanceJettonMinterProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0xd372158c) GovernanceJettonMinterTopUp {
    queryId: uint64
}

struct (0x642b7d07) GovernanceJettonMinterMint {
    queryId: uint64
    toAddress: address
    tonAmount: coins
    tactContinuation: Cell<GovernanceJettonMinterMintContinuation>
}

struct GovernanceJettonMinterMintContinuation {
    masterMsg: GovernanceJettonMinterJettonTransferInternal
}

struct (0x6501f354) GovernanceJettonMinterChangeAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0xfb88e119) GovernanceJettonMinterClaimAdmin {
    queryId: uint64
}

struct (0x235caf52) GovernanceJettonMinterCallTo {
    queryId: uint64
    toAddress: address
    tonAmount: coins
    masterMsg: cell
}

struct (0x2508d66a) GovernanceJettonMinterUpgrade {
    queryId: uint64
    newData: cell
    newCode: cell
}

struct (0x4e565047) GovernanceJettonMinterUpgradeCode {
    queryId: uint64
    newCode: cell
}

struct (0xcb862902) GovernanceJettonMinterChangeMetadataUri {
    queryId: uint64
    metadata: RemainingBitsAndRefs
}

struct (0x011138ea) GovernanceJettonMinterPauseContract {
    pause: bool
}

struct (0xa7c9f123) GovernanceJettonMinterSetFee {
    queryId: uint64
    newFee: uint16
}

struct (0xb1a4c5e7) GovernanceJettonMinterSetMaxTotalSupply {
    queryId: uint64
    newMaxTotalSupply: coins
}

struct (0xc2b6d8f9) GovernanceJettonMinterSetBasePrice {
    queryId: uint64
    newBasePrice: coins
}

struct (0x4e2a5c6d) GovernanceJettonMinterWithdrawAllTon {
    queryId: uint64
    destination: address?
}

struct (0x7b8e48e2) GovernanceJettonMinterBuyTokens {
    queryId: uint64
    buyerAddress: address
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x4f2a8c3d) GovernanceJettonMinterSellTokens {
    queryId: uint64
    sellerAddress: address
    tokensAmount: coins
    responseDestination: address?
}

struct (0x9a4b5c2e) GovernanceJettonMinterSetSellEnabled {
    queryId: uint64
    enabled: bool
}

struct (0x642b7d08) GovernanceJettonMinterMintTokenForTon {
    queryId: uint64
    tokenRate: coins
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x8f5a3c2d) GovernanceJettonMinterSetMintTokenForTonEnabled {
    queryId: uint64
    enabled: bool
}

struct (0x6c2f8d3e) GovernanceJettonMinterForwardTonNotification {
    queryId: uint64
    walletOwner: address
    forwardedAmount: coins
}

struct (0x2b4e6f8a) GovernanceJettonMinterSetMinRate {
    queryId: uint64
    newMinRate: coins
}

struct (0x3c5f7a9b) GovernanceJettonMinterSetMaxRate {
    queryId: uint64
    newMaxRate: coins
}

struct GovernanceJettonMinterData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    totalSupply: coins
    adminAddress: address
    nextAdminAddress: address?
    jettonContent: cell
    locked: bool
    paused: bool
    fee: int257
    tactContinuation: Cell<GovernanceJettonMinterDataContinuation>
}

struct GovernanceJettonMinterDataContinuation {
    maxTotalSupplyLimit: coins
    baseTokenPrice: coins
    sellEnabled: bool
    mintTokenForTonEnabled: bool
    minRate: coins
    maxRate: coins
}

type GovernanceJettonMinterIncomingMessage =
    | GovernanceJettonMinterMint
    | GovernanceJettonMinterJettonBurnNotification
    | GovernanceJettonMinterJettonBurnNotificationWithSale
    | GovernanceJettonMinterProvideWalletAddress
    | GovernanceJettonMinterChangeAdmin
    | GovernanceJettonMinterClaimAdmin
    | GovernanceJettonMinterCallTo
    | GovernanceJettonMinterChangeMetadataUri
    | GovernanceJettonMinterUpgrade
    | GovernanceJettonMinterUpgradeCode
    | GovernanceJettonMinterPauseContract
    | GovernanceJettonMinterSetFee
    | GovernanceJettonMinterSetMaxTotalSupply
    | GovernanceJettonMinterSetBasePrice
    | GovernanceJettonMinterSetSellEnabled
    | GovernanceJettonMinterSetMintTokenForTonEnabled
    | GovernanceJettonMinterSetMinRate
    | GovernanceJettonMinterSetMaxRate
    | GovernanceJettonMinterBuyTokens
    | GovernanceJettonMinterMintTokenForTon
    | GovernanceJettonMinterSellTokens
    | GovernanceJettonMinterTopUp
    | GovernanceJettonMinterJettonExcesses
    | GovernanceJettonMinterForwardTonNotification
    | GovernanceJettonMinterWithdrawAllTon

enum GovernanceJettonMinterErrors {
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
    /// Custom payload too large for sell operation
    CustomPayloadTooLargeForSellOperation = 1558
    /// Total supply overflow
    TotalSupplyOverflow = 1623
    /// Base price must be positive
    BasePriceMustBePositive = 2328
    /// Invalid forward payload in message
    InvalidForwardPayloadInMessage = 2448
    /// Invalid final destination address
    InvalidFinalDestinationAddress = 4120
    /// Insufficient TON for transfer
    InsufficientTONForTransfer = 4121
    /// Forward payload too large
    ForwardPayloadTooLarge = 4141
    /// Too many refs in masterMsg
    TooManyRefsInMasterMsg = 4714
    /// Only master can set auto-forward
    OnlyMasterCanSetAutoForward = 5771
    /// Payout amount unreasonably large
    PayoutAmountUnreasonablyLarge = 6069
    /// Invalid null address
    InvalidNullAddress = 6362
    /// Insufficient TON for UpgradeCode
    InsufficientTONForUpgradeCode = 7066
    /// Invalid workchain
    InvalidWorkchain = 7425
    /// Only master can upgrade wallet code
    OnlyMasterCanUpgradeWalletCode = 7828
    /// No TON balance to withdraw
    NoTONBalanceToWithdraw = 8180
    /// Incorrect sender
    IncorrectSender = 9215
    /// CustomPayload too large
    CustomPayloadTooLarge = 9339
    /// Token selling is disabled
    TokenSellingIsDisabled = 9548
    /// Token rate too low
    TokenRateTooLow = 9657
    /// Balance overflow
    BalanceOverflow = 9765
    /// Transfer amount must be positive
    TransferAmountMustBePositive = 10272
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Invalid wallet status
    InvalidWalletStatus = 11228
    /// Too many refs in customPayload
    TooManyRefsInCustomPayload = 13614
    /// Insufficient TON for burn
    InsufficientTONForBurn = 14417
    /// Invalid status value
    InvalidStatusValue = 15741
    /// Token price not set
    TokenPriceNotSet = 16564
    /// Contract is paused
    ContractIsPaused = 19792
    /// Fee cannot be negative
    FeeCannotBeNegative = 20545
    /// Payout amount must be positive
    PayoutAmountMustBePositive = 21107
    /// Contract is locked
    ContractIsLocked = 21196
    /// Insufficient TON for mint
    InsufficientTONForMint = 22344
    /// Min transfer amount too large
    MinTransferAmountTooLarge = 22981
    /// Transfer not allowed: insufficient TON or amount below minimum
    TransferNotAllowedInsufficientTONOrAmountBelowMinimum = 24250
    /// Invalid fee multiplier
    InvalidFeeMultiplier = 26611
    /// Insufficient contract balance for payout
    InsufficientContractBalanceForPayout = 27122
    /// Unsupported operation in CallTo
    UnsupportedOperationInCallTo = 27762
    /// Max total supply exceeded
    MaxTotalSupplyExceeded = 29103
    /// Incoming transfers are locked
    IncomingTransfersAreLocked = 30277
    /// Contract is not paused
    ContractIsNotPaused = 30405
    /// Min rate must be positive
    MinRateMustBePositive = 30655
    /// Insufficient TON for buy
    InsufficientTONForBuy = 30733
    /// Max rate must be positive
    MaxRateMustBePositive = 30774
    /// MintTokenForTon is disabled
    MintTokenForTonIsDisabled = 31774
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Insufficient total supply
    InsufficientTotalSupply = 34888
    /// Insufficient TON for operation
    InsufficientTONForOperation = 35116
    /// Insufficient TON for sell
    InsufficientTONForSell = 39019
    /// New code cannot be empty
    NewCodeCannotBeEmpty = 39192
    /// Invalid seller workchain
    InvalidSellerWorkchain = 40695
    /// New data cannot be empty
    NewDataCannotBeEmpty = 40809
    /// Not master
    NotMaster = 41109
    /// Max total supply must be positive
    MaxTotalSupplyMustBePositive = 41230
    /// Token rate too high
    TokenRateTooHigh = 42125
    /// Invalid final destination workchain
    InvalidFinalDestinationWorkchain = 42449
    /// Min transfer amount cannot be negative
    MinTransferAmountCannotBeNegative = 42731
    /// Max total supply cannot be less than current total supply
    MaxTotalSupplyCannotBeLessThanCurrentTotalSupply = 43878
    /// Tokens amount must be positive
    TokensAmountMustBePositive = 45429
    /// Wrong workchain
    WrongWorkchain = 46257
    /// Insufficient TON for CallTo
    InsufficientTONForCallTo = 46368
    /// Invalid bounced amount
    InvalidBouncedAmount = 46616
    /// Incorrect balance after burn
    IncorrectBalanceAfterBurn = 47390
    /// Calculated TON amount is zero
    CalculatedTONAmountIsZero = 48504
    /// Min rate must be less than max rate
    MinRateMustBeLessThanMaxRate = 49988
    /// Mint amount too large
    MintAmountTooLarge = 51032
    /// Burn amount must be positive
    BurnAmountMustBePositive = 51144
    /// Transfer amount too large
    TransferAmountTooLarge = 51147
    /// Transfer amount cannot be negative
    TransferAmountCannotBeNegative = 51919
    /// Metadata too large
    MetadataTooLarge = 52731
    /// Fee cannot exceed 100%
    FeeCannotExceed100 = 52864
    /// Sell amount too large
    SellAmountTooLarge = 53266
    /// Invalid customPayload structure
    InvalidCustomPayloadStructure = 53617
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Calculated tokens amount is zero
    CalculatedTokensAmountIsZero = 55080
    /// Buy amount too large
    BuyAmountTooLarge = 55256
    /// Zero address not allowed
    ZeroAddressNotAllowed = 55314
    /// Base price too large for fee calculation
    BasePriceTooLargeForFeeCalculation = 55941
    /// Message too large
    MessageTooLarge = 56064
    /// Insufficient TON for SetAutoForwardTon
    InsufficientTONForSetAutoForwardTon = 56245
    /// Balance overflow on bounce
    BalanceOverflowOnBounce = 59728
    /// Insufficient TON for TransferTon
    InsufficientTONForTransferTon = 59992
    /// Insufficient balance for transfer
    InsufficientBalanceForTransfer = 60664
    /// Amount must be positive
    AmountMustBePositive = 61135
    /// Max rate must be greater than min rate
    MaxRateMustBeGreaterThanMinRate = 61177
    /// Burn amount too large
    BurnAmountTooLarge = 62093
    /// Cannot burn more than total supply
    CannotBurnMoreThanTotalSupply = 62340
    /// No TON attached
    NoTONAttached = 62417
    /// Token rate must be positive
    TokenRateMustBePositive = 63513
    /// Contract must be paused for upgrade
    ContractMustBePausedForUpgrade = 63563
    /// Not next admin
    NotNextAdmin = 63951
}

get fun get_jetton_data(): GovernanceJettonMinterJettonData {
    throw 0;
}

get fun get_wallet_address(ownerAddress: address): address {
    throw 0;
}

get fun get_next_admin_address(): address? {
    throw 0;
}

get fun get_fee(): int257 {
    throw 0;
}

get fun get_token_price_buy(): int257 {
    throw 0;
}

get fun get_token_price_sell(): int257 {
    throw 0;
}

get fun get_base_token_price(): int257 {
    throw 0;
}

get fun get_contract_balance(): int257 {
    throw 0;
}

get fun get_max_total_supply(): int257 {
    throw 0;
}

get fun get_base_price(): int257 {
    throw 0;
}

get fun get_sell_enabled(): bool {
    throw 0;
}

get fun get_mint_token_for_ton_enabled(): bool {
    throw 0;
}

get fun get_min_rate(): int257 {
    throw 0;
}

get fun get_max_rate(): int257 {
    throw 0;
}
