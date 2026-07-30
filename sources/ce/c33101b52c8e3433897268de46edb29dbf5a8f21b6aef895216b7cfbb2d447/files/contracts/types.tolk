// Shared types for the SwiftDelivery contracts.
// ===================== Order =====================

enum OrderStatus: uint8 {
    Open = 0
    Accepted = 1
    Completed = 2
    Cancelled = 3
    Expired = 4 // deadline passed; reward -> sender, courier gets nothing
}

enum OrderErrors {
    WrongStatus = 100
    NotSender = 101
    NotCourier = 102     // courier-release attempted by someone other than the courier
    FeeTooLow = 103      // courier attached less than the minimum accept fee
    NotExpired = 104     // claim attempted before the deadline
    DeadlinePassed = 105 // courier-release attempted after the deadline
    BadCode = 108        // confirm attempted with a secret whose hash does not match
    InvalidMessage = 0xFFFF
}

// Fields kept in a separate referenced cell (`Cell<OrderExtra>`, TL-B
// `^OrderExtra`) so the root OrderStorage cell stays well under the 1023-bit
// limit. The root already carries two full addresses (`sender` + `courier`,
// 267 bits each) plus a `coins` field and the counters. Keeping a THIRD inline
// address (`owner`) here once overflowed the root cell when a courier accepted:
// `courier` grows from a 2-bit null to a 267-bit address, pushing the total
// past 1023. On-chain that surfaced as AcceptOrder failing with exit_code 8
// (cell overflow) for real $10+ orders. Moving `owner` (plus the two contact
// cells) out keeps the root small, so no overflow policy is suppressed.
struct OrderExtra {
    owner: address       // marketplace owner; receives the platform fee on completion
    // Telegram contact of each party, packed as opaque text by the frontend
    // (see src/contact.js). Public on-chain, so it carries only the @username,
    // numeric id and first name — never a phone or the exact street address.
    senderContact: cell  // set by the sender at create time
    courierContact: cell // empty until a courier accepts, then their contact
    // Delivery-code commitment. The sender's app picks a 256-bit random secret at
    // create time and stores it locally; only this HASH of it goes on-chain. The
    // courier learns the secret from the sender at hand-off (shown as a QR code)
    // and sends it with ConfirmWithCode; the contract pays the reward only when
    // hash(secret) == secretHash. So a courier can be paid ONLY with the sender's
    // code — there is no "confirm" button the sender could sit on. It lives here
    // in the referenced extra cell (not the root) to keep the root under 1023 bits
    // (a 256-bit field in the root risks the same overflow `owner` once caused).
    // It is part of the init data, so it changes the order's address like
    // senderContact does — included in CreateOrder and the orderAddress getter.
    secretHash: uint256
    // Referral: the TON wallet address of the Telegram chat whose link opened
    // the app (null = no chat). Set once at create time from CreateOrder and
    // never changed. On every terminal path (ConfirmWithCode / CancelOrder /
    // ClaimExpired) the order pays this address HALF of the accumulated fee
    // pool; the owner gets the rest (see Order.tolk). Any address is accepted
    // as-is — self-referral only returns part of the fees the caller paid, so
    // it yields no profit. Fits here: owner(267) + secretHash(256) +
    // referral(267) = 790 bits < 1023, still 2 refs.
    referral: address?
}

// One delivery order. Holds the escrow and the state machine.
// `description`, `area` and `origin` are cells (text packed by the caller).
// Both are public; the exact street address is NEVER stored on-chain.
//   `area`   — the "to" city (destination).
//   `origin` — the "from" place (where the parcel starts). It is free text and
//              need NOT be a city: it can be a shop, a landmark, an airport zone
//              ("Duty Free", "H&M", "McDonald's"). The UI defaults this to
//              "All world" when the sender does not care about the origin.
//
// All fields here are supplied by the creator (the frontend), NOT by block
// time or a global counter. That is on purpose: a contract's address is the
// hash of its initial state, so keeping the init data fully client-controlled
// lets the frontend recompute the address of an order it just created.
// `nonce` is a client random value that makes the address unique.
struct OrderStorage {
    sender: address
    courier: address?  // null until a courier accepts
    description: cell
    area: cell         // "to" city (destination)
    origin: cell       // "from" place (source, any text); "All world" = any origin
    reward: coins
    status: OrderStatus
    nonce: uint64      // client random, for a unique address
    createdAt: uint32  // client unix time, for display only
    // acceptedAt is 0 in the initial state (so it does not change the order's
    // address) and is set by the contract itself when a courier accepts; it
    // starts the delivery clock that ClaimExpired checks against the deadline.
    acceptedAt: uint32 // contract block time at AcceptOrder; 0 until accepted
    // owner + both Telegram contacts, in a referenced cell (see OrderExtra).
    extra: Cell<OrderExtra>
}

fun OrderStorage.load(): OrderStorage {
    return OrderStorage.fromCell(contract.getData());
}

fun OrderStorage.save(self) {
    contract.setData(self.toCell());
}

struct (0xa00a0001) AcceptOrder {
    courierContact: cell // courier's Telegram contact, revealed once accepted
}

// Confirm a delivery by revealing the secret behind the order's secretHash. The
// courier scans the sender's QR at hand-off to obtain `secret` and sends it here;
// the contract pays the courier only if hash(secret) == secretHash (see Order.tolk).
struct (0xa00a0002) ConfirmWithCode {
    secret: uint256 // preimage; the contract checks hash(secret) == secretHash
}

struct (0xa00a0003) CancelOrder {}

struct (0xa00a0004) ClaimExpired {}

// Courier gives up an order they already accepted. Allowed ONLY before the
// deadline: once the delivery window has passed the courier has no actions left
// and the order can only be settled by the sender (claim or confirm). The order
// does NOT close: it goes back to Open so another courier can take it. The courier
// pays a 0.2 TON release fee on top of the 0.1 TON accept fee they already paid;
// neither is refunded — both stay on the contract for the platform. The reward and
// the sender's create fee also stay on the contract for the next courier.
struct (0xa00a0005) CourierRelease {}

type OrderMessage =
    | AcceptOrder
    | ConfirmWithCode
    | CancelOrder
    | ClaimExpired
    | CourierRelease

// ===================== Events =====================
// TON has no Ethereum-style logs; the equivalent is an EXTERNAL-OUT message:
// it goes nowhere, costs a tiny forward fee from the contract balance, and is
// recorded forever in the block. Indexers (toncenter v3 etc.) filter these by
// source address + opcode. Every state change emits one, so history survives
// the order's self-destruct: a watcher needs no transaction reverse-engineering.
//
// Event opcodes live in their own 0xa00a01xx range so they can never collide
// with the incoming-message opcodes (0xa00a00xx above). The source address of
// an Order event IS the order, so the events carry no orderAddress field —
// except OrderCreated, which the Marketplace emits (one address to watch) and
// which therefore names the new order explicitly.
//
// Events are logs, not money: they are always sent with IGNORE_ERRORS so a
// failed emit (e.g. a drained Marketplace balance) can never block an order.

// Emitted by Marketplace on CreateOrder, right after the Order deploy message.
// Gives a watcher everything to start tracking the order: its address (source
// of all later events), who created it, the escrowed reward and the "to" city
// (the Feed's filter key). Paid from the Marketplace's own balance (~0.0005 TON
// per order) — top it up now and then with a plain empty-body transfer.
struct (0xa00a0100) OrderCreated {
    orderAddress: address
    sender: address
    reward: coins
    area: cell
}

// Emitted by Order on AcceptOrder: a courier took the order; the delivery
// clock starts at this transaction's block time.
struct (0xa00a0101) OrderAccepted {
    courier: address
}

// Emitted by Order on ConfirmWithCode: the courier revealed the sender's
// delivery code and was paid the full reward. referralPayout is the exact
// amount sent to the referral chat (0 when no referral); the owner's payout is
// the rest of the fee pool minus network fees, so it is not repeated here.
struct (0xa00a0102) OrderCompleted {
    courier: address
    reward: coins
    referralPayout: coins
}

// Emitted by Order on CancelOrder: the sender cancelled an Open order and got
// the reward back in full. referralPayout as in OrderCompleted.
struct (0xa00a0103) OrderCancelled {
    reward: coins
    referralPayout: coins
}

// Emitted by Order on ClaimExpired: the courier missed the deadline, the
// reward returned to the sender. `courier` names who failed to deliver.
struct (0xa00a0104) OrderExpired {
    courier: address
    reward: coins
    referralPayout: coins
}

// Emitted by Order on CourierRelease: the courier gave the order up and it
// went back to Open for anyone else to take. `courier` names who walked away.
struct (0xa00a0105) OrderReopened {
    courier: address
}

// Emit one event as an external-out message. IGNORE_ERRORS is deliberate: an
// event is a log, and a log must never make the money-moving action fail —
// if the balance cannot cover the emit's forward fee, the emit is skipped and
// the order proceeds. In terminal handlers the emit must run BEFORE the final
// CARRY_ALL_BALANCE sweep, while the balance still covers its fee.
fun emitEvent<TEvent>(event: TEvent) {
    val msg = createExternalLogMessage({
        dest: createAddressNone(),
        body: event,
    });
    msg.send(SEND_MODE_REGULAR | SEND_MODE_IGNORE_ERRORS);
}

// =================== Marketplace ===================

enum MarketplaceErrors {
    InsufficientValue = 200 // attached coins do not cover reward + create buffer
    RewardTooLow = 202      // stated reward is below MIN_REWARD (anti-spam, M-5)
    InvalidMessage = 0xFFFF
}

// The single registry contract. It deploys Order contracts on demand.
// `orderCode` is the compiled Order code cell, set at deploy time, so the
// Marketplace can build new Order state-init on-chain.
struct MarketplaceStorage {
    owner: address
    orderCode: cell
    orderCount: uint32
}

fun MarketplaceStorage.load(): MarketplaceStorage {
    return MarketplaceStorage.fromCell(contract.getData());
}

fun MarketplaceStorage.save(self) {
    contract.setData(self.toCell());
}

struct (0xa00a0000) CreateOrder {
    reward: coins       // stated reward; sender must attach >= reward + gas
    nonce: uint64       // client random, for a unique order address
    createdAt: uint32   // client unix time, for display
    description: cell
    area: cell          // "to" city (destination)
    origin: cell        // "from" place (source, any text); "All world" = any origin
    senderContact: cell // sender's Telegram contact (opaque text)
    secretHash: uint256 // hash of the sender's delivery code (see OrderExtra.secretHash)
    referral: address?  // referral chat's wallet, or null (see OrderExtra.referral)
}

type MarketplaceMessage =
    | CreateOrder
