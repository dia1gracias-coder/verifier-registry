// SPDX-License-Identifier: MIT

// DOSGRAM round monetary Core. It accepts purchases/refunds only from the
// deterministic Vault code fixed in immutable state. Placement ownership is
// held by the Board. The permanent Draw Core is the only contract allowed to
// supply a winner, and that Draw Core verifies the immutable Quicknet proof.

const OP_PURCHASE_AND_PLACE = 0x44425559; // "DBUY" Vault -> Core
const OP_BOARD_PURCHASE_AND_PLACE = 0x44505552; // "DPUR" Core -> Board
const OP_REFUND = 0x44465246;             // "DFRF" Vault -> Core
const OP_TIMEOUT_REFUND = 0x44544652;     // "DTFR" Vault -> Core, only refundable round
const OP_AVAILABLE_REFUND = 0x44415652;   // "DAVR" Vault -> Core, only paid round
const OP_REFUND_RESULT = 0x44465253;      // "DFRS" Core -> Vault
const OP_TIMEOUT_REFUND_RESULT = 0x44544653;   // "DTFS" Core -> Vault
const OP_AVAILABLE_REFUND_RESULT = 0x44415653; // "DAVS" Core -> Vault
const OP_REFUND_RECEIPT_ACK = 0x4452414B; // "DRAK" Vault -> Core
const OP_ROUTE_FAILED = 0x44464149;       // "DFAI" Core -> Vault
const OP_BOARD_SEALED = 0x44425345;       // "DBSE" Board -> Core
const OP_SEAL_ROUND = 0x44534541;         // "DSEA" Core -> Draw Core
const OP_SEAL_ACK = 0x44534143;           // "DSAC" Draw Core -> Core
const OP_DRAW_RESULT = 0x44524557;        // "DREW" Draw Core -> Core
const OP_RESOLVE_WINNERS = 0x4457494E;    // "DWIN" Core -> Board
const OP_WINNERS_RESULT = 0x44575253;     // "DWRS" Board -> Core
const OP_DRAW_ACK = 0x4441434B;           // "DACK" Core -> Draw Core
const OP_ACCRUAL_ACK = 0x44414353;        // "DACS" Draw Core -> Core
const OP_REFUNDABLE = 0x44524644;         // "DRFD" Draw Core -> Core
const OP_REFUND_ACK = 0x44524143;          // "DRAC" Core -> Draw Core
const OP_RETRY_DRAW = 0x44525452;         // "DRTR" permissionless
const OP_SETTLE_REFERRALS = 0x44534554;   // "DSET" permissionless

const STATUS_OPEN = 0;
const STATUS_RANDOMNESS_PENDING = 1;
const STATUS_SETTLING = 2;
const STATUS_PAID = 3;
const STATUS_REFUNDABLE = 4;
const TOTAL_COMMISSION_BPS = 1000;
const BPS_DENOMINATOR = 10000;
const MIN_ROUTE_GAS = 5000000;
const DRAW_ACK_GAS = 10000000;
const REFUND_ACK_GAS = 5000000;
const WINNER_RESOLUTION_GAS = 15000000;
const REFERRAL_PAYOUT_GAS = 3000000;
const MAX_REFERRAL_BATCH = 16;
const MAX_ROUND_UNITS = 1000000;

struct CoreState {
    roundId: int;
    nanoPerGram: int;
    status: int;
    liabilityUnits: int;
    purchasedUnits: int;
    refundedUnits: int;
    rewardBps: int;
    platformBps: int;
    capacity: int;
    noRefUnits: int;
    drawCore: address;
    roundRoot: int;
    sealedAt: int;
    targetRound: int;
    randomness: int;
    winnerIndex: int;
    bonusWinnerIndex: int;
    jackpot: coins;
    rewardPool: coins;
    platformPool: coins;
    bonusAccrued: coins;
    bonusPrize: coins;
    vaultCode: cell;
    boardCode: cell;
    lastRefundQueries: map<address, uint64>;
    rewardUnits: map<address, uint32>;
}

fun loadState(): CoreState {
    var data = contract.getData().beginParse();
    var drawData = data.loadRef().beginParse();
    var pools = data.loadRef().beginParse();
    var codes = data.loadRef().beginParse();
    var accounting = data.loadRef().beginParse();
    val state = CoreState {
        roundId: data.loadUint(64),
        nanoPerGram: data.loadUint(64),
        status: data.loadUint(3),
        liabilityUnits: data.loadUint(32),
        purchasedUnits: data.loadUint(32),
        refundedUnits: data.loadUint(32),
        rewardBps: data.loadUint(14),
        platformBps: data.loadUint(14),
        capacity: data.loadUint(16),
        noRefUnits: data.loadUint(32),
        drawCore: data.loadAddress(),
        roundRoot: drawData.loadUint(256),
        sealedAt: drawData.loadUint(64),
        targetRound: drawData.loadUint(64),
        randomness: drawData.loadUint(256),
        winnerIndex: drawData.loadUint(32),
        bonusWinnerIndex: drawData.loadUint(32),
        jackpot: pools.loadCoins(),
        rewardPool: pools.loadCoins(),
        platformPool: pools.loadCoins(),
        bonusAccrued: pools.loadCoins(),
        bonusPrize: pools.loadCoins(),
        vaultCode: codes.loadRef(),
        boardCode: codes.loadRef(),
        lastRefundQueries: createMapFromLowLevelDict<address, uint64>(accounting.loadDict()),
        rewardUnits: createMapFromLowLevelDict<address, uint32>(accounting.loadDict()),
    };
    drawData.assertEnd();
    pools.assertEnd();
    codes.assertEnd();
    accounting.assertEnd();
    data.assertEnd();
    assert (state.rewardBps + state.platformBps == TOTAL_COMMISSION_BPS) throw 540;
    assert (
        state.nanoPerGram > 0
        && (state.nanoPerGram * state.rewardBps) % BPS_DENOMINATOR == 0
        && (state.nanoPerGram * state.platformBps) % BPS_DENOMINATOR == 0
    ) throw 539;
    return state;
}

fun saveState(state: CoreState) {
    contract.setData(
        beginCell()
            .storeUint(state.roundId, 64)
            .storeUint(state.nanoPerGram, 64)
            .storeUint(state.status, 3)
            .storeUint(state.liabilityUnits, 32)
            .storeUint(state.purchasedUnits, 32)
            .storeUint(state.refundedUnits, 32)
            .storeUint(state.rewardBps, 14)
            .storeUint(state.platformBps, 14)
            .storeUint(state.capacity, 16)
            .storeUint(state.noRefUnits, 32)
            .storeAddress(state.drawCore)
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
            .storeRef(
                beginCell()
                    .storeCoins(state.jackpot)
                    .storeCoins(state.rewardPool)
                    .storeCoins(state.platformPool)
                    .storeCoins(state.bonusAccrued)
                    .storeCoins(state.bonusPrize)
                    .endCell()
            )
            .storeRef(beginCell().storeRef(state.vaultCode).storeRef(state.boardCode).endCell())
            .storeRef(
                beginCell()
                    .storeDict(state.lastRefundQueries.toLowLevelDict())
                    .storeDict(state.rewardUnits.toLowLevelDict())
                    .endCell()
            )
            .endCell(),
    );
}

fun emptyVaultPlan(): cell {
    val emptyPlan: map<uint16, cell> = [];
    return beginCell().storeDict(emptyPlan.toLowLevelDict()).endCell();
}

fun initialBoardData(state: CoreState): cell {
    val owners: map<uint16, address> = [];
    val receipts: map<address, cell> = [];
    val referralUnits: map<address, uint32> = [];
    return beginCell()
        .storeAddress(contract.getAddress())
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
                .endCell()
        )
        .storeRef(
            beginCell()
                .storeDict(referralUnits.toLowLevelDict())
                .endCell()
        )
        .endCell();
}

fun configuredBoard(state: CoreState): address {
    return AutoDeployAddress {
        workchain: contract.getAddress().getWorkchain(),
        stateInit: ContractState {
            code: state.boardCode,
            data: initialBoardData(state),
        },
    }.calculateAddress();
}

fun initialVaultData(state: CoreState, owner: address): cell {
    return beginCell()
        .storeAddress(contract.getAddress())
        .storeAddress(configuredBoard(state))
        .storeAddress(owner)
        .storeRef(
            beginCell()
                .storeUint(state.roundId, 64)
                .storeUint(state.nanoPerGram, 64)
                .storeUint(0, 2)
                .storeUint(0, 32)
                .storeUint(0, 32)
                .storeUint(0, 2)
                .storeUint(0, 64)
                .storeUint(0, 64)
                .storeUint(0, 16)
                .storeUint(0, 16)
                .storeUint(0, 32)
                .storeUint(0, 32)
                .storeUint(0, 32)
                .storeBool(false)
                .storeRef(beginCell().storeAddressNone().endCell())
                .storeRef(emptyVaultPlan())
                .endCell()
        )
        .endCell();
}

fun expectedVault(state: CoreState, owner: address): address {
    return AutoDeployAddress {
        workchain: owner.getWorkchain(),
        stateInit: ContractState {
            code: state.vaultCode,
            data: initialVaultData(state, owner),
        },
    }.calculateAddress();
}

fun amountForUnits(state: CoreState, units: int): coins {
    return units * state.nanoPerGram * (BPS_DENOMINATOR + TOTAL_COMMISSION_BPS)
        / BPS_DENOMINATOR;
}

fun rewardForUnits(state: CoreState, units: int): coins {
    return units * state.nanoPerGram * state.rewardBps / BPS_DENOMINATOR;
}

fun purchaseAndPlace(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    assert (state.status == STATUS_OPEN) throw 541;
    val owner = body.loadAddress();
    val requestedReferrer = body.loadAddressOpt();
    val queryId = body.loadUint(64);
    val purchaseUnits = body.loadUint(32);
    val batchCount = body.loadUint(16);
    val firstBatch = body.loadRef();
    body.assertEnd();
    assert (sender == expectedVault(state, owner)) throw 542;
    assert (purchaseUnits > 0 && batchCount > 0) throw 543;
    val purchaseAmount = amountForUnits(state, purchaseUnits);
    assert (valueCoins >= purchaseAmount + MIN_ROUTE_GAS) throw 544;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage + purchaseAmount, RESERVE_MODE_EXACT_AMOUNT);

    state.liabilityUnits += purchaseUnits;
    state.purchasedUnits += purchaseUnits;
    assert (state.liabilityUnits <= MAX_ROUND_UNITS && state.purchasedUnits <= MAX_ROUND_UNITS) throw 545;
    createMessage({
        bounce: BounceMode.RichBounce,
        value: 0,
        dest: configuredBoard(state),
        body: beginCell()
            .storeUint(OP_BOARD_PURCHASE_AND_PLACE, 32)
            .storeAddress(sender)
            .storeAddress(owner)
            .storeAddressOpt(requestedReferrer)
            .storeUint(queryId, 64)
            .storeUint(0, 16)
            .storeUint(batchCount, 16)
            .storeRef(firstBatch)
            .endCell(),
    }).send(SEND_MODE_CARRY_ALL_BALANCE);
    return state;
}

fun refund(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
    requiredStatus: int,
    resultOp: int,
): CoreState {
    assert (state.status == requiredStatus) throw 541;
    val owner = body.loadAddress();
    val queryId = body.loadUint(64);
    val units = body.loadUint(32);
    body.assertEnd();
    assert (sender == expectedVault(state, owner)) throw 542;
    assert (units > 0 && units <= state.liabilityUnits && valueCoins >= MIN_ROUTE_GAS) throw 546;
    val previousRefund = state.lastRefundQueries.get(sender);
    if (previousRefund.isFound) {
        assert (queryId > previousRefund.loadValue()) throw 551;
    }
    val refundAmount = amountForUnits(state, units);
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    assert (balanceBeforeMessage >= refundAmount) throw 547;
    reserveToncoinsOnBalance(balanceBeforeMessage - refundAmount, RESERVE_MODE_EXACT_AMOUNT);
    state.liabilityUnits -= units;
    state.refundedUnits += units;
    state.lastRefundQueries.set(sender, queryId);
    createMessage({
        bounce: BounceMode.RichBounce,
        value: 0,
        dest: sender,
        body: beginCell()
            .storeUint(resultOp, 32)
            .storeAddress(owner)
            .storeUint(queryId, 64)
            .storeUint(units, 32)
            .endCell(),
    }).send(SEND_MODE_CARRY_ALL_BALANCE);
    return state;
}

fun handleBoardBounce(state: CoreState, valueCoins: coins, body: slice) {
    val vault = body.loadAddress();
    body.loadAddress(); // owner
    val queryId = body.loadUint(64);
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: vault,
        body: beginCell().storeUint(OP_ROUTE_FAILED, 32).storeUint(queryId, 64).endCell(),
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun handleRefundBounce(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    val owner = body.loadAddress();
    val queryId = body.loadUint(64);
    val units = body.loadUint(32);
    body.assertEnd();
    val savedRefund = state.lastRefundQueries.get(sender);
    assert (
        sender == expectedVault(state, owner)
        && units <= state.refundedUnits
        && savedRefund.isFound
        && savedRefund.loadValue() == queryId
    ) throw 548;
    val amount = amountForUnits(state, units);
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    assert (valueCoins >= amount) throw 549;
    reserveToncoinsOnBalance(balanceBeforeMessage + amount, RESERVE_MODE_EXACT_AMOUNT);
    state.liabilityUnits += units;
    state.refundedUnits -= units;
    assert (state.lastRefundQueries.delete(sender)) throw 551;
    return state;
}

fun acknowledgeRefund(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    val owner = body.loadAddress();
    val queryId = body.loadUint(64);
    body.assertEnd();
    assert (sender == expectedVault(state, owner)) throw 542;
    val savedRefund = state.lastRefundQueries.mustGet(sender, 551);
    assert (savedRefund == queryId) throw 551;
    assert (state.lastRefundQueries.delete(sender)) throw 551;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: owner })
        .send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
    return state;
}

fun sendSeal(state: CoreState) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: 0,
        dest: state.drawCore,
        body: beginCell()
            .storeUint(OP_SEAL_ROUND, 32)
            .storeUint(state.roundId, 64)
            .storeUint(state.capacity, 16)
            .storeUint(state.roundRoot, 256)
            .endCell(),
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun handleBoardSealed(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    val roundId = body.loadUint(64);
    val capacity = body.loadUint(16);
    val root = body.loadUint(256);
    val noRefUnits = body.loadUint(32);
    var rewardUnitsData = body.loadRef().beginParse();
    val rewardUnits = createMapFromLowLevelDict<address, uint32>(rewardUnitsData.loadDict());
    rewardUnitsData.assertEnd();
    body.assertEnd();
    assert (sender == configuredBoard(state)) throw 552;
    assert (
        roundId == state.roundId
        && capacity == state.capacity
        && noRefUnits <= capacity
        && root != 0
    ) throw 553;
    if (state.status == STATUS_RANDOMNESS_PENDING) {
        assert (root == state.roundRoot) throw 554;
        val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
        reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
        sendSeal(state);
        return state;
    }
    assert (state.status == STATUS_OPEN && state.liabilityUnits >= state.capacity) throw 554;
    state.liabilityUnits -= state.capacity;
    state.roundRoot = root;
    state.noRefUnits = noRefUnits;
    state.rewardUnits = rewardUnits;
    state.jackpot = state.capacity * state.nanoPerGram;
    state.rewardPool = (state.capacity - state.noRefUnits) * state.nanoPerGram * state.rewardBps / BPS_DENOMINATOR;
    state.bonusAccrued = state.noRefUnits * state.nanoPerGram * state.rewardBps / BPS_DENOMINATOR;
    state.platformPool = state.capacity * state.nanoPerGram * state.platformBps / BPS_DENOMINATOR;
    state.status = STATUS_RANDOMNESS_PENDING;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    sendSeal(state);
    return state;
}

fun applySealAck(state: CoreState, sender: address, body: slice): CoreState {
    val roundId = body.loadUint(64);
    val root = body.loadUint(256);
    val sealedAt = body.loadUint(64);
    val targetRound = body.loadUint(64);
    body.assertEnd();
    assert (sender == state.drawCore && state.status == STATUS_RANDOMNESS_PENDING) throw 555;
    assert (roundId == state.roundId && root == state.roundRoot) throw 556;
    if (state.targetRound != 0) {
        assert (state.sealedAt == sealedAt && state.targetRound == targetRound) throw 556;
        return state;
    }
    assert (sealedAt > 0 && targetRound > 0) throw 556;
    state.sealedAt = sealedAt;
    state.targetRound = targetRound;
    return state;
}

fun sendWinnerResolution(state: CoreState) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: WINNER_RESOLUTION_GAS,
        dest: configuredBoard(state),
        body: beginCell()
            .storeUint(OP_RESOLVE_WINNERS, 32)
            .storeUint(state.roundRoot, 256)
            .storeUint(state.winnerIndex, 32)
            .storeBool(state.bonusPrize > 0)
            .storeUint(state.bonusWinnerIndex, 32)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun applyDrawResult(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    val roundId = body.loadUint(64);
    val root = body.loadUint(256);
    val targetRound = body.loadUint(64);
    val randomness = body.loadUint(256);
    val winnerIndex = body.loadUint(32);
    val bonusActive = body.loadBool();
    val bonusWinnerIndex = body.loadUint(32);
    body.assertEnd();
    assert (sender == state.drawCore && state.status == STATUS_RANDOMNESS_PENDING) throw 557;
    assert (roundId == state.roundId && root == state.roundRoot && targetRound == state.targetRound) throw 558;
    assert (winnerIndex < state.capacity) throw 558;
    assert (bonusActive == (state.bonusPrize > 0)) throw 558;
    if (bonusActive) {
        assert (bonusWinnerIndex < state.capacity) throw 558;
    }
    state.randomness = randomness;
    state.winnerIndex = winnerIndex;
    state.bonusWinnerIndex = bonusWinnerIndex;
    state.status = STATUS_SETTLING;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    assert (valueCoins >= state.bonusPrize + WINNER_RESOLUTION_GAS) throw 558;
    reserveToncoinsOnBalance(
        balanceBeforeMessage + state.bonusPrize,
        RESERVE_MODE_EXACT_AMOUNT,
    );
    sendWinnerResolution(state);
    return state;
}

fun applyWinners(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    val root = body.loadUint(256);
    val winner = body.loadAddress();
    val hasBonus = body.loadBool();
    val bonusWinner = body.loadAddressOpt();
    body.assertEnd();
    assert (sender == configuredBoard(state) && state.status == STATUS_SETTLING) throw 559;
    assert (root == state.roundRoot && hasBonus == (state.bonusPrize > 0)) throw 560;
    if (hasBonus) {
        assert (bonusWinner != null) throw 560;
    }
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    val winnerPayouts = state.jackpot + state.bonusPrize;
    val drawAccrual = state.bonusAccrued + state.platformPool;
    assert (balanceBeforeMessage >= winnerPayouts + drawAccrual) throw 561;
    reserveToncoinsOnBalance(
        balanceBeforeMessage - winnerPayouts - drawAccrual,
        RESERVE_MODE_EXACT_AMOUNT,
    );
    createMessage({
        bounce: BounceMode.NoBounce,
        value: state.jackpot,
        dest: winner,
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
    if (hasBonus) {
        createMessage({
            bounce: BounceMode.NoBounce,
            value: state.bonusPrize,
            dest: bonusWinner!,
        }).send(SEND_MODE_PAY_FEES_SEPARATELY);
    }
    createMessage({
        bounce: BounceMode.RichBounce,
        value: drawAccrual + DRAW_ACK_GAS,
        dest: state.drawCore,
        body: beginCell()
            .storeUint(OP_DRAW_ACK, 32)
            .storeUint(state.roundId, 64)
            .storeCoins(state.bonusAccrued)
            .storeCoins(state.platformPool)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
    state.status = STATUS_PAID;
    return state;
}

fun applyAccrualAck(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    val roundId = body.loadUint(64);
    val bonusAmount = body.loadCoins();
    val platformAmount = body.loadCoins();
    body.assertEnd();
    assert (sender == state.drawCore && state.status == STATUS_PAID) throw 565;
    assert (roundId == state.roundId) throw 566;
    if (state.bonusAccrued == 0 && state.platformPool == 0) {
        return state;
    }
    assert (
        bonusAmount == state.bonusAccrued
        && platformAmount == state.platformPool
    ) throw 566;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    state.bonusAccrued = 0;
    state.platformPool = 0;
    return state;
}

fun retryDrawAck(state: CoreState) {
    assert (state.bonusAccrued > 0 || state.platformPool > 0) throw 564;
    createMessage({
        bounce: BounceMode.RichBounce,
        value: DRAW_ACK_GAS,
        dest: state.drawCore,
        body: beginCell()
            .storeUint(OP_DRAW_ACK, 32)
            .storeUint(state.roundId, 64)
            .storeCoins(state.bonusAccrued)
            .storeCoins(state.platformPool)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun settleReferrals(
    state: CoreState,
    valueCoins: coins,
    body: slice,
): CoreState {
    val limit = body.loadUint(8);
    body.assertEnd();
    assert (state.status == STATUS_PAID) throw 567;
    assert (limit > 0 && limit <= MAX_REFERRAL_BATCH) throw 568;

    var entry = state.rewardUnits.findFirst();
    var count = 0;
    var total = 0 as coins;
    while (entry.isFound && count < limit) {
        val units = entry.loadValue();
        assert (units > 0) throw 569;
        total += rewardForUnits(state, units);
        count += 1;
        entry = state.rewardUnits.iterateNext(entry);
    }
    assert (count > 0 && total > 0 && total <= state.rewardPool) throw 569;
    assert (valueCoins >= count * REFERRAL_PAYOUT_GAS) throw 570;

    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    assert (balanceBeforeMessage >= total) throw 571;
    reserveToncoinsOnBalance(balanceBeforeMessage - total, RESERVE_MODE_EXACT_AMOUNT);

    var sent = 0;
    while (sent < count) {
        val payout = state.rewardUnits.findFirst();
        assert (payout.isFound) throw 569;
        val referrer = payout.getKey();
        val amount = rewardForUnits(state, payout.loadValue());
        assert (state.rewardUnits.delete(referrer)) throw 569;
        createMessage({
            bounce: BounceMode.NoBounce,
            value: amount,
            dest: referrer,
        }).send(SEND_MODE_PAY_FEES_SEPARATELY);
        sent += 1;
    }
    state.rewardPool -= total;
    return state;
}

fun sendRefundAck(state: CoreState) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: REFUND_ACK_GAS,
        dest: state.drawCore,
        body: beginCell()
            .storeUint(OP_REFUND_ACK, 32)
            .storeUint(state.roundId, 64)
            .storeUint(state.roundRoot, 256)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun applyRefundable(
    state: CoreState,
    sender: address,
    valueCoins: coins,
    body: slice,
): CoreState {
    val roundId = body.loadUint(64);
    val root = body.loadUint(256);
    body.assertEnd();
    assert (sender == state.drawCore) throw 562;
    assert (roundId == state.roundId && root == state.roundRoot) throw 563;
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    if (state.status == STATUS_REFUNDABLE) {
        sendRefundAck(state);
        return state;
    }
    assert (state.status == STATUS_RANDOMNESS_PENDING) throw 562;
    state.liabilityUnits += state.capacity;
    state.jackpot = 0;
    state.rewardPool = 0;
    state.platformPool = 0;
    state.bonusAccrued = 0;
    state.rewardUnits = [];
    state.status = STATUS_REFUNDABLE;
    sendRefundAck(state);
    return state;
}

fun retryDraw(state: CoreState, valueCoins: coins, body: slice) {
    body.assertEnd();
    val balanceBeforeMessage = contract.getOriginalBalance() - valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    if (state.status == STATUS_RANDOMNESS_PENDING) {
        sendSeal(state);
    } else if (state.status == STATUS_SETTLING) {
        sendWinnerResolution(state);
    } else if (state.status == STATUS_PAID) {
        retryDrawAck(state);
    } else {
        throw 564;
    }
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }
    var state = loadState();
    var body = in.body;
    val op = body.loadUint(32);
    if (op == OP_PURCHASE_AND_PLACE) {
        state = purchaseAndPlace(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_REFUND) {
        state = refund(state, in.senderAddress, in.valueCoins, body, STATUS_OPEN, OP_REFUND_RESULT);
    } else if (op == OP_TIMEOUT_REFUND) {
        state = refund(
            state,
            in.senderAddress,
            in.valueCoins,
            body,
            STATUS_REFUNDABLE,
            OP_TIMEOUT_REFUND_RESULT,
        );
    } else if (op == OP_AVAILABLE_REFUND) {
        state = refund(
            state,
            in.senderAddress,
            in.valueCoins,
            body,
            STATUS_PAID,
            OP_AVAILABLE_REFUND_RESULT,
        );
    } else if (op == OP_REFUND_RECEIPT_ACK) {
        state = acknowledgeRefund(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_BOARD_SEALED) {
        state = handleBoardSealed(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_SEAL_ACK) {
        state = applySealAck(state, in.senderAddress, body);
    } else if (op == OP_DRAW_RESULT) {
        state = applyDrawResult(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_WINNERS_RESULT) {
        state = applyWinners(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_ACCRUAL_ACK) {
        state = applyAccrualAck(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_REFUNDABLE) {
        state = applyRefundable(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_RETRY_DRAW) {
        retryDraw(state, in.valueCoins, body);
    } else if (op == OP_SETTLE_REFERRALS) {
        state = settleReferrals(state, in.valueCoins, body);
    } else {
        throw 0xFFFF;
    }
    saveState(state);
}

fun onBouncedMessage(in: InMessageBounced) {
    var state = loadState();
    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);
    var body = rich.originalBody.beginParse();
    val op = body.loadUint(32);
    if (op == OP_BOARD_PURCHASE_AND_PLACE) {
        handleBoardBounce(state, in.valueCoins, body);
    } else if (
        op == OP_REFUND_RESULT
        || op == OP_TIMEOUT_REFUND_RESULT
        || op == OP_AVAILABLE_REFUND_RESULT
    ) {
        state = handleRefundBounce(state, in.senderAddress, in.valueCoins, body);
        saveState(state);
    } else if (
        op == OP_SEAL_ROUND
        || op == OP_RESOLVE_WINNERS
        || op == OP_DRAW_ACK
        || op == OP_REFUND_ACK
    ) {
        return;
    } else {
        throw 550;
    }
}

get fun core_state(): (int, int, int, int, int, int, int) {
    val state = loadState();
    return (
        state.roundId,
        state.status,
        state.liabilityUnits,
        state.purchasedUnits,
        state.refundedUnits,
        amountForUnits(state, state.liabilityUnits),
        state.rewardBps,
    );
}

get fun draw_state(): (int, int, int, int, int, int, coins, coins, coins, coins, coins) {
    val state = loadState();
    return (
        state.status,
        state.roundRoot,
        state.sealedAt,
        state.targetRound,
        state.randomness,
        state.winnerIndex,
        state.jackpot,
        state.rewardPool,
        state.platformPool,
        state.bonusAccrued,
        state.bonusPrize,
    );
}

get fun expected_vault(owner: address): address {
    return expectedVault(loadState(), owner);
}

get fun unit_price(): int {
    return loadState().nanoPerGram;
}

get fun last_refund_query(vault: address): int {
    val found = loadState().lastRefundQueries.get(vault);
    return found.isFound ? found.loadValue() : 0;
}

get fun referral_settlement_state(): (coins, bool) {
    val state = loadState();
    return (state.rewardPool, !state.rewardUnits.isEmpty());
}
