import "trade_types"

contract TradeEscrow {
    author: "TON Trades"
    version: "0.1.0"
    description: "Two-party TON and NFT escrow trade room"
    storage: TradeEscrowStorage
    incomingMessages: EscrowMessage
}

type EscrowMessage =
    | DepositTon
    | AcceptTrade
    | CancelTrade
    | SweepDust
    | RetryPending
    | ForceResolveStuck
    | ExpireTrade
    | OwnershipAssigned

fun isUserA(storage: TradeEscrowStorage, addr: address): bool {
    return storage.participants.load().userA == addr;
}

fun isUserB(storage: TradeEscrowStorage, addr: address): bool {
    return storage.participants.load().userB == addr;
}

fun assertParticipant(storage: TradeEscrowStorage, addr: address) {
    assert (isUserA(storage, addr) || isUserB(storage, addr)) throw TradeErrors.NotParticipant;
}

// SETTLING/COMPLETED only. Deliberately excludes TRADE_STATUS_SETTLE_STUCK so a late bounce can never
// reopen a force-resolved trade, and so RetryPending routes SETTLE_STUCK to its own return path.
fun isSettlementStatus(status: uint8): bool {
    return status == TRADE_STATUS_SETTLING || status == TRADE_STATUS_COMPLETED;
}

fun isRefundStatus(status: uint8): bool {
    return status == TRADE_STATUS_REFUNDING || status == TRADE_STATUS_REFUNDED;
}

fun isStuckStatus(status: uint8): bool {
    return status == TRADE_STATUS_SETTLE_STUCK;
}

// L-04: only truly terminal states allow SweepDust.
// SETTLING and REFUNDING are retry-pending: NFT transfers are still in flight and the escrow
// balance funds each retry send (NFT_TRANSFER_VALUE via PAY_FEES_SEPARATELY). Sweeping early
// narrows that buffer. SETTLE_STUCK must be included — it IS terminal (no state transitions out),
// so excluding it would permanently lock any remaining balance with no recovery path.
fun isTerminalStatus(status: uint8): bool {
    return status == TRADE_STATUS_COMPLETED || status == TRADE_STATUS_REFUNDED ||
    status == TRADE_STATUS_SETTLE_STUCK;
}

fun assertOpen(storage: TradeEscrowStorage) {
    assert (!isSettlementStatus(storage.status)) throw TradeErrors.AlreadyCompleted;
    assert (!isRefundStatus(storage.status)) throw TradeErrors.AlreadyCancelled;
    assert (storage.status == TRADE_STATUS_OPEN) throw TradeErrors.InvalidMessage;
}

fun requiredActionValueForNfts(nftCount: int): coins {
    return MIN_TRADE_ACTION_VALUE + NFT_TRANSFER_VALUE * nftCount;
}

fun shouldTransferNft(status: uint8): bool {
    return status == NFT_STATUS_DEPOSITED || status == NFT_STATUS_TRANSFER_BOUNCED;
}

fun pendingNftCount(nfts: map<address, uint8>): int {
    var count = 0;
    var entry = nfts.findFirst();
    while (entry.isFound) {
        if (shouldTransferNft(entry.loadValue())) {
            count += 1;
        }
        entry = nfts.iterateNext(entry);
    }
    return count;
}

fun totalPendingNftCount(assets: TradeAssets): int {
    return pendingNftCount(assets.nftA) + pendingNftCount(assets.nftB);
}

fun assertNftTransferReserve(inValue: coins, nftCount: int) {
    assert (
        inValue >= requiredActionValueForNfts(nftCount)
    ) throw TradeErrors.InsufficientMessageValue;
}

fun tradeFee(amount: coins): coins {
    return amount * TRADE_FEE_BPS / BPS_DENOMINATOR;
}

// sweepableBalance + sendTon are shared helpers defined in trade_types.tolk (S-1).

// M-04: derive a unique queryId from the NFT address so concurrent settlement transfers are
// distinguishable by off-chain indexers. cell.hash() returns uint256; we read the first 64 bits
// back out via loadUint to avoid a TVM range-check error from a direct uint256 → uint64 cast.
fun nftQueryId(nft: address): uint64 {
    val h = beginCell().storeAddress(nft).endCell().hash();
    return beginCell().storeUint(h, 256).endCell().beginParse().loadUint(64);
}

fun transferNft(nft: address, newOwner: address) {
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: NFT_TRANSFER_VALUE,
        dest: nft,
        body: NftTransfer {
            queryId: nftQueryId(nft),
            newOwner,
            responseDestination: contract.getAddress(),
            customPayload: false,
            forwardAmount: 1,
            forwardPayload: false,
        },
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun returnNft(nft: address, previousOwner: address) {
    // C-03: fund the return from the inbound message (mode 64), never from the escrow balance.
    // OwnershipAssigned is unauthenticated, so any sender can hit a reject branch. If the return
    // were escrow-funded (fixed value + PAY_FEES_SEPARATELY, like transferNft) an attacker could
    // drain the contract by forging notifications. Carrying the remaining inbound value means a
    // return can never pay out more than what just arrived, so forging is never profitable.
    // Legitimate settlement/refund transfers stay escrow-funded via transferNft (reserve-gated).
    createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        value: 0,
        dest: nft,
        body: NftTransfer {
            queryId: 0,
            newOwner: previousOwner,
            responseDestination: previousOwner,
            customPayload: false,
            forwardAmount: 1,
            forwardPayload: false,
        },
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun nftAlreadyRecorded(assets: TradeAssets, nft: address): bool {
    return assets.nftA.exists(nft) || assets.nftB.exists(nft);
}

// Recomputes the TEP-62 item address that a genuine NFT of `collection` at `index` must have, given
// that collection's item code. The escrow only trusts a deposit whose sender equals this address.
// See docs/nft-deposit.md for the full wire format and authentication flow.
fun computeNftItemAddress(itemCode: cell, collection: address, index: uint64): address {
    val stateInit = ContractState {
        code: itemCode,
        data: NftItemInitData { index, collection }.toCell(),
    };
    return AutoDeployAddress { stateInit }.calculateAddress();
}

fun canRecordNftForA(storage: TradeEscrowStorage, assets: TradeAssets, nft: address): bool {
    return !storage.acceptedA && !nftAlreadyRecorded(assets, nft) && assets.nftCountA <
    MAX_NFTS_PER_SIDE;
}

fun canRecordNftForB(storage: TradeEscrowStorage, assets: TradeAssets, nft: address): bool {
    return !storage.acceptedB && !nftAlreadyRecorded(assets, nft) && assets.nftCountB <
    MAX_NFTS_PER_SIDE;
}

// Authenticates and records an incoming NFT deposit.
//
// C-01/H-03: the deposit notification (OwnershipAssigned) is unauthenticated — any contract can send
// one with an arbitrary prevOwner. We never trust prevOwner on its own. Instead the transfer's
// forward payload must carry an allowlisted collection address + item index whose recomputed TEP-62
// address equals the actual sender. Only a genuine item of an allowlisted collection can satisfy this,
// which in turn means its prevOwner field is set by that item and can be trusted to identify the side.
//
// Payload wire format (Either Cell ^Cell — see docs/nft-deposit.md):
//   Inline: bit(0) | address(collection) | uint64(index)
//   Ref:    bit(1) | ^(address(collection) | uint64(index))
//
// Returns true and records the NFT (status DEPOSITED) on success; false on any failure (bad payload,
// unknown collection, address mismatch, wrong/accepted side, duplicate, side full) so the caller can
// return the NFT to its sender. Parsing is wrapped in try/catch so a malformed payload can never
// abort the transaction and strand the NFT at the escrow.
fun tryRecordDeposit(
    mutate storage: TradeEscrowStorage,
    mutate assets: TradeAssets,
    nft: address,
    prevOwner: address,
    payload: slice,
): bool {
    var collection = prevOwner; // placeholder, overwritten by a successful parse
    var index: uint64 = 0;
    try {
        var p = payload;
        var body = p;
        if (p.remainingBitsCount() >= 1) {
            // forward_payload is Either Cell ^Cell: bit 0 = inline, bit 1 = in a ref.
            if (p.loadBool()) {
                body = p.loadRef().beginParse();
            } else {
                body = p;
            }
        }
        collection = body.loadAddress();
        index = body.loadUint(64);
    } catch {
        return false;
    }

    if (!storage.allowedCollections.exists(collection)) {
        return false;
    }
    val itemCode = storage.allowedCollections.mustGet(collection);
    if (computeNftItemAddress(itemCode, collection, index) != nft) {
        return false;
    }

    if (isUserA(storage, prevOwner) && canRecordNftForA(storage, assets, nft)) {
        assets.nftA.set(nft, NFT_STATUS_DEPOSITED);
        assets.nftCountA += 1;
        return true;
    }
    if (isUserB(storage, prevOwner) && canRecordNftForB(storage, assets, nft)) {
        assets.nftB.set(nft, NFT_STATUS_DEPOSITED);
        assets.nftCountB += 1;
        return true;
    }
    return false;
}

fun transferPendingNfts(mutate nfts: map<address, uint8>, to: address) {
    var entry = nfts.findFirst();
    while (entry.isFound) {
        val nft = entry.getKey();
        if (shouldTransferNft(entry.loadValue())) {
            transferNft(nft, to);
            nfts.set(nft, NFT_STATUS_TRANSFER_SENT);
        }
        entry = nfts.iterateNext(entry);
    }
}

fun nftAddressSet(nfts: map<address, uint8>): map<address, bool> {
    var result: map<address, bool> = [];
    var entry = nfts.findFirst();
    while (entry.isFound) {
        result.set(entry.getKey(), true);
        entry = nfts.iterateNext(entry);
    }
    return result;
}

fun isNftTransferBounce(bouncedBody: slice): bool {
    var body = bouncedBody;
    if (body.remainingBitsCount() < 64) {
        return false;
    }
    // M-05: read the prefix explicitly rather than calling skipBouncedPrefix(), whose behaviour on
    // edge-case slices is Tolk-version-specific. A body with the wrong prefix (e.g. a non-bounced
    // message accidentally matching the bit count) is now safely rejected here.
    val prefix = body.loadUint(32);
    if (prefix != 0xFFFFFFFF) {
        return false;
    }
    return body.loadUint(32) == 0x5fcc3d14;
}

fun markBouncedNft(mutate assets: TradeAssets, nft: address): bool {
    if (assets.nftA.exists(nft)) {
        if (assets.nftA.mustGet(nft) == NFT_STATUS_TRANSFER_SENT) {
            assets.nftA.set(nft, NFT_STATUS_TRANSFER_BOUNCED);
        }
        return true;
    }

    if (assets.nftB.exists(nft)) {
        if (assets.nftB.mustGet(nft) == NFT_STATUS_TRANSFER_SENT) {
            assets.nftB.set(nft, NFT_STATUS_TRANSFER_BOUNCED);
        }
        return true;
    }

    return false;
}

fun reopenStatusAfterNftBounce(mutate storage: TradeEscrowStorage) {
    if (isSettlementStatus(storage.status)) {
        storage.status = TRADE_STATUS_SETTLING;
    } else if (isRefundStatus(storage.status)) {
        storage.status = TRADE_STATUS_REFUNDING;
    }
}

fun refundAll(mutate storage: TradeEscrowStorage, inValue: coins) {
    var assets = storage.assets.load();
    val participants = storage.participants.load();
    assertNftTransferReserve(inValue, totalPendingNftCount(assets));

    storage.status = TRADE_STATUS_REFUNDING;
    // Stamp the moment the trade left OPEN. Refunds always target the depositor, so a permanently
    // rejecting NFT just keeps RetryPending-able here (no escape needed) — the stamp is recorded for
    // symmetry and getState observability only.
    storage.statusChangedAt = blockchain.now() as uint32;

    sendTon(participants.userA, storage.depositedTonA);
    sendTon(participants.userB, storage.depositedTonB);
    transferPendingNfts(mutate assets.nftA, participants.userA);
    transferPendingNfts(mutate assets.nftB, participants.userB);

    storage.assets = assets.toCell();
    storage.status = TRADE_STATUS_REFUNDED;
    // L-01: zero the deposit fields so getState() is unambiguous after refund.
    storage.depositedTonA = 0;
    storage.depositedTonB = 0;
    storage.save();
}

fun completeTrade(mutate storage: TradeEscrowStorage, inValue: coins) {
    var assets = storage.assets.load();
    val participants = storage.participants.load();
    val feeA = tradeFee(storage.depositedTonA);
    val feeB = tradeFee(storage.depositedTonB);
    assertNftTransferReserve(inValue, totalPendingNftCount(assets));

    storage.status = TRADE_STATUS_SETTLING;
    // H-01: stamp when settlement began. The stuck-settlement escape is gated on
    // now() >= statusChangedAt + STUCK_SETTLEMENT_TIMEOUT. Retries/bounces never touch this, so the
    // clock runs from the first settlement attempt and cannot be reset by a griefer.
    storage.statusChangedAt = blockchain.now() as uint32;

    sendTon(participants.userA, storage.depositedTonB - feeB);
    sendTon(participants.userB, storage.depositedTonA - feeA);
    sendTon(storage.feeRecipient, feeA + feeB);
    transferPendingNfts(mutate assets.nftA, participants.userB);
    transferPendingNfts(mutate assets.nftB, participants.userA);

    storage.assets = assets.toCell();
    storage.status = TRADE_STATUS_COMPLETED;
    // L-01: zero the deposit fields so getState() is unambiguous after settlement — a non-zero
    // depositedTonA on a COMPLETED trade otherwise looks like funds are still held.
    storage.depositedTonA = 0;
    storage.depositedTonB = 0;
    storage.save();
}

fun retrySettlement(mutate storage: TradeEscrowStorage, inValue: coins) {
    var assets = storage.assets.load();
    val participants = storage.participants.load();
    assert (isSettlementStatus(storage.status)) throw TradeErrors.TradeNotCompleted;
    assertNftTransferReserve(inValue, totalPendingNftCount(assets));

    storage.status = TRADE_STATUS_SETTLING;
    transferPendingNfts(mutate assets.nftA, participants.userB);
    transferPendingNfts(mutate assets.nftB, participants.userA);
    storage.assets = assets.toCell();
    storage.status = TRADE_STATUS_COMPLETED;
    storage.save();
}

fun retryRefund(mutate storage: TradeEscrowStorage, inValue: coins) {
    var assets = storage.assets.load();
    val participants = storage.participants.load();
    assert (isRefundStatus(storage.status)) throw TradeErrors.TradeNotCancelled;
    assertNftTransferReserve(inValue, totalPendingNftCount(assets));

    storage.status = TRADE_STATUS_REFUNDING;
    transferPendingNfts(mutate assets.nftA, participants.userA);
    transferPendingNfts(mutate assets.nftB, participants.userB);
    storage.assets = assets.toCell();
    storage.status = TRADE_STATUS_REFUNDED;
    storage.save();
}

// H-01: permissionless, timeout-gated escape from a permanently-stuck settlement.
//
// When an NFT's item contract permanently rejects the settlement transfer to the counterparty, the
// transfer bounces, the trade reverts COMPLETED -> SETTLING, and RetrySettlement keeps re-sending to
// the same rejecting destination forever — the NFT is locked with no recovery, even though the TON
// was already distributed. After STUCK_SETTLEMENT_TIMEOUT from the first settlement attempt, anyone
// may call this to return each side's still-held NFTs to *their own depositor* (a destination
// RetrySettlement never tries) and move the trade to the terminal TRADE_STATUS_SETTLE_STUCK.
//
// Safety properties:
//   - Status must be exactly SETTLING. A clean COMPLETED trade (no bounce) can never be force-resolved,
//     so this cannot disturb a successful settlement. OPEN/REFUNDING/SETTLE_STUCK are likewise rejected.
//   - Permissionless is safe: the only action is returning NFTs to the address that deposited them,
//     which harms no party that the non-transferable NFT had not already harmed. The timeout — not an
//     admin key — is the safety gate, so there is no trusted operator and no liveness dependency.
//   - TON is NOT touched (it was distributed by completeTrade); only NFTs move.
//   - Reserve-gated like every other NFT-sending action.
fun forceResolveStuckSettlement(mutate storage: TradeEscrowStorage, inValue: coins) {
    assert (storage.status == TRADE_STATUS_SETTLING) throw TradeErrors.TradeNotStuck;
    assert (
        blockchain.now() >= storage.statusChangedAt + STUCK_SETTLEMENT_TIMEOUT
    ) throw TradeErrors.StuckTimeoutNotReached;

    var assets = storage.assets.load();
    val participants = storage.participants.load();
    assertNftTransferReserve(inValue, totalPendingNftCount(assets));

    // Return each side's still-held NFTs to that side's depositor (nftA -> userA, nftB -> userB).
    transferPendingNfts(mutate assets.nftA, participants.userA);
    transferPendingNfts(mutate assets.nftB, participants.userB);

    storage.assets = assets.toCell();
    storage.status = TRADE_STATUS_SETTLE_STUCK;
    storage.save();
}

// Re-attempt the depositor returns for a trade already in TRADE_STATUS_SETTLE_STUCK. Reached via
// RetryPending. Covers the rare case where the force-resolve return itself bounced (an NFT that
// rejects transfers to *every* destination); if such an item later becomes transferable, the
// depositor can still recover it. Status stays SETTLE_STUCK (terminal); never reopens settlement.
fun retryStuckReturn(mutate storage: TradeEscrowStorage, inValue: coins) {
    var assets = storage.assets.load();
    val participants = storage.participants.load();
    assertNftTransferReserve(inValue, totalPendingNftCount(assets));

    transferPendingNfts(mutate assets.nftA, participants.userA);
    transferPendingNfts(mutate assets.nftB, participants.userB);

    storage.assets = assets.toCell();
    storage.save();
}

// M-03: permissionless, timeout-gated refund of an abandoned OPEN trade.
//
// Either participant can already `CancelTrade` an OPEN trade, so this only matters when *no* live party
// remains — both ghost, or a depositor loses their key and the counterparty never appears — leaving the
// deposited TON and NFTs locked forever. After `OPEN_TRADE_TIMEOUT` of inactivity (`lastActivityAt` is
// reset on every participant deposit/accept), anyone may refund everything to its depositors.
//
// Safety properties:
//   - Must be OPEN (assertOpen) — cannot touch a settling/refunding/closed trade.
//   - `lastActivityAt == 0` (no deposit ever happened) is *not* expirable: an empty freshly-created
//     trade has nothing to recover and must not be closable out from under its participants.
//   - Any participant action pushes the deadline out, so an active trade is never force-expired.
//   - Permissionless is safe: the only action is `refundAll`, which returns assets to their depositors.
//   - Reserve-gated via `refundAll`.
fun expireTrade(mutate storage: TradeEscrowStorage, inValue: coins) {
    assertOpen(storage);
    assert (
        storage.lastActivityAt != 0 &&
        blockchain.now() >= storage.lastActivityAt + OPEN_TRADE_TIMEOUT
    ) throw TradeErrors.TradeNotExpired;
    refundAll(mutate storage, inValue);
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    val msg = lazy EscrowMessage.fromSlice(in.body);

    match (msg) {
        DepositTon => {
            var storage = lazy TradeEscrowStorage.load();
            assertOpen(storage);
            assertParticipant(storage, in.senderAddress);
            assert (in.valueCoins > MIN_TRADE_ACTION_VALUE) throw TradeErrors.EmptyTonDeposit;
            val depositAmount = in.valueCoins - MIN_TRADE_ACTION_VALUE;

            if (isUserA(storage, in.senderAddress)) {
                assert (!storage.acceptedA) throw TradeErrors.SideAlreadyAccepted;
                storage.depositedTonA += depositAmount;
            } else {
                assert (!storage.acceptedB) throw TradeErrors.SideAlreadyAccepted;
                storage.depositedTonB += depositAmount;
            }

            storage.lastActivityAt = blockchain.now() as uint32; // M-03: reset the abandonment clock
            storage.save();
        }
        OwnershipAssigned => {
            // N-2: an underfunded notification cannot fund the mode-64 return gas if authentication
            // fails, causing the transaction to revert after ownership already moved at the item
            // level — stranding the NFT. Reject early before loading storage so the failure is
            // predictable and no gas is wasted on adversarial low-value inputs. Honest deposits
            // (SDK always forwards 20 mTON) are well above this 5 mTON floor.
            assert (
                in.valueCoins >= MIN_NFT_FORWARD_VALUE
            ) throw TradeErrors.InsufficientMessageValue;
            var storage = lazy TradeEscrowStorage.load();
            var assets = storage.assets.load();
            assertOpen(storage);

            val nft = in.senderAddress;
            // C-01/H-03: authenticate the deposit by recomputing the sender's expected TEP-62 item
            // address from the allowlisted collection + index in the forward payload. Anything that
            // fails to authenticate (forged sender, unknown collection, wrong side, duplicate, side
            // full, malformed payload) is returned to its sender, funded from the inbound value
            // (see returnNft / C-03), so a forged notification can never seed phantom assets.
            if (
                !tryRecordDeposit(
                    mutate storage,
                    mutate assets,
                    nft,
                    msg.prevOwner,
                    msg.forwardPayload,
                )
            ) {
                returnNft(nft, msg.prevOwner);
                return;
            }

            storage.assets = assets.toCell();
            storage.lastActivityAt = blockchain.now() as uint32; // M-03: reset the abandonment clock
            storage.save();
        }
        AcceptTrade => {
            var storage = lazy TradeEscrowStorage.load();
            assertOpen(storage);
            assertParticipant(storage, in.senderAddress);
            assert (
                in.valueCoins >= MIN_TRADE_ACTION_VALUE
            ) throw TradeErrors.InsufficientMessageValue;

            // Every recorded NFT is already DEPOSITED (deposits are authenticated and recorded
            // synchronously in OwnershipAssigned), so accepting can never lock in an asset the
            // escrow does not yet hold.
            if (isUserA(storage, in.senderAddress)) {
                assert (!storage.acceptedA) throw TradeErrors.SideAlreadyAccepted;
                storage.acceptedA = true;
            } else {
                assert (!storage.acceptedB) throw TradeErrors.SideAlreadyAccepted;
                storage.acceptedB = true;
            }

            if (storage.acceptedA && storage.acceptedB) {
                completeTrade(mutate storage, in.valueCoins);
            } else {
                storage.lastActivityAt = blockchain.now() as uint32; // M-03: reset abandonment clock
                storage.save();
            }
        }
        CancelTrade => {
            var storage = lazy TradeEscrowStorage.load();
            assertOpen(storage);
            assertParticipant(storage, in.senderAddress);
            assert (
                in.valueCoins >= MIN_TRADE_ACTION_VALUE
            ) throw TradeErrors.InsufficientMessageValue;
            refundAll(mutate storage, in.valueCoins);
        }
        SweepDust => {
            val storage = lazy TradeEscrowStorage.load();
            assert (isTerminalStatus(storage.status)) throw TradeErrors.TradeNotClosed;
            val amount = sweepableBalance(in.valueCoins, MIN_ESCROW_DUST_RESERVE);
            assert (amount > 0) throw TradeErrors.NothingToSweep;
            sendTon(storage.feeRecipient, amount);
            sendTon(in.senderAddress, in.valueCoins);
        }
        RetryPending => {
            var storage = lazy TradeEscrowStorage.load();
            if (isStuckStatus(storage.status)) {
                retryStuckReturn(mutate storage, in.valueCoins);
            } else if (isSettlementStatus(storage.status)) {
                retrySettlement(mutate storage, in.valueCoins);
            } else if (isRefundStatus(storage.status)) {
                retryRefund(mutate storage, in.valueCoins);
            } else {
                assert (false) throw TradeErrors.InvalidMessage;
            }
        }
        ForceResolveStuck => {
            var storage = lazy TradeEscrowStorage.load();
            forceResolveStuckSettlement(mutate storage, in.valueCoins);
        }
        ExpireTrade => {
            var storage = lazy TradeEscrowStorage.load();
            expireTrade(mutate storage, in.valueCoins);
        }
        else => {
            assert (in.body.isEmpty()) throw TradeErrors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    if (!isNftTransferBounce(in.bouncedBody)) {
        return;
    }

    var storage = lazy TradeEscrowStorage.load();
    var assets = storage.assets.load();

    if (markBouncedNft(mutate assets, in.senderAddress)) {
        storage.assets = assets.toCell();
        reopenStatusAfterNftBounce(mutate storage);
        storage.save();
    }
}

get fun getState(): TradeState {
    val storage = lazy TradeEscrowStorage.load();
    val assets = storage.assets.load();
    val participants = storage.participants.load();
    return {
        tradeId: storage.tradeId,
        factory: storage.factory,
        feeRecipient: storage.feeRecipient,
        userA: participants.userA,
        userB: participants.userB,
        acceptedA: storage.acceptedA,
        acceptedB: storage.acceptedB,
        depositedTonA: storage.depositedTonA,
        depositedTonB: storage.depositedTonB,
        nftCountA: assets.nftCountA,
        nftCountB: assets.nftCountB,
        pendingNftCount: totalPendingNftCount(assets),
        status: storage.status,
        statusChangedAt: storage.statusChangedAt,
        lastActivityAt: storage.lastActivityAt,
        completed: storage.status == TRADE_STATUS_COMPLETED,
        cancelled: storage.status == TRADE_STATUS_REFUNDED,
        stuck: isStuckStatus(storage.status),
    };
}

get fun getNftsA(): map<address, bool> {
    val storage = lazy TradeEscrowStorage.load();
    return nftAddressSet(storage.assets.load().nftA);
}

get fun getNftsB(): map<address, bool> {
    val storage = lazy TradeEscrowStorage.load();
    return nftAddressSet(storage.assets.load().nftB);
}

get fun getNftStatusesA(): map<address, uint8> {
    val storage = lazy TradeEscrowStorage.load();
    return storage.assets.load().nftA;
}

get fun getNftStatusesB(): map<address, uint8> {
    val storage = lazy TradeEscrowStorage.load();
    return storage.assets.load().nftB;
}

// I-05: numeric code version so the indexer can route by version after a code upgrade.
get fun getVersion(): uint16 {
    return CONTRACT_VERSION;
}
