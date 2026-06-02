tolk 1.3

import "storage"
import "signatures"

// ---- Owner / admin lifecycle --------------------------------------------
struct (0x01000010) AddAdminPubkey   { queryId: uint64; pubkey: uint256 }
struct (0x01000011) RemoveAdminPubkey { queryId: uint64; pubkey: uint256 }
struct (0x01000020) ChangeOwner      { queryId: uint64; newOwner: address }
struct (0x01000021) ClaimOwner       { queryId: uint64 }
struct (0x01000022) DropOwner        { queryId: uint64 }
struct (0x01000040) SetMessagePrefix { queryId: uint64; newPrefix: string }

struct (0x01000050) RegisterAcceptedJetton {
    queryId: uint64
    jettonMasterHash: uint256
    ourJettonWalletAddress: address
}

struct (0x01000030) WithdrawFunds {
    queryId: uint64
    amount: coins
    recipient: address
    jettonMasterHash: uint256?               // null = native withdraw
}

struct (0x01000060) ProposeUpgrade { queryId: uint64; newCode: cell }
struct (0x01000061) ExecuteUpgrade { queryId: uint64 }
struct (0x01000062) CancelUpgrade  { queryId: uint64 }

// ---- Game ops (player-relayed, admin-signed) ----------------------------
struct (0x01000001) CreateNativeGame {
    queryId: uint64
    inputs: Cell<CreateGameInputs>
    signature: bits512
    signerPubkey: uint256
}

struct (0x01000002) CreateZeroBetGame {
    queryId: uint64
    inputs: Cell<CreateGameInputs>
    signature: bits512
    signerPubkey: uint256
}

struct (0x01000003) CreateJettonGameRequest {
    queryId: uint64
    inputs: Cell<CreateGameInputs>
    signature: bits512
    signerPubkey: uint256
}

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

// ---- TEP-74 jetton interop ----------------------------------------------
// Inbound notification from our jetton wallet. Forward payload (a ref) carries
// CreateJettonGameRequest. Use RemainingBitsAndRefs and parse explicitly.
struct (0x7362d09c) JettonNotify {
    queryId: uint64
    amount: coins
    fromAddress: address
    forwardPayload: RemainingBitsAndRefs
}

// Outbound TEP-74 transfer (we pay a player from our jetton wallet, or refund).
struct (0x0f8a7ea5) JettonTransferOut {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs     // empty (single 0 bit) = no notify
}

type Incoming =
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
    | CashOut
    | MarkLost
    | JettonNotify
