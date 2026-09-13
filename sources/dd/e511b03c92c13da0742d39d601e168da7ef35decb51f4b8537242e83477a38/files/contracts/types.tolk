import "constants"


struct JettonConfig {
    grmMaster: address
    grmWalletCode: cell
}

struct GrmDnsCollectionStorage {
    ownerAddress: address?
    mintedCount: uint64
    domainIndex: map<uint64, uint256>
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

struct GrmDnsItemStorage {
    itemIndex: uint256
    collectionAddress: address
    ownerAddress: address?
    content: cell
    domain: cell
    auction: Cell<AuctionInfo>?
    lastFillUpTime: uint64
    wallet: Cell<DomainData>
}

struct DomainData {
    grmWallet: address
    records: cell?
}

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

fun GrmDnsItemStorage.isExpired(self): bool {
    return blockchain.now() - self.lastFillUpTime > ONE_YEAR;
}

fun calcDeployedDomain(
    itemIndex: uint256,
    collectionAddress: address,
    itemCode: cell,
): AutoDeployAddress {
    val emptyStorage: GrmDnsItemStorageNotInitialized = { itemIndex, collectionAddress };
    return { stateInit: { code: itemCode, data: emptyStorage.toCell() } };
}


fun addressOrNone(a: address?): any_address {
    if (a == null) {
        return createAddressNone();
    }
    return a! as any_address;
}


struct CollectionDataReply {
    nextItemIndex: int
    collectionContent: cell
    ownerAddress: any_address
}

struct NftDataReply {
    isInitialized: int
    itemIndex: int
    collectionAddress: address
    ownerAddress: any_address
    content: cell
}

struct GrmConfigReply {
    grmMaster: address
    grmWallet: address
}

struct AuctionInfoReply {
    maxBidAddress: any_address
    maxBidAmount: coins
    auctionEndTime: int
    isFunded: bool
}
