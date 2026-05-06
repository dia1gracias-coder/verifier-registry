tolk 1.3

import "@stdlib/strings"
import "errors"
import "storage"

// Domain-separated signed payload formats. Each struct is wrapped into a
// Cell<T> on the wire, and the backend signs `cellRef.hash()` with Ed25519.

// Header for all CreateGame variants — fits the small inline budget.
struct CreateGameInputs {
    domainHash: uint256                       // hash(messagePrefix || ":createGame")
    preliminaryGameIdHash: uint256
    gameSeedHash: uint256
    deadline: uint32
    body: Cell<CreateGameBody>                // longer, ref'd
}

struct CreateGameBody {
    player: address
    betAmount: coins
    isCredit: bool
    creditKind: uint8
    jettonMasterHash: uint256?
    algoVersion: string                       // ref
    gameConfig: string                        // ref
}

struct CashOutInputs {
    domainHash: uint256                       // hash(messagePrefix || ":cashOut")
    gameContractAddr: address
    payoutAmount: coins
    deadline: uint32
    gameSeed: string                          // ref
    gameState: string                         // ref
}

struct MarkLostInputs {
    domainHash: uint256                       // hash(messagePrefix || ":markLost")
    gameContractAddr: address
    deadline: uint32
    gameSeed: string                          // ref
    gameState: string                         // ref
}

// Verifies that `signature` is a valid Ed25519 signature of `signedHash` by
// `signerPubkey`, AND that signerPubkey is a registered admin pubkey.
fun verifyAdminSignature(
    signedHash: uint256,
    signature: bits512,
    signerPubkey: uint256,
    dicts: MasterDicts,
) {
    assert (dicts.adminPubkeys.exists(signerPubkey)) throw ERR_NOT_ADMIN_PUBKEY;
    assert (isSignatureValid(signedHash, signature as slice, signerPubkey)) throw ERR_INVALID_SIGNATURE;
}

// Builds the domain hash from a messagePrefix and an action suffix. Backend
// computes the same hash off-chain. XOR of two FNV hashes is the cheapest
// composition that domain-separates each (prefix, action) pair.
fun buildDomainHash(messagePrefix: string, action: string): uint256 {
    return messagePrefix.hash() ^ action.hash();
}

// Provable-fairness commitment: at create time the backend commits to
//     gameSeedHash = hash( cell(seed) | cell(config) | cell(algo) )
// where the outer cell embeds each string as a ref. At reveal we recompute
// and compare; mismatch indicates the backend cheated.
fun computeSeedCommitmentHash(seed: string, config: string, algo: string): uint256 {
    // Hash each string via its cell representation (SHA-256), then combine
    // into a fresh cell and hash again. Both steps are standard TON math
    // that the backend can replicate via @ton/core.
    return beginCell()
        .storeUint((seed as unknown as cell).hash(), 256)
        .storeUint((config as unknown as cell).hash(), 256)
        .storeUint((algo as unknown as cell).hash(), 256)
        .endCell()
        .hash();
}
