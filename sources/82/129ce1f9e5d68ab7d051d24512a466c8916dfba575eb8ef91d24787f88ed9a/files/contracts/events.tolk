struct (0x10000001) BagIndexedEvent {
    bagIndex: uint64
    bagId: uint256
    category: uint8
    uploader: address
    timestamp: uint64
    name: cell
}

struct (0x10000002) BagRemovedEvent {
    bagIndex: uint64
    removedBy: address
}

type BagEvent = BagIndexedEvent | BagRemovedEvent

fun emitBagIndexed(ev: BagIndexedEvent) {
    val msg = createExternalLogMessage({
        dest: createAddressNone(),
        body: ev,
    });
    msg.send(SEND_MODE_REGULAR);
}

fun emitBagRemoved(ev: BagRemovedEvent) {
    val msg = createExternalLogMessage({
        dest: createAddressNone(),
        body: ev,
    });
    msg.send(SEND_MODE_REGULAR);
}
