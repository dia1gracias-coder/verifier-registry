struct NftItemStorage {
    itemIndex: uint32
    collectionAddress: address
    ownerAddress: address
    content: string
}

struct NftItemStorageNotInitialized {
    itemIndex: uint32
    collectionAddress: address
}

struct NftItemStorageLoader {
    itemIndex: uint32
    collectionAddress: address
    private rest: RemainingBitsAndRefs
}

fun NftItemStorage.startLoading(): NftItemStorageLoader {
    return NftItemStorageLoader.fromCell(contract.getData());
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

fun NftItemStorage.save(self) {
    contract.setData(self.toCell());
}
