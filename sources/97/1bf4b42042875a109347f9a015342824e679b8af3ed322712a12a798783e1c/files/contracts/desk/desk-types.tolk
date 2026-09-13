import "../common/tep-nft"

// ---------------------------------------------------------------------------
// DeskCollection storage
// ---------------------------------------------------------------------------

struct CollectionContent {
    collectionMetadata: cell
    commonContent: string
}

struct CollectionStorage {
    admin: address
    minter: address
    pot: address
    nextSerial: uint32
    cap: uint32
    content: Cell<CollectionContent>
    deskItemCode: cell
    royalty: Cell<RoyaltyParams>
}

fun CollectionStorage.load(): CollectionStorage {
    return CollectionStorage.fromCell(contract.getData());
}

fun CollectionStorage.save(self) {
    contract.setData(self.toCell());
}

// ---------------------------------------------------------------------------
// DeskItem storage — shape changes after deployment (see NftItem template pattern)
// ---------------------------------------------------------------------------

struct DeskItemStorageNotInitialized {
    serial: uint32
    collection: address
}

struct DeskItemStorage {
    serial: uint32
    collection: address
    owner: address
    pot: address
    stampsReady: bool
    /// slot -> last counter value already credited to this desk (COUNTER_SCALE fixed point)
    stamps: map<uint8, uint128>
    /// slot -> stamp sent with an in-flight SweepRequest / WithdrawViaPot
    pending: map<uint8, uint128>
}

struct DeskItemStorageLoader {
    serial: uint32
    collection: address
    private rest: RemainingBitsAndRefs
}

fun DeskItemStorage.startLoading(): DeskItemStorageLoader {
    return DeskItemStorageLoader.fromCell(contract.getData());
}

fun DeskItemStorageLoader.isNotInitialized(self): bool {
    return self.rest.isEmpty();
}

fun DeskItemStorageLoader.endLoading(mutate self): DeskItemStorage {
    return {
        serial: self.serial,
        collection: self.collection,
        owner: self.rest.loadAny(),
        pot: self.rest.loadAny(),
        stampsReady: self.rest.loadAny(),
        stamps: self.rest.loadAny(),
        pending: self.rest.loadAny(),
    };
}

fun DeskItemStorage.save(self) {
    contract.setData(self.toCell());
}

/// Deterministic desk address: hash(deskItemCode, {serial, collection}).
fun calcDeployedDesk(serial: uint32, collection: address, deskItemCode: cell): AutoDeployAddress {
    val empty: DeskItemStorageNotInitialized = { serial, collection };
    return { stateInit: { code: deskItemCode, data: empty.toCell() } };
}

struct DeskDataReply {
    serial: int
    owner: address
    pot: address
    stampsReady: bool
    stamps: map<uint8, uint128>
    pending: map<uint8, uint128>
}
