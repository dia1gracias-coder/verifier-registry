
struct JettonWalletInitialStorage {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
    jettonWalletCode: cell
}

fun calcDeployedJettonWallet(
    ownerAddress: address,
    minterAddress: address,
    jettonWalletCode: cell,
): AutoDeployAddress {
    val emptyStorage: JettonWalletInitialStorage = {
        jettonBalance: 0,
        ownerAddress,
        minterAddress,
        jettonWalletCode,
    };
    return {
        workchain: BASECHAIN,
        stateInit: { code: jettonWalletCode, data: emptyStorage.toCell() },
    };
}

fun calcAddressOfJettonWallet(
    ownerAddress: address,
    minterAddress: address,
    jettonWalletCode: cell,
): address {
    return calcDeployedJettonWallet(
        ownerAddress,
        minterAddress,
        jettonWalletCode,
    ).calculateAddress();
}
