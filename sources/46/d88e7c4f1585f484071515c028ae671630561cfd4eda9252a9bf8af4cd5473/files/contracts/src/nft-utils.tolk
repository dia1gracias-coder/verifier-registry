import "item-storage"

fun calcDeployedNftItem(
    itemIndex: uint32,
    collectionAddress: address,
    nftItemCode: cell,
): AutoDeployAddress {
    val initial: NftItemStorageNotInitialized = { itemIndex, collectionAddress };
    return { stateInit: { code: nftItemCode, data: initial.toCell() } };
}
