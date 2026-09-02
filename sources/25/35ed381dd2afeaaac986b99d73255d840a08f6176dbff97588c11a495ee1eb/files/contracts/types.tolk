struct RoyaltyParams {
    numerator: uint16
    denominator: uint16
    royaltyAddress: address
}

/// PUBLIC is represented by absence from the catalog dictionary.
const NAME_STATUS_PUBLIC = 0
const NAME_STATUS_VIP = 1
const NAME_STATUS_RESERVED = 2
const NAME_STATUS_BLOCKED = 3

const MINT_STATE_UNMINTED = 0
const MINT_STATE_PENDING = 1
const MINT_STATE_ACTIVE = 2

const PENDING_MINT_DEPLOYING = 0
const PENDING_MINT_REFUND_DUE = 1
const NFT_ITEM_CONTENT_PREFIX = 0x00

struct NamePrices {
    length1: coins
    length2: coins
    length3: coins
    length4: coins
    length5: coins
    length6: coins
    length7To12: coins
    length13To32: coins
}

struct NameCatalogEntry {
    status: uint2
    price: coins
    reservedFor: address?
}

struct CatalogInitializationState {
    expectedCount: uint32
    loadedCount: uint32
    rollingHash: uint256
    expectedHash: uint256
    finalized: bool
}

struct PendingMint {
    itemIndex: uint256
    payerAddress: address
    queryId: uint64
    price: coins
    refundAmount: coins
    state: uint1
}

struct TimelockProposal {
    governanceEpoch: uint32
    executeAfter: uint64
    expiresAt: uint64
    action: cell
}

struct PendingAdminChange {
    newAdminAddress: address
    executeAfter: uint64
    expiresAt: uint64
}

struct PricingStorage {
    treasuryAddress: address
    pricingVersion: uint32
    itemDeployValue: coins
    prices: Cell<NamePrices>
    catalog: map<uint256, NameCatalogEntry>
    catalogInitialization: Cell<CatalogInitializationState>
}

struct RecycledItemIndexes {
    head: uint256
    tail: uint256
    indexes: map<uint256, uint256>
}

struct RegistryStorage {
    nextItemIndex: uint256
    recycled: Cell<RecycledItemIndexes>
    governanceEpoch: uint32
    activeNames: map<uint256, uint256>
    pendingMints: map<uint256, PendingMint>
    proposals: map<uint256, TimelockProposal>
    pendingAdmin: PendingAdminChange?
}

struct CollectionContent {
    collectionMetadata: cell
    commonContent: Cell<SnakeString>
}

struct CollectionDetails {
    content: Cell<CollectionContent>
    royaltyParams: Cell<RoyaltyParams>
}

struct NftCollectionStorage {
    adminAddress: address
    paused: bool
    details: Cell<CollectionDetails>
    nftItemCode: cell
    pricing: Cell<PricingStorage>
    registry: Cell<RegistryStorage>
}

struct NftNameDetails {
    name: string
    nameHash: uint256
    content: Cell<SnakeString>
    category: uint2
    mintPrice: coins
    mintedAt: uint64
}

struct NftItemStorage {
    itemIndex: uint256
    collectionAddress: address
    ownerAddress: address
    details: Cell<NftNameDetails>
}

struct NftItemStorageNotInitialized {
    itemIndex: uint256
    collectionAddress: address
}

struct NftItemStorageLoader {
    itemIndex: uint256
    collectionAddress: address
    private rest: RemainingBitsAndRefs
}

struct NftDataReply {
    isInitialized: bool
    itemIndex: int
    collectionAddress: address
    ownerAddress: address? = null
    content: Cell<SnakeString>? = null
}

struct NameDataReply {
    name: string
    nameHash: uint256
    length: uint8
    category: uint2
    mintPrice: coins
    mintedAt: uint64
}

struct CollectionDataReply {
    nextItemIndex: int
    collectionMetadata: cell
    adminAddress: address
}

struct NameQuoteReply {
    nameHash: uint256
    itemIndex: uint256
    length: uint8
    status: uint2
    mintState: uint2
    price: coins
    requiredValue: coins
    pricingVersion: uint32
    itemAddress: address
}

struct CollectionConfigReply {
    adminAddress: address
    treasuryAddress: address
    paused: bool
    pricingVersion: uint32
    itemDeployValue: coins
    prices: NamePrices
    timelockDelay: uint32
    proposalExecutionWindow: uint32
    governanceEpoch: uint32
    catalogExpectedCount: uint32
    catalogLoadedCount: uint32
    catalogRollingHash: uint256
    catalogExpectedHash: uint256
    catalogFinalized: bool
}

struct ProposalStateReply {
    exists: bool
    governanceEpoch: uint32
    executeAfter: uint64
    expiresAt: uint64
    action: cell?
}

struct PendingMintReply {
    exists: bool
    itemIndex: uint256
    payerAddress: address?
    queryId: uint64
    price: coins
    refundAmount: coins
    state: uint1
}

struct PendingAdminReply {
    exists: bool
    newAdminAddress: address?
    executeAfter: uint64
    expiresAt: uint64
}

fun NftCollectionStorage.load(): NftCollectionStorage {
    return NftCollectionStorage.fromCell(contract.getData());
}

fun NftCollectionStorage.save(self) {
    contract.setData(self.toCell());
}

fun NftItemStorage.startLoading(): NftItemStorageLoader {
    return NftItemStorageLoader.fromCell(contract.getData());
}

fun NftItemStorage.save(self) {
    contract.setData(self.toCell());
}

fun NftItemStorageLoader.isNotInitialized(self): bool {
    return self.rest.isEmpty();
}

fun NftItemStorageLoader.endLoading(mutate self): NftItemStorage {
    return {
        itemIndex: self.itemIndex,
        collectionAddress: self.collectionAddress,
        ownerAddress: self.rest.loadAny(),
        details: self.rest.loadAny(),
    };
}

fun calcDeployedNftItem(
    itemIndex: uint256,
    collectionAddress: address,
    nftItemCode: cell,
): AutoDeployAddress {
    val emptyStorage: NftItemStorageNotInitialized = { itemIndex, collectionAddress };
    return { stateInit: { code: nftItemCode, data: emptyStorage.toCell() } };
}

/// TEP-62/TEP-64 use a raw snake slice for item content, not the higher-level
/// `string` ABI type. Keeping this explicit also makes the generated getter
/// signature identical to the canonical TON NFT implementation.
type SnakeString = slice

fun SnakeString.unpackFromSlice(mutate s: slice): slice {
    val snakeRemainder = s;
    s = createEmptySlice();
    return snakeRemainder;
}

fun SnakeString.packToBuilder(self, mutate b: builder) {
    b.storeSlice(self);
}

fun stringToSnakeCell(value: string): Cell<SnakeString> {
    return value as unknown as Cell<SnakeString>;
}
