tolk 1.3

import "@stdlib/strings"
import "errors"
import "storage"

// Signed CreateGame payload. Backend signs cellRef.hash() with Ed25519.
struct CreateGameInputs {
    domainHash: uint256                       // hash(messagePrefix XOR ":createGame")
    preliminaryGameIdHash: uint256
    gameSeedHash: uint256
    deadline: uint32
    body: Cell<CreateGameBody>
}

struct CreateGameBody {
    player: address
    betAmount: coins                          // 0 = sponsored (admin-resolved); >0 = funded (player-resolved)
    creditKind: uint8                         // 0=none,1=IP,2=Superstake,3=TelegramStars
    jettonMasterHash: uint256?
    algoVersion: string                       // ref
    gameConfig: string                        // ref
}

// Reveal strings bundled into one sub-cell (exactly 4 string refs).
struct ResolveReveal {
    gameSeed: string
    gameConfig: string
    algoVersion: string
    gameState: string
}

struct CashOutInputs {
    domainHash: uint256                       // hash(messagePrefix XOR ":cashOut")
    preliminaryGameIdHash: uint256
    payoutAmount: coins
    deadline: uint32
    reveal: Cell<ResolveReveal>
}

struct MarkLostInputs {
    domainHash: uint256                       // hash(messagePrefix XOR ":markLost")
    preliminaryGameIdHash: uint256
    deadline: uint32
    reveal: Cell<ResolveReveal>
}

// Verifies Ed25519 signature AND that signerPubkey is a registered admin.
fun verifyAdminSignature(
    signedHash: uint256,
    signature: bits512,
    signerPubkey: uint256,
    dicts: ContractDicts,
) {
    assert (dicts.adminPubkeys.exists(signerPubkey)) throw ERR_NOT_ADMIN_PUBKEY;
    assert (isSignatureValid(signedHash, signature as slice, signerPubkey)) throw ERR_INVALID_SIGNATURE;
}

// Max flat-string size whose on-chain hash matches the TS wrapper. MUST equal
// MAX_SIGNED_STRING_BYTES (120) in wrappers/CashOrCrash.ts: both string.hash()
// (FNV) and (s as cell).hash() (SHA256) only cover a single flat cell, so a string
// that spills into snake refs would silently diverge from the backend's value.
const MAX_FLAT_STRING_BITS: int = 120 * 8;

// Throws ERR_PREFIX_TOO_LONG if `s` would not fit flat in a single cell.
fun assertFlatString(s: string) {
    val sl = (s as unknown as cell).beginParse();
    assert (sl.remainingRefsCount() == 0 && sl.remainingBitsCount() <= MAX_FLAT_STRING_BITS) throw ERR_PREFIX_TOO_LONG;
}

// Domain separation: XOR of the two content hashes (matches existing backend).
fun buildDomainHash(messagePrefix: string, action: string): uint256 {
    return messagePrefix.hash() ^ action.hash();
}

// Fairness commitment: hash( hash(seed) | hash(config) | hash(algo) ).
// Identical to wrappers/CashOrCrash.ts computeSeedCommitmentHash.
fun computeSeedCommitmentHash(seed: string, config: string, algo: string): uint256 {
    return beginCell()
        .storeUint((seed as unknown as cell).hash(), 256)
        .storeUint((config as unknown as cell).hash(), 256)
        .storeUint((algo as unknown as cell).hash(), 256)
        .endCell()
        .hash();
}
