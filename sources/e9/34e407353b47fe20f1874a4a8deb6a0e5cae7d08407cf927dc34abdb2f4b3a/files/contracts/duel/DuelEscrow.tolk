import "errors"
import "messages"
import "storage"

const BASIS_POINTS = 10_000
const MIN_POOL = 1_000_000_000
const MAX_POOL = 100_000_000_000
const OPEN_GAS_BUFFER = 50_000_000
const MIN_CALL_GAS = 20_000_000
const WITHDRAW_GAS_BUFFER = 50_000_000
const MIN_CONTRACT_RESERVE = 200_000_000
const MIN_EXPIRY_DELAY = 30
const MAX_EXPIRY_DELAY = 3_600
const REVEAL_WINDOW = 300
const BOOST_WINDOW = 60
const BOOST_EXTENSION = 20
const BOOST_HARD_WINDOW = 180
const MIN_BOOST = 100_000_000
const MAX_CHANCE_BPS = 9_000
const MIN_CHANCE_BPS = 1_000
const COMMITMENT_DOMAIN = 0x4C4F4F60
const OUTCOME_DOMAIN = 0x4C4F4F61
const DIRECT_ACCEPT_DOMAIN = 0x4C4F4F62
const HOLDER_FEE_DOMAIN = 0x4C4F4F63

const REASON_BOTH_REVEALED = 1
const REASON_ONLY_REVEALER = 2
const REASON_CANCELLED = 3
const REASON_OFFER_EXPIRED = 4
const REASON_NO_REVEALS = 5

contract DuelEscrow {
    author: "LOOP"
    version: "1.5.0"
    description: "Address-bound TON escrow with a guaranteed boost response window, commit-reveal and holder fee permits"
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
    | OpenDirectOffer
    | AcceptDirectOffer
    | DuelFundReserve
    | DuelWithdrawSurplus
    | DuelSetFee
    | DuelSetTreasury
    | DuelSetOwner
    | BoostDuel

fun validChance(chanceBps: uint16): bool {
    return chanceBps == 2_500 || chanceBps == 5_000 || chanceBps == 7_500;
}

fun stakeFor(totalPool: coins, chanceBps: uint16): coins {
    return mulDivFloor(totalPool, chanceBps, BASIS_POINTS);
}

fun commitmentHash(
    networkId: int32,
    offerId: uint64,
    owner: address,
    secret: uint256,
): uint256 {
    return beginCell()
        .storeUint(COMMITMENT_DOMAIN, 32)
        .storeInt(networkId, 32)
        .storeAddress(contract.getAddress())
        .storeUint(offerId, 64)
        .storeAddress(owner)
        .storeUint(secret, 256)
        .hash();
}

fun holderFeeHash(
    networkId: int32,
    offerId: uint64,
    owner: address,
    validUntil: uint32,
): uint256 {
    return beginCell()
        .storeUint(HOLDER_FEE_DOMAIN, 32)
        .storeInt(networkId, 32)
        .storeAddress(contract.getAddress())
        .storeUint(offerId, 64)
        .storeAddress(owner)
        .storeUint(validUntil, 32)
        .hash();
}

fun directAcceptHash(
    networkId: int32,
    inviteId: uint256,
    counterOfferId: uint64,
    invitedAddress: address,
    validUntil: uint32,
): uint256 {
    return beginCell()
        .storeUint(DIRECT_ACCEPT_DOMAIN, 32)
        .storeInt(networkId, 32)
        .storeAddress(contract.getAddress())
        .storeUint(inviteId, 256)
        .storeUint(counterOfferId, 64)
        .storeAddress(invitedAddress)
        .storeUint(validUntil, 32)
        .hash();
}

fun Storage.verifyHolderPermit(
    self,
    owner: address,
    offerId: uint64,
    holder: Cell<HolderFeePermit>?,
): bool {
    if (holder == null) {
        return false;
    }
    val permit = holder.load();
    assert (permit.validUntil >= blockchain.now()) throw Errors.HolderPermitExpired;
    assert (
        permit.validUntil <= blockchain.now() + MAX_EXPIRY_DELAY
    ) throw Errors.HolderPermitExpired;
    assert (
        isSignatureValid(
            holderFeeHash(self.networkId, offerId, owner, permit.validUntil),
            permit.signature as slice,
            self.inviteSignerPublicKey,
        )
    ) throw Errors.InvalidHolderPermit;
    return true;
}

fun Storage.addOpenOffer(
    mutate self,
    owner: address,
    valueCoins: coins,
    offerId: uint64,
    commitment: uint256,
    chanceBps: uint16,
    totalPool: coins,
    expiresAt: uint32,
    direct: DirectOfferData,
    holder: Cell<HolderFeePermit>?,
): void {
    assert (self.feeBps <= 1_000) throw Errors.InvalidFee;
    assert (offerId != 0) throw Errors.InvalidOfferId;
    assert (validChance(chanceBps)) throw Errors.InvalidChance;
    assert (
        totalPool >= MIN_POOL && totalPool <= MAX_POOL && totalPool % 4 == 0
    ) throw Errors.InvalidPool;
    assert (
        expiresAt >= blockchain.now() + MIN_EXPIRY_DELAY &&
        expiresAt <= blockchain.now() + MAX_EXPIRY_DELAY
    ) throw Errors.InvalidExpiry;
    assert (!self.usedOfferIds.exists(offerId)) throw Errors.OfferAlreadyUsed;
    assert (!self.activeOffers.exists(owner)) throw Errors.OwnerAlreadyActive;

    val feeExempt = self.verifyHolderPermit(owner, offerId, holder);
    val stake = stakeFor(totalPool, chanceBps);
    assert (valueCoins >= stake + OPEN_GAS_BUFFER) throw Errors.InsufficientValue;
    self
        .offers
        .set(
            offerId,
            OfferData {
                owner,
                commitment,
                chanceBps,
                totalPool,
                stake,
                expiresAt,
                state: OFFER_OPEN,
                feeExempt,
                direct: direct.toCell(),
            }.toCell(),
        );
    self.activeOffers.set(owner, offerId);
    self.usedOfferIds.set(offerId, true);
    self.locked += stake;
}

fun Storage.matchOpenOffers(
    mutate self,
    firstOfferId: uint64,
    secondOfferId: uint64,
    allowDirect: bool,
): uint64 {
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

    val firstDirect = first.direct.load();
    val secondDirect = second.direct.load();
    val bothAfk = firstDirect.inviteId == 0 && firstDirect.opponent == null &&
    secondDirect.inviteId == 0 &&
    secondDirect.opponent == null;
    val addressBound = firstDirect.opponent != null && secondDirect.opponent != null &&
    firstDirect.opponent! == second.owner &&
    secondDirect.opponent! == first.owner;
    assert (bothAfk || (allowDirect && addressBound)) throw Errors.IncompatibleOffers;

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
                boostDeadline: blockchain.now() + BOOST_WINDOW,
                hardDeadline: blockchain.now() + BOOST_HARD_WINDOW,
                revealDeadline: blockchain.now() + BOOST_WINDOW + REVEAL_WINDOW,
                boostRevision: 0,
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

fun Storage.withdrawableBalance(self, balance: coins): coins {
    val protectedBalance = self.locked + MIN_CONTRACT_RESERVE;
    return balance > protectedBalance ? balance - protectedBalance : 0;
}

fun Storage.requireOwner(self, sender: address) {
    assert (self.owner == sender) throw Errors.NotOwner;
}

fun sendDuelAdminWithdrawal(
    queryId: uint64,
    treasury: address,
    amount: coins,
) {
    val withdrawal = createMessage({
        bounce: BounceMode.NoBounce,
        dest: treasury,
        value: amount,
        body: DuelAdminWithdrawal { queryId, amount },
    });
    withdrawal.send(SEND_MODE_PAY_FEES_SEPARATELY);
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
    // A verified PLUSH BRICK holder pays no protocol fee on a won duel. The
    // exemption was proven by a signed permit when the offer was opened; it
    // never changes the chance math, only the fee withheld from the winner.
    val fee = winner.feeExempt ? 0 : mulDivFloor(totalPool, self.feeBps, BASIS_POINTS);
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
        .storeInt(self.networkId, 32)
        .storeAddress(contract.getAddress())
        .storeUint(duelId, 64)
        .storeRef(
            beginCell()
                .storeUint(duel.offerAId, 64)
                .storeUint(duel.secretA, 256)
                .storeUint(duel.offerBId, 64)
                .storeUint(duel.secretB, 256)
                .endCell(),
        )
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

fun Storage.boostDuel(
    mutate self,
    sender: address,
    valueCoins: coins,
    duelId: uint64,
    offerId: uint64,
    amount: coins,
    expectedRevision: uint16,
    minChanceBps: uint16,
    validUntil: uint32,
): void {
    assert (!self.paused) throw Errors.Paused;
    var duel = self.loadDuel(duelId);
    // A boost must leave the opponent a full extension to answer in. Without
    // this, alternating boosts could walk the soft deadline up to the hard cap
    // and the last one would land in the same second the window shuts,
    // provably unanswerable. That is value-neutral under proportional stakes,
    // but the product promises a response window, so the contract enforces one
    // instead of the interface explaining its absence.
    assert (
        blockchain.now() <= duel.boostDeadline &&
        blockchain.now() + BOOST_EXTENSION <= duel.hardDeadline
    ) throw Errors.BoostClosed;
    assert (
        blockchain.now() <= validUntil && validUntil <= duel.hardDeadline
    ) throw Errors.InvalidExpiry;
    assert (duel.boostRevision == expectedRevision) throw Errors.StaleBoost;
    assert (amount >= MIN_BOOST) throw Errors.InvalidBoost;
    assert (valueCoins >= amount + OPEN_GAS_BUFFER) throw Errors.InsufficientValue;
    assert (offerId == duel.offerAId || offerId == duel.offerBId) throw Errors.IncompatibleOffers;

    var offerA = self.loadOffer(duel.offerAId);
    var offerB = self.loadOffer(duel.offerBId);
    assert (
        offerA.state == OFFER_MATCHED && offerB.state == OFFER_MATCHED
    ) throw Errors.OfferNotOpen;
    val boostedOffer = offerId == duel.offerAId ? offerA : offerB;
    assert (boostedOffer.owner == sender) throw Errors.NotOwner;

    if (offerId == duel.offerAId) {
        offerA.stake += amount;
    } else {
        offerB.stake += amount;
    }
    val totalPool = offerA.stake + offerB.stake;
    assert (totalPool <= MAX_POOL) throw Errors.InvalidPool;
    val chanceA = mulDivFloor(offerA.stake, BASIS_POINTS, totalPool);
    val chanceB = BASIS_POINTS - chanceA;
    assert (
        chanceA >= MIN_CHANCE_BPS && chanceA <= MAX_CHANCE_BPS && chanceB >= MIN_CHANCE_BPS &&
        chanceB <= MAX_CHANCE_BPS
    ) throw Errors.InvalidBoost;
    val boostedChance = offerId == duel.offerAId ? chanceA : chanceB;
    assert (boostedChance >= minChanceBps) throw Errors.InvalidBoost;

    offerA.chanceBps = chanceA;
    offerB.chanceBps = chanceB;
    offerA.totalPool = totalPool;
    offerB.totalPool = totalPool;
    self.offers.set(duel.offerAId, offerA.toCell());
    self.offers.set(duel.offerBId, offerB.toCell());
    self.locked += amount;

    val extendedDeadline = blockchain.now() + BOOST_EXTENSION;
    if (extendedDeadline > duel.boostDeadline) {
        duel.boostDeadline = extendedDeadline < duel.hardDeadline
            ? extendedDeadline
            : duel.hardDeadline;
        duel.revealDeadline = duel.boostDeadline + REVEAL_WINDOW;
    }
    duel.boostRevision += 1;
    self.duels.set(duelId, duel.toCell());
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);

    match (msg) {
        OpenOffer => {
            var storage = Storage.load();
            assert (!storage.paused) throw Errors.Paused;
            storage.addOpenOffer(
                in.senderAddress,
                in.valueCoins,
                msg.offerId,
                msg.commitment,
                msg.chanceBps,
                msg.totalPool,
                msg.expiresAt,
                DirectOfferData {
                    inviteId: 0,
                    opponent: null,
                },
                msg.holder,
            );

            if (msg.counterOfferId != 0) {
                storage.matchOpenOffers(msg.counterOfferId, msg.offerId, false);
            }
            storage.save();
        }
        OpenDirectOffer => {
            var storage = Storage.load();
            assert (!storage.paused) throw Errors.Paused;
            assert (msg.inviteId != 0) throw Errors.DirectInviteRequired;
            storage.addOpenOffer(
                in.senderAddress,
                in.valueCoins,
                msg.offerId,
                msg.commitment,
                msg.chanceBps,
                msg.totalPool,
                msg.expiresAt,
                DirectOfferData {
                    inviteId: msg.inviteId,
                    opponent: null,
                },
                msg.holder,
            );
            storage.save();
        }
        AcceptDirectOffer => {
            var storage = Storage.load();
            assert (!storage.paused) throw Errors.Paused;
            val acceptance = msg.acceptance.load();
            assert (
                acceptance.validUntil >= blockchain.now() && acceptance.validUntil <= msg.expiresAt
            ) throw Errors.DirectPermitExpired;
            var counter = storage.loadOffer(acceptance.counterOfferId);
            assert (counter.owner != in.senderAddress) throw Errors.SameOwner;
            var counterDirect = counter.direct.load();
            assert (
                counterDirect.inviteId != 0 && counterDirect.opponent == null
            ) throw Errors.DirectInviteRequired;
            val permitHash = directAcceptHash(
                storage.networkId,
                counterDirect.inviteId,
                acceptance.counterOfferId,
                in.senderAddress,
                acceptance.validUntil,
            );
            assert (
                isSignatureValid(
                    permitHash,
                    acceptance.signature as slice,
                    storage.inviteSignerPublicKey,
                )
            ) throw Errors.InvalidDirectPermit;

            storage.addOpenOffer(
                in.senderAddress,
                in.valueCoins,
                msg.offerId,
                msg.commitment,
                msg.chanceBps,
                msg.totalPool,
                msg.expiresAt,
                DirectOfferData {
                    inviteId: 0,
                    opponent: counter.owner,
                },
                msg.holder,
            );
            counterDirect.opponent = in.senderAddress;
            counter.direct = counterDirect.toCell();
            storage.offers.set(acceptance.counterOfferId, counter.toCell());
            storage.matchOpenOffers(acceptance.counterOfferId, msg.offerId, true);
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
            storage.matchOpenOffers(msg.firstOfferId, msg.secondOfferId, false);
            storage.save();
        }
        Reveal => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            var duel = storage.loadDuel(msg.duelId);
            assert (blockchain.now() > duel.boostDeadline) throw Errors.RevealNotOpen;
            assert (blockchain.now() <= duel.revealDeadline) throw Errors.RevealClosed;
            assert (
                msg.offerId == duel.offerAId || msg.offerId == duel.offerBId
            ) throw Errors.WrongRevealer;
            val offer = storage.loadOffer(msg.offerId);
            assert (offer.owner == in.senderAddress) throw Errors.WrongRevealer;
            assert (
                commitmentHash(storage.networkId, msg.offerId, offer.owner, msg.secret) ==
                offer.commitment
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
        BoostDuel => {
            var storage = Storage.load();
            storage.boostDuel(
                in.senderAddress,
                in.valueCoins,
                msg.duelId,
                msg.offerId,
                msg.amount,
                msg.expectedRevision,
                msg.minChanceBps,
                msg.validUntil,
            );
            storage.save();
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
            storage.requireOwner(in.senderAddress);
            storage.paused = msg.paused;
            storage.save();
        }
        DuelFundReserve => {
            val storage = Storage.load();
            storage.requireOwner(in.senderAddress);
            assert (msg.amount > 0) throw Errors.InvalidAdminAmount;
            assert (in.valueCoins >= msg.amount + MIN_CALL_GAS) throw Errors.InsufficientValue;
        }
        DuelWithdrawSurplus => {
            assert (in.valueCoins >= WITHDRAW_GAS_BUFFER) throw Errors.InsufficientValue;
            val originalBalance = contract.getOriginalBalance();
            assert (originalBalance >= in.valueCoins) throw Errors.InsufficientValue;
            val storage = Storage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw Errors.MustBePaused;
            assert (msg.amount > 0) throw Errors.InvalidAdminAmount;
            val balanceBeforeCall = originalBalance - in.valueCoins;
            assert (
                msg.amount <= storage.withdrawableBalance(balanceBeforeCall)
            ) throw Errors.InsufficientSurplus;
            reserveToncoinsOnBalance(
                storage.locked + MIN_CONTRACT_RESERVE,
                RESERVE_MODE_EXACT_AMOUNT,
            );
            sendDuelAdminWithdrawal(msg.queryId, storage.treasury, msg.amount);
        }
        DuelSetFee => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw Errors.MustBePaused;
            assert (storage.locked == 0) throw Errors.ActiveValueLocked;
            assert (msg.feeBps <= 1_000) throw Errors.InvalidFee;
            storage.feeBps = msg.feeBps;
            storage.save();
        }
        DuelSetTreasury => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw Errors.MustBePaused;
            assert (msg.treasury != contract.getAddress()) throw Errors.InvalidTreasury;
            storage.treasury = msg.treasury;
            storage.save();
        }
        DuelSetOwner => {
            assert (in.valueCoins >= MIN_CALL_GAS) throw Errors.InsufficientValue;
            var storage = Storage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw Errors.MustBePaused;
            assert (
                msg.owner != storage.owner && msg.owner != contract.getAddress()
            ) throw Errors.InvalidOwner;
            storage.owner = msg.owner;
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
        networkId: storage.networkId,
        inviteSignerPublicKey: storage.inviteSignerPublicKey,
        contractAddress: contract.getAddress(),
        paused: storage.paused,
        locked: storage.locked,
        holderFeeSupported: true,
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

get fun duelBoostData(duelId: uint64): DuelBoostView {
    val storage = Storage.load();
    val duel = storage.loadDuel(duelId);
    val offerA = storage.loadOffer(duel.offerAId);
    val offerB = storage.loadOffer(duel.offerBId);
    return {
        stakeA: offerA.stake,
        stakeB: offerB.stake,
        chanceABps: offerA.chanceBps,
        chanceBBps: offerB.chanceBps,
        boostDeadline: duel.boostDeadline,
        hardDeadline: duel.hardDeadline,
        revealDeadline: duel.revealDeadline,
        boostRevision: duel.boostRevision,
    };
}

get fun directOfferData(offerId: uint64): DirectOfferData {
    val storage = Storage.load();
    return storage.loadOffer(offerId).direct.load();
}

get fun activeOffer(owner: address): uint64 {
    val storage = Storage.load();
    return storage.activeOffers.mustGet(owner, Errors.OfferMissing);
}

get fun adminState(): DuelAdminStateView {
    val storage = Storage.load();
    return {
        owner: storage.owner,
        treasury: storage.treasury,
        feeBps: storage.feeBps,
        paused: storage.paused,
        locked: storage.locked,
    };
}
