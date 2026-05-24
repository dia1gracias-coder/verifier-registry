struct BagMetadata {
    description: cell
    bagSize: uint64
    filesCount: uint32
    files: cell
    pieceSize: uint32
    merkleHash: uint256
    dirName: cell
}

struct (0x42495F49) BagItemInitParams {
    bagId: uint256
    category: uint8
    uploaderAddress: address
    timestamp: uint64
    name: cell
    metadata: Cell<BagMetadata>
}

struct (0x41444247) AddBag {
    bagId: uint256
    category: uint8
    name: cell
    metadata: Cell<BagMetadata>
}

type BagRegistryMessage = AddBag

struct (0x44454143) DeactivateBag {}

type BagItemMessage = DeactivateBag

struct BagDataReply {
    isInitialized: bool
    bagIndex: uint64
    registryAddress: address
    bagId: uint256
    name: cell
    category: uint8
    uploaderAddress: address
    timestamp: uint64
    isActive: bool
}

struct StaticDataReply {
    bagIndex: uint64
    registryAddress: address
}

struct StorageMetadataReply {
    isInitialized: bool
    description: cell
    bagSize: uint64
    filesCount: uint32
    files: cell
    pieceSize: uint32
    merkleHash: uint256
    dirName: cell
}
