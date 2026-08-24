import "@stdlib/gas-payments"

const DEPOSIT_GAS_UNITS: int = 3000

const WITHDRAW_GAS_UNITS: int = 9500

const WITHDRAW_GAS: coins = ton("0.05")

const MIN_WITHDRAW: coins = ton("0.01")

@inline
fun depositGasAllowance(): coins {
    return calculateGasFee(BASECHAIN, DEPOSIT_GAS_UNITS);
}

@inline
fun payoutForwardFee(): coins {
    return calculateForwardFee(BASECHAIN, 0, 0);
}

@inline
fun minWithdrawValue(): coins {
    return max(WITHDRAW_GAS, calculateGasFee(BASECHAIN, WITHDRAW_GAS_UNITS) + payoutForwardFee());
}

struct Participant {
    shares: uint32
    withdrawn: coins
}

struct Storage {
    totalShares: uint32
    reserveFloor: coins
    distributedCumulative: coins = 0
    participants: map<address, Participant>
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData())
}

fun Storage.save(self) {
    contract.setData(self.toCell())
}

struct (0x57535744) Withdraw {
    amount: coins
    toAddress: address?
}

type AllowedMessage = Withdraw

contract WorkSplitVault {
    storage: Storage
    incomingMessages: AllowedMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessage.fromSlice(in.body);
    match (msg) {
        Withdraw => {

            handleWithdraw(in.senderAddress, in.valueCoins, msg);
        }
        else => {

            handleDeposit(in.valueCoins);
        }
    }
}

fun handleDeposit(valueCoins: coins) {
    var s = Storage.load();

    val balanceBefore = contract.getOriginalBalance() - valueCoins;

    val topup = min(valueCoins, max(0, s.reserveFloor - balanceBefore));

    val credit = max(0, valueCoins - topup - depositGasAllowance());

    s.distributedCumulative += credit;
    s.save();

}

fun handleWithdraw(senderAddress: address, valueCoins: coins, msg: Withdraw) {

    if (valueCoins < minWithdrawValue()) {
        return;
    }

    var s = Storage.load();

    val found = s.participants.get(senderAddress);
    if (!found.isFound) {

        refundChange(senderAddress);
        return;
    }

    var p = found.loadValue();

    val entitlement = mulDivFloor(s.distributedCumulative, p.shares, s.totalShares) - p.withdrawn;
    val requested = msg.amount == 0 ? entitlement : min(msg.amount, entitlement);

    if (requested < MIN_WITHDRAW) {
        refundChange(senderAddress);
        return;
    }

    p.withdrawn += requested;
    s.participants.set(senderAddress, p);
    s.save();

    reserveToncoinsOnBalance(s.reserveFloor, RESERVE_MODE_AT_MOST);

    val dest = msg.toAddress ?? senderAddress;
    val payout = createMessage({
        bounce: BounceMode.NoBounce,
        value: requested,
        dest,
    });
    payout.send(SEND_MODE_PAY_FEES_SEPARATELY);

    val change = valueCoins - calculateGasFee(BASECHAIN, WITHDRAW_GAS_UNITS) - payoutForwardFee();
    if (change > 0) {
        val back = createMessage({
            bounce: BounceMode.NoBounce,
            value: change,
            dest: senderAddress,
        });
        back.send(SEND_MODE_REGULAR);
    }
}

fun refundChange(to: address) {
    val change = createMessage({
        bounce: BounceMode.NoBounce,
        value: 0,
        dest: to,
    });

    change.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

const VERSION: int = 2

get fun contractVersion(): int {
    return VERSION;
}

struct VaultInfo {
    totalShares: uint32
    reserveFloor: coins
    distributedCumulative: coins
}

get fun vaultInfo(): VaultInfo {
    val s = lazy Storage.load();
    return {
        totalShares: s.totalShares,
        reserveFloor: s.reserveFloor,
        distributedCumulative: s.distributedCumulative,
    }
}

struct FeeInfo {
    depositGasAllowance: coins
    payoutForwardFee: coins
    minDeployValue: coins
    minWithdrawValue: coins
}

get fun feeInfo(): FeeInfo {
    val s = lazy Storage.load();
    val allowance = depositGasAllowance();
    return {
        depositGasAllowance: allowance,
        payoutForwardFee: payoutForwardFee(),
        minDeployValue: s.reserveFloor + allowance,
        minWithdrawValue: minWithdrawValue(),
    }
}

get fun entitlementOf(owner: address): coins {
    val s = lazy Storage.load();
    val found = s.participants.get(owner);
    if (!found.isFound) {
        return 0;
    }
    val p = found.loadValue();
    return mulDivFloor(s.distributedCumulative, p.shares, s.totalShares) - p.withdrawn;
}

get fun withdrawnOf(owner: address): coins {
    val s = lazy Storage.load();
    val found = s.participants.get(owner);
    if (!found.isFound) {
        return 0;
    }
    return found.loadValue().withdrawn;
}
