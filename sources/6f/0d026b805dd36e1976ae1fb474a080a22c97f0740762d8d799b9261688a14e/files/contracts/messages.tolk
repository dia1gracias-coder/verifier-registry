// Сообщения капсулы. Опкоды = crc32 имени (см. INTERFACE.md).
// ---------- пользователь → Vault ----------

/// deposit: внести `amount` TON; value ≥ amount + POOL_DEPOSIT_FEE + DEPOSIT_GAS.
struct (0x95db9d39) Deposit {
    queryId: uint64
    amount: coins
}

/// stake_forfeits: ручной триггер стейка котла (любой отправитель).
struct (0x959c593e) StakeForfeits {
    queryId: uint64
}

// ---------- Vault → MemberAccount ----------

/// credit_tranche: новый транш (+stateInit при первом депозите).
struct (0x5ce33f6f) CreditTranche {
    queryId: uint64
    principal: coins
    acc0: uint128
    depositedAt: uint32
    owner: address // для возврата TON при bounce
}

/// exit_ack: решение Vault по батчу (mode = MODE_EARLY | MODE_FULL, bonus = tsTON, уже отправленные аккаунту или 0).
struct (0x4fccc930) ExitAck {
    queryId: uint64
    mode: uint2
    bonus: coins
}

/// exit_rejected: окно закрыто, force_early не задан.
struct (0xa0465851) ExitRejected {
    queryId: uint64
    nextWindowAt: uint32
}

// ---------- MemberAccount → Vault ----------

/// tranche_cancelled: депозит в пул отбился (или нет свободного слота: slot = 255),
/// транш удалён, TON возвращён владельцу.
struct (0xd1116e69) TrancheCancelled {
    queryId: uint64
    owner: address
    principal: coins
    slot: uint8
}

/// tranche_activated: транш подтверждён стейком; first = аккаунт стал участником.
struct (0x18e86633) TrancheActivated {
    queryId: uint64
    owner: address
    slot: uint8
    principal: coins
    tokens: coins
    first: bool
}

/// exit_notice: аккаунт просит решение по батчу.
struct (0x5b129b50) ExitNotice {
    queryId: uint64
    owner: address
    slots: uint64
    principalSum: coins
    debtSum: uint256
    forceEarly: bool
}

/// forfeit: TON в котёл (неатрибутированный TON при sweep); value ≥ amount + газ.
struct (0xbcbc6c5e) Forfeit {
    queryId: uint64
    owner: address
    amount: coins
}

/// exit_report: выплата произведена; forfeit — TON в котёл (value ≥ forfeit + газ).
struct (0xd730a916) ExitReport {
    queryId: uint64
    owner: address
    mode: uint2
    slots: uint64
    payout: coins
    forfeit: coins
    hasTranches: bool
}

// ---------- пользователь → MemberAccount ----------

/// withdraw: вывести транши по маске слотов; value ≥ WITHDRAW_GAS.
struct (0xb5de5f9e) Withdraw {
    queryId: uint64
    slots: uint64
    forceEarly: bool
}

/// retry_exit: повторить burn тем же batch_id через RETRY_TIMEOUT.
struct (0x770cf851) RetryExit {
    queryId: uint64
}

/// top_up: пополнить баланс контракта (Vault или аккаунт); пустое тело тоже принимается.
struct (0x34813b76) TopUp {
    queryId: uint64
}

// ---------- события (внешние сообщения из Vault; query_id — первым после опкода) ----------

/// Депозит принят Vault'ом, транш ещё стейкается (слот назначит аккаунт).
struct (0x85b4434a) LogDeposited {
    queryId: uint64
    owner: address
    account: address
    principal: coins
}

/// Транш подтверждён стейком: с этого момента он существует в слоте.
struct (0xd4592eba) LogTrancheActivated {
    queryId: uint64
    owner: address
    slot: uint8
    principal: coins
    tokens: coins
    memberJoined: bool
    memberCount: uint32
}

/// Депозит не удался (bounce пула или нет слота: slot = 255), principal снят с total_principal.
struct (0x1da026e0) LogTrancheCancelled {
    queryId: uint64
    owner: address
    principal: coins
    slot: uint8
}

struct (0x72d5e9ca) LogExitStarted {
    queryId: uint64
    owner: address
    mode: uint2
    slots: uint64
    principalSum: coins
    bonus: coins
}

struct (0x9f2b0f1e) LogExitRejected {
    queryId: uint64
    owner: address
    nextWindowAt: uint32
}

struct (0x72208540) LogExited {
    queryId: uint64
    owner: address
    mode: uint2
    slots: uint64
    payout: coins
    forfeit: coins
    hasTranches: bool
    memberCount: uint32
}

struct (0x344b89ee) LogForfeitStaked {
    queryId: uint64
    amount: coins
}

/// Отправить событие как внешнее сообщение; topic = опкод структуры.
fun emitLog<T>(topic: int, body: T) {
    val msg = createExternalLogMessage({
        dest: ExtOutLogBucket { topic },
        body,
    });
    msg.send(SEND_MODE_REGULAR);
}
