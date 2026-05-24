import "messages.tolk"

struct BagRegistryStorage {
    nextBagIndex: uint64 = 0
}

fun BagRegistryStorage.load(): BagRegistryStorage {
    return BagRegistryStorage.fromCell(contract.getData());
}

fun BagRegistryStorage.save(self) {
    contract.setData(self.toCell());
}

struct BagItemDataNotInitialized {
    bagIndex: uint64
    registryAddress: address
}

struct BagItemDataInitialized {
    bagIndex: uint64
    registryAddress: address
    bagId: uint256
    name: cell
    category: uint8
    uploaderAddress: address
    timestamp: uint64
    isActive: bool
    metadata: Cell<BagMetadata>
}

type BagItemData = BagItemDataNotInitialized | BagItemDataInitialized

fun serializeBagItemData(data: BagItemData): cell {
    return data.toCell();
}

fun BagItemData.load(): BagItemData {
    return BagItemData.fromCell(contract.getData());
}

fun BagItemData.save(self) {
    contract.setData(serializeBagItemData(self));
}

fun calcDeployedBagItem(
    bagIndex: uint64,
    registryAddress: address,
    bagItemCode: cell,
): AutoDeployAddress {
    val preInitData: BagItemData = BagItemDataNotInitialized { bagIndex, registryAddress };
    return { stateInit: { code: bagItemCode, data: serializeBagItemData(preInitData) } };
}
