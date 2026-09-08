// ============================================================
//  Jetton wallet address, classic TEP-74 layout
//
//  The collection has to derive the GRM wallet address of any owner: its own
//  and every domain's. The layout is taken from the GRM jetton sources
//  (`pack_jetton_wallet_data`):
//
//      balance:Coins owner:MsgAddress jetton:MsgAddress wallet_code:^Cell
//
//  No sharding, workchain 0. Any deviation here means the collection would miss
//  every wallet, so before going live compare `get_grm_wallet_of` against the
//  master's own `get_wallet_address`.
// ============================================================

/// Initial jetton wallet state: zero balance, owner, minter and code. The
/// address is derived from exactly these fields.
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
