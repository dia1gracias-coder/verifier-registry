import "errors"
import "messages"
import "storage"

const BASIS_POINTS = 10_000
const MIN_POOL = 1_000_000_000
const MAX_POOL = 100_000_000_000
const OPEN_GAS_BUFFER = 50_000_000
const MIN_CALL_GAS = 20_000_000
const MIN_EXPIRY_DELAY = 30
const MAX_EXPIRY_DELAY = 3_600
const REVEAL_WINDOW = 300
const COMMITMENT_DOMAIN = 0x4C4F4F50
const OUTCOME_DOMAIN = 0x4C4F4F51

const REASON_BOTH_REVEALED = 1
const REASON_ONLY_REVEALER = 2
const REASON_CANCELLED = 3
const REASON_OFFER_EXPIRED = 4
const REASON_NO_REVEALS = 5

contract DuelEscrow {
    author: "LOOP"
    version: "1.0.0"
    description: "Native TON escrow with weighted two-party commit-reveal"
    storage: Storage
    incomingMessages: AllowedMessage
}

type AllowedMessage =
    | OpenOffer
    | CancelOffer
    | MatchOffers
    | Reveal
    | ExpireOffer
    | ExpireDuel
    | SetPaused

fun validChance(chanceBps: uint16): bool {
    return chanceBps == 2_500 || chanceBps == 5_000 || chanceBps == 7_500;
}

fun stakeFor(totalPool: coins, chanceBps: uint16): coins {
    return mulDivFloor(totalPool, chanceBps, BASIS_POINTS);
}

fun commitmentHash(offerId: uint64, owner: address, secret: uint256): uint256 {
    return beginCell()
        .storeUint(COMMITMENT_DOMAIN, 32)
        .storeUint(offerId, 64)
        .storeAddress(owner)
        .storeUint(secret, 256)
        .hash();
}

fun Storage.matchOpenOffers(mutate self, firstOfferId: uint64, secondOfferId: uint64): uint64 {
    assert (firstOfferId != secondOfferId) throw Errors.IncompatibleOffers;

    var first = self.loadOffer(firstOfferId);
    var second = self.loadOffer(secondOfferId);
    assert (first.state == OFFER_OPEN && second.state == OFFER_OPEN) throw Errors.OfferNotOpen;
    assert (first.owner != second.owner) throw Errors.SameOwner;
    assert (first.totalPool == second.totalPool) throw Errors.IncompatibleOffers;
    assert (first.chanceBps + second.chanceBps == BASIS_POINTS) throw Errors.IncompatibleOffers;
    assert (
        first.expiresAt > blockchain.now() && second.expiresAt > blockchain.now()
    ) throw Errors.InvalidExpiry;

    first.state = OFFER_MATCHED;
    second.state = OFFER_MATCHED;
    self.offers.set(firstOfferId, first.toCell());
    self.offers.set(secondOfferId, second.toCell());

    var offerAId = firstOfferId;
    var offerBId = secondOfferId;
    if (firstOfferId > secondOfferId) {
        offerAId = secondOfferId;
        offerBId = firstOfferId;
    }
    val duelId = offerBId;
    self
        .duels
        .set(
            duelId,
            DuelData {
                offerAId,
                offerBId,
                revealDeadline: blockchain.now() + REVEAL_WINDOW,
                secretA: 0,
                secretB: 0,
                revealedMask: 0,
            }.toCell(),
        );
    return duelId;
}

fun Storage.removeMatchedDuel(mutate self, duelId: uint64, duel: DuelData): void {
    val offerA = self.loadOffer(duel.offerAId);
    val offerB = self.loadOffer(duel.offerBId);
    val totalLocked = offerA.stake + offerB.stake;
    assert (self.locked >= totalLocked) throw Errors.InsufficientValue;

    self.locked -= totalLocked;
    self.activeOffers.delete(offerA.owner);
    self.activeOffers.delete(offerB.owner);
    self.offers.delete(duel.offerAId);
    self.offers.delete(duel.offerBId);
    self.duels.delete(duelId);
}

fun sendRefund(queryId: uint64, offerId: uint64, to: address, amount: coins, reason: uint8) {
    val refundMessage = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: amount,
        body: OfferRefund { queryId, offerId, reason },
    });
    refundMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sendWinner(
    queryId: uint64,
    duelId: uint64,
    offerId: uint64,
    to: address,
    amount: coins,
    reason: uint8,
) {
    val payoutMessage = createMessage({
        bounce: BounceMode.NoBounce,
        dest: to,
        value: amount,
        body: DuelPayout { queryId, duelId, offerId, reason },
    });
    payoutMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sendFee(queryId: uint64, duelId: uint64, to: address, amount: coins) {
    if (amount > 0) {
        val feeMessage = createMessage({
            bounce: BounceMode.NoBounce,
            dest: to,
            value: amount,
            body: ProtocolFee { queryId, duelId },
        });
        feeMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
}

fun Storage.settleWinner(
    mutate self,
    queryId: uint64,
    duelId: uint64,
    duel: DuelData,
    winnerOfferId: uint64,
    reason: uint8,
) {
    val offerA = self.loadOffer(duel.offerAId);
    val offerB = self.loadOffer(duel.offerBId);
    val winner = winnerOfferId == duel.offerAId ? offerA : offerB;
    val totalPool = offerA.stake + offerB.stake;
    val fee = mulDivFloor(totalPool, self.feeBps, BASIS_POINTS);
    val payout = totalPool - fee;

    self.removeMatchedDuel(duelId, duel);
    self.save();
    sendWinner(
        queryId,
        duelId,
        winnerOfferId,
        winner.owner,
        payout,
        reason,
    );
    sendFee(queryId, duelId, self.treasury, fee);
}

fun Storage.settleRevealed(mutate self, queryId: uint64, duelId: uint64, duel: DuelData) {
    val offerA = self.loadOffer(duel.offerAId);
    val offerB = self.loadOffer(duel.offerBId);
    val totalPool = offerA.stake + offerB.stake;
    val outcome = beginCell()
        .storeUint(OUTCOME_DOMAIN, 32)
        .storeUint(duelId, 64)
        .storeUint(duel.offerAId, 64)
        .storeUint(duel.secretA, 256)
        .storeUint(duel.offerBId, 64)
        .storeUint(duel.secretB, 256)
        .hash();
    val winnerOfferId = outcome % totalPool < offerA.stake ? duel.offerAId : duel.offerBId;
    self.settleWinner(
        queryId,
        duelId,
        duel,
        winnerOfferId,
        REASON_BOTH_REVEALED,
    );
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        OpenOffer => {
            var storage = Storage.load();
            assert (!storage.paused) throw Errors.Paused;
            assert (storage.feeBps <= 1_000) throw Errors.InvalidFee;
            assert (msg.offerId != 0) throw Errors.InvalidOfferId;
            assert (validChance(msg.chanceBps)) throw Errors.InvalidChance;
            assert (
                msg.totalPool >= MIN_POOL && msg.totalPool <= MAX_POOL && msg.totalPool % 4 == 0
            ) throw Errors.InvalidPool;
            assert (
                msg.expiresAt >= blockchain.now() + MIN_EXPIRY_DELAY &&
                msg.expiresAt <= blockchain.now() + MAX_EXPIRY_DELAY
            ) throw Errors.InvalidExpiry;
            assert (!storage.usedOfferIds.exists(msg.offerId)) throw Errors.OfferAlreadyUsed;
            assert (!storage.activeOffers.exists(in.senderAddress)) throw Errors.OwnerAlreadyActive;

            val stake = stakeFor(msg.totalPool, msg.chanceBps);
            assert (in.valueCoins >= stake + OPEN_GAS_BUFFER) throw Errors.InsufficientValue;
            val offer = OfferData {
                owner: in.senderAddress,
                commitment: msg.commitment,
                chanceBps: msg.chanceBps,
                totalPool: msg.totalPool,
                stake,
                expiresAt: msg.expiresAt,
                state: OFFER_OPEN,
            };
            storage.offers.set(msg.offerId, offer.toCell());
            storage.activeOffers.set(in.senderAddress, msg.offerId);
            storage.usedOfferIds.set(msg.offerId, true);
            storage.locked += stake;

            if (msg.counterOfferId != 0) {
                storage.matchOpenOffers(msg.counterOfferId, msg.offerId);
            }
            storage.save();
        }
        CancelOffer => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            val offer = storage.loadOffer(msg.offerId);
            assert (offer.state == OFFER_OPEN) throw Errors.OfferNotOpen;
            assert (offer.owner == in.senderAddress) throw Errors.NotOwner;
            assert (storage.locked >= offer.stake) throw Errors.InsufficientValue;

            storage.locked -= offer.stake;
            storage.activeOffers.delete(offer.owner);
            storage.offers.delete(msg.offerId);
            storage.save();
            sendRefund(msg.queryId, msg.offerId, offer.owner, offer.stake, REASON_CANCELLED);
        }
        MatchOffers => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            assert (!storage.paused) throw Errors.Paused;
            storage.matchOpenOffers(msg.firstOfferId, msg.secondOfferId);
            storage.save();
        }
        Reveal => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            var duel = storage.loadDuel(msg.duelId);
            assert (blockchain.now() <= duel.revealDeadline) throw Errors.RevealClosed;
            assert (
                msg.offerId == duel.offerAId || msg.offerId == duel.offerBId
            ) throw Errors.WrongRevealer;
            val offer = storage.loadOffer(msg.offerId);
            assert (offer.owner == in.senderAddress) throw Errors.WrongRevealer;
            assert (
                commitmentHash(msg.offerId, offer.owner, msg.secret) == offer.commitment
            ) throw Errors.InvalidCommitment;

            if (msg.offerId == duel.offerAId) {
                assert ((duel.revealedMask & REVEALED_A) == 0) throw Errors.AlreadyRevealed;
                duel.secretA = msg.secret;
                duel.revealedMask |= REVEALED_A;
            } else {
                assert ((duel.revealedMask & REVEALED_B) == 0) throw Errors.AlreadyRevealed;
                duel.secretB = msg.secret;
                duel.revealedMask |= REVEALED_B;
            }

            if (duel.revealedMask == (REVEALED_A | REVEALED_B)) {
                storage.settleRevealed(msg.queryId, msg.duelId, duel);
            } else {
                storage.duels.set(msg.duelId, duel.toCell());
                storage.save();
            }
        }
        ExpireOffer => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            val offer = storage.loadOffer(msg.offerId);
            assert (offer.state == OFFER_OPEN) throw Errors.OfferNotOpen;
            assert (blockchain.now() > offer.expiresAt) throw Errors.TooEarly;
            assert (storage.locked >= offer.stake) throw Errors.InsufficientValue;

            storage.locked -= offer.stake;
            storage.activeOffers.delete(offer.owner);
            storage.offers.delete(msg.offerId);
            storage.save();
            sendRefund(msg.queryId, msg.offerId, offer.owner, offer.stake, REASON_OFFER_EXPIRED);
        }
        ExpireDuel => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            val duel = storage.loadDuel(msg.duelId);
            assert (blockchain.now() > duel.revealDeadline) throw Errors.TooEarly;

            if (duel.revealedMask == REVEALED_A) {
                storage.settleWinner(
                    msg.queryId,
                    msg.duelId,
                    duel,
                    duel.offerAId,
                    REASON_ONLY_REVEALER,
                );
            } else if (duel.revealedMask == REVEALED_B) {
                storage.settleWinner(
                    msg.queryId,
                    msg.duelId,
                    duel,
                    duel.offerBId,
                    REASON_ONLY_REVEALER,
                );
            } else {
                val offerA = storage.loadOffer(duel.offerAId);
                val offerB = storage.loadOffer(duel.offerBId);
                storage.removeMatchedDuel(msg.duelId, duel);
                storage.save();
                sendRefund(
                    msg.queryId,
                    duel.offerAId,
                    offerA.owner,
                    offerA.stake,
                    REASON_NO_REVEALS,
                );
                sendRefund(
                    msg.queryId,
                    duel.offerBId,
                    offerB.owner,
                    offerB.stake,
                    REASON_NO_REVEALS,
                );
            }
        }
        SetPaused => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            assert (storage.owner == in.senderAddress) throw Errors.NotOwner;
            storage.paused = msg.paused;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun contractConfig(): ContractConfigView {
    val storage = Storage.load();
    return {
        owner: storage.owner,
        treasury: storage.treasury,
        feeBps: storage.feeBps,
        paused: storage.paused,
        locked: storage.locked,
    };
}

get fun offerData(offerId: uint64): OfferData {
    val storage = Storage.load();
    return storage.loadOffer(offerId);
}

get fun duelData(duelId: uint64): DuelData {
    val storage = Storage.load();
    return storage.loadDuel(duelId);
}

get fun activeOffer(owner: address): uint64 {
    val storage = Storage.load();
    return storage.activeOffers.mustGet(owner, Errors.OfferMissing);
}
