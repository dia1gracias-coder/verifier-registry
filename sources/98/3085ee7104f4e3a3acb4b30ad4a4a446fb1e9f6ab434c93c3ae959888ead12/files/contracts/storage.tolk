tolk 1.3

import "errors"

// Persistent storage of the master contract.
//
// Cells max out at 4 refs and 1023 bits. To stay under the ref limit, the two
// dicts are packed into a single sub-cell (`Cell<MasterDicts>`). Inline refs:
// gameWalletCode (1) + messagePrefix (1) + dicts (1) + optional pendingUpgrade
// (0..1) = 3..4. Safe.
struct MasterStorage {
    owner: address?                              // null = immutable (admin dropped)
    nextOwner: address?                          // staged in two-step transfer
    gameCounter: uint64                          // informational; not part of game-id derivation
    gameWalletCode: cell                         // code for child game contracts (ref)
    messagePrefix: string                        // snake-encoded domain separator (ref)
    dicts: Cell<MasterDicts>                     // bundled dicts (ref)
    pendingUpgrade: Cell<PendingUpgrade>?        // null when no upgrade pending
}

// Bundled dictionary fields. Lives in its own cell so MasterStorage fits.
struct MasterDicts {
    adminPubkeys: map<uint256, bool>             // set of Ed25519 admin pubkey hashes
    acceptedJettonWallets: map<uint256, address> // jettonMaster.hash() -> master's jetton wallet
}

struct PendingUpgrade {
    newMasterCode: cell
    newGameWalletCode: cell?
    executeAfter: uint32
}

fun MasterStorage.load(): MasterStorage {
    return MasterStorage.fromCell(contract.getData())
}

fun MasterStorage.save(self) {
    contract.setData(self.toCell())
}

fun MasterStorage.loadDicts(self): MasterDicts {
    return self.dicts.load()
}

fun MasterStorage.saveDicts(mutate self, dicts: MasterDicts) {
    self.dicts = dicts.toCell();
}

// Helper: throws ERR_OWNER_DROPPED if the contract is immutable, else
// ERR_NOT_OWNER if the sender doesn't match.
fun assertSenderIsOwner(senderAddress: address, owner: address?) {
    assert (owner != null) throw ERR_OWNER_DROPPED;
    assert (senderAddress == owner) throw ERR_NOT_OWNER;
}

// =========================================================================
//   Game contract storage
// =========================================================================

enum GameStatus: uint8 {
    Active = 0,
    Won = 1,
    Lost = 2,
}

// Initial state-init data for a game contract — what the master commits to
// when it computes the deterministic child address. Kept minimal so the master
// can recompute it later (e.g. for LostGameSweep sender verification) from
// only the preliminaryGameIdHash and its own address.
struct GameInitialData {
    initFlag: bool                  // false at deploy; flipped to true on first InitGame
    masterAddress: address
    preliminaryGameIdHash: uint256
}

// Per-game contract storage AFTER InitGame has been processed. Shares the
// same `initFlag, masterAddress, preliminaryGameIdHash` prefix as
// GameInitialData so a peek at the first bit tells us which shape we're in.
//
// Hot-path fields live inline; bet config + identity strings + reveal-time
// strings are bundled into sub-cells to stay under the 1023-bit / 4-ref limits.
struct GameStorage {
    initFlag: bool                  // always true post-InitGame
    masterAddress: address          // hot — auth check on every callback from master
    preliminaryGameIdHash: uint256  // identity (echoed back to master in callbacks)
    status: GameStatus              // hot
    payoutAmount: coins             // hot — set at CashOut, restored on bounce
    player: address                 // hot — destination of payouts
    betConfig: Cell<BetConfig>      // bet metadata
    identity: Cell<GameIdentity>    // immutable IDs + the long config strings
    metadata: Cell<GameMetadata>    // reveal-time strings (gameSeed, gameState)
}

fun GameInitialData.load(): GameInitialData {
    return GameInitialData.fromCell(contract.getData())
}

// Quick check: peek at the first bit (initFlag) without loading everything.
fun isGameInitialized(): bool {
    return contract.getData().beginParse().loadBool()
}

struct BetConfig {
    betAmount: coins
    createdAt: uint32
    isNative: bool
    isCredit: bool
    creditKind: uint8                        // 0=none, 1=IP, 2=Superstake
    jettonMasterHash: uint256?               // null if isNative or credit-with-native-payout
}

struct GameIdentity {
    preliminaryGameIdHash: uint256           // identity — game's address derives from this
    gameSeedHash: uint256                    // committed at create
    algoVersion: string                      // ref
    gameConfig: string                       // ref
}

struct GameMetadata {
    gameSeed: string?                        // null until reveal
    gameState: string?                       // null until reveal
}

fun GameStorage.load(): GameStorage {
    return GameStorage.fromCell(contract.getData())
}

fun GameStorage.save(self) {
    contract.setData(self.toCell())
}
