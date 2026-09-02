tolk 1.4.1

import "constants.tolk"

struct WalletStorage {
    status: uint8;
    jettonBalance: coins;
    ownerAddress: address;
    minterAddress: address;
}

fun WalletStorage.load(): WalletStorage {
    return WalletStorage.fromCell(contract.getData());
}

fun WalletStorage.save(self): void {
    contract.setData(self.toCell());
}

// Canonical wallet for an owner. Status is ALWAYS STATUS_BLOCKED in the
// address-determining template, so a self-deployed wallet is born blocked.
fun calcDeployedJettonWallet(ownerAddress: address, minterAddress: address, walletCode: cell): AutoDeployAddress {
    val initialData: WalletStorage = {
        status: STATUS_BLOCKED,
        jettonBalance: 0,
        ownerAddress: ownerAddress,
        minterAddress: minterAddress,
    };
    return {
        workchain: BASECHAIN,
        stateInit: { code: walletCode, data: initialData.toCell() },
    };
}
