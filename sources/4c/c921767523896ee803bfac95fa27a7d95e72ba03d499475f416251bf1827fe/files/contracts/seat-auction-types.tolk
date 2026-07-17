// SeatAuction storage and message schemas. Spec: docs/spec/seat-auction.md.

// Deployed with just {registry, auctionSeqno} (loader pattern, mirroring ConsulOrder's own
// registry/orderSeqno prefix) — the real config arrives as a follow-up AuctionInit message.
struct SeatAuctionStorage {
    registry: address
    auctionSeqno: uint32
    treasury: address
    endAt: uint32
    highestBid: coins
    highestBidder: address?
    settled: bool
}

struct SeatAuctionStorageTail {
    treasury: address
    endAt: uint32
    highestBid: coins
    highestBidder: address?
    settled: bool
}

struct SeatAuctionStorageLoader {
    registry: address
    auctionSeqno: uint32
    private rest: RemainingBitsAndRefs
}

fun SeatAuctionStorage.startLoading(): SeatAuctionStorageLoader {
    return SeatAuctionStorageLoader.fromCell(contract.getData());
}

fun SeatAuctionStorage.save(self) {
    contract.setData(self.toCell());
}

fun SeatAuctionStorageLoader.isInitialized(self): bool {
    return !self.rest.isEmpty();
}

fun SeatAuctionStorageLoader.endLoading(self): SeatAuctionStorage {
    val tail = SeatAuctionStorageTail.fromSlice(self.rest);
    return {
        registry: self.registry,
        auctionSeqno: self.auctionSeqno,
        treasury: tail.treasury,
        endAt: tail.endAt,
        highestBid: tail.highestBid,
        highestBidder: tail.highestBidder,
        settled: tail.settled,
    };
}

// Registry -> this contract, deploy+message (docs/spec/seat-auction.md "AuctionInit").
struct (0x444e0601) AuctionInit {
    queryId: uint64
    treasury: address
    endAt: uint32
}

// Any wallet -> this contract (docs/spec/seat-auction.md "Bid"). Permissionless: no rank, no
// chain-proof, no prior title required.
struct (0x444e0602) Bid {
    queryId: uint64
}

// Anyone -> this contract (docs/spec/seat-auction.md "Settle"). Permissionless trigger.
struct (0x444e0603) Settle {
    queryId: uint64
}

// Registry -> this contract, in reply to AuctionResult once the coarse duke-cap guard passes
// (docs/spec/registry.md "Task 8 — auction hook", escrow-until-ack amendment): release the
// escrowed winning bid to treasury. Opcode from the 0x444e011x block (the Task 8 auction-hook
// message family, alongside StartAuction/AuctionResult), not this contract's own 0x444e06xx
// range — it is a Registry-authored message, mirroring where DukeGrant/Revoke etc. live.
struct (0x444e011e) AuctionCollect {
    queryId: uint64
    treasury: address
}

// Registry -> this contract: the coarse duke-cap guard failed at settle time — refund the
// escrowed bid to the never-seated winner instead of losing it (the fix this amendment makes
// over the originally accepted "winner loses their bid" gap, docs/spec/seat-auction-test-plan.md
// "Spec concerns" #1).
struct (0x444e011f) AuctionRefund {
    queryId: uint64
}

type SeatAuctionMessage = AuctionInit | Bid | Settle | AuctionCollect | AuctionRefund
