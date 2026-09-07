import "@stdlib/gas-payments"
import "errors"
import "sharding"

const STORAGE_SIZE_MAX_WALLET_BITS = 1026
const STORAGE_SIZE_MAX_WALLET_CELLS = 3
const STORAGE_SIZE_INIT_STATE_WALLET_BITS = 812
const STORAGE_SIZE_INIT_STATE_WALLET_CELLS = 3

const MESSAGE_SIZE_BURN_NOTIFICATION_BITS = 754
const MESSAGE_SIZE_BURN_NOTIFICATION_CELLS = 1
const MIN_STORAGE_DURATION = 5 * 365 * 24 * 3600

const GAS_CONSUMPTION_JETTON_TRANSFER = 6327
const GAS_CONSUMPTION_JETTON_RECEIVE = 7443
const GAS_CONSUMPTION_BURN_REQUEST = 4254
const GAS_CONSUMPTION_BURN_NOTIFICATION = 4071

// SAFETY: GETPRECOMPILEDGAS is read-only; callers use the reference gas fallback on null.
fun getPrecompiledGasConsumption(): int?
    asm "GETPRECOMPILEDGAS"

fun calculateJettonWalletMinStorageFee(): coins {
    return calculateStorageFee(
        MY_WORKCHAIN,
        MIN_STORAGE_DURATION,
        STORAGE_SIZE_MAX_WALLET_BITS,
        STORAGE_SIZE_MAX_WALLET_CELLS,
    );
}

fun forwardInitStateOverhead(): coins {
    return calculateForwardFeeWithoutLumpPrice(
        MY_WORKCHAIN,
        STORAGE_SIZE_INIT_STATE_WALLET_BITS,
        STORAGE_SIZE_INIT_STATE_WALLET_CELLS,
    );
}

fun calcMinimalTransferAmount(forwardTonAmount: int, fwdFee: int): int {
    val fwdCount = forwardTonAmount != 0 ? 2 : 1;
    val precompiledGas = getPrecompiledGasConsumption();
    val sendGas = precompiledGas == null ? GAS_CONSUMPTION_JETTON_TRANSFER : precompiledGas;
    val receiveGas = precompiledGas == null ? GAS_CONSUMPTION_JETTON_RECEIVE : precompiledGas;

    return forwardTonAmount + fwdCount * fwdFee + forwardInitStateOverhead() +
    calculateGasFee(MY_WORKCHAIN, sendGas) +
    calculateGasFee(MY_WORKCHAIN, receiveGas) +
    calculateJettonWalletMinStorageFee();
}

fun checkAmountIsEnoughToTransfer(msgValue: int, forwardTonAmount: int, fwdFee: int) {
    assert (
        msgValue > calcMinimalTransferAmount(forwardTonAmount, fwdFee)
    ) throw Errors.NotEnoughGas;
}

fun calcMinimalBurnAmount(): coins {
    val precompiledGas = getPrecompiledGasConsumption();
    val sendGas = precompiledGas == null ? GAS_CONSUMPTION_BURN_REQUEST : precompiledGas;

    return calculateForwardFee(
        MY_WORKCHAIN,
        MESSAGE_SIZE_BURN_NOTIFICATION_BITS,
        MESSAGE_SIZE_BURN_NOTIFICATION_CELLS,
    ) +
    calculateGasFee(MY_WORKCHAIN, sendGas) +
    calculateGasFee(MY_WORKCHAIN, GAS_CONSUMPTION_BURN_NOTIFICATION);
}

fun checkAmountIsEnoughToBurn(msgValue: int) {
    assert (msgValue > calcMinimalBurnAmount()) throw Errors.NotEnoughGas;
}
