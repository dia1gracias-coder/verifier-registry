import "pot-types"

// ---------------------------------------------------------------------------
// Keeper operations
// ---------------------------------------------------------------------------

/// Swap `spend` TON for USDT through a whitelisted DeDust pool. The swap body is built by the Pot
/// itself (receiver = Pot, limit = `minUsdt`); the keeper only picks pool, amount and minimum,
/// and `minUsdt` must respect the admin price floor (`floorUsdtPerTon`).
struct (0x50540001) Convert {
    queryId: uint64
    pool: address
    spend: coins
    minUsdt: coins
}

/// Open an Omniston escrow position: transfer `spendUsdt` from the Pot's USDT wallet to the
/// whitelisted escrow minter with `escrowPayload` as forward payload. The Pot checks that the
/// payload names itself as position owner and carries a min-out >= `minOut`, itself >= the slot floor.
struct (0x50540002) Round {
    queryId: uint64
    slot: uint8
    spendUsdt: coins
    minOut: coins
    forwardTon: coins
    advance: bool
    escrowPayload: cell
}

/// Clear a pending operation after `pendingTimeout` seconds (funds were, or will be, returned).
struct (0x50540003) CancelPending {
    queryId: uint64
}

/// Advance the rotation without a round (slot not quotable).
struct (0x50540004) SkipSlot {
    queryId: uint64
}

// ---------------------------------------------------------------------------
// Admin operations
// ---------------------------------------------------------------------------

struct (0x50540010) AddSlot {
    queryId: uint64
    slot: uint8
    master: address
    potWallet: address
    floorPerUsdt: coins
}

/// Update the Round price floor of a slot (stock units per 1 USDT). 0 disables rounds on that slot.
struct (0x50540014) SetSlotFloor {
    queryId: uint64
    slot: uint8
    floorPerUsdt: coins
}

struct (0x50540011) SetSlotEnabled {
    queryId: uint64
    slot: uint8
    enabled: bool
}

struct (0x50540012) SetPotParams {
    queryId: uint64
    params: Cell<PotParams>
}

struct (0x50540013) SetPotRoles {
    queryId: uint64
    roles: Cell<PotRoles>
}

// ---------------------------------------------------------------------------
// Labelled TON deposits (Minter surcharge, FeeSplitter share). Plain transfers are royalties.
// ---------------------------------------------------------------------------

struct (0x50540020) PotTopUp {
    queryId: uint64
    source: uint8
}

// ---------------------------------------------------------------------------
// Events (external out messages, topic in destination)
// ---------------------------------------------------------------------------

const EVENT_TOPIC_POT_IN = 0x5054E001
const EVENT_TOPIC_ROUND_SETTLED = 0x5054E002
const EVENT_TOPIC_ROUND_REFUNDED = 0x5054E003
const EVENT_TOPIC_CONVERT_SETTLED = 0x5054E004
const EVENT_TOPIC_SLIPPAGE_BREACH = 0x5054E005
const EVENT_TOPIC_PENDING_CANCELLED = 0x5054E006
const EVENT_TOPIC_SLOT_SKIPPED = 0x5054E007
const EVENT_TOPIC_UNALLOCATED = 0x5054E008
const EVENT_TOPIC_DESK_SWEPT = 0x5054E009
const EVENT_TOPIC_DESK_WITHDRAWN = 0x5054E00A

struct PotInEvent {
    source: uint8
    amount: coins
    from: address
}

struct RoundSettledEvent {
    roundNo: uint32
    slot: uint8
    spendUsdt: coins
    received: coins
    liveDesks: uint32
    counter: uint128
}

struct RoundRefundedEvent {
    slot: uint8
    spendUsdt: coins
    refunded: coins
}

struct ConvertSettledEvent {
    spendTon: coins
    receivedUsdt: coins
    minUsdt: coins
}

struct SlippageBreachEvent {
    kind: uint8
    slot: uint8
    expectedMin: coins
    received: coins
}

struct PendingCancelledEvent {
    kind: uint8
    slot: uint8
    spend: coins
}

struct SlotSkippedEvent {
    slot: uint8
    next: uint8
}

/// Stock arrived for a slot while no desk is live: stays in the Pot wallet, unallocated.
struct UnallocatedEvent {
    slot: uint8
    amount: coins
}

/// A desk swept a slot: `owed` stock sent to the desk, its stamp moves to `newStamp` (owed may be 0).
struct DeskSweptEvent {
    serial: uint32
    slot: uint8
    owed: coins
    newStamp: uint128
}

/// A desk withdrew `amount` of a slot's stock to `to` (only possible when nothing is owed).
struct DeskWithdrawnEvent {
    serial: uint32
    slot: uint8
    amount: coins
    to: address
}
