// SPDX-License-Identifier: MIT

// DOSGRAM v2 board for a fixed-size round. The board is authoritative for
// cell ownership. A deterministic player Vault submits bounded batches and
// receives a receipt carrying all unused execution value back.

const OP_PURCHASE_AND_PLACE = 0x44505552; // "DPUR" (Core -> Board)
const OP_PLACE_BATCH = 0x44504C43;        // "DPLC" (Vault -> Board)
const OP_REMOVE_BATCH = 0x44524D56;       // "DRMV" (Vault -> Board)
const OP_RETRY_RECEIPT = 0x44525459;      // "DRTY" (permissionless)
const OP_BATCH_RESULT = 0x44524553;       // "DRES" (Board -> Vault)
const OP_SEAL = 0x5345414C;               // "SEAL"
const OP_BOARD_SEALED = 0x44425345;        // "DBSE" (Board -> Core)
const OP_RETRY_SEAL = 0x44525345;          // "DRSE" (permissionless)
const OP_RESOLVE_WINNERS = 0x4457494E;     // "DWIN" (Core -> Board)
const OP_WINNERS_RESULT = 0x44575253;      // "DWRS" (Board -> Core)

const MODE_PLACE = 1;
const MODE_REMOVE = 2;
const MAX_BOARD_CELLS = 1000;
const MAX_BATCH_CELLS = 32;
const FINAL_RECEIPT_GAS = 5000000;
const SEAL_NOTICE_GAS = 30000000;
const RETRY_MIN_VALUE = 40000000;

@inline
fun cellHash(value: cell): int
    asm "HASHCU";

struct BoardState {
    core: address;
    roundId: int;
    nanoPerGram: int;
    capacity: int;
    filled: int;
    sequence: int;
    sealed: bool;
    noRefUnits: int;
    vaultCode: cell;
    owners: map<uint16, address>;
    lastReceipts: map<address, cell>;
    referrers: map<address, address>;
    referralLocked: map<address, uint8>;
    referralUnits: map<address, uint32>;
}

fun loadState(): BoardState {
    var data = contract.getData().beginParse();
    val core = data.loadAddress();
    val roundId = data.loadUint(64);
    val nanoPerGram = data.loadUint(64);
    val capacity = data.loadUint(16);
    val filled = data.loadUint(16);
    val sequence = data.loadUint(32);
    val sealed = data.loadBool();
    val noRefUnits = data.loadUint(32);
    val vaultCode = data.loadRef();
    var ownership = data.loadRef().beginParse();
    var referrals = data.loadRef().beginParse();
    val state = BoardState {
        core,
        roundId,
        nanoPerGram,
        capacity,
        filled,
        sequence,
        sealed,
        noRefUnits,
        vaultCode,
        owners: createMapFromLowLevelDict<uint16, address>(ownership.loadDict()),
        lastReceipts: createMapFromLowLevelDict<address, cell>(ownership.loadDict()),
        referrers: createMapFromLowLevelDict<address, address>(ownership.loadDict()),
        referralLocked: createMapFromLowLevelDict<address, uint8>(referrals.loadDict()),
        referralUnits: createMapFromLowLevelDict<address, uint32>(referrals.loadDict()),
    };
    ownership.assertEnd();
    referrals.assertEnd();
    data.assertEnd();
    return state;
}

fun saveState(state: BoardState) {
    contract.setData(
        beginCell()
            .storeAddress(state.core)
            .storeUint(state.roundId, 64)
            .storeUint(state.nanoPerGram, 64)
            .storeUint(state.capacity, 16)
            .storeUint(state.filled, 16)
            .storeUint(state.sequence, 32)
            .storeBool(state.sealed)
            .storeUint(state.noRefUnits, 32)
            .storeRef(state.vaultCode)
            .storeRef(
                beginCell()
                    .storeDict(state.owners.toLowLevelDict())
                    .storeDict(state.lastReceipts.toLowLevelDict())
                    .storeDict(state.referrers.toLowLevelDict())
                    .endCell()
            )
            .storeRef(
                beginCell()
                    .storeDict(state.referralLocked.toLowLevelDict())
                    .storeDict(state.referralUnits.toLowLevelDict())
                    .endCell()
            )
            .endCell(),
    );
}

fun emptyVaultPlan(): cell {
    val emptyPlan: map<uint16, cell> = [];
    return beginCell().storeDict(emptyPlan.toLowLevelDict()).endCell();
}

fun initialVaultData(state: BoardState, owner: address): cell {
    return beginCell()
        .storeAddress(state.core)
        .storeAddress(contract.getAddress())
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

fun expectedVault(state: BoardState, owner: address): address {
    return AutoDeployAddress {
        workchain: owner.getWorkchain(),
        stateInit: ContractState {
            code: state.vaultCode,
            data: initialVaultData(state, owner),
        },
    }.calculateAddress();
}

fun parseAndValidateBatch(batch: cell, capacity: int): (int, slice) {
    var data = batch.beginParse();
    val count = data.loadUint(8);
    assert (count > 0 && count <= MAX_BATCH_CELLS) throw 501;
    val indices = data.loadBits(count * 16);
    data.assertEnd();

    var check = indices;
    var i = 0;
    while (i < count) {
        assert (check.loadUint(16) < capacity) throw 502;
        i += 1;
    }
    return (count, indices);
}

fun ownersRoot(state: BoardState): int {
    return cellHash(
        beginCell()
            .storeUint(state.capacity, 16)
            .storeUint(state.filled, 16)
            .storeUint(state.noRefUnits, 32)
            .storeDict(state.owners.toLowLevelDict())
            .storeDict(state.referrers.toLowLevelDict())
            .storeDict(state.referralUnits.toLowLevelDict())
            .endCell()
    );
}

fun addReferralUnits(state: BoardState, referrer: address, delta: int): BoardState {
    val found = state.referralUnits.get(referrer);
    val current = found.isFound ? found.loadValue() as int : 0;
    val next = current + delta;
    assert (next >= 0) throw 517;
    if (next == 0) {
        state.referralUnits.delete(referrer);
    } else {
        state.referralUnits.set(referrer, next as uint32);
    }
    return state;
}

fun sendReceipt(vault: address, receipt: cell, finalReceipt: bool) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: finalReceipt ? FINAL_RECEIPT_GAS : 0,
        dest: vault,
        body: beginCell()
            .storeUint(OP_BATCH_RESULT, 32)
            .storeSlice(receipt.beginParse())
            .endCell(),
    }).send(finalReceipt ? SEND_MODE_PAY_FEES_SEPARATELY : SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun sendSealNotice(state: BoardState) {
    createMessage({
        bounce: BounceMode.RichBounce,
        value: SEAL_NOTICE_GAS,
        dest: state.core,
        body: beginCell()
            .storeUint(OP_BOARD_SEALED, 32)
            .storeUint(state.roundId, 64)
            .storeUint(state.capacity, 16)
            .storeUint(ownersRoot(state), 256)
            .storeUint(state.noRefUnits, 32)
            .storeRef(beginCell().storeDict(state.referralUnits.toLowLevelDict()).endCell())
            .endCell(),
    }).send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun applyBatch(
    state: BoardState,
    sender: address,
    body: slice,
    mode: int,
    fromCore: bool,
): BoardState {
    assert (!state.sealed) throw 503;
    val vault = fromCore ? body.loadAddress() : sender;
    val owner = body.loadAddress();
    val requestedReferrer = body.loadAddressOpt();
    val queryId = body.loadUint(64);
    val cursor = body.loadUint(16);
    val batchCount = body.loadUint(16);
    val batch = body.loadRef();
    body.assertEnd();
    assert (batchCount > 0 && cursor < batchCount) throw 504;
    assert (vault == expectedVault(state, owner)) throw 505;
    if (fromCore) {
        assert (sender == state.core && cursor == 0 && mode == MODE_PLACE) throw 506;
    }
    if (requestedReferrer != null) {
        assert (requestedReferrer! != owner) throw 518;
    }

    val (attempted, indices) = parseAndValidateBatch(batch, state.capacity);
    val previous = state.lastReceipts.get(vault);
    if (previous.isFound) {
        val receipt = previous.loadValue();
        var saved = receipt.beginParse();
        val savedQueryId = saved.loadUint(64);
        val savedCursor = saved.loadUint(16);
        val savedBatchCount = saved.loadUint(16);
        saved.loadUint(8);
        saved.loadUint(8);
        val savedMode = saved.loadUint(2);
        val savedBatchHash = saved.loadUint(256);
        saved.assertEnd();
        if (savedQueryId == queryId && savedCursor == cursor && savedMode == mode) {
            assert (savedBatchCount == batchCount && savedBatchHash == batch.hash()) throw 507;
            sendReceipt(vault, receipt, false);
            return state;
        }
    }

    var changed = 0;
    var cells = indices;
    var i = 0;
    while (i < attempted) {
        val cellIndex = cells.loadUint(16);
        if (mode == MODE_PLACE) {
            if (state.owners.addIfNotExists(cellIndex, owner)) {
                changed += 1;
            }
        } else {
            val current = state.owners.get(cellIndex);
            if (current.isFound && current.loadValue() == owner) {
                assert (state.owners.delete(cellIndex)) throw 508;
                changed += 1;
            }
        }
        i += 1;
    }

    if (mode == MODE_PLACE) {
        state.filled += changed;
    } else {
        state.filled -= changed;
    }
    if (changed > 0) {
        if (mode == MODE_PLACE && !state.referralLocked.exists(owner)) {
            state.referralLocked.set(owner, 1);
            if (requestedReferrer != null) {
                state.referrers.set(owner, requestedReferrer!);
            }
        }
        val referrer = state.referrers.get(owner);
        if (requestedReferrer != null) {
            assert (referrer.isFound && referrer.loadValue() == requestedReferrer!) throw 518;
        }
        if (referrer.isFound) {
            state = addReferralUnits(
                state,
                referrer.loadValue(),
                mode == MODE_PLACE ? changed : -changed,
            );
        } else {
            state.noRefUnits += mode == MODE_PLACE ? changed : -changed;
            assert (state.noRefUnits >= 0) throw 517;
        }
    }
    assert (state.filled >= 0 && state.filled <= state.capacity) throw 509;
    state.sequence += 1;
    val receipt = beginCell()
        .storeUint(queryId, 64)
        .storeUint(cursor, 16)
        .storeUint(batchCount, 16)
        .storeUint(attempted, 8)
        .storeUint(changed, 8)
        .storeUint(mode, 2)
        .storeUint(batch.hash(), 256)
        .endCell();
    state.lastReceipts.set(vault, receipt);
    val sealsNow = mode == MODE_PLACE && state.filled == state.capacity;
    if (sealsNow) {
        state.sealed = true;
    }
    sendReceipt(vault, receipt, sealsNow);
    if (sealsNow) {
        sendSealNotice(state);
    }
    return state;
}

fun retryReceipt(state: BoardState, body: slice) {
    val vault = body.loadAddress();
    body.assertEnd();
    val receipt = state.lastReceipts.mustGet(vault, 510);
    sendReceipt(vault, receipt, false);
}

fun resolveWinners(state: BoardState, sender: address, body: slice) {
    assert (sender == state.core && state.sealed) throw 512;
    val root = body.loadUint(256);
    val winnerIndex = body.loadUint(32);
    val hasBonus = body.loadBool();
    val bonusWinnerIndex = body.loadUint(32);
    body.assertEnd();
    assert (root == ownersRoot(state)) throw 513;
    assert (winnerIndex < state.capacity) throw 514;
    val winner = state.owners.mustGet(winnerIndex, 515);
    var bonusWinner: address? = null;
    if (hasBonus) {
        assert (bonusWinnerIndex < state.capacity) throw 514;
        bonusWinner = state.owners.mustGet(bonusWinnerIndex, 515);
    }
    createMessage({
        bounce: BounceMode.RichBounce,
        value: 0,
        dest: state.core,
        body: beginCell()
            .storeUint(OP_WINNERS_RESULT, 32)
            .storeUint(root, 256)
            .storeAddress(winner)
            .storeBool(hasBonus)
            .storeAddressOpt(bonusWinner)
            .endCell(),
    }).send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }
    // Preserve the Board's pre-message balance. All permissionless retries and
    // callbacks must be funded by the current inbound message.
    val balanceBeforeMessage = contract.getOriginalBalance() - in.valueCoins;
    reserveToncoinsOnBalance(balanceBeforeMessage, RESERVE_MODE_EXACT_AMOUNT);
    var state = loadState();
    assert (state.capacity > 0 && state.capacity <= MAX_BOARD_CELLS) throw 511;
    var body = in.body;
    val op = body.loadUint(32);
    if (op == OP_PURCHASE_AND_PLACE) {
        state = applyBatch(state, in.senderAddress, body, MODE_PLACE, true);
        saveState(state);
    } else if (op == OP_PLACE_BATCH) {
        state = applyBatch(state, in.senderAddress, body, MODE_PLACE, false);
        saveState(state);
    } else if (op == OP_REMOVE_BATCH) {
        state = applyBatch(state, in.senderAddress, body, MODE_REMOVE, false);
        saveState(state);
    } else if (op == OP_RETRY_RECEIPT) {
        retryReceipt(state, body);
    } else if (op == OP_RETRY_SEAL) {
        body.assertEnd();
        assert (in.valueCoins >= RETRY_MIN_VALUE) throw 516;
        assert (state.sealed && state.filled == state.capacity) throw 503;
        sendSealNotice(state);
    } else if (op == OP_RESOLVE_WINNERS) {
        resolveWinners(state, in.senderAddress, body);
    } else if (op == OP_SEAL) {
        throw 0xFFFF;
    } else {
        throw 0xFFFF;
    }
}

get fun board_state(): (int, int, int, int, bool, int) {
    val state = loadState();
    return (state.roundId, state.capacity, state.filled, state.sequence, state.sealed, ownersRoot(state));
}

get fun owner_of(cellIndex: int): (int, int, int) {
    val state = loadState();
    assert (cellIndex >= 0 && cellIndex < state.capacity) throw 502;
    val found = state.owners.get(cellIndex);
    if (!found.isFound) {
        return (0, 0, 0);
    }
    val (workchain, hash) = found.loadValue().getWorkchainAndHash();
    return (1, workchain, hash);
}

get fun expected_vault(owner: address): address {
    return expectedVault(loadState(), owner);
}

get fun protocol_limits(): (int, int) {
    return (MAX_BOARD_CELLS, MAX_BATCH_CELLS);
}
