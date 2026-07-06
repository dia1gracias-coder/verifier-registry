enum Errors {
    NotFactoryOwner = 100
    FactoryCreatePaused = 101
    InvalidFeeBps = 102
    InvalidPrice = 103
    InvalidExpiry = 104
    InvalidIntentHash = 105
    InvalidFeeConfig = 106
    PendingDepositExists = 107
    PendingDepositMissing = 108
    WrongPendingDeposit = 109
    RecoveryNotAllowed = 110
    NotSeller = 200
    SaleNotActive = 201
    SaleExpired = 202
    SaleNotExpired = 203
    PriceMismatch = 204
    InsufficientValue = 205
    WrongNftSender = 206
    WrongNftMarker = 207
    WrongNftResponse = 208
    AlreadySettled = 209
    BuyerMismatch = 210
    NotBuyer = 211
    InsufficientReserve = 212
    WrongFactoryDeposit = 213
    InvalidPricingMode = 214
    InvalidQuote = 215
    QuoteExpired = 216
    QuoteNotActive = 217
    InvalidSignature = 218
    QuotePriceMismatch = 219
    NotNftOwner = 300
    NotImplemented = 0xFFFE
    InvalidMessage = 0xFFFF
}

type MarketTlbEither<X, Y> = MarketTlbEitherLeft<X> | MarketTlbEitherRight<Y>

@inline
fun MarketTlbEither<X, Y>.left(value: X): MarketTlbEitherLeft<X> {
    return MarketTlbEitherLeft { value };
}

@inline
fun MarketTlbEither<X, Y>.right(value: Y): MarketTlbEitherRight<Y> {
    return MarketTlbEitherRight { value };
}

struct (0b0) MarketTlbEitherLeft<X> {
    value: X
}

struct (0b1) MarketTlbEitherRight<X> {
    value: X
}

type MarketTlbMaybe<X> = MarketTlbNone | MarketTlbJust<X>

struct (0b0) MarketTlbNone

struct (0b1) MarketTlbJust<X> {
    value: X
}

fun MarketTlbMaybe<X>.none(): MarketTlbMaybe<X> {
    return MarketTlbNone {};
}

fun MarketTlbMaybe<X>.just(value: X): MarketTlbMaybe<X> {
    return MarketTlbJust { value };
}

enum SaleState {
    Created = 0
    Active = 1
    SettlingBuy = 2
    SettlingCancel = 3
    Sold = 4
    Cancelled = 5
    TransferFailedBuy = 6
    TransferFailedCancel = 7
}

enum SalePricingMode {
    FixedNative = 0
    LiveUsdQuote = 1
}

enum FactoryPendingStage {
    WaitingSaleReady = 1
    TransferringToSale = 2
    TransferFailedToSale = 3
    RecoveringToSeller = 4
    RecoveryFailedToSeller = 5
}

struct FactoryPendingDeposit {
    seller: address
    expectedSale: address
    terms: Cell<SaleTerms>
    transferQueryId: uint64
    recoveryQueryId: uint64
    stage: FactoryPendingStage
    createdAt: uint64
}

struct FactoryStorage {
    owner: address
    feeWallet: address
    feeBps: uint16
    defaultLifetimeSeconds: uint32
    createPaused: bool
    nextSaleId: uint64
    saleCode: cell
    pendingDeposits: map<address, Cell<FactoryPendingDeposit>>
}

struct FactoryV2PendingDeposit {
    seller: address
    expectedSale: address
    terms: Cell<SaleV2Terms>
    transferQueryId: uint64
    recoveryQueryId: uint64
    stage: FactoryPendingStage
    createdAt: uint64
}

struct FactoryV2Storage {
    owner: address
    feeWallet: address
    feeBps: uint16
    defaultLifetimeSeconds: uint32
    networkId: uint32
    createPaused: bool
    nextSaleId: uint64
    saleCode: cell
    pendingDeposits: map<address, Cell<FactoryV2PendingDeposit>>
}

fun FactoryStorage.load(): FactoryStorage {
    return FactoryStorage.fromCell(contract.getData());
}

fun FactoryStorage.save(self) {
    contract.setData(self.toCell());
}

fun FactoryV2Storage.load(): FactoryV2Storage {
    return FactoryV2Storage.fromCell(contract.getData());
}

fun FactoryV2Storage.save(self) {
    contract.setData(self.toCell());
}

struct SaleParties {
    seller: address
    nftItem: address
}

struct SaleTerms {
    price: coins
    feeWallet: address
    feeBps: uint16
    expiresAt: uint64
    marketplaceIntentHash: uint256
}

struct SaleSettlement {
    buyer: address?
    refundRecipient: address?
    refundBudget: coins
    nftTransferQueryId: uint64
    payoutDone: bool
}

struct SaleV2PricingPolicy {
    pricingMode: uint8
    networkId: uint32
    fixedPrice: coins
    usdPriceMicro: uint64
    rateScale: uint32
    oraclePublicKey: uint256
    minPriceNano: coins
    maxPriceNano: coins
}

struct SaleV2Terms {
    pricing: Cell<SaleV2PricingPolicy>
    feeWallet: address
    feeBps: uint16
    expiresAt: uint64
    marketplaceIntentHash: uint256
}

struct SaleV2Settlement {
    buyer: address?
    refundRecipient: address?
    refundBudget: coins
    nftTransferQueryId: uint64
    settlementPrice: coins
    payoutDone: bool
}

struct SaleV2Storage {
    factory: address
    saleId: uint64
    state: uint8
    parties: Cell<SaleParties>
    terms: Cell<SaleV2Terms>
    settlement: Cell<SaleV2Settlement>
}

fun SaleV2Storage.load(): SaleV2Storage {
    return SaleV2Storage.fromCell(contract.getData());
}

fun SaleV2Storage.save(self) {
    contract.setData(self.toCell());
}

struct SaleStorage {
    factory: address
    saleId: uint64
    state: uint8
    parties: Cell<SaleParties>
    terms: Cell<SaleTerms>
    settlement: Cell<SaleSettlement>
}

fun SaleStorage.load(): SaleStorage {
    return SaleStorage.fromCell(contract.getData());
}

fun SaleStorage.save(self) {
    contract.setData(self.toCell());
}

struct MockNftStorage {
    owner: address
    collection: address
    bounceTransfers: bool
    suppressResponses: bool
}

fun MockNftStorage.load(): MockNftStorage {
    return MockNftStorage.fromCell(contract.getData());
}

fun MockNftStorage.save(self) {
    contract.setData(self.toCell());
}

struct DisposableNftStorage {
    owner: address
    collection: address
    index: uint64
    content: cell
}

fun DisposableNftStorage.load(): DisposableNftStorage {
    return DisposableNftStorage.fromCell(contract.getData());
}

fun DisposableNftStorage.save(self) {
    contract.setData(self.toCell());
}

struct Tep62NftData {
    initialized: int
    index: uint64
    collection: address
    owner: address
    content: cell
}

struct (0x47524353) FactoryCreateSale {
    queryId: uint64
    parties: Cell<SaleParties>
    terms: Cell<SaleTerms>
}

struct (0x47324353) FactoryV2CreateSale {
    queryId: uint64
    parties: Cell<SaleParties>
    terms: Cell<SaleV2Terms>
}

struct (0x47504643) FactorySetCreatePaused {
    queryId: uint64
    paused: bool
}

struct (0x47504645) FactorySetFeeConfig {
    queryId: uint64
    feeWallet: address
    feeBps: uint16
}

struct (0x4746444e) FactoryDepositNft {
    queryId: uint64
    parties: Cell<SaleParties>
    terms: Cell<SaleTerms>
    factoryRefundBudget: coins
}

struct (0x4732444e) FactoryV2DepositNft {
    queryId: uint64
    parties: Cell<SaleParties>
    terms: Cell<SaleV2Terms>
    factoryRefundBudget: coins
}

struct (0x47464443) FactoryDepositCompleted {
    queryId: uint64
    nftItem: address
    marketplaceIntentHash: uint256
}

struct (0x4746524e) FactoryRecoverPendingNft {
    queryId: uint64
    nftItem: address
    marketplaceIntentHash: uint256
}

struct FactoryListWithNftTerms {
    price: coins
    feeWallet: address
    feeBps: uint16
    expiresAt: uint64
    marketplaceIntentHash: uint256
}

struct (0x47534c4e) FactoryListWithNftMarker {
    queryId: uint64
    sellerAddress: address
    terms: Cell<FactoryListWithNftTerms>
}

struct (0x47324c4e) FactoryV2ListWithNftMarker {
    queryId: uint64
    sellerAddress: address
    terms: Cell<SaleV2Terms>
}

struct (0x47535244) SaleRequestDeposit {
    queryId: uint64
    marketplaceIntentHash: uint256
    factoryRefundBudget: coins
}

struct (0x47534259) SaleBuy {
    queryId: uint64
    buyerAddress: address
    expectedPriceNano: coins
    marketplaceIntentHash: uint256
}

struct (0x47324658) SaleV2BuyFixed {
    queryId: uint64
    buyerAddress: address
    expectedPriceNano: coins
    marketplaceIntentHash: uint256
}

struct SaleV2LiveQuoteScope {
    networkId: uint32
    factory: address
    sale: address
    buyer: address
}

struct SaleV2LiveQuoteListing {
    seller: address
    nftItem: address
    marketplaceIntentHash: uint256
    usdPriceMicro: uint64
}

struct SaleV2LiveQuotePricing {
    rateUsdPerGramMicro: uint64
    priceNano: coins
    issuedAt: uint64
    expiresAt: uint64
    quoteId: uint256
}

struct SaleV2LiveQuote {
    scope: Cell<SaleV2LiveQuoteScope>
    listing: Cell<SaleV2LiveQuoteListing>
    pricing: Cell<SaleV2LiveQuotePricing>
}

struct (0x47324c52) SaleV2BuyLive {
    queryId: uint64
    quote: Cell<SaleV2LiveQuote>
    signature: bits512
}

struct (0x4753434c) SaleCancel {
    queryId: uint64
    marketplaceIntentHash: uint256
}

struct (0x47535254) SaleRetryTransfer {
    queryId: uint64
    marketplaceIntentHash: uint256
}

struct (0x47535246) SaleRefundBuy {
    queryId: uint64
    marketplaceIntentHash: uint256
}

struct (0x47534450) SaleDepositMarker {
    queryId: uint64
    marketplaceIntentHash: uint256
    sellerAddress: address
}

struct (0x05138d91) NftOwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: MarketTlbEither<cell, Cell<cell>>
}

struct (0x5fcc3d14) NftTransfer {
    queryId: uint64
    newOwner: address
    responseDestination: address
    customPayload: MarketTlbMaybe<Cell<cell>>
    forwardAmount: coins
    forwardPayload: MarketTlbEither<cell, Cell<cell>>
}

struct (0xd53276db) NftExcesses {
    queryId: uint64
}

struct (0x4d534246) MockSetBehavior {
    queryId: uint64
    bounceTransfers: bool
    suppressResponses: bool
}
