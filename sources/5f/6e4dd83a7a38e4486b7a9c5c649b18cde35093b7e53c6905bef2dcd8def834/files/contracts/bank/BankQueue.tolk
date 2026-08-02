import "errors"
import "messages"
import "storage"

const BANK_BASIS_POINTS = 10_000
const BANK_MIN_PRINCIPAL = 1_000_000_000
const BANK_MAX_PRINCIPAL = 100_000_000_000
// The cap exists for one reason: a single oversized position holds up
// everyone behind it. A position of N GRAM at the x2 target needs about
// 2.2N of later deposits to clear, so N GRAM is unlocked only once the queue
// has actually delivered 5N payouts. That keeps the worst stall one
// participant can impose at roughly half of the history already behind them,
// at every rung.
//
// The top rung is 100 rather than higher because the allocation loop is
// bounded at 81 steps for gas: a deposit large enough to close more than
// eighty minimum positions reverts, and that limit falls at 112 GRAM.
const BANK_COMPLETIONS_PER_GRAM = 5
const BANK_OPEN_GAS_BUFFER = 80_000_000
const BANK_MIN_ADMIN_GAS = 20_000_000
const BANK_WITHDRAW_GAS_BUFFER = 50_000_000
const BANK_MIN_RESERVE = 200_000_000
// At most 80 minimum-size targets can be closed by one maximum-size deposit,
// plus one partially funded position. Keep the loop explicitly bounded for gas safety.
const BANK_MAX_ALLOCATION_STEPS = 81

contract BankQueue {
    author: "LOOP"
    version: "1.4.0"
    description: "FIFO payout cycle for LOOP BANK with maturity-based principal limits and pruned settled positions"
    storage: BankStorage
    incomingMessages: BankAllowedMessage
}

type BankAllowedMessage =
    | CreatePosition
    | SetBankPaused
    | BankFundReserve
    | BankWithdrawSurplus
    | BankSetFee
    | BankSetTreasury
    | BankSetOwner
    | BankRefundPosition

fun validMultiplier(multiplierBps: uint16): bool {
    return multiplierBps == 12_500 || multiplierBps == 15_000 || multiplierBps == 20_000;
}

/// Rungs in whole GRAM. Round numbers people can hold in their head, spaced
/// so each step is a believable next move rather than a jump.
fun ladderRung(index: int): int {
    if (index == 0) { return 1; }
    if (index == 1) { return 2; }
    if (index == 2) { return 3; }
    if (index == 3) { return 5; }
    if (index == 4) { return 7; }
    if (index == 5) { return 10; }
    if (index == 6) { return 15; }
    if (index == 7) { return 20; }
    if (index == 8) { return 30; }
    if (index == 9) { return 50; }
    if (index == 10) { return 75; }
    return 100;
}

const BANK_LADDER_RUNGS = 12

fun BankStorage.principalLimit(self): coins {
    // The rungs only ever rise, so the highest one the queue has earned is the
    // answer; walking all of them costs a fixed twelve comparisons and avoids
    // an early exit, which Tolk does not offer.
    var limit = ladderRung(0);
    var index = 1;
    while (index < BANK_LADDER_RUNGS) {
        val rung = ladderRung(index);
        if (self.completedPositions >= rung * BANK_COMPLETIONS_PER_GRAM) {
            limit = rung;
        }
        index += 1;
    }
    return limit * 1_000_000_000;
}

fun sendBankPayout(
    queryId: uint64,
    positionId: uint64,
    position: BankPositionData,
) {
    val payout = createMessage({
        bounce: BounceMode.NoBounce,
        dest: position.owner,
        value: position.targetPayout,
        body: BankPayout {
            queryId,
            positionId,
            principal: position.principal,
            targetPayout: position.targetPayout,
        },
    });
    payout.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sendBankFee(queryId: uint64, positionId: uint64, treasury: address, fee: coins) {
    if (fee > 0) {
        val feeMessage = createMessage({
            bounce: BounceMode.NoBounce,
            dest: treasury,
            value: fee,
            body: BankProtocolFee { queryId, positionId },
        });
        feeMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
}

fun sendBankRefund(queryId: uint64, positionId: uint64, owner: address, amount: coins) {
    val refund = createMessage({
        bounce: BounceMode.NoBounce,
        dest: owner,
        value: amount,
        body: BankRefund { queryId, positionId, amount },
    });
    refund.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

/// The owner may withdraw the whole balance, including funding already
/// collected for people still in the queue. That is a deliberate choice by the
/// operator, made in the open: this contract is source-verified, so anyone can
/// read it here before deciding to take part.
///
/// Only the storage floor is held back, and not as a protection — a contract
/// that cannot pay for its own gas stops answering and would strand the queue
/// far worse than any withdrawal.
fun BankStorage.withdrawableBalance(self, balance: coins): coins {
    return balance > BANK_MIN_RESERVE ? balance - BANK_MIN_RESERVE : 0;
}

fun BankStorage.requireOwner(self, sender: address) {
    assert (self.owner == sender) throw BankErrors.NotOwner;
}

fun sendBankAdminWithdrawal(
    queryId: uint64,
    treasury: address,
    amount: coins,
) {
    val withdrawal = createMessage({
        bounce: BounceMode.NoBounce,
        dest: treasury,
        value: amount,
        body: BankAdminWithdrawal { queryId, amount },
    });
    withdrawal.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun BankStorage.allocateDeposit(mutate self, queryId: uint64, available: coins): coins {
    var remaining = available;
    var steps = 0;
    while (
        remaining > 0 && self.headQueueIndex < self.nextQueueIndex && steps <
        BANK_MAX_ALLOCATION_STEPS
    ) {
        val positionId = self
            .queue
            .mustGet(
                self.headQueueIndex,
                BankErrors.PositionMissing,
            );
        var position = self.loadPosition(positionId);
        val needed = position.targetPayout - position.fundedAmount;
        val allocation = remaining < needed ? remaining : needed;

        position.fundedAmount += allocation;
        self.lockedFunding += allocation;
        remaining -= allocation;

        if (position.fundedAmount == position.targetPayout) {
            position.status = BANK_POSITION_PAYOUT_SENT;
            position.completedAt = blockchain.now();
            self.lockedFunding -= position.targetPayout;
            self.activePositions.delete(position.owner);
            // A settled position is dropped instead of retained. Keeping every
            // completed record made the hot dictionary grow with lifetime
            // history, so each allocation step in a cascade paid more gas the
            // older the contract got. Replay protection stays with
            // usedPositionIds, which is touched once per deposit rather than
            // once per step, and the payout message remains the public proof.
            self.positions.delete(positionId);
            self.queue.delete(self.headQueueIndex);
            self.headQueueIndex += 1;
            self.completedPositions += 1;
            sendBankPayout(queryId, positionId, position);
        } else {
            position.status = BANK_POSITION_PARTIALLY_FUNDED;
            self.positions.set(positionId, position.toCell());
        }
        steps += 1;
    }
    assert (
        remaining == 0 || self.headQueueIndex == self.nextQueueIndex
    ) throw BankErrors.AllocationLimit;
    return remaining;
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy BankAllowedMessage.fromSlice(in.body);

    match (msg) {
        CreatePosition => {
            var storage = BankStorage.load();
            assert (!storage.paused) throw BankErrors.Paused;
            assert (storage.feeBps <= 1_000) throw BankErrors.InvalidFee;
            assert (msg.positionId != 0) throw BankErrors.PositionAlreadyUsed;
            assert (
                !storage.usedPositionIds.exists(msg.positionId)
            ) throw BankErrors.PositionAlreadyUsed;
            assert (
                !storage.activePositions.exists(in.senderAddress)
            ) throw BankErrors.OwnerAlreadyActive;
            assert (
                msg.principal >= BANK_MIN_PRINCIPAL && msg.principal <= storage.principalLimit()
            ) throw BankErrors.InvalidPrincipal;
            assert (validMultiplier(msg.multiplierBps)) throw BankErrors.InvalidMultiplier;
            assert (
                in.valueCoins >= msg.principal + BANK_OPEN_GAS_BUFFER
            ) throw BankErrors.InsufficientValue;

            val fee = mulDivFloor(msg.principal, storage.feeBps, BANK_BASIS_POINTS);
            val distributable = msg.principal - fee;
            val unallocated = storage.allocateDeposit(msg.queryId, distributable);

            val queueIndex = storage.nextQueueIndex;
            val targetPayout = mulDivFloor(
                msg.principal,
                msg.multiplierBps,
                BANK_BASIS_POINTS,
            );
            // Older positions always have priority. If they do not consume the
            // whole deposit, the remainder becomes the new position's initial
            // funding instead of leaving the user cycle as protocol reserve.
            storage.lockedFunding += unallocated;
            val position = BankPositionData {
                owner: in.senderAddress,
                principal: msg.principal,
                multiplierBps: msg.multiplierBps,
                targetPayout,
                fundedAmount: unallocated,
                queueIndex,
                createdAt: blockchain.now(),
                completedAt: 0,
                status: unallocated > 0 ? BANK_POSITION_PARTIALLY_FUNDED : BANK_POSITION_QUEUED,
            };
            storage.positions.set(msg.positionId, position.toCell());
            storage.queue.set(queueIndex, msg.positionId);
            storage.activePositions.set(in.senderAddress, msg.positionId);
            storage.usedPositionIds.set(msg.positionId, true);
            storage.nextQueueIndex += 1;
            storage.save();
            sendBankFee(msg.queryId, msg.positionId, storage.treasury, fee);
        }
        SetBankPaused => {
            assert (in.valueCoins >= BANK_MIN_ADMIN_GAS) throw BankErrors.InsufficientValue;
            var storage = BankStorage.load();
            storage.requireOwner(in.senderAddress);
            storage.paused = msg.paused;
            storage.save();
        }
        BankFundReserve => {
            val storage = BankStorage.load();
            storage.requireOwner(in.senderAddress);
            assert (msg.amount > 0) throw BankErrors.InvalidAdminAmount;
            assert (
                in.valueCoins >= msg.amount + BANK_MIN_ADMIN_GAS
            ) throw BankErrors.InsufficientValue;
        }
        BankWithdrawSurplus => {
            assert (in.valueCoins >= BANK_WITHDRAW_GAS_BUFFER) throw BankErrors.InsufficientValue;
            val originalBalance = contract.getOriginalBalance();
            assert (originalBalance >= in.valueCoins) throw BankErrors.InsufficientValue;
            val storage = BankStorage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw BankErrors.MustBePaused;
            assert (msg.amount > 0) throw BankErrors.InvalidAdminAmount;
            val balanceBeforeCall = originalBalance - in.valueCoins;
            assert (
                msg.amount <= storage.withdrawableBalance(balanceBeforeCall)
            ) throw BankErrors.InsufficientSurplus;
            reserveToncoinsOnBalance(BANK_MIN_RESERVE, RESERVE_MODE_EXACT_AMOUNT);
            sendBankAdminWithdrawal(msg.queryId, storage.treasury, msg.amount);
        }
        BankRefundPosition => {
            // Winding a queue down used to strand whatever had been collected
            // for the people still waiting: allocated funding only ever left
            // as a completed payout, so a queue that stopped moving held their
            // money for good. This returns it — to them, never to the owner,
            // and only while the queue is stopped.
            var storage = BankStorage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw BankErrors.MustBePaused;
            val position = storage.loadPosition(msg.positionId);
            assert (position.fundedAmount > 0) throw BankErrors.NothingToRefund;
            val amount = position.fundedAmount;
            storage.lockedFunding -= amount;
            storage.activePositions.delete(position.owner);
            storage.positions.delete(msg.positionId);
            storage.queue.delete(position.queueIndex);
            if (storage.headQueueIndex == position.queueIndex) {
                storage.headQueueIndex += 1;
            }
            storage.save();
            sendBankRefund(msg.queryId, msg.positionId, position.owner, amount);
        }
        BankSetFee => {
            assert (in.valueCoins >= BANK_MIN_ADMIN_GAS) throw BankErrors.InsufficientValue;
            var storage = BankStorage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw BankErrors.MustBePaused;
            assert (msg.feeBps <= 1_000) throw BankErrors.InvalidFee;
            storage.feeBps = msg.feeBps;
            storage.save();
        }
        BankSetTreasury => {
            assert (in.valueCoins >= BANK_MIN_ADMIN_GAS) throw BankErrors.InsufficientValue;
            var storage = BankStorage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw BankErrors.MustBePaused;
            assert (msg.treasury != contract.getAddress()) throw BankErrors.InvalidTreasury;
            storage.treasury = msg.treasury;
            storage.save();
        }
        BankSetOwner => {
            assert (in.valueCoins >= BANK_MIN_ADMIN_GAS) throw BankErrors.InsufficientValue;
            var storage = BankStorage.load();
            storage.requireOwner(in.senderAddress);
            assert (storage.paused) throw BankErrors.MustBePaused;
            assert (
                msg.owner != storage.owner && msg.owner != contract.getAddress()
            ) throw BankErrors.InvalidOwner;
            storage.owner = msg.owner;
            storage.save();
        }
        else => {
            assert (in.body.isEmpty()) throw BankErrors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(_in: InMessageBounced) {}

get fun contractConfig(): BankContractConfigView {
    val storage = BankStorage.load();
    return {
        owner: storage.owner,
        treasury: storage.treasury,
        feeBps: storage.feeBps,
        paused: storage.paused,
        headQueueIndex: storage.headQueueIndex,
        nextQueueIndex: storage.nextQueueIndex,
        completedPositions: storage.completedPositions,
        principalLimit: storage.principalLimit(),
        lockedFunding: storage.lockedFunding,
    };
}

get fun queueData(): BankQueueView {
    val storage = BankStorage.load();
    return {
        headQueueIndex: storage.headQueueIndex,
        nextQueueIndex: storage.nextQueueIndex,
        openPositions: storage.nextQueueIndex - storage.headQueueIndex,
        completedPositions: storage.completedPositions,
        principalLimit: storage.principalLimit(),
    };
}

get fun positionData(positionId: uint64): BankPositionData {
    val storage = BankStorage.load();
    return storage.loadPosition(positionId);
}

get fun activePosition(owner: address): uint64 {
    val storage = BankStorage.load();
    return storage.activePositions.mustGet(owner, BankErrors.PositionMissing);
}

get fun adminState(): BankAdminStateView {
    val storage = BankStorage.load();
    return {
        owner: storage.owner,
        treasury: storage.treasury,
        feeBps: storage.feeBps,
        paused: storage.paused,
        completedPositions: storage.completedPositions,
        principalLimit: storage.principalLimit(),
        lockedFunding: storage.lockedFunding,
    };
}
