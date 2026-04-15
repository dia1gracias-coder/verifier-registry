import "errors"

type SnakeString = slice

fun SnakeString.unpackFromSlice(mutate s: slice) {
    assert (s.remainingRefsCount() <= 1) throw 5;
    val snakeRemainder = s;
    s = createEmptySlice();
    return snakeRemainder
}

fun SnakeString.packToBuilder(self, mutate b: builder) {
    b.storeSlice(self)
}

struct CollectionMetadata {
    collectionName: Cell<SnakeString>
    collectionDescription: Cell<SnakeString>
    channelLink: Cell<SnakeString>
}

struct PostData {
    postKind: uint8
    textContent: Cell<SnakeString>? = null
    mediaUrl: Cell<SnakeString>? = null
    description: Cell<SnakeString>? = null
}

struct TheOpenChannelStorage {
    adminAddress: address
    nextItemIndex: uint64
    metadata: Cell<CollectionMetadata>
    itemCode: cell
}

struct TheOpenChannelItemStorage {
    itemIndex: uint64
    collectionAddress: address
    ownerAddress: address
    postData: Cell<PostData>
}

struct TheOpenChannelItemStorageNotInitialized {
    itemIndex: uint64
    collectionAddress: address
}

struct TheOpenChannelItemStorageMaybeNotInitialized {
    contractData: slice
}

fun TheOpenChannelStorage.load() {
    return TheOpenChannelStorage.fromCell(contract.getData())
}

fun TheOpenChannelStorage.save(self) {
    contract.setData(self.toCell())
}

fun TheOpenChannelItemStorage.save(self) {
    contract.setData(self.toCell())
}

fun TheOpenChannelItemStorageMaybeNotInitialized.isInitialized(self) {
    return self.contractData.remainingRefsCount()
}

fun TheOpenChannelItemStorageMaybeNotInitialized.parseInitialized(self) {
    return TheOpenChannelItemStorage.fromSlice(self.contractData)
}

fun TheOpenChannelItemStorageMaybeNotInitialized.parseNotInitialized(self) {
    return TheOpenChannelItemStorageNotInitialized.fromSlice(self.contractData)
}

fun startLoadingTheOpenChannelItemStorage(): TheOpenChannelItemStorageMaybeNotInitialized {
    return {
        contractData: contract.getData().beginParse()
    }
}

fun validatePostData(data: PostData) {
    if (data.postKind == POST_KIND_TEXT) {
        assert (data.textContent != null) throw ERROR_INVALID_POST_DATA;
        assert (data.mediaUrl == null) throw ERROR_INVALID_POST_DATA;
        assert (data.description == null) throw ERROR_INVALID_POST_DATA;
        return;
    }
    if (data.postKind == POST_KIND_MEDIA) {
        assert (data.textContent == null) throw ERROR_INVALID_POST_DATA;
        assert (data.mediaUrl != null) throw ERROR_INVALID_POST_DATA;
        assert (data.description != null) throw ERROR_INVALID_POST_DATA;
        return;
    }

    throw ERROR_INVALID_POST_KIND;
}

fun validatePostDataCell(data: Cell<PostData>) {
    val parsed = lazy data.load();
    validatePostData(parsed);
}

fun calcDeployedTheOpenChannelItem(
    itemIndex: uint64,
    collectionAddress: address,
    itemCode: cell,
): AutoDeployAddress {
    val emptyItemStorage: TheOpenChannelItemStorageNotInitialized = {
        itemIndex,
        collectionAddress,
    };

    return {
        stateInit: {
            code: itemCode,
            data: emptyItemStorage.toCell()
        }
    }
}
