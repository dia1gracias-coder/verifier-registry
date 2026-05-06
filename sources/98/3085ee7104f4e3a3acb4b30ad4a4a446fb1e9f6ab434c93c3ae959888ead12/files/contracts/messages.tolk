tolk 1.3

import "storage"
import "signatures"

// =========================================================================
//   Owner / admin lifecycle (Phase 1)
// =========================================================================

struct (0x01000010) AddAdminPubkey {
    queryId: uint64
    pubkey: uint256
}

struct (0x01000011) RemoveAdminPubkey {
    queryId: uint64
    pubkey: uint256
}

struct (0x01000020) ChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x01000021) ClaimOwner {
    queryId: uint64
}

struct (0x01000022) DropOwner {
    queryId: uint64
}

struct (0x01000040) SetMessagePrefix {
    queryId: uint64
    newPrefix: string
}

// Owner registers (or re-registers) the address of master's own jetton wallet
// for a given jetton master. Required before JettonNotification flow works.
struct (0x01000050) RegisterAcceptedJetton {
    queryId: uint64
    jettonMasterHash: uint256                  // hash of the jetton master contract address
    masterJettonWalletAddress: address         // master's wallet for this jetton
}

// Owner withdraws native TON or jetton from master treasury.
// jettonMasterHash = null -> native withdraw. Otherwise -> jetton withdraw via
// the registered master JW for that jetton.
struct (0x01000030) WithdrawFunds {
    queryId: uint64
    amount: coins
    recipient: address
    jettonMasterHash: uint256?
}

// Owner stages a code upgrade. The contract enforces a fixed 48h delay before
// ExecuteUpgrade is accepted, regardless of an earlier `executeAfter` hint.
struct (0x01000060) ProposeUpgrade {
    queryId: uint64
    newMasterCode: cell
    newGameWalletCode: cell?                   // null = leave game code unchanged
}

struct (0x01000061) ExecuteUpgrade {
    queryId: uint64
}

struct (0x01000062) CancelUpgrade {
    queryId: uint64
}

// =========================================================================
//   Game lifecycle (Phase 3) — admin-signed messages to master
// =========================================================================

// Admin submits this to the master to create a new native-bet game. The
// attached value MUST be >= betAmount + GAS_FOR_NATIVE_CREATE.
struct (0x01000001) CreateNativeGame {
    queryId: uint64
    inputs: Cell<CreateGameInputs>
    signature: bits512                         // Ed25519 sig over inputs.hash()
    signerPubkey: uint256
}

// Admin submits this for sponsored / zero-bet games (Intraverse Points or
// Superstake credits). No funds are collected; payouts/losses are recorded
// for provable fairness only and resolved off-chain by the backend.
struct (0x01000002) CreateZeroBetGame {
    queryId: uint64
    inputs: Cell<CreateGameInputs>
    signature: bits512
    signerPubkey: uint256
}

// Wrapped inside a Jetton transfer's forwardPayload. Carries the same
// admin-signed CreateGameInputs as CreateNativeGame; the bet amount is
// implicit (it equals the JettonNotification.amount).
struct (0x01000003) CreateJettonGameRequest {
    queryId: uint64
    inputs: Cell<CreateGameInputs>
    signature: bits512
    signerPubkey: uint256
}

// Standard TEP-74 transfer notification. Master's own jetton wallet sends
// this when a player transfers jettons to it. We mandate forwardPayload to
// be a single ref containing CreateJettonGameRequest (either-bit = true).
struct (0x7362d09c) JettonNotification {
    queryId: uint64
    amount: coins
    fromAddress: address
    forwardPayloadInRef: bool                  // require true (Right Cell)
    forwardPayload: Cell<CreateJettonGameRequest>
}

// Standard TEP-74 jetton transfer body. Used outbound when master pays a
// player from its jetton wallet. forwardPayloadInRef = false + no payload
// bits encodes "no notification on the receiver side".
struct (0x0f8a7ea5) JettonTransferOut {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayloadInRef: bool                  // = false; no payload
}

// Admin submits this to the master. Master verifies sig + forwards to the
// game contract.
struct (0x02000010) CashOut {
    queryId: uint64
    inputs: Cell<CashOutInputs>
    signature: bits512
    signerPubkey: uint256
}

struct (0x02000011) MarkLost {
    queryId: uint64
    inputs: Cell<MarkLostInputs>
    signature: bits512
    signerPubkey: uint256
}

// =========================================================================
//   Master -> Game initialisation
// =========================================================================

// Master sends this with the deploy stateInit. The game uses it to populate
// the rest of its storage (player + bet config + identity).
struct (0x02000001) InitGame {
    queryId: uint64
    player: address
    betConfig: Cell<BetConfig>
    identity: Cell<GameIdentity>
}

// =========================================================================
//   Master <-> Game internal messages
// =========================================================================

// Master forwards CashOut to the game (no sig — sender == master is enough).
struct (0x02000012) CashOutForward {
    queryId: uint64
    payoutAmount: coins
    gameSeed: string
    gameState: string
}

// Master forwards MarkLost to the game.
struct (0x02000013) MarkLostForward {
    queryId: uint64
    gameSeed: string
    gameState: string
}

// Game contract sweeps its native bet to master treasury at MarkLost.
struct (0x03000010) LostGameSweep {
    queryId: uint64
    preliminaryGameIdHash: uint256             // for master to verify game's identity
}

// Game contract requests master to pay out the player. Game attaches its
// remaining balance (bet + leftover gas) so master nets the difference.
struct (0x03000001) RequestNativePayout {
    queryId: uint64
    preliminaryGameIdHash: uint256             // identity proof
    player: address
    payoutAmount: coins
}

// Game contract requests master to pay out the player in a jetton.
// (For jetton bets the bet itself stays in master's jetton wallet — game
// only holds the IOU + a tiny native gas reserve.)
struct (0x03000002) RequestJettonPayout {
    queryId: uint64
    preliminaryGameIdHash: uint256
    player: address
    jettonMasterHash: uint256
    payoutAmount: coins
}

// =========================================================================
//   Dispatch unions
// =========================================================================

type MasterIncoming =
    | AddAdminPubkey
    | RemoveAdminPubkey
    | ChangeOwner
    | ClaimOwner
    | DropOwner
    | SetMessagePrefix
    | RegisterAcceptedJetton
    | WithdrawFunds
    | ProposeUpgrade
    | ExecuteUpgrade
    | CancelUpgrade
    | CreateNativeGame
    | CreateZeroBetGame
    | JettonNotification
    | CashOut
    | MarkLost
    | LostGameSweep
    | RequestNativePayout
    | RequestJettonPayout

type GameIncoming =
    | InitGame
    | CashOutForward
    | MarkLostForward
