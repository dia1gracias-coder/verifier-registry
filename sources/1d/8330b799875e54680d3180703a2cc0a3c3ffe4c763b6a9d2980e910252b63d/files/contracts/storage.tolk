import "errors"

const OFFER_OPEN = 1
const OFFER_MATCHED = 2

const REVEALED_A = 1
const REVEALED_B = 2

type OfferMap = map<uint64, Cell<OfferData>>

type DuelMap = map<uint64, Cell<DuelData>>

type ActiveOfferMap = map<address, uint64>

type UsedOfferMap = map<uint64, bool>

struct OfferData {
    owner: address
    commitment: uint256
    chanceBps: uint16
    totalPool: coins
    stake: coins
    expiresAt: uint32
    state: uint8
}

struct DuelData {
    offerAId: uint64
    offerBId: uint64
    revealDeadline: uint32
    secretA: uint256
    secretB: uint256
    revealedMask: uint8
}

struct Storage {
    owner: address
    treasury: address
    feeBps: uint16
    paused: bool
    locked: coins
    offers: OfferMap
    duels: DuelMap
    activeOffers: ActiveOfferMap
    usedOfferIds: UsedOfferMap
}

struct ContractConfigView {
    owner: address
    treasury: address
    feeBps: uint16
    paused: bool
    locked: coins
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self) {
    contract.setData(self.toCell());
}

fun Storage.loadOffer(self, offerId: uint64): OfferData {
    return self.offers.mustGet(offerId, Errors.OfferMissing).load();
}

fun Storage.loadDuel(self, duelId: uint64): DuelData {
    return self.duels.mustGet(duelId, Errors.DuelMissing).load();
}
