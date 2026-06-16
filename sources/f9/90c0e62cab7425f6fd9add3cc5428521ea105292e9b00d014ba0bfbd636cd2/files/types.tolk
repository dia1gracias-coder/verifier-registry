struct RoyaltyParams {
    numerator: uint16
    denominator: uint16
    royaltyAddress: address
}

struct CollectionContent {
    collectionMetadata: cell
    commonContent: string
}

struct NftCollectionStorage {
    adminAddress: address
    nextItemIndex: uint64
    content: Cell<CollectionContent>
    nftItemCode: cell
    royaltyParams: Cell<RoyaltyParams>
    mintPrice: coins
    maxSupply: uint64
}

fun NftCollectionStorage.load(): NftCollectionStorage {
    return NftCollectionStorage.fromCell(contract.getData());
}

fun NftCollectionStorage.save(self) {
    contract.setData(self.toCell());
}

// NFT item storage is tricky: it changes shape after deployment.
// Initially it holds only itemIndex + collectionAddress (NftItemStorageNotInitialized);
// after the collection initializes it, it becomes a full NftItemStorage.
struct NftItemStorage {
    itemIndex: uint64
    collectionAddress: address
    ownerAddress: address
    content: string
}

struct NftItemStorageNotInitialized {
    itemIndex: uint64
    collectionAddress: address
}

struct NftItemStorageLoader {
    itemIndex: uint64
    collectionAddress: address
    private rest: RemainingBitsAndRefs
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
        content: self.rest.loadAny(),
    };
}

fun calcDeployedNftItem(
    itemIndex: uint64,
    collectionAddress: address,
    nftItemCode: cell,
): AutoDeployAddress {
    val emptyNftItemStorage: NftItemStorageNotInitialized = { itemIndex, collectionAddress };
    return { stateInit: { code: nftItemCode, data: emptyNftItemStorage.toCell() } };
}

struct CollectionDataReply {
    nextItemIndex: int
    collectionMetadata: cell
    adminAddress: address
}

struct MintDataReply {
    nextItemIndex: int
    maxSupply: int
    mintPrice: coins
    adminAddress: address
}

struct NftDataReply {
    isInitialized: bool
    itemIndex: int
    collectionAddress: address
    ownerAddress: address? = null
    content: string? = null
}

struct (0x01) OffchainMetadataReply {
    string: string
}
