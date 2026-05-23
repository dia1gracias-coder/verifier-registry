// External-out log events for indexers and mirrors.
//
// M4 fix: events are now typed structs emitted with `createExternalLogMessage`
// instead of hand-built `ext_out_msg_info` cells + `sendRawMessage`.
//
// SLIM EVENT (gas optimisation): BagIndexedEvent carries only the fields that
// cannot be re-derived from another on-chain source. The full TON Storage
// metadata is NOT embedded — indexers fetch it on demand via the BagItem's
// `get_storage_metadata`. This roughly halves the external forward fee paid
// per AddBag (fwd fees scale with the cell tree size of the message body).
// ===========================================================================
// EVENT BODIES
//
// Opcodes use the 0x10xxxxxx range to stay clearly distinct from the inbound
// message opcodes ("ASCII" range). They are the first 32 bits of the emitted
// external-out message body, so indexers route purely on the opcode.
// ===========================================================================

/// Emitted by BagRegistry when a new bag is successfully registered.
///
/// Indexer flow: filter on `bagId` / `category` / `uploader` from this event,
/// then call `get_storage_metadata` on the BagItem (whose address derives from
/// `bagIndex`) for the full TON Storage technical metadata.
struct (0x10000001) BagIndexedEvent {
    /// Sequential index assigned in the registry. Used to derive the BagItem
    /// address via the registry's `get_bag_address(bagIndex)`.
    bagIndex: uint64
    /// TON Storage bag hash.
    bagId: uint256
    /// Category id, 0..5.
    category: uint8
    /// Wallet that registered the bag.
    uploader: address
    /// Registration time (Unix seconds), as recorded by the registry.
    timestamp: uint64
    /// Bag display name as a direct ref, so indexers can label entries without
    /// an extra RPC. Snake-format string cell.
    name: cell
}

/// Emitted by a BagItem when its uploader deactivates it.
struct (0x10000002) BagRemovedEvent {
    /// Sequential index of the deactivated bag.
    bagIndex: uint64
    /// Address that triggered the deactivation (always the uploader).
    removedBy: address
}

/// Union of every external-out event this project emits (for ABI export).
type BagEvent = BagIndexedEvent | BagRemovedEvent

// ===========================================================================
// EMIT HELPERS
// ===========================================================================

/// Emit a BagIndexed event. `dest` is the "none" external address; indexers
/// route on the 32-bit opcode prefix of the body.
fun emitBagIndexed(ev: BagIndexedEvent) {
    val msg = createExternalLogMessage({
        dest: createAddressNone(),
        body: ev,
    });
    msg.send(SEND_MODE_REGULAR);
}

/// Emit a BagRemoved event.
fun emitBagRemoved(ev: BagRemovedEvent) {
    val msg = createExternalLogMessage({
        dest: createAddressNone(),
        body: ev,
    });
    msg.send(SEND_MODE_REGULAR);
}
