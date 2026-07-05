// OpenRaff v1 — incoming message bodies (opcodes). See messages.md §2.
//
// Note on the organizer publisher key: on-chain the organizer is identified by
// a TON address (receives funds, may cancel), but a *publisher* is an ed25519
// key. These are distinct, so `CreateRaffle` carries the organizer's ed25519
// pubkey explicitly and the factory force-adds it to the allowlist (the
// always-available fallback publisher of specification §7.3).

import "common"

// ------------------------------- Factory -----------------------------------

struct (0xF0000001) CreateRaffle {
    queryId: uint64
    organizerPubkey: uint256        // ed25519; force-added to publishers
    config: Cell<RaffleConfig>
    publishers: map<uint256, uint8> // extra auto-publisher keys (may be empty)
}

// Admin stopgap until DAO governance. Affects future raffles only.
struct (0xF0000002) SetParams {
    queryId: uint64
    protocolFeeBps: uint16
    drawTimeout: uint32
    treasury: address
}

// -------------------------------- Raffle -----------------------------------

struct (0xA0000001) BuyTicket {
    queryId: uint64
    count: uint32
}

struct (0xA0000002) CloseSales {
    queryId: uint64
}

struct (0xA0000003) SubmitRandomness {
    queryId: uint64
    round: uint64
    randomness: uint256
    signature: cell          // DRAND BLS signature (stored, not verified in v1)
    publisherPubkey: uint256 // ed25519
    edSignature: cell        // ed25519 signature (512 bits) over the auth preimage
}

struct (0xA0000007) DrawStep {
    queryId: uint64
}

struct (0xA0000004) Settle {
    queryId: uint64
}

struct (0xA0000005) Cancel {
    queryId: uint64
}

struct (0xA0000006) ClaimRefund {
    queryId: uint64
}

// Permissionless trigger for the one-off TEP-89 wallet discovery of a jetton
// raffle (the UI calls it once after creation). No-op / rejected in native mode.
struct (0xA0000008) SetupJettonWallet {
    queryId: uint64
}

// --------------------------- Jetton standard -------------------------------
// TEP-74 (jettons) + TEP-89 (wallet discovery). `forward_payload` and the
// optional trailing `owner_address` are consumed as an opaque remainder.

// Incoming: our jetton wallet notifies us that `amount` jettons arrived from
// `sender` (the buyer). This is the jetton-path equivalent of BuyTicket.
struct (0x7362D09C) JettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

// Outgoing: instruct our jetton wallet to send `amount` jettons to `destination`
// (payout / refund / excess). `responseDestination` receives the TON excesses.
struct (0x0F8A7EA5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

// Outgoing: ask the jetton master for our wallet address (TEP-89).
struct (0x2C76B973) ProvideWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeAddress: bool
}

// Incoming: the jetton master's reply carrying our wallet address (TEP-89).
struct (0xD1735400) TakeWalletAddress {
    queryId: uint64
    walletAddress: address
    rest: RemainingBitsAndRefs
}

// ------------------------- Events (external-out) ---------------------------
// Emitted as external-out log messages (dest = addr_none) at each significant
// transition, so an indexer / UI can reconstruct state without reading storage.
// They carry no value and cannot change state. Opcodes in the 0xE0.. range.

// Factory event: a new raffle instance was deployed.
struct (0xE0000001) EvRaffleCreated {
    raffleId: uint64
    instance: address
    organizer: address
    paymentJetton: address?
}

// Raffle events.
struct (0xE0000010) EvTicketPurchased {
    buyer: address
    count: uint32
    ticketsSold: uint32
    totalCollected: coins
}

struct (0xE0000011) EvSalesClosed {
    salesClosedAt: uint32
    targetRound: uint64
    ticketsSold: uint32
    totalCollected: coins
}

struct (0xE0000012) EvRandomnessPublished {
    round: uint64
    randomness: uint256
}

struct (0xE0000013) EvWinnerResolved {
    rank: uint32
    ticketIndex: uint32
    owner: address
}

// Emitted at the end of every draw batch; the draw is complete when
// winnersDrawn == target.
struct (0xE0000014) EvDrawProgress {
    winnersDrawn: uint32
    target: uint32
}

struct (0xE0000015) EvSettled {
    fee: coins
    payout: coins
}

struct (0xE0000016) EvCancelled {
    queryId: uint64
}

struct (0xE0000017) EvRefunded {
    buyer: address
    amount: coins
}

// Jetton wallet discovery completed (TEP-89).
struct (0xE0000018) EvWalletDiscovered {
    jettonWallet: address
}

// A bounceable payout/refund bounced back and was recovered (settle downgraded
// to retry, or the participant's refund flag was cleared). See
// Raffle.onBouncedMessage.
struct (0xE0000019) EvPayoutBounced {
    recipient: address
}
