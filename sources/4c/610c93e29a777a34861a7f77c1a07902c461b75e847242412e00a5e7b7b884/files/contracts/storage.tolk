tolk 1.3

import "errors"

// Persistent storage of the single Cash-or-Crash contract.
// Ref budget: messagePrefix(1) + dicts(1) + pendingUpgrade(0..1) = 2..3 refs. Safe.
struct ContractStorage {
    owner: address?                              // null = immutable (dropped)
    nextOwner: address?                          // staged two-step transfer
    messagePrefix: string                        // domain separator (ref)
    dicts: Cell<ContractDicts>                   // bundled maps (ref)
    pendingUpgrade: Cell<PendingUpgrade>?        // null when no upgrade pending
}

// Three maps bundled into one cell (3 dict roots <= 4 refs).
struct ContractDicts {
    adminPubkeys: map<uint256, bool>             // registered Ed25519 admin pubkeys
    acceptedJettonWallets: map<uint256, address> // jettonMasterHash -> our jetton wallet
    games: map<uint256, Cell<Game>>              // preliminaryGameIdHash -> active game
}

struct PendingUpgrade {
    newCode: cell
    executeAfter: uint32
}

// Status is for EVENTS only (resolved games are pruned from the map).
enum GameStatus: uint8 {
    Active = 0,
    Won = 1,
    Lost = 2,
}

// A game record. Present in the `games` map IFF the game is Active; deleted on resolve.
// betAmount is the resolve-auth discriminator: >0 = funded (player resolves),
// 0 = sponsored (backend relayer resolves, settled off-chain).
struct Game {
    player: address                  // payout destination (bound at create)
    betAmount: coins
    createdAt: uint32
    isNative: bool                   // true = native bet; false = jetton bet
    creditKind: uint8                // 0=none,1=IP,2=Superstake,3=TelegramStars
    jettonMasterHash: uint256?       // set IFF jetton bet
    gameSeedHash: uint256            // fairness commitment = hash(seed|config|algo)
}

fun ContractStorage.load(): ContractStorage {
    return ContractStorage.fromCell(contract.getData())
}

fun ContractStorage.save(self) {
    contract.setData(self.toCell())
}

fun ContractStorage.loadDicts(self): ContractDicts {
    return self.dicts.load()
}

fun ContractStorage.saveDicts(mutate self, dicts: ContractDicts) {
    self.dicts = dicts.toCell();
}

// Throws ERR_OWNER_DROPPED if immutable, else ERR_NOT_OWNER if sender mismatches.
fun assertSenderIsOwner(senderAddress: address, owner: address?) {
    assert (owner != null) throw ERR_OWNER_DROPPED;
    assert (senderAddress == owner) throw ERR_NOT_OWNER;
}
