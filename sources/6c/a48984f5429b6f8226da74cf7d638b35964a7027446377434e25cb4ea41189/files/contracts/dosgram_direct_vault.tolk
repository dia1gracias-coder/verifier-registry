// SPDX-License-Identifier: MIT

// DOSGRAM v2 deterministic per-player Vault. The owner signs once. The Vault
// stores the immutable batch plan and advances it automatically from Board
// receipts. Anyone may add gas to resume the exact same committed operation.

const OP_START_PLACE = 0x44535450;         // "DSTP" owner -> Vault
const OP_START_REMOVE = 0x44535452;        // "DSTR" owner -> Vault
const OP_REFUND_ALL = 0x44524644;           // "DRFD" owner -> Vault
const OP_CONTINUE = 0x44434F4E;             // "DCON" permissionless
const OP_CORE_PURCHASE_AND_PLACE = 0x44425559; // "DBUY" Vault -> Core
const OP_BOARD_PURCHASE_AND_PLACE = 0x44505552; // "DPUR" Core -> Board
const OP_BOARD_PLACE = 0x44504C43;          // "DPLC" Vault -> Board
const OP_BOARD_REMOVE = 0x44524D56;         // "DRMV" Vault -> Board
const OP_BATCH_RESULT = 0x44524553;          // "DRES" Board -> Vault
const OP_RECEIPT_ACK = 0x44414352;            // "DACR" Vault -> Board
const OP_CORE_REFUND = 0x44465246;           // "DFRF" Vault -> Core
const OP_CORE_TIMEOUT_REFUND = 0x44544652;   // "DTFR" Vault -> Core
const OP_CORE_AVAILABLE_REFUND = 0x44415652; // "DAVR" Vault -> Core
const OP_REFUND_RESULT = 0x44465253;         // "DFRS" Core -> Vault
const OP_TIMEOUT_REFUND_RESULT = 0x44544653;   // "DTFS" Core -> Vault
const OP_AVAILABLE_REFUND_RESULT = 0x44415653; // "DAVS" Core -> Vault
const OP_REFUND_RECEIPT_ACK = 0x4452414B;     // "DRAK" Vault -> Core
const OP_ROUTE_FAILED = 0x44464149;          // "DFAI" Core -> Vault
const OP_CLAIM_TIMEOUT_REFUND = 0x44544644;  // "DTFD" permissionless -> Vault
const OP_CLAIM_AVAILABLE = 0x44415641;       // "DAVA" permissionless -> Vault

const STATUS_OPEN = 0;
const MODE_NONE = 0;
const MODE_PLACE = 1;
const MODE_REMOVE = 2;
const MODE_REFUND = 3;
const MAX_BATCHES = 32;
const MAX_BATCH_CELLS = 32;
const MAX_ROUND_UNITS = 1000000;
const TOTAL_COMMISSION_BPS = 1000;
const BPS_DENOMINATOR = 10000;
const VAULT_RESERVE = 30000000;
const MIN_OPERATION_GAS = 10000000;
const RECEIPT_ACK_GAS = 1000000;
const REFUND_RECEIPT_ACK_GAS = 2000000;
const SEND_MODE_DESTROY_AND_CARRY_ALL = 160;
const SEND_MODE_PAY_FEES_AND_IGNORE_ERRORS = 3;

struct VaultState {
    core: address;
    board: address;
    owner: address;
    roundId: int;
    nanoPerGram: int;
    status: int;
    totalUnits: int;
    onBoard: int;
    pendingMode: int;
    lastQueryId: int;
    queryId: int;
    cursor: int;
    batchCount: int;
    requestedUnits: int;
    changedUnits: int;
    refundUnits: int;
    referrerFixed: bool;
    requestedReferrer: address?;
    plan: cell;
}

fun emptyPlan(): cell {
    val empty: map<uint16, cell> = [];
    return beginCell().storeDict(empty.toLowLevelDict()).endCell();
}

fun loadState(): VaultState {
    var data = contract.getData().beginParse();
    val core = data.loadAddress();
    val board = data.loadAddress();
    val owner = data.loadAddress();
    var metadata = data.loadRef().beginParse();
    val state = VaultState {
        core,
        board,
        owner,
        roundId: metadata.loadUint(64),
        nanoPerGram: metadata.loadUint(64),
        status: metadata.loadUint(2),
        totalUnits: metadata.loadUint(32),
        onBoard: metadata.loadUint(32),
        pendingMode: metadata.loadUint(2),
        lastQueryId: metadata.loadUint(64),
        queryId: metadata.loadUint(64),
        cursor: metadata.loadUint(16),
        batchCount: metadata.loadUint(16),
        requestedUnits: metadata.loadUint(32),
        changedUnits: metadata.loadUint(32),
        refundUnits: metadata.loadUint(32),
        referrerFixed: metadata.loadBool(),
        requestedReferrer: metadata.loadRef().beginParse().loadAddressOpt(),
        plan: metadata.loadRef(),
    };
    metadata.assertEnd();
    data.assertEnd();
    return state;
}

fun saveState(state: VaultState) {
    contract.setData(
        beginCell()
            .storeAddress(state.core)
            .storeAddress(state.board)
            .storeAddress(state.owner)
            .storeRef(
                beginCell()
                    .storeUint(state.roundId, 64)
                    .storeUint(state.nanoPerGram, 64)
                    .storeUint(state.status, 2)
                    .storeUint(state.totalUnits, 32)
                    .storeUint(state.onBoard, 32)
                    .storeUint(state.pendingMode, 2)
                    .storeUint(state.lastQueryId, 64)
                    .storeUint(state.queryId, 64)
                    .storeUint(state.cursor, 16)
                    .storeUint(state.batchCount, 16)
                    .storeUint(state.requestedUnits, 32)
                    .storeUint(state.changedUnits, 32)
                    .storeUint(state.refundUnits, 32)
                    .storeBool(state.referrerFixed)
                    .storeRef(beginCell().storeAddressOpt(state.requestedReferrer).endCell())
                    .storeRef(state.plan)
                    .endCell()
            )
            .endCell(),
    );
}

fun amountForUnits(state: VaultState, units: int): coins {
    return units * state.nanoPerGram * (BPS_DENOMINATOR + TOTAL_COMMISSION_BPS)
        / BPS_DENOMINATOR;
}

fun availableUnits(state: VaultState): int {
    val pendingPlace = state.pendingMode == MODE_PLACE ? state.requestedUnits : 0;
    return state.totalUnits - state.onBoard - pendingPlace;
}

fun assertAccounting(state: VaultState) {
    assert (state.status == STATUS_OPEN && state.nanoPerGram > 0) throw 520;
    assert (state.totalUnits >= 0 && state.totalUnits <= MAX_ROUND_UNITS) throw 520;
    assert (state.onBoard >= 0 && state.onBoard <= state.totalUnits) throw 520;
    assert (availableUnits(state) >= 0) throw 520;
    assert (state.pendingMode >= MODE_NONE && state.pendingMode <= MODE_REFUND) throw 520;
    if (state.pendingMode == MODE_NONE) {
        assert (state.queryId == 0 && state.cursor == 0 && state.batchCount == 0) throw 520;
        assert (state.requestedUnits == 0 && state.changedUnits == 0) throw 520;
        assert (state.refundUnits == 0) throw 520;
    }
}

fun loadBatch(plan: cell, cursor: int): cell {
    var data = plan.beginParse();
    val batches = createMapFromLowLevelDict<uint16, cell>(data.loadDict());
    data.assertEnd();
    return batches.mustGet(cursor, 521);
}

fun validatePlan(plan: cell, batchCount: int, requestedUnits: int) {
    assert (batchCount > 0 && batchCount <= MAX_BATCHES) throw 522;
    var total = 0;
    var cursor = 0;
    while (cursor < batchCount) {
        var batch = loadBatch(plan, cursor).beginParse();
        val count = batch.loadUint(8);
        assert (count > 0 && count <= MAX_BATCH_CELLS) throw 523;
        batch.loadBits(count * 16);
        batch.assertEnd();
        total += count;
        cursor += 1;
    }
    assert (total == requestedUnits) throw 524;
}

fun reserveVault() {
    assert (contract.getOriginalBalance() >= VAULT_RESERVE) throw 525;
    reserveToncoinsOnBalance(VAULT_RESERVE, RESERVE_MODE_EXACT_AMOUNT);
}

fun resetOperation(state: VaultState): VaultState {
    state.pendingMode = MODE_NONE;
    state.queryId = 0;
    state.cursor = 0;
    state.batchCount = 0;
    state.requestedUnits = 0;
    state.changedUnits = 0;
    state.refundUnits = 0;
    if (!state.referrerFixed) {
        state.requestedReferrer = null;
    }
    state.plan = emptyPlan();
    return state;
}

fun boardRequestBody(state: VaultState, op: int): cell {
    return beginCell()
        .storeUint(op, 32)
        .storeAddress(state.owner)
        .storeAddressOpt(state.requestedReferrer)
        .storeUint(state.queryId, 64)
        .storeUint(state.cursor, 16)
        .storeUint(state.batchCount, 16)
        .storeRef(loadBatch(state.plan, state.cursor))
        .endCell();
}

fun sendCurrentBatch(state: VaultState) {
    val op = state.pendingMode == MODE_PLACE ? OP_BOARD_PLACE : OP_BOARD_REMOVE;
    reserveVault();
    createMessage({
        bounce: BounceMode.RichBounce,
        value: 0,
        dest: state.board,
        body: boardRequestBody(state, op),
    }).send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun sendRefundRequest(state: VaultState) {
    reserveVault();
    createMessage({
        bounce: BounceMode.RichBounce,
        value: 0,
        dest: state.core,
        body: beginCell()
            .storeUint(OP_CORE_REFUND, 32)
            .storeAddress(state.owner)
            .storeUint(state.queryId, 64)
            .storeUint(state.refundUnits, 32)
            .endCell(),
    }).send(SEND_MODE_CARRY_ALL_BALANCE);
}

fun sendReceiptAck(state: VaultState, cursor: int, mode: int) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: RECEIPT_ACK_GAS,
        dest: state.board,
        body: beginCell()
            .storeUint(OP_RECEIPT_ACK, 32)
            .storeAddress(state.owner)
            .storeUint(state.queryId, 64)
            .storeUint(cursor, 16)
            .storeUint(mode, 2)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_AND_IGNORE_ERRORS);
}

fun sendRefundReceiptAck(state: VaultState, queryId: int) {
    createMessage({
        bounce: BounceMode.NoBounce,
        value: REFUND_RECEIPT_ACK_GAS,
        dest: state.core,
        body: beginCell()
            .storeUint(OP_REFUND_RECEIPT_ACK, 32)
            .storeAddress(state.owner)
            .storeUint(queryId, 64)
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_AND_IGNORE_ERRORS);
}

fun startPlace(
    state: VaultState,
    sender: address,
    valueCoins: coins,
    body: slice,
): VaultState {
    assert (sender == state.owner && state.pendingMode == MODE_NONE) throw 526;
    val queryId = body.loadUint(64);
    val purchaseUnits = body.loadUint(32);
    val requestedUnits = body.loadUint(32);
    val batchCount = body.loadUint(16);
    val requestedReferrer = body.loadAddressOpt();
    val plan = body.loadRef();
    body.assertEnd();
    assert (queryId > state.lastQueryId && requestedUnits > 0) throw 527;
    if (requestedReferrer != null) {
        assert (requestedReferrer! != state.owner) throw 528;
    }
    if (state.referrerFixed) {
        if (requestedReferrer != null) {
            assert (
                state.requestedReferrer != null
                && requestedReferrer! == state.requestedReferrer!
            ) throw 528;
        }
    } else {
        state.requestedReferrer = requestedReferrer;
    }
    validatePlan(plan, batchCount, requestedUnits);
    val purchaseAmount = amountForUnits(state, purchaseUnits);
    assert (valueCoins >= purchaseAmount + MIN_OPERATION_GAS) throw 529;

    state.totalUnits += purchaseUnits;
    assert (requestedUnits <= availableUnits(state)) throw 530;
    state.pendingMode = MODE_PLACE;
    state.lastQueryId = queryId;
    state.queryId = queryId;
    state.cursor = 0;
    state.batchCount = batchCount;
    state.requestedUnits = requestedUnits;
    state.changedUnits = 0;
    state.plan = plan;
    assertAccounting(state);

    reserveVault();
    if (purchaseUnits > 0) {
        createMessage({
            bounce: BounceMode.RichBounce,
            value: 0,
            dest: state.core,
            body: beginCell()
                .storeUint(OP_CORE_PURCHASE_AND_PLACE, 32)
                .storeAddress(state.owner)
                .storeAddressOpt(state.requestedReferrer)
                .storeUint(queryId, 64)
                .storeUint(purchaseUnits, 32)
                .storeUint(batchCount, 16)
                .storeRef(loadBatch(plan, 0))
                .endCell(),
        }).send(SEND_MODE_CARRY_ALL_BALANCE);
    } else {
        createMessage({
            bounce: BounceMode.RichBounce,
            value: 0,
            dest: state.board,
            body: boardRequestBody(state, OP_BOARD_PLACE),
        }).send(SEND_MODE_CARRY_ALL_BALANCE);
    }
    return state;
}

fun startRemoval(
    state: VaultState,
    sender: address,
    valueCoins: coins,
    body: slice,
    refundAfter: bool,
): VaultState {
    assert (sender == state.owner && state.pendingMode == MODE_NONE) throw 526;
    val queryId = body.loadUint(64);
    val requestedUnits = body.loadUint(32);
    val batchCount = body.loadUint(16);
    val plan = body.loadRef();
    body.assertEnd();
    assert (queryId > state.lastQueryId && requestedUnits > 0 && requestedUnits <= state.onBoard) throw 527;
    if (refundAfter) {
        assert (requestedUnits == state.onBoard) throw 531;
    }
    validatePlan(plan, batchCount, requestedUnits);
    assert (valueCoins >= MIN_OPERATION_GAS) throw 529;
    state.pendingMode = refundAfter ? MODE_REFUND : MODE_REMOVE;
    state.lastQueryId = queryId;
    state.queryId = queryId;
    state.cursor = 0;
    state.batchCount = batchCount;
    state.requestedUnits = requestedUnits;
    state.changedUnits = 0;
    state.plan = plan;
    assertAccounting(state);
    sendCurrentBatch(state);
    return state;
}

fun startRefundWithoutBoard(
    state: VaultState,
    sender: address,
    valueCoins: coins,
    body: slice,
): VaultState {
    assert (sender == state.owner && state.pendingMode == MODE_NONE) throw 526;
    val queryId = body.loadUint(64);
    val requestedUnits = body.loadUint(32);
    val batchCount = body.loadUint(16);
    val plan = body.loadRef();
    body.assertEnd();
    assert (queryId > state.lastQueryId && requestedUnits == 0 && batchCount == 0) throw 527;
    assert (plan.hash() == emptyPlan().hash()) throw 532;
    assert (state.onBoard == 0 && state.totalUnits > 0 && valueCoins >= MIN_OPERATION_GAS) throw 531;
    state.pendingMode = MODE_REFUND;
    state.lastQueryId = queryId;
    state.queryId = queryId;
    state.refundUnits = state.totalUnits;
    assertAccounting(state);
    sendRefundRequest(state);
    return state;
}

fun requestPermissionlessRefund(
    state: VaultState,
    valueCoins: coins,
    body: slice,
    requestOp: int,
): VaultState {
    val queryId = body.loadUint(64);
    body.assertEnd();
    assert (state.pendingMode == MODE_NONE && state.totalUnits > 0) throw 526;
    assert (queryId == state.lastQueryId + 1 && valueCoins >= MIN_OPERATION_GAS) throw 527;
    val units = requestOp == OP_CORE_TIMEOUT_REFUND ? state.totalUnits : availableUnits(state);
    assert (
        (requestOp == OP_CORE_TIMEOUT_REFUND || requestOp == OP_CORE_AVAILABLE_REFUND)
        && units > 0
    ) throw 527;
    reserveVault();
    createMessage({
        bounce: BounceMode.RichBounce,
        value: 0,
        dest: state.core,
        body: beginCell()
            .storeUint(requestOp, 32)
            .storeAddress(state.owner)
            .storeUint(queryId, 64)
            .storeUint(units, 32)
            .endCell(),
    }).send(SEND_MODE_CARRY_ALL_BALANCE);
    return state;
}

fun applyBatchResult(state: VaultState, sender: address, body: slice): VaultState {
    assert (sender == state.board && state.pendingMode != MODE_NONE) throw 533;
    val queryId = body.loadUint(64);
    val cursor = body.loadUint(16);
    val batchCount = body.loadUint(16);
    val attempted = body.loadUint(8);
    val changed = body.loadUint(8);
    val mode = body.loadUint(2);
    body.loadUint(256); // authenticated batch hash retained by Board
    body.assertEnd();
    assert (queryId == state.queryId && cursor == state.cursor && batchCount == state.batchCount) throw 534;
    val expectedMode = state.pendingMode == MODE_PLACE ? MODE_PLACE : MODE_REMOVE;
    assert (mode == expectedMode && changed <= attempted) throw 534;
    state.changedUnits += changed;
    assert (state.changedUnits <= state.requestedUnits) throw 535;
    val finalBatch = state.cursor + 1 == state.batchCount;
    if (finalBatch) {
        sendReceiptAck(state, cursor, mode);
    }
    state.cursor += 1;

    if (state.cursor < state.batchCount) {
        sendCurrentBatch(state);
        return state;
    }

    if (state.pendingMode == MODE_PLACE) {
        state.onBoard += state.changedUnits;
        if (state.changedUnits > 0 && !state.referrerFixed) {
            state.referrerFixed = true;
        }
        state = resetOperation(state);
        assertAccounting(state);
        reserveVault();
        createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: state.owner })
            .send(SEND_MODE_CARRY_ALL_BALANCE);
        return state;
    }

    val refundAfter = state.pendingMode == MODE_REFUND;
    state.onBoard -= state.changedUnits;
    if (refundAfter && state.onBoard == 0) {
        state.refundUnits = state.totalUnits;
        sendRefundRequest(state);
        return state;
    }
    state = resetOperation(state);
    assertAccounting(state);
    reserveVault();
    createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: state.owner })
        .send(SEND_MODE_CARRY_ALL_BALANCE);
    return state;
}

fun applyRefund(state: VaultState, sender: address, body: slice, resultOp: int): VaultState {
    assert (sender == state.core) throw 536;
    val owner = body.loadAddress();
    val queryId = body.loadUint(64);
    val units = body.loadUint(32);
    body.assertEnd();
    assert (owner == state.owner) throw 537;
    if (resultOp == OP_REFUND_RESULT) {
        assert (
            state.pendingMode == MODE_REFUND
            && queryId == state.queryId
            && units == state.refundUnits
        ) throw 537;
    } else {
        assert (state.pendingMode == MODE_NONE && queryId == state.lastQueryId + 1) throw 537;
        if (resultOp == OP_TIMEOUT_REFUND_RESULT) {
            assert (units == state.totalUnits) throw 537;
        } else {
            assert (resultOp == OP_AVAILABLE_REFUND_RESULT && units == availableUnits(state)) throw 537;
        }
        state.lastQueryId = queryId;
    }
    assert (
        units > 0
        && units <= state.totalUnits
        && (units == state.totalUnits || state.totalUnits - units >= state.onBoard)
    ) throw 537;
    val destroysVault = units == state.totalUnits;
    state.totalUnits -= units;
    if (destroysVault) {
        state.onBoard = 0;
    }
    if (resultOp == OP_REFUND_RESULT) {
        state = resetOperation(state);
    }
    // The Core keeps the refund query only until the authenticated Vault has
    // accepted the result. A best-effort ACK prevents one permanent Core map
    // entry per fully-refunded wallet while preserving bounce rollback.
    sendRefundReceiptAck(state, queryId);
    if (destroysVault) {
        reserveToncoinsOnBalance(0, RESERVE_MODE_EXACT_AMOUNT);
        createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: state.owner })
            .send(SEND_MODE_DESTROY_AND_CARRY_ALL);
    } else {
        assertAccounting(state);
        reserveVault();
        createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: state.owner })
            .send(SEND_MODE_CARRY_ALL_BALANCE);
    }
    return state;
}

fun handleRouteFailure(state: VaultState, sender: address, body: slice): VaultState {
    assert (sender == state.core && state.pendingMode == MODE_PLACE) throw 533;
    val queryId = body.loadUint(64);
    body.assertEnd();
    assert (queryId == state.queryId && state.cursor == 0) throw 534;
    state = resetOperation(state);
    reserveVault();
    createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: state.owner })
        .send(SEND_MODE_CARRY_ALL_BALANCE);
    return state;
}

fun continueOperation(state: VaultState, valueCoins: coins, body: slice): VaultState {
    body.assertEnd();
    assert (state.pendingMode != MODE_NONE && valueCoins >= MIN_OPERATION_GAS) throw 538;
    if (state.pendingMode == MODE_REFUND && state.onBoard == 0) {
        sendRefundRequest(state);
    } else {
        sendCurrentBatch(state);
    }
    return state;
}

fun handlePurchaseBounce(state: VaultState, body: slice): VaultState {
    val owner = body.loadAddress();
    body.loadAddressOpt(); // requested referrer
    val queryId = body.loadUint(64);
    val purchaseUnits = body.loadUint(32);
    body.loadUint(16); // batch count
    body.loadRef();
    body.assertEnd();
    assert (
        owner == state.owner
        && state.pendingMode == MODE_PLACE
        && queryId == state.queryId
        && state.cursor == 0
        && purchaseUnits > 0
        && purchaseUnits <= state.totalUnits - state.onBoard
    ) throw 539;
    state.totalUnits -= purchaseUnits;
    return resetOperation(state);
}

fun handleBoardRequestBounce(state: VaultState, body: slice, mode: int): VaultState {
    val owner = body.loadAddress();
    body.loadAddressOpt(); // requested referrer
    val queryId = body.loadUint(64);
    val cursor = body.loadUint(16);
    val batchCount = body.loadUint(16);
    body.loadRef();
    body.assertEnd();
    assert (
        owner == state.owner
        && state.pendingMode != MODE_NONE
        && queryId == state.queryId
        && cursor == state.cursor
        && batchCount == state.batchCount
    ) throw 539;
    val expectedMode = state.pendingMode == MODE_PLACE ? MODE_PLACE : MODE_REMOVE;
    assert (mode == expectedMode) throw 539;
    if (mode == MODE_PLACE) {
        state.onBoard += state.changedUnits;
        if (state.changedUnits > 0 && !state.referrerFixed) {
            state.referrerFixed = true;
        }
    } else {
        state.onBoard -= state.changedUnits;
    }
    return resetOperation(state);
}

fun handleRefundRequestBounce(state: VaultState, body: slice): VaultState {
    val owner = body.loadAddress();
    val queryId = body.loadUint(64);
    val units = body.loadUint(32);
    body.assertEnd();
    assert (
        owner == state.owner
        && state.pendingMode == MODE_REFUND
        && queryId == state.queryId
        && units == state.refundUnits
    ) throw 539;
    return resetOperation(state);
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }
    var state = loadState();
    assertAccounting(state);
    var body = in.body;
    val op = body.loadUint(32);
    if (op == OP_START_PLACE) {
        state = startPlace(state, in.senderAddress, in.valueCoins, body);
    } else if (op == OP_START_REMOVE) {
        state = startRemoval(state, in.senderAddress, in.valueCoins, body, false);
    } else if (op == OP_REFUND_ALL) {
        if (state.onBoard > 0) {
            state = startRemoval(state, in.senderAddress, in.valueCoins, body, true);
        } else {
            state = startRefundWithoutBoard(state, in.senderAddress, in.valueCoins, body);
        }
    } else if (op == OP_CONTINUE) {
        state = continueOperation(state, in.valueCoins, body);
    } else if (op == OP_CLAIM_TIMEOUT_REFUND) {
        state = requestPermissionlessRefund(
            state,
            in.valueCoins,
            body,
            OP_CORE_TIMEOUT_REFUND,
        );
    } else if (op == OP_CLAIM_AVAILABLE) {
        state = requestPermissionlessRefund(
            state,
            in.valueCoins,
            body,
            OP_CORE_AVAILABLE_REFUND,
        );
    } else if (op == OP_BATCH_RESULT) {
        state = applyBatchResult(state, in.senderAddress, body);
    } else if (
        op == OP_REFUND_RESULT
        || op == OP_TIMEOUT_REFUND_RESULT
        || op == OP_AVAILABLE_REFUND_RESULT
    ) {
        state = applyRefund(state, in.senderAddress, body, op);
    } else if (op == OP_ROUTE_FAILED) {
        state = handleRouteFailure(state, in.senderAddress, body);
    } else {
        throw 0xFFFF;
    }
    assertAccounting(state);
    saveState(state);
}

fun onBouncedMessage(in: InMessageBounced) {
    var state = loadState();
    assertAccounting(state);
    val rich = lazy RichBounceBody.fromSlice(in.bouncedBody);
    var body = rich.originalBody.beginParse();
    val op = body.loadUint(32);
    if (op == OP_CORE_PURCHASE_AND_PLACE) {
        state = handlePurchaseBounce(state, body);
    } else if (op == OP_BOARD_PLACE) {
        state = handleBoardRequestBounce(state, body, MODE_PLACE);
    } else if (op == OP_BOARD_REMOVE) {
        state = handleBoardRequestBounce(state, body, MODE_REMOVE);
    } else if (op == OP_CORE_REFUND) {
        state = handleRefundRequestBounce(state, body);
    } else if (op == OP_CORE_TIMEOUT_REFUND || op == OP_CORE_AVAILABLE_REFUND) {
        // Permissionless claims do not mutate Vault state before Core accepts.
    } else {
        throw 539;
    }
    assertAccounting(state);
    saveState(state);
    reserveVault();
    createMessage({ bounce: BounceMode.NoBounce, value: 0, dest: state.owner })
        .send(SEND_MODE_CARRY_ALL_BALANCE);
}

get fun vault_state(): (int, int, int, int, int, int, int, int, int, bool, int, int) {
    val state = loadState();
    var refWorkchain = 0;
    var refHash = 0;
    if (state.requestedReferrer != null) {
        (refWorkchain, refHash) = state.requestedReferrer!.getWorkchainAndHash();
    }
    return (
        state.roundId,
        state.status,
        state.totalUnits,
        state.onBoard,
        availableUnits(state),
        state.pendingMode,
        state.queryId,
        state.cursor,
        state.batchCount,
        state.referrerFixed,
        refWorkchain,
        refHash,
    );
}

get fun operation_state(): (int, int, int, int, int) {
    val state = loadState();
    return (state.lastQueryId, state.requestedUnits, state.changedUnits, state.plan.hash(), amountForUnits(state, state.totalUnits));
}
