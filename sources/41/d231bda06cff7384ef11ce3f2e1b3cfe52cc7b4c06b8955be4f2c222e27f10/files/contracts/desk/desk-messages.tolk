// Protocol-specific messages for the desk system. Opcodes use the 0x4465xxxx ("De") prefix
// for the collection / item family and 0x5054xxxx ("PT") for the Pot family.

// ---------------------------------------------------------------------------
// Collection
// ---------------------------------------------------------------------------

/// Minter -> Collection. Deploys desk `serial` for `owner`. `serial <= nextSerial`;
/// only `serial == nextSerial` increments the counter and registers the desk in the Pot.
struct (0x44650001) DeployDesk {
    queryId: uint64
    serial: uint32
    owner: address
}

/// External log topic (Collection): a DeployDesk was accepted. Indexers learn the item address and owner from it.
const EVENT_TOPIC_DESK_DEPLOYED = 0x4443E001

struct DeskDeployedEvent {
    serial: uint32
    owner: address
    item: address
    isNew: bool
}

/// Collection -> Minter. Emitted when a DeployDesk was accepted (first or retried deploy).
struct (0x44650002) DeployDeskOk {
    queryId: uint64
    serial: uint32
}

struct (0x44650003) ChangeCollectionAdmin {
    queryId: uint64
    newAdmin: address
}

struct (0x44650004) SetCollectionMinter {
    queryId: uint64
    minter: address
}

/// Collection -> DeskItem, body of the deploying message.
struct DeskItemInit {
    owner: address
    pot: address
}

// ---------------------------------------------------------------------------
// DeskItem
// ---------------------------------------------------------------------------

/// Owner -> DeskItem. Bit i set => sweep slot i.
struct (0x44650010) Sweep {
    queryId: uint64
    slotsMask: uint64
}

/// DeskItem -> Pot.
struct (0x44650011) SweepRequest {
    queryId: uint64
    serial: uint32
    slot: uint8
    stamp: uint128
}

/// Pot -> DeskItem. `newStamp` = Pot counter for that slot at settlement time.
struct (0x44650012) SweepAck {
    queryId: uint64
    slot: uint8
    newStamp: uint128
}

/// Pot -> DeskItem, once, right after registration: counters snapshot at mint time.
struct (0x44650013) StampsInit {
    queryId: uint64
    stamps: map<uint8, uint128>
}

/// Owner -> DeskItem.
struct (0x44650014) Withdraw {
    queryId: uint64
    slot: uint8
    jettonWallet: address
    amount: coins
    to: address
}

/// DeskItem -> Pot. Pot refuses (RoundOwed) if `stamp != counter[slot]`.
struct (0x44650015) WithdrawViaPot {
    queryId: uint64
    serial: uint32
    slot: uint8
    stamp: uint128
    jettonWallet: address
    amount: coins
    to: address
}

/// Pot -> DeskItem.
struct (0x44650016) WithdrawOk {
    queryId: uint64
    slot: uint8
    jettonWallet: address
    amount: coins
    to: address
}

/// Collection -> Pot.
struct (0x44650017) RegisterDesk {
    queryId: uint64
    serial: uint32
}

// ---------------------------------------------------------------------------
// Minter
// ---------------------------------------------------------------------------

/// Anyone -> Minter. Re-sends DeployDesk for a serial whose deploy has not been acknowledged.
struct (0x44650020) RetryDeploy {
    queryId: uint64
    serial: uint32
}

/// Anyone: burn the deposits whose burn bounced earlier (value ≥ BURN_VALUE).
struct (0x44650024) RetryBurn {
    queryId: uint64
}

struct (0x44650021) SetDeskMinterPaused {
    queryId: uint64
    paused: bool
}

struct (0x44650022) SetDeskMinterConfig {
    queryId: uint64
    config: Cell<DeskMinterConfig>
}

struct (0x44650023) ChangeDeskMinterAdmin {
    queryId: uint64
    newAdmin: address
}

struct DeskMinterConfig {
    /// Minter's own $DESK jetton wallet; null until discovered (mint disabled until set).
    deskJettonWallet: address?
    protocolWallet: address
    depositAmount: coins
    surcharge: coins
    protocolShareBps: uint16
}

struct DeskMinterStorage {
    admin: address
    collection: address
    pot: address
    minted: uint32
    cap: uint32
    paused: bool
    /// Deposits whose burn bounced (wallet busy / underfunded): still held by our wallet, burnable by anyone.
    unburned: coins
    config: Cell<DeskMinterConfig>
    pendingDeploys: map<uint32, address>
}

fun DeskMinterStorage.load(): DeskMinterStorage {
    return DeskMinterStorage.fromCell(contract.getData());
}

fun DeskMinterStorage.save(self) {
    contract.setData(self.toCell());
}

struct DeskMinterDataReply {
    admin: address
    collection: address
    pot: address
    minted: int
    cap: int
    paused: bool
    unburned: coins
    config: DeskMinterConfig
    pendingDeploys: map<uint32, address>
}
