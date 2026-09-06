// Общие константы протокола капсулы. Значения газа — первичные оценки,
// уточняются по профилю `acton test --gas-profile` (см. PLAN.md §5).

const MY_WORKCHAIN = BASECHAIN

/// Минимальный вклад: минимум депозита Tonstakers (DESIGN §5, §7.2).
const MIN_DEPOSIT = ton("1")

/// Слотов траншей на аккаунт (DESIGN §3.2): битовая маска uint64.
const MAX_TRANCHES = 64

/// Множитель накопительного счётчика acc (DESIGN §4.4): 2^64.
const ACC_SCALE_BITS = 64

/// Комиссия депозита Tonstakers: пул удерживает ровно 1 TON и возвращает остаток excesses (§7.2).
const POOL_DEPOSIT_FEE = ton("1")

/// Сколько TON должно дойти до пула вместе с burn (§7.3: > 0.5 TON, SDK прикладывает 1.05).
const POOL_BURN_VALUE_MIN = ton("1.05")

/// Газ цепочки депозита сверх `amount + POOL_DEPOSIT_FEE`: Vault → Account(deploy) → pool → mint → notification.
const DEPOSIT_GAS = ton("0.3")

/// Газ цепочки выхода: exit_notice → (бонус jetton) → burn → выплата → exit_report.
const WITHDRAW_GAS = ton("1.5")

/// Газ повторного burn (retry_exit).
const RETRY_GAS = ton("1.2")

/// Газ ручного триггера стейка котла.
const STAKE_FORFEITS_GAS = ton("0.1")

/// Резерв аккаунта на хранение (капсула бессрочна, §4.5).
const ACCOUNT_MIN_BALANCE = ton("0.1")

/// Сверх резерва аккаунта: всё, что выше `ACCOUNT_MIN_BALANCE + SWEEP_THRESHOLD`
/// при withdraw считается неатрибутированным TON и уходит в котёл (§7.3 п. 3).
const SWEEP_THRESHOLD = ton("0.2")

/// Резерв Vault на хранение и газ.
const VAULT_MIN_BALANCE = ton("0.5")

/// Порог стейка котла (§4.4): меньше — комиссия пула съедает смысл.
const FORFEIT_STAKE_MIN = ton("1")

/// Что Vault оставляет себе с каждого проходящего сообщения на газ (deposit, exit_notice).
const VAULT_GAS_CUT = ton("0.02")

/// Газ, который аккаунт прикладывает к служебным сообщениям в Vault (отчёты, отмены).
const REPORT_GAS = ton("0.03")

/// Запас на два jetton-хопа при переводе бонуса из Vault в аккаунт: сколько TON НЕ уходит в forward_ton_amount.
const JETTON_TRANSFER_RESERVE = ton("0.12")

/// Что аккаунт оставляет от входящего value при отправке burn (газ этой транзакции и forward fee).
const BURN_TX_RESERVE = ton("0.02")

/// Отложенная выплата принимается, если value ≥ P_sum × 90 % (§7.3 п. 2).
const DEFERRED_PAYOUT_MIN_PERCENT = 90

/// Через сколько владелец может повторить burn (§7.3, retry_exit): 3 суток.
const RETRY_TIMEOUT = 3 * 24 * 3600

/// Статусы транша (DESIGN §3.2).
const TRANCHE_STAKING = 0
const TRANCHE_ACTIVE = 1
const TRANCHE_EXITING = 2

/// Режимы pending-батча (DESIGN §3.2).
const MODE_AWAITING_ACK = 0
const MODE_EARLY = 1
const MODE_FULL = 2
