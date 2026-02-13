// START STORAGE FOR MASTER CONTRACT
struct AdminData {
    address: address
    role: uint8 // refer to constant.tolk for role constants
    isActive: bool
    createdAt: uint64
    updatedAt: uint64
}

struct OwnerData {
    address: address
    addedBy: address
    isActive: bool
    createdAt: uint64
    updatedAt: uint64
}

struct NftCollectionData {
    collectionId: uint64
    address: address
    isActive: bool
    launchDate: uint64
    deployedDate: uint64
    landTitleIds: map<uint64, bool>
    createdAt: uint64
    updatedAt: uint64
}

struct NftItemData {
    ownerAddress: address
    collectionAddress: address
    index: uint64
    content: cell
    createdAt: uint64
    updatedAt: uint64
}

fun NftItemData.load() {
    return NftItemData.fromCell(contract.getData());
}

fun NftItemData.save(self) {
    contract.setData(self.toCell());
}

struct PhaseRegistry {
    phaseId: uint64
    collectionId: uint64
    phaseNumber: uint64
    maxNfts: uint64
    startNftId: uint64
    endNftId: uint64
    landTitleIds: map<uint64, bool>
    registeredDate: uint64
    createdAt: uint64
    updatedAt: uint64
}

struct MasterContractStorage {
    version: uint32 // version of the contract
    // Global Phase counter
    nextCollectionId: uint64
    nextPhaseId: uint64
    nextLandTitleId: uint64
    // key is the id for the struct
    collections: map<uint64, NftCollectionData>
    phases: map<uint64, PhaseRegistry>
    // admin addresses (for access control)
    adminAddresses: map<address, AdminData>
    owners: map<address, OwnerData>
    // store singleton address with fixed key
    contractAddresses: map<uint64, address>
    //  system state
    isPaused: bool
    lastPausedBy: address
    lastPausedAt: uint64
    lastUnpausedBy: address
    lastUnpausedAt: uint64
    createdAt: uint64
    updatedAt: uint64
}

fun MasterContractStorage.load() {
    return MasterContractStorage.fromCell(contract.getData());
}

fun MasterContractStorage.save(self) {
    contract.setData(self.toCell());
}
// END STORAGE FOR MASTER CONTRACT
// START STORAGE FOR NFT COLLECTION CONTRACT
struct NftCollectionStorage {
    nextItemIndex: uint64
    totalNfts: uint64
    content: cell
    itemCode: cell
    ownerAddress: address
    authorizedAdmins: map<address, bool>
    extraData: Cell<NftCollectionExtraData>
}

struct NftCollectionExtraData {
    isPaused: bool
    lastPausedBy: address?
    lastPausedAt: uint64
    lastUnpausedBy: address?
    lastUnpausedAt: uint64
    createdAt: uint64
    updatedAt: uint64
}

fun NftCollectionStorage.load() {
    return NftCollectionStorage.fromCell(contract.getData());
}

fun NftCollectionStorage.save(self) {
    contract.setData(self.toCell());
}
// END STORAGE FOR NFT COLLECTION CONTRACT
// START STORAGE FOR NFT ITEM CONTRACT
struct NftItemStorage {
    ownerAddress: address
    collectionAddress: address
    index: uint64
    content: cell
    isPaused: bool // CHANGED from isFreeze
    createdAt: uint64
    updatedAt: uint64
}

fun NftItemStorage.load() {
    return NftItemStorage.fromCell(contract.getData());
}

fun NftItemStorage.save(self) {
    contract.setData(self.toCell());
}
