// SPDX-License-Identifier: MIT

// Permanent immutable DOSGRAM draw Core. Round contracts are deterministic
// children derived from code cells pinned in this contract's state. No sender
// can replace the Quicknet verifier, collective key, selected beacon, root, or
// winner after the round has been sealed.

import "drand_quicknet_verifier.tolk";

const OP_SEAL_ROUND = 0x44534541;       // "DSEA" Round -> Draw Core
const OP_SEAL_ACK = 0x44534143;         // "DSAC" Draw Core -> Round
const OP_SUBMIT_DRAND = 0x4452414E;     // "DRAN" permissionless
const OP_DRAW_RESULT = 0x44524557;      // "DREW" Draw Core -> Round
const OP_RETRY_RESULT = 0x44525452;     // "DRTR" permissionless
const OP_DRAW_ACK = 0x4441434B;         // "DACK" Round -> Draw Core
const OP_ACCRUAL_ACK = 0x44414353;      // "DACS" Draw Core -> Round
const OP_MARK_REFUNDABLE = 0x52454644;  // "REFD" permissionless
const OP_REFUNDABLE = 0x44524644;       // "DRFD" Draw Core -> Round
const OP_REFUND_ACK = 0x44524143;       // "DRAC" Round -> Draw Core
const OP_WITHDRAW_PLATFORM = 0x44505744; // "DPWD" either pinned admin
const OP_CONFIGURE_NEXT = 0x444E5854;   // "DNXT" either pinned admin

const STATUS_CONFIGURED = 0;
const STATUS_RANDOMNESS_PENDING = 1;
const STATUS_PROOF_VERIFIED = 2;
const STATUS_REFUNDABLE = 3;
const STATUS_PAID = 4;

const PROOF_TIMEOUT = 259200; // 72 hours
const TOTAL_COMMISSION_BPS = 1000;
const MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
const MAIN_DOMAIN = 0x444F534752414D5F4D41494E5F5631;   // "DOSGRAM_MAIN_V1"
const BONUS_DOMAIN = 0x444F534752414D5F424F4E55535F5631; // "DOSGRAM_BONUS_V1"
const CALLBACK_GAS = 25000000;
const ACCRUAL_ACK_GAS = 5000000;
const RETRY_MIN_VALUE = 35000000;

struct DrawState {
    roundId: int;
    nanoPerGram: int;
    status: int;
    capacity: int;
    rewardBps: int;
    platformBps: int;
    bonusActive: bool;
    refundAcknowledged: bool;
    bonusPrize: coins;
    sealedAt: int;
    targetRound: int;
    roundRoot: int;
    randomness: int;
    winnerIndex: int;
    bonusWinnerIndex: int;
    bonusPool: coins;
    platformPool: coins;
    adminHot: address;
    adminRecovery: address;
    roundCode: cell;
    vaultCode: cell;
    boardCode: cell;
    history: map<uint64, cell>;
}

@inline
fun unixTime(): int
    asm "NOW";

@inline
fun ownAddress(): slice
    asm "MYADDR";

@inline
fun cellHash(value: cell): int
    asm "HASHCU";

@inline
fun sha256Draw(a: builder, b: builder, c: builder, d: builder): int
    asm "4 PUSHINT HASHEXT_SHA256";

fun loadState(): DrawState {
    var data = contract.getData().beginParse();
    var codes = data.loadRef().beginParse();
    var financials = data.loadRef().beginParse();
    var historyData = data.loadRef().beginParse();
    val state = DrawState {
        roundId: data.loadUint(64),
        nanoPerGram: data.loadUint(64),
        status: data.loadUint(3),
        capacity: data.loadUint(16),
        rewardBps: data.loadUint(14),
        platformBps: data.loadUint(14),
        bonusActive: data.loadBool(),
        refundAcknowledged: data.loadBool(),
        bonusPrize: data.loadCoins(),
        sealedAt: data.loadUint(64),
        targetRound: data.loadUint(64),
        roundRoot: data.loadUint(256),
        randomness: data.loadUint(256),
        winnerIndex: data.loadUint(32),
        bonusWinnerIndex: data.loadUint(32),
        bonusPool: financials.loadCoins(),
        platformPool: financials.loadCoins(),
        adminHot: codes.loadAddress(),
        adminRecovery: codes.loadAddress(),
        roundCode: codes.loadRef(),
        vaultCode: codes.loadRef(),
        boardCode: codes.loadRef(),
        history: createMapFromLowLevelDict<uint64, cell>(historyData.loadDict()),
    };
    codes.assertEnd();
    financials.assertEnd();
    historyData.assertEnd();
    data.assertEnd();
    assert (state.rewardBps + state.platformBps == TOTAL_COMMISSION_BPS) throw 600;
    assert (state.capacity > 0 && state.capacity <= 1000) throw 601;
    assert (
        state.nanoPerGram > 0
        && (state.nanoPerGram * state.rewardBps) % 10000 == 0
        && (state.nanoPerGram * state.platformBps) % 10000 == 0
    ) throw 617;
    return state;
}

fun saveState(state: DrawState) {
    contract.setData(
        beginCell()
            .storeUint(state.roundId, 64)
            .storeUint(state.nanoPerGram, 64)
            .storeUint(state.status, 3)
            .storeUint(state.capacity, 16)
            .storeUint(state.rewardBps, 14)
            .storeUint(state.platformBps, 14)
            .storeBool(state.bonusActive)
            .storeBool(state.refundAcknowledged)
            .storeCoins(state.bonusPrize)
            .storeUint(state.sealedAt, 64)
            .storeUint(state.targetRound, 64)
            .storeUint(state.roundRoot, 256)
            .storeUint(state.randomness, 256)
            .storeUint(state.winnerIndex, 32)
            .storeUint(state.bonusWinnerIndex, 32)
            .storeRef(
                beginCell()
                    .storeAddress(state.adminHot)
                    .storeAddress(state.adminRecovery)
                    .storeRef(state.roundCode)
                    .storeRef(state.vaultCode)
                    .storeRef(state.boardCode)
                    .endCell()
            )
            .storeRef(
                beginCell()
                    .storeCoins(state.bonusPool)
                    .storeCoins(state.platformPool)
                    .endCell()
            )
            .storeRef(beginCell().storeDict(state.history.toLowLevelDict()).endCell())
            .endCell(),
    );
}

fun emptyVaultPlan(): cell {
    val emptyPlan: map<uint16, cell> = [];
    return beginCell().storeDict(emptyPlan.toLowLevelDict()).endCell();
}

fun initialBoardData(state: DrawState, round: address): cell {
    val owners: map<uint16, address> = [];
    val receipts: map<address, cell> = [];
    val referrers: map<address, address> = [];
    val referralLocked: map<address, uint8> = [];
    val referralUnits: map<address, uint32> = [];
    return beginCell()
        .storeAddress(round)
        .storeUint(state.roundId, 64)
        .storeUint(state.nanoPerGram, 64)
        .storeUint(state.capacity, 16)
        .storeUint(0, 16)
        .storeUint(0, 32)
        .storeBool(false)
        .storeUint(0, 32)
        .storeRef(state.vaultCode)
        .storeRef(
            beginCell()
                .storeDict(owners.toLowLevelDict())
                .storeDict(receipts.toLowLevelDict())
                .storeDict(referrers.toLowLevelDict())
                .endCell()
        )
        .storeRef(
            beginCell()
                .storeDict(referralLocked.toLowLevelDict())
                .storeDict(referralUnits.toLowLevelDict())
                .endCell()
        )
        .endCell();
}

fun initialRoundData(state: DrawState): cell {
    val refunds: map<address, uint64> = [];
    val rewardUnits: map<address, uint32> = [];
    return beginCell()
        .storeUint(state.roundId, 64)
        .storeUint(state.nanoPerGram, 64)
        .storeUint(0, 3)
        .storeUint(0, 32)
        .storeUint(0, 32)
        .storeUint(0, 32)
        .storeUint(state.rewardBps, 14)
        .storeUint(state.platformBps, 14)
        .storeUint(state.capacity, 16)
        .storeUint(0, 32)
        .storeAddress(contract.getAddress())
        .storeRef(
            beginCell()
                .storeUint(0, 256)
                .storeUint(0, 64)
                .storeUint(0, 64)
                .storeUint(0, 256)
                .storeUint(0, 32)
                .storeUint(0, 32)
                .endCell()
        )
        .storeRef(
            beginCell()
                .storeCoins(0)
                .storeCoins(0)
                .storeCoins(0)
                .storeCoins(0)
                .storeCoins(state.bonusPrize)
                .endCell()
        )
        .storeRef(beginCell().storeRef(state.vaultCode).storeRef(state.boardCode).endCell())
        .storeRef(
            beginCell()
                .storeDict(refunds.toLowLevelDict())
                .storeDict(rewardUnits.toLowLevelDict())
                .endCell()
        )
        .endCell();
}

fun expectedRound(state: DrawState): address {
    return AutoDeployAddress {
        workchain: contract.getAddress().getWorkchain(),
        stateInit: ContractState {
            code: state.roundCode,
            data: initialRoundData(state),
        },
    }.calculateAddress();
}

fun roundReceipt(state: DrawState): cell {
    return beginCell()
        .storeAddress(expectedRound(state))
        .storeUint(state.status, 3)
        .storeUint(state.capacity, 16)
        .storeUint(state.rewardBps, 14)
        .storeUint(state.platformBps, 14)
        .storeBool(state.bonusActive)
        .storeCoins(state.bonusPrize)
        .storeRef(
            beginCell()
                .storeUint(state.roundRoot, 256)
                .storeUint(state.sealedAt, 64)
                .storeUint(state.targetRound, 64)
                .storeUint(state.randomness, 256)
                .storeUint(state.winnerIndex, 32)
                .storeUint(state.bonusWinnerIndex, 32)
                .endCell()
        )
        .endCell();
}

fun ownAddressHash(): int {
    return cellHash(beginCell().storeSlice(ownAddress()).endCell());
}

fun drawCandidate(
    state: DrawState,
    domain: int,
    domainBits: int,
    randomness: int,
    counter: int,
): int {
    return sha256Draw(
        beginCell().storeUint(domain, domainBits),
        beginCell().storeUint(randomness, 256).storeUint(state.roundId, 64),
        beginCell().storeUint(ownAddressHash(), 256),
        beginCell().storeUint(state.roundRoot, 256).storeUint(counter, 32),
    );
}

fun winnerFor(state: DrawState, domain: int, domainBits: int, randomness: int): int {
    val rejectedTail = ((MAX_UINT256 % state.capacity) + 1) % state.capacity;
    val largestAccepted = MAX_UINT256 - rejectedTail;
    var counter = 0;
    var candidate = drawCandidate(state, domain, domainBits, randomness, counter);
    while (candidate > largestAccepted) {
        counter += 1;
        candidate = drawCandidate(state, domain, domainBits, randomness, counter);
    }
    return candidate % state.capacity;
}

fun sendSealAck(state: DrawState) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: CALLBACK_GAS,
        dest: expectedRound(state),
        body: beginCell()
            .storeUint(OP_SEAL_ACK, 32)
            .storeUint(state.roundId, 64)
            .storeUint(state.roundRoot, 256)
            .storeUint(state.sealedAt, 64)
            .storeUint(state.targetRound, 64)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sendResult(state: DrawState) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: state.bonusPrize + CALLBACK_GAS,
        dest: expectedRound(state),
        body: beginCell()
            .storeUint(OP_DRAW_RESULT, 32)
            .storeUint(state.roundId, 64)
            .storeUint(state.roundRoot, 256)
            .storeUint(state.targetRound, 64)
            .storeUint(state.randomness, 256)
            .storeUint(state.winnerIndex, 32)
            .storeBool(state.bonusActive)
            .storeUint(state.bonusWinnerIndex, 32)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sendRefundable(state: DrawState) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: CALLBACK_GAS,
        dest: expectedRound(state),
        body: beginCell()
            .storeUint(OP_REFUNDABLE, 32)
            .storeUint(state.roundId, 64)
            .storeUint(state.roundRoot, 256)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun sealRound(state: DrawState, sender: address, body: slice): DrawState {
    val roundId = body.loadUint(64);
    val capacity = body.loadUint(16);
    val roundRoot = body.loadUint(256);
    body.assertEnd();
    assert (sender == expectedRound(state)) throw 602;
    assert (roundId == state.roundId && capacity == state.capacity && roundRoot != 0) throw 603;
    if (state.status == STATUS_RANDOMNESS_PENDING) {
        assert (roundRoot == state.roundRoot) throw 604;
        sendSealAck(state);
        return state;
    }
    assert (state.status == STATUS_CONFIGURED) throw 604;
    state.roundRoot = roundRoot;
    state.sealedAt = unixTime();
    state.targetRound = roundForSealTime(state.sealedAt);
    state.status = STATUS_RANDOMNESS_PENDING;
    sendSealAck(state);
    return state;
}

fun submitDrand(state: DrawState, valueCoins: coins, body: slice): DrawState {
    val round = body.loadUint(64);
    val signature = body.loadRef();
    val witness = body.loadRef();
    body.assertEnd();
    assert (state.status == STATUS_RANDOMNESS_PENDING) throw 605;
    assert (round == state.targetRound) throw 606;
    assert (unixTime() >= state.sealedAt + CEREMONY_DELAY) throw 607;
    val randomness = verifyQuicknet(round, signature, witness);
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    assert (balanceBeforeMessage >= state.bonusPrize) throw 618;
    reserveToncoinsOnBalance(
        balanceBeforeMessage - state.bonusPrize,
        RESERVE_MODE_EXACT_AMOUNT,
    );
    state.randomness = randomness;
    state.winnerIndex = winnerFor(state, MAIN_DOMAIN, 120, randomness);
    state.bonusWinnerIndex = state.bonusActive
        ? winnerFor(state, BONUS_DOMAIN, 128, randomness)
        : 0;
    state.status = STATUS_PROOF_VERIFIED;
    sendResult(state);
    return state;
}

fun markRefundable(state: DrawState): DrawState {
    assert (state.status == STATUS_RANDOMNESS_PENDING) throw 605;
    assert (unixTime() >= state.sealedAt + PROOF_TIMEOUT) throw 608;
    state.status = STATUS_REFUNDABLE;
    state.refundAcknowledged = false;
    sendRefundable(state);
    return state;
}

fun applyRefundAck(state: DrawState, sender: address, body: slice): DrawState {
    val roundId = body.loadUint(64);
    val root = body.loadUint(256);
    body.assertEnd();
    assert (sender == expectedRound(state) && state.status == STATUS_REFUNDABLE) throw 619;
    assert (roundId == state.roundId && root == state.roundRoot) throw 620;
    state.refundAcknowledged = true;
    return state;
}

fun configureNext(state: DrawState, sender: address, body: slice): DrawState {
    val nextRoundId = body.loadUint(64);
    val capacity = body.loadUint(16);
    val rewardBps = body.loadUint(14);
    val platformBps = body.loadUint(14);
    val useBonusPool = body.loadBool();
    body.assertEnd();
    assert (sender == state.adminHot || sender == state.adminRecovery) throw 614;
    assert (
        state.status == STATUS_PAID
        || (state.status == STATUS_REFUNDABLE && state.refundAcknowledged)
    ) throw 621;
    assert (
        nextRoundId == state.roundId + 1
        && capacity > 0
        && capacity <= 1000
        && rewardBps + platformBps == TOTAL_COMMISSION_BPS
        && (state.nanoPerGram * rewardBps) % 10000 == 0
        && (state.nanoPerGram * platformBps) % 10000 == 0
    ) throw 622;
    assert (!state.history.exists(state.roundId)) throw 623;
    state.history.set(state.roundId, roundReceipt(state));

    if (state.status == STATUS_REFUNDABLE && state.bonusPrize > 0) {
        state.bonusPool += state.bonusPrize;
    }
    var nextBonusPrize = 0 as coins;
    if (useBonusPool) {
        assert (state.bonusPool > 0) throw 624;
        nextBonusPrize = state.bonusPool;
        state.bonusPool = 0;
    }
    state.roundId = nextRoundId;
    state.status = STATUS_CONFIGURED;
    state.capacity = capacity;
    state.rewardBps = rewardBps;
    state.platformBps = platformBps;
    state.bonusActive = nextBonusPrize > 0;
    state.refundAcknowledged = false;
    state.bonusPrize = nextBonusPrize;
    state.sealedAt = 0;
    state.targetRound = 0;
    state.roundRoot = 0;
    state.randomness = 0;
    state.winnerIndex = 0;
    state.bonusWinnerIndex = 0;
    return state;
}

fun applyDrawAck(
    state: DrawState,
    sender: address,
    valueCoins: coins,
    body: slice,
): DrawState {
    val roundId = body.loadUint(64);
    val bonusAmount = body.loadCoins();
    val platformAmount = body.loadCoins();
    body.assertEnd();
    assert (sender == expectedRound(state)) throw 612;
    assert (roundId == state.roundId) throw 613;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    if (state.status == STATUS_PROOF_VERIFIED) {
        assert (valueCoins >= bonusAmount + platformAmount) throw 613;
        state.bonusPool += bonusAmount;
        state.platformPool += platformAmount;
        state.status = STATUS_PAID;
        reserveToncoinsOnBalance(
            balanceBeforeMessage + bonusAmount + platformAmount,
            RESERVE_MODE_EXACT_AMOUNT,
        );
    } else {
        assert (state.status == STATUS_PAID) throw 610;
        reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    }
    createMessage({
        bounce: BounceMode.RichBounce,
        value: ACCRUAL_ACK_GAS,
        dest: sender,
        body: beginCell()
            .storeUint(OP_ACCRUAL_ACK, 32)
            .storeUint(roundId, 64)
            .storeCoins(bonusAmount)
            .storeCoins(platformAmount)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
    return state;
}

fun withdrawPlatform(
    state: DrawState,
    sender: address,
    valueCoins: coins,
    body: slice,
): DrawState {
    body.assertEnd();
    assert (sender == state.adminHot || sender == state.adminRecovery) throw 614;
    assert (state.platformPool > 0 && valueCoins >= 10000000) throw 615;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    assert (balanceBeforeMessage >= state.platformPool) throw 616;
    reserveToncoinsOnBalance(
        balanceBeforeMessage - state.platformPool,
        RESERVE_MODE_EXACT_AMOUNT,
    );
    state.platformPool = 0;
    createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: sender })
        .send(SEND_MODE_CARRY_ALL_BALANCE);
    return state;
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }
    val balanceBeforeMessage = contract.getOriginalBalance() - in.valueCoins;
    var state = loadState();
    var body = in.body;
    val op = body.loadUint(32);
    // Every public/authenticated operation except an admin withdrawal may
    // spend only its inbound value. Existing protocol balances are reserved.
    if (
        op != OP_WITHDRAW_PLATFORM
        && op != OP_DRAW_ACK
        && op != OP_SUBMIT_DRAND
        && op != OP_RETRY_RESULT
    ) {
        reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    }
    if (op == OP_SEAL_ROUND) {
        state = sealRound(state, in.senderAddress, body);
    } else if (op == OP_SUBMIT_DRAND) {
        state = submitDrand(state, in.valueCoins, body);
    } else if (op == OP_RETRY_RESULT) {
        body.assertEnd();
        assert (in.valueCoins >= RETRY_MIN_VALUE) throw 611;
        if (state.status == STATUS_RANDOMNESS_PENDING) {
            reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
            sendSealAck(state);
        } else if (state.status == STATUS_PROOF_VERIFIED) {
            assert (balanceBeforeMessage >= state.bonusPrize) throw 618;
            reserveToncoinsOnBalance(
                balanceBeforeMessage - state.bonusPrize,
                RESERVE_MODE_EXACT_AMOUNT,
            );
            sendResult(state);
        } else if (state.status == STATUS_REFUNDABLE) {
            reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
            sendRefundable(state);
        } else {
            throw 609;
        }
    } else if (op == OP_DRAW_ACK) {
        state = applyDrawAck(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_MARK_REFUNDABLE) {
        body.assertEnd();
        state = markRefundable(state);
    } else if (op == OP_REFUND_ACK) {
        state = applyRefundAck(state, in.senderAddress, body);
    } else if (op == OP_WITHDRAW_PLATFORM) {
        state = withdrawPlatform(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_CONFIGURE_NEXT) {
        state = configureNext(state, in.senderAddress, body);
    } else {
        throw 0xFFFF;
    }
    saveState(state);
}

fun onBouncedMessage(in: InMessageBounced) {
    // State remains authoritative and retryable. Any account may call DRTR
    // with fresh gas; no result or target can be changed by the retry.
    return;
}

get fun pending_randomness(): (int, int, int, int, int, int, int, bool) {
    val state = loadState();
    val refundableAt = state.sealedAt > 0 ? state.sealedAt + PROOF_TIMEOUT : 0;
    return (
        state.roundId,
        state.status,
        state.targetRound,
        state.sealedAt,
        refundableAt,
        state.roundRoot,
        state.capacity,
        state.refundAcknowledged,
    );
}

get fun proof_receipt(): (int, int, int, int, int, int, int, int, bool) {
    val state = loadState();
    return (
        state.roundId,
        state.status,
        state.targetRound,
        state.randomness,
        state.winnerIndex,
        state.bonusWinnerIndex,
        state.roundRoot,
        state.sealedAt,
        state.bonusActive,
    );
}

get fun configured_round(): (address, int, int, int, int, bool, coins) {
    val state = loadState();
    return (
        expectedRound(state),
        state.roundId,
        state.capacity,
        state.rewardBps,
        state.platformBps,
        state.bonusActive,
        state.bonusPrize,
    );
}

get fun protocol_constants(): (int, int, int, int, int) {
    return (QUICKNET_GENESIS, QUICKNET_PERIOD, CEREMONY_DELAY, PROOF_TIMEOUT, 1000);
}

get fun accrued_pools(): (coins, coins) {
    val state = loadState();
    return (state.bonusPool, state.platformPool);
}

get fun round_receipt(roundId: int): cell {
    val state = loadState();
    if (roundId == state.roundId) {
        return roundReceipt(state);
    }
    return state.history.mustGet(roundId, 625);
}
