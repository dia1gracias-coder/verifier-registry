// ConsulOrder storage and message schemas. Spec: docs/spec/consul-order.md.

// Deployed with just {registry, orderSeqno} (loader pattern, mirroring TitleItem's
// registry/owner prefix) — the real config arrives as a follow-up OrderInit message.
// Deviation from docs/spec/consul-order.md's storage TL-B (noted in the Task 6 report and
// mirrored into the spec in this same commit): `treasury` is not listed there, but
// "ApproveOrder"'s kind-0 execution effect ("ExecuteActions ... to treasury") is otherwise
// unaddressable — TON has no synchronous cross-contract read, so this contract cannot ask the
// Registry "what's your treasury" mid-flight. Copied from the Registry's own storage.treasury
// at NewProposal/OrderInit time, exactly the same snapshot-at-creation reasoning the spec
// already applies to `emperor`/`emperorWeight`.
struct ConsulOrderStorage {
    registry: address
    orderSeqno: uint32
    kind: uint8
    body: cell
    emperor: address
    emperorWeight: uint8
    requiredWeight: uint8
    expiry: uint32
    holders: map<uint8, address>
    treasury: address
    approvedWeight: uint8
    approvedSeatsMask: uint8
    emperorApproved: bool
    executed: bool
}

struct ConsulOrderStorageTail {
    kind: uint8
    body: cell
    emperor: address
    emperorWeight: uint8
    requiredWeight: uint8
    expiry: uint32
    holders: map<uint8, address>
    treasury: address
    approvedWeight: uint8
    approvedSeatsMask: uint8
    emperorApproved: bool
    executed: bool
}

struct ConsulOrderStorageLoader {
    registry: address
    orderSeqno: uint32
    private rest: RemainingBitsAndRefs
}

fun ConsulOrderStorage.startLoading(): ConsulOrderStorageLoader {
    return ConsulOrderStorageLoader.fromCell(contract.getData());
}

fun ConsulOrderStorage.save(self) {
    contract.setData(self.toCell());
}

fun ConsulOrderStorageLoader.isInitialized(self): bool {
    return !self.rest.isEmpty();
}

fun ConsulOrderStorageLoader.endLoading(self): ConsulOrderStorage {
    val tail = ConsulOrderStorageTail.fromSlice(self.rest);
    return {
        registry: self.registry,
        orderSeqno: self.orderSeqno,
        kind: tail.kind,
        body: tail.body,
        emperor: tail.emperor,
        emperorWeight: tail.emperorWeight,
        requiredWeight: tail.requiredWeight,
        expiry: tail.expiry,
        holders: tail.holders,
        treasury: tail.treasury,
        approvedWeight: tail.approvedWeight,
        approvedSeatsMask: tail.approvedSeatsMask,
        emperorApproved: tail.emperorApproved,
        executed: tail.executed,
    };
}

// Registry -> this contract, deploy+message (docs/spec/consul-order.md "OrderInit").
// `proposerSeat` 0 means "the emperor proposed" (seat indices are 1..7). `treasury`: see the
// deviation note on ConsulOrderStorage above.
struct (0x444e0502) OrderInit {
    queryId: uint64
    kind: uint8
    body: cell
    emperor: address
    emperorWeight: uint8
    requiredWeight: uint8
    expiry: uint32
    holders: map<uint8, address>
    treasury: address
    proposerSeat: uint8
    proposerWeight: uint8
}

// A roster wallet or the emperor wallet -> this contract.
struct (0x444e0501) ApproveOrder {
    queryId: uint64
}

type ConsulOrderMessage = OrderInit | ApproveOrder
