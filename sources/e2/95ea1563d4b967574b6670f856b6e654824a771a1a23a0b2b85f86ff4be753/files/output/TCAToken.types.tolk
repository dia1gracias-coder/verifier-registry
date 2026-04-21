// Generated from the verified Tact contract ABI.
contract TCAToken {
    storage: TCATokenData
    incomingMessages: TCATokenIncomingMessage
    thrownErrors: TCATokenErrors
}

struct (0x946a98b6) TCATokenDeploy {
    queryId: uint64
}

struct (0x4eb9fa94) TCATokenBatchMint {
    portfolioAmount: coins
    profitAmount: coins
}

struct (0x7b6553e4) TCATokenBatchBurn {
    amount: coins
}

struct (0x4956cbf6) TCATokenRecordWithdrawal {
    amount: coins
}

struct (0x1c4c0bd4) TCATokenProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

struct (0x6377b77f) TCATokenBurnNotification {
    queryId: uint64
    amount: coins
    sender: address
    responseDestination: address?
}

struct (0xbceb819a) TCATokenSetMinter {
    newMinter: address
}

struct (0x4d9c0367) TCATokenSetAdminWallet {
    newAdminWallet: address
}

struct (0x460155df) TCATokenSetMarketing {
    newWallet: address
    newPct: uint8
}

struct (0x53acce9a) TCATokenDisableMinting {
}

struct TCATokenJettonData {
    total_supply: int257
    mintable: bool
    admin_address: address
    jetton_content: cell
    jetton_wallet_code: cell
}

struct TCATokenData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    minter: address
    adminWallet: address
    tactContinuation: Cell<TCATokenDataContinuation>
}

struct TCATokenDataContinuation {
    marketingWallet: address
    marketingPct: uint8
    totalSupply: coins
    content: cell
    mintable: bool
    portfolioLocked: coins
    profitCirculating: coins
    totalMinted: coins
    totalBurned: coins
    totalWithdrawn: coins
    tactContinuation: Cell<TCATokenDataContinuation2>
}

struct TCATokenDataContinuation2 {
    totalMarketingMinted: coins
    lastSyncAt: uint32
    syncCount: uint32
}

type TCATokenIncomingMessage =
    | TCATokenBatchMint
    | TCATokenBatchBurn
    | TCATokenRecordWithdrawal
    | TCATokenBurnNotification
    | TCATokenProvideWalletAddress
    | TCATokenSetMinter
    | TCATokenSetAdminWallet
    | TCATokenSetMarketing
    | TCATokenDisableMinting
    | TCATokenDeploy

enum TCATokenErrors {
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
    /// Exceeds profit circulating
    ExceedsProfitCirculating = 9998
    /// Burn exceeds portfolio locked
    BurnExceedsPortfolioLocked = 15245
    /// Only owner can burn
    OnlyOwnerCanBurn = 21543
    /// Nothing to burn
    NothingToBurn = 32351
    /// Unauthorized burn notification
    UnauthorizedBurnNotification = 34393
    /// Only owner
    OnlyOwner = 35499
    /// Nothing to mint
    NothingToMint = 36724
    /// Only owner can transfer
    OnlyOwnerCanTransfer = 36952
    /// Insufficient balance
    InsufficientBalance = 54615
    /// Max 20%
    Max20 = 55349
    /// Minting disabled
    MintingDisabled = 56760
    /// Only minter
    OnlyMinter = 57414
}

get fun portfolioLocked(): int257 {
    throw 0;
}

get fun profitCirculating(): int257 {
    throw 0;
}

get fun totalInGame(): int257 {
    throw 0;
}

get fun totalMinted(): int257 {
    throw 0;
}

get fun totalBurned(): int257 {
    throw 0;
}

get fun totalWithdrawn(): int257 {
    throw 0;
}

get fun totalMarketingMinted(): int257 {
    throw 0;
}

get fun lastSyncAt(): int257 {
    throw 0;
}

get fun syncCount(): int257 {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun minter(): address {
    throw 0;
}

get fun adminWallet(): address {
    throw 0;
}

get fun marketingWallet(): address {
    throw 0;
}

get fun marketingPct(): int257 {
    throw 0;
}

get fun totalSupply(): int257 {
    throw 0;
}

get fun mintable(): bool {
    throw 0;
}

get fun jetton_data(): TCATokenJettonData {
    throw 0;
}

get fun wallet_address(ownerAddress: address): address {
    throw 0;
}
