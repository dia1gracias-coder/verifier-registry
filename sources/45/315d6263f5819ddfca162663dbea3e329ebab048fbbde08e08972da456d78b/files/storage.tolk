// ─── Numeric constants ────────────────────────────────────────────────────────
const MONTHS_IN_LEASE = 12
const SECONDS_PER_MONTH = 180 // 3 min for tests — change to 2592000 (30 days) for production

const USDT_JETTON_MASTER = address("EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs")

struct MonthStorage {
    state: MonthState
    dueTs: uint32
}

struct RentStorage {
    globalState: GlobalState
    months: map<uint8, MonthStorage>
    currentMonth: uint8
    monthRent: coins
    depositAmount: coins
    startTs: uint32
    extra: Cell<ExtraFields>
    timestamps: Cell<TimeFields>
    balances: Cell<Balances>
}

struct Balances {
    deposit: coins
    rentPaid: coins
    rentReleased: coins
    rentBalance: coins
}

// factory and jettonWallet live here so they don't inflate RentStorage's inline bits.
// RentStorage inline bits stay at 917 (always < 1023), keeping refs at exactly 4.
// This cell peaks at factory(267) + wallet_set(268) = 535 bits — well under 1023.
struct ExtraFields {
    service: Cell<ServiceFields>
    clients: Cell<ClientsFields>
    administrative: Cell<AdministrativeFields>
}

struct AdministrativeFields {
    admin: address
    factory: address
    jettonWallet: address?
    // reserved for future use, e.g. for multisig or DAO-based upgrades
}

struct ServiceFields {
    tenantSign: uint32
    landlordSign: uint32
    agreementHash: uint256
}

struct ClientsFields {
    tenant: address
    landlord: address
}
struct TimeFields {
    disputeOpen: uint32
    disputeClosed: uint32
    checkInConfirmed: uint32
    checkOutConfirmed: uint32
    lastMonthDueTs: uint32
}

enum GlobalState {
    CREATED
    CHECK_IN
    ACTIVE
    DISPUTE
    CHECK_OUT
    COMPLETED
}

enum MonthState {
    PENDING
    PAID
    RELEASED
    DISPUTE
}


enum Purpose {
    DEPOSIT
    RENT
}

fun RentStorage.load() {
    return RentStorage.fromCell(contract.getData())
}

fun RentStorage.save(self) {
    contract.setData(self.toCell())
}