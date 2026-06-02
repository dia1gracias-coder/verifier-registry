tolk 1.3

// External-log message bodies. Indexers subscribe by external destination address
// (ExtOutLogBucket topic) to pick events up.

const TOPIC_ADMIN_ADDED: int = 0xE0000004
const TOPIC_ADMIN_REMOVED: int = 0xE0000005
const TOPIC_OWNERSHIP_TRANSFERRED: int = 0xE0000006
const TOPIC_DEPOSIT_RECEIVED: int = 0xE0000007
const TOPIC_MESSAGE_PREFIX_CHANGED: int = 0xE0000008
const TOPIC_GAME_CREATED: int = 0xE0000010
const TOPIC_GAME_STATUS_UPDATED: int = 0xE0000011
const TOPIC_PAYOUT_SENT: int = 0xE0000012
const TOPIC_PAYOUT_FAILED: int = 0xE0000013

struct AdminAddedLog {
    queryId: uint64
    pubkey: uint256
}

struct AdminRemovedLog {
    queryId: uint64
    pubkey: uint256
}

struct OwnershipTransferredLog {
    queryId: uint64
    previousOwner: address?
    newOwner: address?
}

struct DepositReceivedLog {
    sender: address
    amount: coins
}

struct MessagePrefixChangedLog {
    queryId: uint64
}

fun emitAdminAdded(queryId: uint64, pubkey: uint256) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_ADMIN_ADDED as uint248 },
        body: AdminAddedLog { queryId, pubkey },
    }).send(SEND_MODE_REGULAR);
}

fun emitAdminRemoved(queryId: uint64, pubkey: uint256) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_ADMIN_REMOVED as uint248 },
        body: AdminRemovedLog { queryId, pubkey },
    }).send(SEND_MODE_REGULAR);
}

fun emitOwnershipTransferred(queryId: uint64, previousOwner: address?, newOwner: address?) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_OWNERSHIP_TRANSFERRED as uint248 },
        body: OwnershipTransferredLog { queryId, previousOwner, newOwner },
    }).send(SEND_MODE_REGULAR);
}

fun emitDepositReceived(sender: address, amount: coins) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_DEPOSIT_RECEIVED as uint248 },
        body: DepositReceivedLog { sender, amount },
    }).send(SEND_MODE_REGULAR);
}

fun emitMessagePrefixChanged(queryId: uint64) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_MESSAGE_PREFIX_CHANGED as uint248 },
        body: MessagePrefixChangedLog { queryId },
    }).send(SEND_MODE_REGULAR);
}

// ---- Game event structs -------------------------------------------------

// Extra fields for GameCreatedLog that do not fit inline (ref-based).
struct GameCreatedLogExtra {
    betAmount: coins
    isNative: bool
    creditKind: uint8
    jettonMasterHash: uint256?
    gameSeedHash: uint256
    algoVersion: string
    gameConfig: string
}

struct GameCreatedLog {
    preliminaryGameIdHash: uint256
    player: address
    extra: Cell<GameCreatedLogExtra>
}

// Bundle the reveal strings into a sub-cell.
struct GameStatusUpdatedLogReveal {
    gameSeed: string
    gameState: string
}

struct GameStatusUpdatedLog {
    preliminaryGameIdHash: uint256
    status: uint8
    reveal: Cell<GameStatusUpdatedLogReveal>
}

struct PayoutSentLog {
    preliminaryGameIdHash: uint256
    player: address
    amount: coins
}

struct PayoutFailedLog {
    preliminaryGameIdHash: uint256
    player: address
    amount: coins
}

fun emitGameCreated(log: GameCreatedLog) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_GAME_CREATED as uint248 },
        body: log,
    }).send(SEND_MODE_REGULAR);
}

fun emitGameStatusUpdated(log: GameStatusUpdatedLog) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_GAME_STATUS_UPDATED as uint248 },
        body: log,
    }).send(SEND_MODE_REGULAR);
}

fun emitPayoutSent(log: PayoutSentLog) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_PAYOUT_SENT as uint248 },
        body: log,
    }).send(SEND_MODE_REGULAR);
}

fun emitPayoutFailed(log: PayoutFailedLog) {
    createExternalLogMessage({
        dest: ExtOutLogBucket { topic: TOPIC_PAYOUT_FAILED as uint248 },
        body: log,
    }).send(SEND_MODE_REGULAR);
}
