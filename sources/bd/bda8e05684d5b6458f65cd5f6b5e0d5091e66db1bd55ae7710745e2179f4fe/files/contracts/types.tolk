// Shared types for the SwiftParcel contracts.
// ===================== Order =====================

enum OrderStatus: uint8 {
    Open = 0
    Accepted = 1
    Delivered = 2
    Completed = 3
    Cancelled = 4
}

enum OrderErrors {
    WrongStatus = 100
    NotSender = 101
    NotCourier = 102
    InvalidMessage = 0xFFFF
}

// One delivery order. Holds the escrow and the state machine.
// `description` and `area` are cells (text packed by the caller).
// `area` is public; the exact street address is NEVER stored on-chain.
//
// All fields here are supplied by the creator (the frontend), NOT by block
// time or a global counter. That is on purpose: a contract's address is the
// hash of its initial state, so keeping the init data fully client-controlled
// lets the frontend recompute the address of an order it just created.
// `nonce` is a client random value that makes the address unique.
struct OrderStorage {
    sender: address
    courier: address? // null until a courier accepts
    description: cell
    area: cell
    reward: coins
    status: OrderStatus
    nonce: uint64     // client random, for a unique address
    createdAt: uint32 // client unix time, for display only
}

fun OrderStorage.load(): OrderStorage {
    return OrderStorage.fromCell(contract.getData());
}

fun OrderStorage.save(self) {
    contract.setData(self.toCell());
}

struct (0xa00a0001) AcceptOrder {}

struct (0xa00a0002) MarkDelivered {}

struct (0xa00a0003) ConfirmDelivery {}

struct (0xa00a0004) CancelOrder {}

type OrderMessage =
    | AcceptOrder
    | MarkDelivered
    | ConfirmDelivery
    | CancelOrder

// =================== Marketplace ===================

enum MarketplaceErrors {
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

struct (0x1a2b3c4d) CreateOrder {
    reward: coins     // stated reward; sender must attach >= reward + gas
    nonce: uint64     // client random, for a unique order address
    createdAt: uint32 // client unix time, for display
    description: cell
    area: cell
}

type MarketplaceMessage = CreateOrder
