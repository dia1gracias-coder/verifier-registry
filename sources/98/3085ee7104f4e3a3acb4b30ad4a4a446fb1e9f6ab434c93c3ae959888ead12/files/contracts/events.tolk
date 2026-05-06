tolk 1.3

// External-log message bodies. Indexers subscribe by external destination address
// (ExtOutLogBucket topic) to pick events up.

const TOPIC_ADMIN_ADDED: int = 0xE0000004
const TOPIC_ADMIN_REMOVED: int = 0xE0000005
const TOPIC_OWNERSHIP_TRANSFERRED: int = 0xE0000006
const TOPIC_DEPOSIT_RECEIVED: int = 0xE0000007
const TOPIC_MESSAGE_PREFIX_CHANGED: int = 0xE0000008

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
