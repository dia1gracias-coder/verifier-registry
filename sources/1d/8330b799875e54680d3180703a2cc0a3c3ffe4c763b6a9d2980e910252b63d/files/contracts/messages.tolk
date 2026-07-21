struct (0x4C4F4F01) OpenOffer {
    queryId: uint64
    offerId: uint64
    commitment: uint256
    chanceBps: uint16
    totalPool: coins
    expiresAt: uint32
    counterOfferId: uint64
}

struct (0x4C4F4F02) CancelOffer {
    queryId: uint64
    offerId: uint64
}

struct (0x4C4F4F03) MatchOffers {
    queryId: uint64
    firstOfferId: uint64
    secondOfferId: uint64
}

struct (0x4C4F4F04) Reveal {
    queryId: uint64
    duelId: uint64
    offerId: uint64
    secret: uint256
}

struct (0x4C4F4F05) ExpireOffer {
    queryId: uint64
    offerId: uint64
}

struct (0x4C4F4F06) ExpireDuel {
    queryId: uint64
    duelId: uint64
}

struct (0x4C4F4F07) SetPaused {
    queryId: uint64
    paused: bool
}

/// Attached to every terminal winner transfer so indexers can project the result.
struct (0x4C4F4F11) DuelPayout {
    queryId: uint64
    duelId: uint64
    offerId: uint64
    reason: uint8
}

/// Attached to unmatched or no-reveal refunds.
struct (0x4C4F4F12) OfferRefund {
    queryId: uint64
    offerId: uint64
    reason: uint8
}

/// Attached to the protocol fee transfer.
struct (0x4C4F4F13) ProtocolFee {
    queryId: uint64
    duelId: uint64
}
