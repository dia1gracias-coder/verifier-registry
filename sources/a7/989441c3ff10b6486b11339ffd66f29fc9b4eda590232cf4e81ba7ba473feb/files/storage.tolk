// Storage layouts for the TEP-62 NFT collection + royalty-enabled NFT item.
//
// In TON, a contract's persistent state ("storage") is just a `cell` — a
// binary blob. Tolk's `struct` + `.toCell()` / `.fromCell()` let us treat
// that blob as a typed object instead of hand-packing bits ourselves.

// SnakeString describes a (potentially long) string inside a cell.
// Short strings are stored as-is, long strings are stored in nested refs
// ("snake"-shaped, hence the name) so they can exceed one cell's ~1023 bits.
type SnakeString = slice;

fun SnakeString.unpackFromSlice(mutate s: slice) {
    // In the original reference implementation, the whole remaining slice is returned.
    // We keep the behavior but skip extra reference-count validations.
    val snakeRemainder = s;
    s = createEmptySlice(); // no more left to read
    return snakeRemainder;
}

fun SnakeString.packToBuilder(self, mutate b: builder) {
    b.storeSlice(self);
}

// Content of the collection itself (its metadata JSON + a prefix shared by
// every NFT's own metadata URI).
struct CollectionContent {
    collectionMetadata: cell
    commonContent: Cell<SnakeString>
}

// ---- Collection contract storage ----
// One collection contract manages many NFT items. It only needs to
// remember who's allowed to mint, how many items exist so far, its own
// metadata, and the code every new NFT item should be deployed with.
struct NftCollectionStorage {
    adminAddress: address   // only this address can mint new NFTs
    nextItemIndex: uint64   // index to use for the next minted NFT (0, 1, 2, ...)
    content: Cell<CollectionContent>
    nftItemCode: cell       // compiled code every NFT item contract is deployed with
}

// ---- NFT item contract storage ----
// Each individual NFT is its own tiny contract. It only needs to know
// which item/collection it is, who owns it right now, its metadata, and
// where the 2% transfer royalty should be paid.
struct NftItemStorage {
    itemIndex: uint64
    collectionAddress: address
    ownerAddress: address
    content: Cell<SnakeString>

    // Address that receives the 2% royalty every time this NFT is transferred.
    royaltyAddress: address
}

// Before the collection deploys an item, the item contract only knows its
// own index and its parent collection — nothing else exists yet.
struct NftItemStorageNotInitialized {
    itemIndex: uint64
    collectionAddress: address
}

fun NftCollectionStorage.load() {
    return NftCollectionStorage.fromCell(contract.getData());
}

fun NftCollectionStorage.save(self) {
    contract.setData(self.toCell());
}

fun NftItemStorage.save(self) {
    contract.setData(self.toCell());
}

// An NFT item contract's storage cell is either "not initialized yet"
// (just deployed, waiting for its first message from the collection) or
// "initialized" (has an owner, content, royalty address). We tell the two
// apart by checking whether the cell has any reference cells attached yet.
struct NftItemStorageMaybeNotInitialized {
    contractData: slice
}

fun NftItemStorageMaybeNotInitialized.isInitialized(self): bool {
    return self.contractData.remainingRefsCount() != 0;
}

fun NftItemStorageMaybeNotInitialized.parseNotInitialized(self) {
    return NftItemStorageNotInitialized.fromSlice(self.contractData);
}

fun NftItemStorageMaybeNotInitialized.parseInitialized(self) {
    return NftItemStorage.fromSlice(self.contractData);
}

fun startLoadingNftItemStorage(): NftItemStorageMaybeNotInitialized {
    return {
        contractData: contract.getData().beginParse(),
    }
}

// Computes the on-chain address an NFT item with a given index *would*
// have, without needing that contract to exist yet. TON addresses are
// derived from (code + initial data), so this is fully deterministic —
// the collection and anyone else can predict it in advance.
fun calcDeployedNftItem(
    itemIndex: uint64,
    collectionAddress: address,
    nftItemCode: cell,
): AutoDeployAddress {
    val emptyNftItemStorage: NftItemStorageNotInitialized = {
        itemIndex,
        collectionAddress,
    };

    return {
        stateInit: {
            code: nftItemCode,
            data: emptyNftItemStorage.toCell(),
        },
    }
}
