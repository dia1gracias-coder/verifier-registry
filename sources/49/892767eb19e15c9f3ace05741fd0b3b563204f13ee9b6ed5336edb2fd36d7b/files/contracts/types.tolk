import "constants"

// ============================================================
//  Collection
// ============================================================

struct RoyaltyParams {
    numerator: uint16
    denominator: uint16
    royaltyAddress: address
}

/// The collection stores the GRM master and the code of its jetton wallets,
/// which is enough to derive the GRM wallet address of any owner — its own and
/// every domain's. Nothing has to be configured after deployment.
struct JettonConfig {
    grmMaster: address
    grmWalletCode: cell
    /// Лежит здесь, а не в корне: корневая ячейка вмещает только четыре ссылки,
    /// а реестр доменов занял одну из них.
    royalty: Cell<RoyaltyParams>
}

/// `ownerAddress` is null once ownership has been renounced, after which no
/// administrative message can ever be accepted again.
struct GrmDnsCollectionStorage {
    ownerAddress: address?
    /// Сколько доменов создано. Растёт ровно тогда, когда новый контракт
    /// домена подтвердил приём первой ставки: повторный аукцион после
    /// истечения через коллекцию не идёт и счётчик не трогает.
    mintedCount: uint64
    /// Порядковый номер -> хеш имени. Нужен, чтобы `get_nft_address_by_index`
    /// работал как ждёт TEP-62: по номеру от 0 до mintedCount-1, а не по хешу.
    /// Без него количество в `get_collection_data` было бы враньём —
    /// индексатор пошёл бы перебирать номера и получил несуществующие адреса.
    domainIndex: dict
    content: cell
    itemCode: cell
    jetton: Cell<JettonConfig>
}

fun GrmDnsCollectionStorage.load(): GrmDnsCollectionStorage {
    return GrmDnsCollectionStorage.fromCell(contract.getData());
}

fun GrmDnsCollectionStorage.save(self) {
    contract.setData(self.toCell());
}

// ============================================================
//  Domain item
// ============================================================

/// `isFunded` is false in the short window between a first bid being accepted
/// and the GRM actually arriving from the collection. Competing bids are
/// refunded during that window: the domain cannot pay back a leader whose money
/// is still in flight.
struct AuctionInfo {
    maxBidAddress: address
    maxBidAmount: coins
    auctionEndTime: uint64
    isFunded: bool
}

struct GrmDnsItemStorageNotInitialized {
    itemIndex: uint256
    collectionAddress: address
}

/// `ownerAddress` is null while an auction is running: an unclaimed domain has
/// no owner and resolves to nothing.
struct GrmDnsItemStorage {
    itemIndex: uint256
    collectionAddress: address
    ownerAddress: address?
    content: cell
    domain: cell
    auction: Cell<AuctionInfo>?
    lastFillUpTime: uint64
    /// This domain's own GRM wallet. Every bid after the first one is paid
    /// straight into it, and refunds and the final burn leave from it.
    /// Kept behind a reference: index, collection, owner and wallet are four
    /// addresses' worth of bits and would not fit in one cell.
    wallet: Cell<DomainWallet>
}

struct DomainWallet {
    grmWallet: address
}

/// The storage of a domain changes shape after the first bid: before it, only
/// the index and the collection are present. `startLoading` lets the contract
/// tell the two states apart without failing to deserialize.
struct GrmDnsItemStorageLoader {
    itemIndex: uint256
    collectionAddress: address
    private rest: RemainingBitsAndRefs
}

fun GrmDnsItemStorage.startLoading(): GrmDnsItemStorageLoader {
    return GrmDnsItemStorageLoader.fromCell(contract.getData());
}

fun GrmDnsItemStorageLoader.isNotInitialized(self): bool {
    return self.rest.isEmpty();
}

fun GrmDnsItemStorageLoader.endLoading(mutate self): GrmDnsItemStorage {
    return {
        itemIndex: self.itemIndex,
        collectionAddress: self.collectionAddress,
        ownerAddress: self.rest.loadAny(),
        content: self.rest.loadAny(),
        domain: self.rest.loadAny(),
        auction: self.rest.loadAny(),
        lastFillUpTime: self.rest.loadAny(),
        wallet: self.rest.loadAny(),
    };
}

fun GrmDnsItemStorage.save(self) {
    contract.setData(self.toCell());
}

/// A domain expires a year after the last owner action.
fun GrmDnsItemStorage.isExpired(self): bool {
    return blockchain.now() - self.lastFillUpTime > ONE_YEAR;
}

/// Domain contracts are addressed by the sha256 of their name, so the address
/// of every domain is known before it exists.
fun calcDeployedDomain(
    itemIndex: uint256,
    collectionAddress: address,
    itemCode: cell,
): AutoDeployAddress {
    val emptyStorage: GrmDnsItemStorageNotInitialized = { itemIndex, collectionAddress };
    return { stateInit: { code: itemCode, data: emptyStorage.toCell() } };
}

// ============================================================
//  Getter replies
// ============================================================

struct CollectionDataReply {
    nextItemIndex: int
    collectionContent: cell
    ownerAddress: address?
}

struct NftDataReply {
    isInitialized: bool
    itemIndex: int
    collectionAddress: address
    ownerAddress: address? = null
    content: cell? = null
}

struct GrmConfigReply {
    grmMaster: address
    grmWallet: address
}

struct AuctionInfoReply {
    maxBidAddress: address?
    maxBidAmount: coins
    auctionEndTime: int
    isFunded: bool
}
