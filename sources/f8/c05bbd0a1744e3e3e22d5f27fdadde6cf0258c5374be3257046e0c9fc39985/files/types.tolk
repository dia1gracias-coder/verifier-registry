enum Errors {
    InvalidAmount = 100
    NotEnoughTon = 101
    InvalidMessage = 102
}

struct Storage {
    version: uint8
}

/// Custom command accepted by the router.
///
/// Opcode 0x54544f4e is ASCII "TTON".
struct (0x54544f4e) TransferTon {
    amount: coins
    recipient: address
}
