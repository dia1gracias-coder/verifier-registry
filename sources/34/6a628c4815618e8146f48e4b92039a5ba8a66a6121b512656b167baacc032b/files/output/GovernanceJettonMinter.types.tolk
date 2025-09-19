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

struct GovernanceJettonMinterData {
    tactSystemCell: cell
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
}

type GovernanceJettonMinterIncomingMessage =
    | GovernanceJettonMinterMint
    | GovernanceJettonMinterJettonBurnNotification
    | GovernanceJettonMinterProvideWalletAddress
    | GovernanceJettonMinterChangeAdmin
    | GovernanceJettonMinterClaimAdmin
    | GovernanceJettonMinterCallTo
    | GovernanceJettonMinterChangeMetadataUri
    | GovernanceJettonMinterUpgrade
    | GovernanceJettonMinterPauseContract
    | GovernanceJettonMinterSetFee
    | GovernanceJettonMinterSetMaxTotalSupply
    | GovernanceJettonMinterSetBasePrice
    | GovernanceJettonMinterTopUp

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
    /// Total supply overflow
    TotalSupplyOverflow = 1623
    /// Base price must be positive
    BasePriceMustBePositive = 2328
    /// Incorrect balance after send
    IncorrectBalanceAfterSend = 2366
    /// Invalid forward payload in message
    InvalidForwardPayloadInMessage = 2448
    /// Insufficient TON for transfer
    InsufficientTONForTransfer = 4121
    /// Forward payload too large
    ForwardPayloadTooLarge = 4141
    /// Too many refs in masterMsg
    TooManyRefsInMasterMsg = 4714
    /// Transfer amount too small
    TransferAmountTooSmall = 4858
    /// Cannot send to self
    CannotSendToSelf = 6477
    /// Invalid workchain
    InvalidWorkchain = 7425
    /// Incorrect sender
    IncorrectSender = 9215
    /// Balance overflow
    BalanceOverflow = 9765
    /// Transfer amount must be positive
    TransferAmountMustBePositive = 10272
    /// Unauthorized burn
    UnauthorizedBurn = 10363
    /// Insufficient TON for burn
    InsufficientTONForBurn = 14417
    /// Not owner
    NotOwner = 14534
    /// Invalid status value
    InvalidStatusValue = 15741
    /// Contract is paused
    ContractIsPaused = 19792
    /// Contract is locked
    ContractIsLocked = 21196
    /// Insufficient TON for mint
    InsufficientTONForMint = 22344
    /// Unsupported operation in CallTo
    UnsupportedOperationInCallTo = 27762
    /// Max total supply exceeded
    MaxTotalSupplyExceeded = 29103
    /// Incoming transfers are locked
    IncomingTransfersAreLocked = 30277
    /// Insufficient amount of TON attached
    InsufficientAmountOfTONAttached = 32113
    /// Max total supply must be positive
    MaxTotalSupplyMustBePositive = 41230
    /// Max total supply cannot be less than current total supply
    MaxTotalSupplyCannotBeLessThanCurrentTotalSupply = 43878
    /// Wrong workchain
    WrongWorkchain = 46257
    /// Insufficient TON for CallTo
    InsufficientTONForCallTo = 46368
    /// Mint amount too large
    MintAmountTooLarge = 51032
    /// Burn amount must be positive
    BurnAmountMustBePositive = 51144
    /// Transfer amount too large
    TransferAmountTooLarge = 51147
    /// Metadata too large
    MetadataTooLarge = 52731
    /// Fee cannot exceed 100%
    FeeCannotExceed100 = 52864
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Zero address not allowed
    ZeroAddressNotAllowed = 55314
    /// Message too large
    MessageTooLarge = 56064
    /// Amount must be positive
    AmountMustBePositive = 61135
    /// Burn amount too large
    BurnAmountTooLarge = 62093
    /// Cannot burn more than total supply
    CannotBurnMoreThanTotalSupply = 62340
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
