// Сообщения протокола Tonstakers (ton-blockchain/liquid-staking-contract) и TEP-74,
// а также расчёт адреса tsTON-кошелька (раскладка jetton_dao, DESIGN §7.1).

import "constants"

// ---------- пул ----------

/// deposit#47d54391 query_id:uint64 — депозит TON в пул; пул удерживает 1 TON и возвращает excesses.
struct (0x47d54391) PoolDeposit {
    queryId: uint64
}

/// pool::withdrawal#0a77535c query_id:uint64 — мгновенная выплата TON от пула после burn.
struct (0x0a77535c) PoolWithdrawal {
    queryId: uint64
}

/// distributed_asset#db3b8abd query_id:uint64 — отложенная выплата от коллекции раунда (query_id = lt пула).
struct (0xdb3b8abd) DistributedAsset {
    queryId: uint64
}

/// ownership_assigned#05138d91 — payout-NFT сообщает о выдаче (отложенный путь); аккаунт игнорирует.
struct (0x05138d91) OwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

/// custom_payload для burn в tsTON-кошельке: wait_till_round_end:Bool fill_or_kill:Bool.
struct BurnCustomPayload {
    waitTillRoundEnd: bool
    fillOrKill: bool
}

// ---------- TEP-74 ----------

struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    jettonAmount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x178d4519) JettonInternalTransfer {
    queryId: uint64
    jettonAmount: coins
    from: address?
    responseDestination: address?
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x7362d09c) JettonTransferNotification {
    queryId: uint64
    jettonAmount: coins
    from: address?
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) JettonBurn {
    queryId: uint64
    jettonAmount: coins
    responseDestination: address?
    customPayload: cell?
}

struct (0x7bdd97de) JettonBurnNotification {
    queryId: uint64
    jettonAmount: coins
    sender: address
    responseDestination: address?
}

struct (0xd53276db) Excesses {
    queryId: uint64
}

/// Ответ стандартного get_wallet_data (TEP-74).
struct JettonWalletData {
    balance: coins
    owner: address
    master: address
    walletCode: cell
}

// ---------- адрес tsTON-кошелька ----------

/// Данные jetton-кошелька tsTON (jetton_dao): coins(0) owner master ^code coins(0) uint48(0).
struct TsTonWalletData {
    balance: coins
    owner: address
    master: address
    walletCode: cell
    locked: coins
    lockExpiration: uint48
}

fun calcTsTonWalletInit(owner: address, master: address, walletCode: cell): AutoDeployAddress {
    val data: TsTonWalletData = {
        balance: 0,
        owner,
        master,
        walletCode,
        locked: 0,
        lockExpiration: 0,
    };
    return { workchain: MY_WORKCHAIN, stateInit: { code: walletCode, data: data.toCell() } };
}

fun calcTsTonWalletAddress(owner: address, master: address, walletCode: cell): address {
    return calcTsTonWalletInit(owner, master, walletCode).calculateAddress();
}
