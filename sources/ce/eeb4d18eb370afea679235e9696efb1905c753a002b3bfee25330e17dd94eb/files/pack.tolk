import "@stdlib/common"
import "@stdlib/gas-payments"
import "@stdlib/tvm-dicts"
import "common/errors"
import "common/const"
import "stickerpack/price"
import "stickerpack/storage"
import "stickerpack/types"

struct (0xda03b40) BuyPackMsg {
    amount: uint16;
}

struct (0xf776c5d1) SellCallbackMsg {
    amount: uint16;
    user: address;
}

struct (0x7cf3ee5c) AdminStopMsg {
    stop: bool;
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    val storage:Storage = loadStorage();
    var bodySlice = in.body;
    val opcode = bodySlice.loadUint(32);

    if (opcode == 0x7cf3ee5c) {
        val stop = bodySlice.loadBool();
        val msg = AdminStopMsg{
            stop: stop,
        };
        return handle_admin_stop(storage, in.senderAddress, msg);
    }

    assert (in.createdAt >= storage.startTime) throw ERROR_PACK_NOT_STARTED_YET;
    if (opcode == 0xda03b40) {
        val amount = bodySlice.loadUint(16);
        val msg = BuyPackMsg{
            amount: amount,
        };
        return handle_buy_pack(storage, in.senderAddress, in.valueCoins, msg);
    } else if (opcode == 0xf776c5d1) {
        val msg = SellCallbackMsg{
            amount: bodySlice.loadUint(16),
            user: bodySlice.loadAddress(),
        };
        return handle_sell_callback(storage, in.senderAddress, in.valueCoins, msg);
    } else if (opcode == 0xb977610b) {
        return handle_beneficiary_withdraw(storage);
    } else if (opcode == 0xcf3ad223) {
        return handle_protocol_fees(storage);
    } else {
        throw ERROR_UNKNOWN_OPCODE;
    }
}

fun handle_buy_pack(storage: Storage, senderAddress: address, valueCoins: coins, msg: BuyPackMsg) {
    assert (storage.currentSupply < storage.packThreshold) throw ERROR_THRESHOLD_REACHED;
    assert (msg.amount > 0 && (msg.amount + storage.currentSupply) <= storage.packThreshold) throw ERROR_INVALID_AMOUNT;
    assert (storage.isStopped == false) throw ERROR_PACK_STOPPED;

    var buyData = initOperationsData(true);
    var i = 0;
    // hard limit max items per transaction
    while (i < msg.amount && i < MAX_PACKS_PER_TRANSACTION) {
        var current_price:coins = getPrice(storage, storage.currentSupply);
        var protocol_fee:coins = current_price * storage.protocolFeeBuy / 100;

        buyData.AddItem(current_price, protocol_fee);

        storage.currentSupply += 1;
        storage.protocolFeeBalance += protocol_fee;

        i += 1;
    }

    assert (buyData.coinsValue > 0 && buyData.fees > 0) throw ERROR_INVALID_PRICE_DATA;
    assert (valueCoins >= buyData.fees + buyData.coinsValue + ton("0.1")) throw ERROR_NOT_ENOUGH_VALUE;

    storage.beneficiaryBalance += buyData.coinsValue;
    var excess: int = valueCoins - (buyData.fees + buyData.coinsValue);
    storage.Save();

    buyData.SendLog(LOG_TOPIC_BUY);

    if (excess > 0) {
        val reply = createMessage({
            bounce: true,
            value: excess,
            dest: senderAddress,
            body: "Excess refund"
        });
        reply.send(SEND_MODE_REGULAR);
    }
    deployOrUpdateUserHoldings(storage, senderAddress, msg.amount)
}

fun handle_sell_callback(storage: Storage, senderAddress: address, valueCoins: coins, msg: SellCallbackMsg) {
    val userHoldingsContract = generateUserHoldingAddress(msg.user, storage.userHoldingCode);
    assert (userHoldingsContract == senderAddress) throw ERROR_USER_HOLDINGS_ADDRESS_ERROR;
    assert (msg.amount > 0) throw ERROR_INVALID_AMOUNT;
    if (storage.currentSupply >= storage.packThreshold) {
        val reply = createMessage({
            bounce: true,
            value: ton("0.1"),
            dest: userHoldingsContract,
            body: beginCell()
                .storeUint(0xef4247f9, 32)
                .storeUint(msg.amount, 16)
                .endCell(),
        });
        reply.send(SEND_MODE_REGULAR);
        throw ERROR_THRESHOLD_REACHED;
    }
    var sellData = initOperationsData(false);
    var i = 0;
    while (i < msg.amount && i < MAX_PACKS_PER_TRANSACTION) {
        val current_price:coins = getPrice(storage, storage.currentSupply - 1);
        val protocol_fee:coins = current_price * storage.protocolFeeSell / 100;

        sellData.AddItem((current_price - protocol_fee), protocol_fee);

        storage.currentSupply -= 1;
        storage.protocolFeeBalance += protocol_fee;

        i += 1;
    }
    storage.Save();

    sellData.SendLog(LOG_TOPIC_SELL);

    val reply = createMessage({
        bounce: true,
        value: sellData.coinsValue,
        dest: msg.user,
        body: "pack sold"
    });
    reply.send(SEND_MODE_REGULAR);
}

fun handle_protocol_fees(storage: Storage) {
    val feeBalance = storage.protocolFeeBalance;
    assert (feeBalance > 0) throw ERROR_PROTOCOL_FEE_BALANCE_EMPTY;
    storage.protocolFeeBalance = 0;
    val extendedStorage = storage.Save();

    val reply = createMessage({
        bounce: true,
        value: feeBalance,
        dest: extendedStorage.protocolFeeAddress,
        body: "withdraw"
    });
    reply.send(SEND_MODE_REGULAR);
}

fun handle_beneficiary_withdraw(storage: Storage) {
    assert (storage.currentSupply >= storage.packThreshold) throw ERROR_THRESHOLD_NOT_REACHED;
    val beneficiaryBalance = storage.beneficiaryBalance;
    assert (beneficiaryBalance > 0) throw ERROR_NOT_ENOUGH_VALUE;
    storage.beneficiaryBalance = 0;
    val extendedStorage = storage.Save();

    val reply = createMessage({
        bounce: false,
        value: beneficiaryBalance,
        dest: extendedStorage.beneficiaryAddress,
        body: "withdraw"
    });
    reply.send(SEND_MODE_REGULAR);
}

fun handle_admin_stop(storage: Storage, senderAddress: address, msg: AdminStopMsg) {
    val extendedStorage = loadExtendedStorage();
    assert (extendedStorage.factoryAddress == senderAddress) throw ERROR_ACCESS_RESTRICTION;
    storage.isStopped = msg.stop;
    storage.Save();
    val emitMsg = createExternalLogMessage({
        dest: ExtOutLogBucket{
            topic: LOG_TOPIC_ADMIN_STOP,
        },
        body: msg.stop,
    });
    emitMsg.send(SEND_MODE_REGULAR);
}

get fun get_current_price(): coins {
    val storage = loadStorage();
    return getPrice(storage, storage.currentSupply);
}

get fun get_price_at_supply(supply:uint16): coins {
    val storage = loadStorage();
    if (supply == 0) {
        return storage.startPrice;
    }
    return getPrice(storage, supply);
}

get fun get_current_buy_price(): coins {
    val storage = loadStorage();
    return getBuyPrice(storage, storage.currentSupply);
}

get fun get_buy_price_at_supply(atSupply:uint16): coins {
    val storage = loadStorage();
    return getBuyPrice(storage, atSupply);
}

get fun get_current_sell_price(): coins {
    val storage = loadStorage();
    return getSellPrice(storage, storage.currentSupply);
}

get fun get_sell_price_at_supply(atSupply:uint16): coins {
    val storage = loadStorage();
    return getSellPrice(storage, atSupply);
}

get fun get_current_supply(): uint16 {
    val storage = loadStorage();
    return storage.currentSupply;
}

get fun get_protocol_fee_balance(): coins {
    val storage = loadStorage();
    return storage.protocolFeeBalance;
}

get fun get_beneficiary_address(): address {
    val extendedStorage = loadExtendedStorage();
    return extendedStorage.beneficiaryAddress;
}

get fun get_beneficiary_balance(): coins {
    val storage = loadStorage();
    return storage.beneficiaryBalance;
}

get fun get_threshold(): uint16 {
    val storage = loadStorage();
    return storage.packThreshold;
}

get fun get_params(): (uint128, uint16, uint16, uint4, uint16, uint16, uint32, bool, coins, coins) {
    val storage = loadStorage();
    return (
        storage.contractId,
        storage.packThreshold,
        storage.priceCoefficient,
        storage.priceAlgo,
        storage.protocolFeeBuy,
        storage.protocolFeeSell,
        storage.startTime,
        storage.isStopped,
        storage.startPrice,
        storage.endPrice,
    );
}

get fun get_user_holdings_address(user:address): address {
    val storage = loadStorage();
    return generateUserHoldingAddress(user, storage.userHoldingCode);
}

get fun get_contract_id(): uint128 {
    val storage = loadStorage();
    return storage.contractId;
}

@inline
fun getBuyPrice(storage: Storage, atSupply: uint16): coins {
    val price = getPrice(storage, atSupply);
    return price + (price * storage.protocolFeeBuy / PRECISION_PIPS);
}

@inline
fun getSellPrice(storage: Storage, atSupply: uint16): coins {
    if (storage.currentSupply < 1) {
        return storage.startPrice - (storage.startPrice * storage.protocolFeeSell) / PRECISION_PIPS;
    } else {
        val price = getPrice(storage, storage.currentSupply - 1);
        return price - (price * storage.protocolFeeSell / PRECISION_PIPS);
    }
}

@inline
fun generateUserHoldingAddress(userAddress: address, userHoldingCode: cell): address {
    return address.fromValidBuilder(
        AutoDeployAddress{
            stateInit: generateUserHoldingsStateData(contract.getAddress(), userAddress, userHoldingCode)
        }.buildAddress()
    );
}

@inline
fun generateUserHoldingsStateData(packAddress: address, senderAddress: address, userHoldingCode: cell): ContractState {
    val initData = beginCell()
        .storeUint(0, 16)
        .storeAddress(packAddress)
        .storeAddress(senderAddress)
        .endCell();
    return ContractState{
        code: userHoldingCode,
        data: initData,
    }
}

@inline
fun deployOrUpdateUserHoldings(storage: Storage, senderAddress:address, amount: uint16) {
    val deployOrUpdateUserHoldingsMsg = createMessage({
        dest: {
            stateInit: generateUserHoldingsStateData(contract.getAddress(), senderAddress, storage.userHoldingCode),
        },
        value: ton("0.1"),
        body: beginCell()
            .storeUint(0xef4247f9, 32)
            .storeUint(amount, 16)
            .endCell(),
        bounce: false,
    });
    deployOrUpdateUserHoldingsMsg.send(SEND_MODE_REGULAR);
}