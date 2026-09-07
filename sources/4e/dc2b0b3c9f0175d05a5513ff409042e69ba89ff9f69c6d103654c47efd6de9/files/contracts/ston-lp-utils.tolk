import "sharding"

// STON.fi LP wallets use the standard Jetton address derivation with one extra
// reference to their own wallet code in persistent data. This layout mirrors
// `pack_jetton_lp_wallet_data` from the STON.fi DEX contracts. Unlike this
// repository's TEP-89 Jetton wallets, STON.fi LP wallets use an ordinary
// unsharded StateInit; this is also what Pool.get_wallet_address returns.
struct StonLpWalletStorage {
    jettonBalance: coins
    ownerAddress: address
    minterAddress: address
    jettonWalletCode: cell
}

fun calcDeployedStonLpWallet(
    ownerAddress: address,
    lpMasterAddress: address,
    lpWalletCode: cell,
): AutoDeployAddress {
    val emptyStorage: StonLpWalletStorage = {
        jettonBalance: 0,
        ownerAddress,
        minterAddress: lpMasterAddress,
        jettonWalletCode: lpWalletCode,
    };
    return {
        workchain: MY_WORKCHAIN,
        stateInit: { code: lpWalletCode, data: emptyStorage.toCell() },
    };
}

fun calcAddressOfStonLpWallet(
    ownerAddress: address,
    lpMasterAddress: address,
    lpWalletCode: cell,
): address {
    return calcDeployedStonLpWallet(
        ownerAddress,
        lpMasterAddress,
        lpWalletCode,
    ).calculateAddress();
}
