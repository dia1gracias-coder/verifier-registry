import "@stdlib/gas-payments"

import "errors"
import "sharding"

/// The configured APE claim charge is the total value sent by the user's wallet.
/// It follows the complete claim trace as carry-value, so compute, forwarding,
/// wallet deployment and storage costs are deducted from this one amount and
/// only the actual remainder reaches treasury.
const APE_MIN_CLAIM_TOTAL_VALUE = ton("0.05")
const APE_MINTER_STORAGE_RESERVE = ton("0.10")

/// The admin funds withdrawal execution separately. The requested amount is
/// limited to the balance that existed before this request, and the storage
/// reserve is protected by RAWRESERVE in the action phase.
const APE_TREASURY_WITHDRAW_REQUEST_VALUE = ton("0.05")

/// Global transfer policy adds one authenticated wallet -> master -> wallet hop.
const APE_TRANSFER_POLICY_PROCESSING_BUFFER = ton("0.02")
const APE_TRANSFER_POLICY_REQUEST_VALUE = ton("0.05")

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
const GAS_CONSUMPTION_TRANSFER_POLICY = 4842
const GAS_CONSUMPTION_POLICY_DECISION = 7480

// SAFETY: Safe opcode, returning int/null
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

    val jettonWalletGasConsumption = getPrecompiledGasConsumption();
    val sendTransferGasConsumption = (jettonWalletGasConsumption == null)
        ? GAS_CONSUMPTION_JETTON_TRANSFER
        : jettonWalletGasConsumption;
    val receiveTransferGasConsumption = (jettonWalletGasConsumption == null)
        ? GAS_CONSUMPTION_JETTON_RECEIVE
        : jettonWalletGasConsumption;

    // Besides the standard wallet-to-wallet transfer, the global freeze
    // policy requires wallet -> minter -> wallet authorization. Include both
    // forward fees, the minter's retained processing allowance and the gas of
    // the policy/decision handlers so the accepted edge value is executable.
    return forwardTonAmount + (fwdCount + 2) * fwdFee + forwardInitStateOverhead() +
    calculateGasFee(MY_WORKCHAIN, sendTransferGasConsumption) +
    calculateGasFee(MY_WORKCHAIN, receiveTransferGasConsumption) +
    calculateGasFee(MY_WORKCHAIN, GAS_CONSUMPTION_TRANSFER_POLICY) +
    calculateGasFee(MY_WORKCHAIN, GAS_CONSUMPTION_POLICY_DECISION) +
    APE_TRANSFER_POLICY_PROCESSING_BUFFER +
    calculateJettonWalletMinStorageFee();
}

fun checkAmountIsEnoughToTransfer(msgValue: int, forwardTonAmount: int, fwdFee: int) {
    val minTransferAmount = calcMinimalTransferAmount(forwardTonAmount, fwdFee);
    assert (msgValue > minTransferAmount) throw Errors.NotEnoughGas;
}

fun calcMinimalBurnAmount(): coins {
    val jettonWalletGasConsumption = getPrecompiledGasConsumption();
    val sendBurnGasConsumption = (jettonWalletGasConsumption == null)
        ? GAS_CONSUMPTION_BURN_REQUEST
        : jettonWalletGasConsumption;

    return calculateForwardFee(
        MY_WORKCHAIN,
        MESSAGE_SIZE_BURN_NOTIFICATION_BITS,
        MESSAGE_SIZE_BURN_NOTIFICATION_CELLS,
    ) +
    calculateGasFee(MY_WORKCHAIN, sendBurnGasConsumption) +
    calculateGasFee(MY_WORKCHAIN, GAS_CONSUMPTION_BURN_NOTIFICATION);
}

fun checkAmountIsEnoughToBurn(msgValue: int) {
    val minBurnAmount = calcMinimalBurnAmount();
    assert (msgValue > minBurnAmount) throw Errors.NotEnoughGas;
}
