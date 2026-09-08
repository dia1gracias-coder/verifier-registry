import "types"

// ============================================================
//  TEP-62 / TEP-66 — NFT standard
// ============================================================

struct (0b0) PayloadInline {
    value: RemainingBitsAndRefs
}

struct (0b1) PayloadInRef {
    value: Cell<RemainingBitsAndRefs>
}

struct (0x5fcc3d14) AskToChangeOwnership {
    queryId: uint64
    newOwnerAddress: address
    sendExcessesTo: address?
    customPayload: cell?
    forwardTonAmount: coins
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}

struct (0x05138d91) NotificationForNewOwner {
    queryId: uint64
    oldOwnerAddress: address?
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64
}

struct (0x2fcb26a2) RequestStaticData {
    queryId: uint64
}

struct (0x8b771735) ResponseStaticData {
    queryId: uint64
    itemIndex: uint256
    collectionAddress: address
}

struct (0x693d3950) RequestRoyaltyParams {
    queryId: uint64
}

struct (0xa8cb00ad) ResponseRoyaltyParams {
    queryId: uint64
    royaltyParams: RoyaltyParams
}

// ============================================================
//  TEP-81 — DNS records
// ============================================================

/// Deleting a record is the same message with no value reference.
struct (0x4eb1f0f9) ChangeDnsRecord {
    queryId: uint64
    key: uint256
    value: cell?
}

// ============================================================
//  TEP-74 / TEP-89 — GRM jetton
// ============================================================

struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    sendExcessesTo: address?
    customPayload: cell?
    forwardTonAmount: coins
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) JettonBurn {
    queryId: uint64
    amount: coins
    sendExcessesTo: address?
    customPayload: cell?
}

struct (0x7362d09c) JettonTransferNotification {
    queryId: uint64
    amount: coins
    senderAddress: address
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}

// ============================================================
//  Grm DNS internal: collection <-> domain
// ============================================================

/// The collection relays the FIRST bid on a name, deploying the domain contract
/// on the way. Every later bid is paid straight into the domain's own GRM
/// wallet and never passes through the collection.
///
/// `grmWallet` is the domain's own jetton wallet address. The collection can
/// derive it because it knows the GRM master and the wallet code; the domain
/// cannot, so it is told once and remembers it.
struct (0x67726d01) RelayBid {
    queryId: uint64
    bidder: address
    amount: coins
    domain: cell
    grmWallet: address
}

/// The domain accepted the first bid and asks the collection to hand over the
/// GRM that came with it.
struct (0x67726d02) RequestFunds {
    queryId: uint64
    itemIndex: uint256
    amount: coins
    /// Кому вернуть остаток TON. Джеттон-кошелёк отдаёт сдачу с перевода
    /// `sendExcessesTo`, и она должна уйти тому, кто за всё платил, а не осесть
    /// на домене мёртвым грузом.
    bidder: address
}

/// The domain already exists, so this bid should have gone straight to it.
/// The collection gives the money back.
struct (0x67726d03) RejectBid {
    queryId: uint64
    itemIndex: uint256
    amount: coins
    bidder: address
}

/// Closes a finished auction. Anyone may send it.
struct (0x67726d04) FinalizeAuction {
    queryId: uint64
}

// ============================================================
//  Grm DNS administration
//
//  Note what is missing: there is no operation that withdraws GRM, and no
//  operation that configures the GRM wallet — its address is derived, not
//  stored. The winning bid is burned by the domain itself and outbid
//  participants are refunded by the domain itself, so the collection owner
//  never has a reason, or a way, to touch anyone's money.
// ============================================================

/// Rescues foreign jettons sent to the collection by mistake. Refuses to touch
/// the GRM wallet, whose balance backs the live bids.
struct (0x67726d12) RescueJettons {
    queryId: uint64
    amount: coins
    walletAddress: address
    to: address
}

struct (0x67726d13) WithdrawTon {
    queryId: uint64
}

/// Passing null renounces ownership permanently.
struct (0x67726d14) ChangeOwner {
    queryId: uint64
    newOwnerAddress: address?
}

struct (0x67726d15) ChangeContent {
    queryId: uint64
    newContent: cell
}

struct (0x67726d16) ChangeRoyalty {
    queryId: uint64
    newRoyalty: Cell<RoyaltyParams>
}
