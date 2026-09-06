import "constants"

/// Неизменяемые параметры протокола; одна ячейка, общая для Vault и всех аккаунтов (init-данные).
struct AccountParams {
    pool: address
    tstonMaster: address
    tstonWalletCode: cell
}

// ---------- Vault ----------

struct VaultStorage {
    period: uint32        // секунды между окнами, неизменяемо
    windowLength: uint32  // секунды, сколько окно открыто, неизменяемо
    epochStart: uint32    // момент отсчёта окон, неизменяемо
    accountCode: cell     // код MemberAccount
    accountParams: Cell<AccountParams>
    memberCount: uint32
    totalPrincipal: coins // сумма principal всех активных траншей
    acc: uint128          // бонус-tsTON на 1 nanoTON principal, ×2^64
    unallocated: coins    // tsTON котла, ещё не разнесённые в acc (некому было)
    forfeitBuffer: coins  // TON форфейтов, ещё не отправленные в стейкинг
    pendingStake: coins   // TON форфейтов, отправленные в пул и ещё не подтверждённые
}

fun VaultStorage.load(): VaultStorage {
    return VaultStorage.fromCell(contract.getData());
}

fun VaultStorage.save(self) {
    contract.setData(self.toCell());
}

// ---------- MemberAccount ----------

struct Tranche {
    queryId: uint64     // query_id депозита (для сопоставления с событиями)
    principal: coins
    depositedAt: uint32 // только для UI и истории
    tokens: coins       // tsTON; 0, пока stake не подтверждён
    acc0: uint128       // снимок Vault.acc в момент депозита
    status: uint2       // TRANCHE_STAKING / ACTIVE / EXITING
}

struct PendingBatch {
    queryId: uint64    // query_id из withdraw владельца (для событий)
    slots: uint64      // маска слотов траншей в батче
    principalSum: coins
    tokensSum: coins
    debtSum: uint256   // Σ principal_i × acc0_i
    mode: uint2        // MODE_AWAITING_ACK / EARLY / FULL
    bonusTokens: coins
    batchId: uint32    // query_id для burn и атрибуции выплаты
    createdAt: uint32  // для RETRY_TIMEOUT
    burnSentAt: uint32 // 0, пока burn не отправлен
    burnValue: coins   // TON, приложенные к burn: пул возвращает их вместе с выплатой
}

struct AccountStorage {
    vault: address
    owner: address
    params: Cell<AccountParams>
    tstonWallet: address? // вычисляется при первом credit_tranche
    usedSlots: uint64     // маска занятых слотов (staking | active | exiting)
    isMember: bool        // учтён в Vault.member_count
    batchSeq: uint32
    tranches: map<uint8, Tranche>
    pending: Cell<PendingBatch>?
}

fun AccountStorage.load(): AccountStorage {
    return AccountStorage.fromCell(contract.getData());
}

fun AccountStorage.save(self) {
    contract.setData(self.toCell());
}

/// Init-данные аккаунта участника: детерминированы из (vault, owner, params).
fun calcAccountInit(
    vault: address,
    owner: address,
    accountCode: cell,
    params: Cell<AccountParams>,
): AutoDeployAddress {
    val data: AccountStorage = {
        vault,
        owner,
        params,
        tstonWallet: null,
        usedSlots: 0,
        isMember: false,
        batchSeq: 0,
        tranches: [],
        pending: null,
    };
    return { workchain: MY_WORKCHAIN, stateInit: { code: accountCode, data: data.toCell() } };
}

fun calcAccountAddress(
    vault: address,
    owner: address,
    accountCode: cell,
    params: Cell<AccountParams>,
): address {
    return calcAccountInit(vault, owner, accountCode, params).calculateAddress();
}
