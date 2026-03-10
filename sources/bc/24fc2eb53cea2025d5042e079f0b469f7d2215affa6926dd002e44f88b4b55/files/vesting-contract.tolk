import "@stdlib/gas-payments"
import "storage"

// Gaia Team Vesting Contract
// Locks GAIA jettons with a cliff period and linear unlock schedule.
// Only the beneficiary can claim unlocked tokens.
// Once deployed, the schedule is immutable.

const ERR_VESTING_NOT_BENEFICIARY = 801
const ERR_VESTING_NOTHING_TO_CLAIM = 802

struct VestingData {
    beneficiaryAddress: address
    minterAddress: address
    jettonWalletCode: cell
    totalAllocation: coins
    totalClaimed: coins
    startTime: uint32
    cliffDuration: uint32
    vestingDuration: uint32
}

fun VestingData.load() {
    return VestingData.fromCell(contract.getData())
}

fun VestingData.save(self) {
    contract.setData(self.toCell())
}

fun calcVestedAmount(totalAllocation: int, startTime: int, cliffDuration: int, vestingDuration: int, nowTime: int): int {
    if (nowTime < startTime) {
        return 0;
    }

    val elapsed = nowTime - startTime;

    // During cliff: nothing vested
    if (elapsed < cliffDuration) {
        return 0;
    }

    // After full vesting: everything vested
    if (elapsed >= vestingDuration) {
        return totalAllocation;
    }

    // Linear vesting: totalAllocation * elapsed / vestingDuration
    return totalAllocation * elapsed / vestingDuration;
}

fun calcVestingJettonWallet(ownerAddress: address, minterAddress: address, jettonWalletCode: cell): address {
    val emptyWalletStorage: WalletStorage = {
        jettonBalance: 0,
        ownerAddress,
        minterAddress,
    };

    val deployed: AutoDeployAddress = {
        stateInit: {
            code: jettonWalletCode,
            data: emptyWalletStorage.toCell()
        }
    };

    return deployed.calculateAddress();
}

fun onInternalMessage(in: InMessage) {
    // Accept incoming messages silently if body too short
    if (in.body.remainingBitsCount() < 32) {
        return;
    }

    val op = in.body.preloadUint(32);

    // Accept TON deposits (for gas)
    if (op == 0) {
        return;
    }

    // Accept jetton transfer notifications (InternalTransferStep)
    if (op == 0x178d4519) {
        return;
    }

    // Accept jetton transfer notifications (TransferNotificationForRecipient)
    if (op == 0x7362d09c) {
        return;
    }

    // ClaimVested (0x00000020)
    assert (op == 0x00000020) throw 0xFFFF;

    in.body.loadUint(32);
    val queryId = in.body.loadUint(64);

    var storage = lazy VestingData.load();
    assert (in.senderAddress == storage.beneficiaryAddress) throw ERR_VESTING_NOT_BENEFICIARY;

    val nowTime: int = blockchain.now();

    val vestedAmount = calcVestedAmount(
        storage.totalAllocation,
        storage.startTime,
        storage.cliffDuration,
        storage.vestingDuration,
        nowTime
    );

    val claimable = vestedAmount - storage.totalClaimed;
    assert (claimable > 0) throw ERR_VESTING_NOTHING_TO_CLAIM;

    storage.totalClaimed += claimable;
    storage.save();

    // Send AskToTransfer (0x0f8a7ea5) to our jetton wallet
    val transferBody = beginCell()
        .storeUint(0x0f8a7ea5, 32)
        .storeUint(queryId, 64)
        .storeCoins(claimable)
        .storeAddress(storage.beneficiaryAddress)  // transfer recipient
        .storeAddress(storage.beneficiaryAddress)  // send excesses to
        .storeBool(false)   // no custom payload
        .storeCoins(0)      // no forward TON
        .storeBool(false)   // forward payload (1 bit minimum)
        .endCell();

    // Compute our jetton wallet address using same method as jetton-utils
    val vestingWallet = calcVestingJettonWallet(
        contract.getAddress(),
        storage.minterAddress,
        storage.jettonWalletCode
    );

    val transferMsg = createMessage({
        bounce: BounceMode.Only256BitsOfBody,
        dest: vestingWallet,
        value: 0,
        body: transferBody,
    });
    transferMsg.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE | SEND_MODE_PAY_FEES_SEPARATELY);
}

struct VestingInfoReply {
    beneficiaryAddress: address
    totalAllocation: coins
    totalClaimed: coins
    startTime: uint32
    cliffDuration: uint32
    vestingDuration: uint32
}

get fun get_vesting_info(): VestingInfoReply {
    val storage = lazy VestingData.load();
    return {
        beneficiaryAddress: storage.beneficiaryAddress,
        totalAllocation: storage.totalAllocation,
        totalClaimed: storage.totalClaimed,
        startTime: storage.startTime,
        cliffDuration: storage.cliffDuration,
        vestingDuration: storage.vestingDuration,
    }
}

get fun get_claimable_amount(): int {
    val storage = lazy VestingData.load();
    val nowTime: int = blockchain.now();
    val vestedAmount = calcVestedAmount(
        storage.totalAllocation,
        storage.startTime,
        storage.cliffDuration,
        storage.vestingDuration,
        nowTime
    );
    val claimable = vestedAmount - storage.totalClaimed;
    if (claimable < 0) {
        return 0;
    }
    return claimable;
}

get fun get_vested_amount(): int {
    val storage = lazy VestingData.load();
    val nowTime: int = blockchain.now();
    return calcVestedAmount(
        storage.totalAllocation,
        storage.startTime,
        storage.cliffDuration,
        storage.vestingDuration,
        nowTime
    );
}
