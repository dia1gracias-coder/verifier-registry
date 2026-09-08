// ============================================================
//  Адрес джеттон-кошелька по классической раскладке TEP-74
//
//  Коллекции нужно уметь вычислять адрес GRM-кошелька — своего и каждого
//  домена. Раскладка взята из исходников GRM (`pack_jetton_wallet_data`):
//
//      balance:Coins owner:MsgAddress jetton:MsgAddress wallet_code:^Cell
//
//  Без шардинга, воркчейн 0. Любое расхождение здесь означает, что коллекция
//  промахнётся мимо каждого кошелька, поэтому перед запуском обязательно
//  сверить `get_grm_wallet_of` с `get_wallet_address` самого мастера.
// ============================================================

/// Начальное состояние джеттон-кошелька: нулевой баланс, владелец, мастер и
/// код. Именно из этих полей выводится адрес.
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
