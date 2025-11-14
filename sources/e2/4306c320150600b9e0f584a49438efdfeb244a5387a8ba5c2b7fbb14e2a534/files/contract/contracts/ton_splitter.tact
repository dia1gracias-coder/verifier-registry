import "@stdlib/deploy";
import "@stdlib/ownable";

// ===================================================================================
// === TON Splitter Smart Contract v3.2.1 - Tact Implementation ===
// ===================================================================================

// Константы версий
const CONTRACT_VERSION: Int = 3210;
const DATA_SCHEMA_VERSION: Int = 1;

// Опкоды операций
const OP_UPDATE_PARAMS: Int = 0x75706470;
const OP_WITHDRAW_FEES: Int = 0x77697468;
const OP_PAUSE: Int = 0x70617573;
const OP_RESUME: Int = 0x72657375;
const OP_UPDATE_LOGGING: Int = 0x756c6f67;
const OP_EMERGENCY_WITHDRAW: Int = 0x656d6572;

// Комиссии (в nanotons)
const PROTOCOL_FEE: Int = 50000000;        // 0.05 TON
const SPLIT_GAS_FEE: Int = 30000000;       // 0.03 TON
const REFUND_GAS_FEE: Int = 10000000;      // 0.01 TON
const TOTAL_FEE: Int = 80000000;           // PROTOCOL_FEE + SPLIT_GAS_FEE
const STORAGE_BUFFER: Int = 1000000;       // 0.001 TON

// Настройки логирования
const DEFAULT_LOG_GAS: Int = 500000;       // 0.0005 TON
const AMOUNT_TOLERANCE: Int = 20000000;    // 2 * REFUND_GAS_FEE

// Таймлоки
const USER_TIME_LOCK: Int = 5;             // 5 секунд для пользователей
const OWNER_TIME_LOCK: Int = 30;           // 30 секунд для владельца

// Лимиты безопасности
const MAX_SINGLE_AMOUNT: Int = 1000000000000;   // 1000 TON
const MAX_TOTAL_AMOUNT: Int = 2000000000000;    // 2000 TON

// События
const EVENT_SPLIT: Int = 1;
const EVENT_UPDATE: Int = 2;
const EVENT_WITHDRAW: Int = 3;
const EVENT_PAUSE: Int = 4;
const EVENT_RESUME: Int = 5;
const EVENT_TOP_UP: Int = 999;
const EVENT_PENDING: Int = 7001;
const EVENT_QUEUE_ERROR: Int = 9000;
const EVENT_EMERGENCY_WITHDRAW: Int = 9999;

// Сообщения для операций

message UpdateParams {
    amount1: Int as coins;
    amount2: Int as coins;
    wallet1: Address;
    wallet2: Address;
    logAddress: Address?;
}

message WithdrawFees {
    // Пустое сообщение
}

message Pause {
    // Пустое сообщение
}

message Resume {
    // Пустое сообщение
}

message UpdateLogging {
    logAddress: Address?;
    logGas: Int as uint32;
}

message EmergencyWithdraw {
    // Пустое сообщение
}

// Внутреннее сообщение для логирования
message LogEvent {
    eventType: Int as uint16;
    eventData: Int as uint32;
    timestamp: Int as uint32;
    nonce: Int as uint16;
}

// Структура для очереди
struct PendingMessage {
    value: Int as uint64;
    sender: Address;
}

// ===== НОВЫЕ СТРУКТУРЫ ДЛЯ GET-МЕТОДОВ (вместо кортежей) ===========================

struct FullState {
    amount1: Int;
    amount2: Int;
    wallet1: Address;
    wallet2: Address;
    owner: Address;
    balance: Int;
    total: Int;
    requiredTotal: Int;
    minAmount: Int;
    maxAmount: Int;
    isReady: Bool;
    accumulatedFees: Int;
    logGas: Int;
}

// Основной контракт
contract TonSplitter with Deployable, Ownable {
    // Основные параметры сплита
    amount1: Int as coins;
    amount2: Int as coins;
    wallet1: Address;
    wallet2: Address;
    owner: Address;
    
    // Логирование
    logAddress: Address?;
    logGas: Int as uint32;
    
    // Счетчики и флаги
    nonce: Int as uint32;
    isPaused: Bool;
    lastUserOperation: Int as uint32;
    lastOwnerOperation: Int as uint32;
    accumulatedFees: Int as coins;
    
    // Защита от повторного входа
    inProgress: Bool;
    pendingMsg: PendingMessage?;
    
    // Антидубликат
    lastSender: Address?;
    lastValue: Int as uint64;
    lastCallTime: Int as uint32;
    
    // Инициализация контракта
    init(
        owner: Address,
        amount1: Int,
        amount2: Int,
        wallet1: Address,
        wallet2: Address,
        logAddress: Address?
    ) {
        self.owner = owner;
        self.amount1 = amount1;
        self.amount2 = amount2;
        self.wallet1 = wallet1;
        self.wallet2 = wallet2;
        self.logAddress = logAddress;
        self.logGas = DEFAULT_LOG_GAS;
        self.nonce = 0;
        self.isPaused = false;
        self.lastUserOperation = 0;
        self.lastOwnerOperation = 0;
        self.accumulatedFees = 0;
        self.inProgress = false;
        self.pendingMsg = null;
        self.lastSender = null;
        self.lastValue = 0;
        self.lastCallTime = 0;
    }
    
    // ============================================================
    // ПОЛУЧЕНИЕ ВХОДЯЩИХ СООБЩЕНИЙ
    // ============================================================
    
    receive() {
        // Пустое сообщение от владельца = пополнение
        let s = sender();
        if (s == self.owner) {
            self.emitLogEvent(EVENT_TOP_UP, context().value);
            return;
        }
        
        // Пустое сообщение от других = split
        self.handleTonSplit(context().value, s);
    }
    
    receive(msg: UpdateParams) {
        self.requireOwner();
        self.checkOwnerTimeLock();
        require(!self.isPaused, "Contract is paused");
        
        // Валидация параметров
        require(msg.amount1 > 0, "Amount1 must be positive");
        require(msg.amount2 > 0, "Amount2 must be positive");
        require(msg.amount1 <= MAX_SINGLE_AMOUNT, "Amount1 too large");
        require(msg.amount2 <= MAX_SINGLE_AMOUNT, "Amount2 too large");
        require(msg.amount1 + msg.amount2 <= MAX_TOTAL_AMOUNT, "Total amount too large");
        
        // Проверка адресов
        require(msg.wallet1 != msg.wallet2, "Wallets must be different");
        require(msg.wallet1 != myAddress(), "Wallet1 cannot be contract");
        require(msg.wallet2 != myAddress(), "Wallet2 cannot be contract");
        require(msg.wallet1 != self.owner, "Wallet1 cannot be owner");
        require(msg.wallet2 != self.owner, "Wallet2 cannot be owner");
        
        // Обновление параметров
        self.amount1 = msg.amount1;
        self.amount2 = msg.amount2;
        self.wallet1 = msg.wallet1;
        self.wallet2 = msg.wallet2;
        self.logAddress = msg.logAddress;
        
        // Антидубликат
        self.lastSender = sender();
        self.lastCallTime = now();
        
        self.emitLogEvent(EVENT_UPDATE, msg.amount1 + msg.amount2);
    }
    
    receive(msg: WithdrawFees) {
        self.requireOwner();
        
        let feesToWithdraw = self.accumulatedFees;
        require(feesToWithdraw > 0, "No fees to withdraw");
        require(feesToWithdraw + STORAGE_BUFFER <= myBalance(), "Insufficient balance");
        
        self.accumulatedFees = 0;
        
        send(SendParameters{
            to: sender(),
            value: feesToWithdraw,
            mode: SendIgnoreErrors,
            body: emptyCell()
        });
        
        self.emitLogEvent(EVENT_WITHDRAW, feesToWithdraw);
    }
    
    receive(msg: Pause) {
        self.requireOwner();
        self.checkOwnerTimeLock();
        
        self.isPaused = true;
        self.emitLogEvent(EVENT_PAUSE, 0);
    }
    
    receive(msg: Resume) {
        self.requireOwner();
        self.checkOwnerTimeLock();
        
        self.isPaused = false;
        self.emitLogEvent(EVENT_RESUME, 0);
    }
    
    receive(msg: UpdateLogging) {
        self.requireOwner();
        self.checkOwnerTimeLock();
        
        require(msg.logGas >= 0 && msg.logGas <= 10000000, "Invalid log gas");
        
        self.logAddress = msg.logAddress;
        self.logGas = msg.logGas;
        
        self.emitLogEvent(EVENT_UPDATE, msg.logGas);
    }
    
    receive(msg: EmergencyWithdraw) {
        self.requireOwner();
        self.checkOwnerTimeLock();
        
        let balance = myBalance() - STORAGE_BUFFER;
        require(balance > 0, "Insufficient balance");
        
        self.accumulatedFees = 0;
        
        send(SendParameters{
            to: sender(),
            value: balance,
            mode: SendIgnoreErrors,
            body: emptyCell()
        });
        
        self.emitLogEvent(EVENT_EMERGENCY_WITHDRAW, balance);
    }
    
    // ============================================================
    // ОСНОВНАЯ ЛОГИКА СПЛИТА
    // ============================================================
    
    fun handleTonSplit(msgValue: Int, senderAddr: Address) {
        require(!self.isPaused, "Contract is paused");
        self.checkUserTimeLock();
        
        // Антидубликат
        if (self.lastSender != null) {
            if (self.lastSender!! == senderAddr && 
                self.lastValue == msgValue && 
                now() - self.lastCallTime < 10) {
                throw(998);  // Duplicate transaction
            }
        }
        
        // Защита от повторного входа
        require(!self.inProgress, "Operation in progress");
        self.inProgress = true;
        
        // Если есть очередь, не обрабатываем
        if (self.pendingMsg != null) {
            self.emitLogEvent(EVENT_PENDING, 0);
            self.inProgress = false;
            return;
        }
        
        self.nonce = self.nonce + 1;
        
        let totalAmount = self.amount1 + self.amount2;
        let requiredTotal = totalAmount + TOTAL_FEE;
        
        // Проверка достаточности средств
        if (msgValue < requiredTotal) {
            let refundAmount = msgValue - REFUND_GAS_FEE;
            if (refundAmount > 0) {
                send(SendParameters{
                    to: senderAddr,
                    value: refundAmount,
                    mode: SendIgnoreErrors,
                    body: emptyCell()
                });
            }
            self.inProgress = false;
            throw(120);  // Insufficient funds
        }
        
        let remainder = msgValue - requiredTotal;
        
        // Проверки адресов
        require(self.wallet1 != self.wallet2, "Wallets must be different");
        require(self.wallet1 != myAddress(), "Invalid wallet1");
        require(self.wallet2 != myAddress(), "Invalid wallet2");
        require(self.wallet1 != self.owner, "Wallet1 is owner");
        require(self.wallet2 != self.owner, "Wallet2 is owner");
        
        // Накопление комиссии
        self.accumulatedFees = self.accumulatedFees + PROTOCOL_FEE;
        
        // Проверка баланса
        let totalToSend = self.amount1 + self.amount2;
        require(myBalance() >= totalToSend + (2 * STORAGE_BUFFER), "Insufficient contract balance");
        
        // Отправка средств получателям
        send(SendParameters{
            to: self.wallet1,
            value: self.amount1 + STORAGE_BUFFER,
            mode: SendIgnoreErrors,
            body: emptyCell()
        });
        
        send(SendParameters{
            to: self.wallet2,
            value: self.amount2 + STORAGE_BUFFER,
            mode: SendIgnoreErrors,
            body: emptyCell()
        });
        
        // Возврат переплаты
        if (remainder > (2 * REFUND_GAS_FEE)) {
            let refundExtra = remainder - REFUND_GAS_FEE;
            require(refundExtra > 0, "Invalid refund amount");
            send(SendParameters{
                to: senderAddr,
                value: refundExtra,
                mode: SendIgnoreErrors,
                body: emptyCell()
            });
        } else if (remainder > 0) {
            self.accumulatedFees = self.accumulatedFees + remainder;
        }
        
        // Обновление антидубликата
        self.lastSender = senderAddr;
        self.lastValue = msgValue;
        self.lastCallTime = now();
        
        self.emitLogEvent(EVENT_SPLIT, totalAmount);
        self.inProgress = false;
    }
    
    // ============================================================
    // ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    // ============================================================
    
    fun checkUserTimeLock() {
        let currentTime = now();
        require(currentTime >= self.lastUserOperation + USER_TIME_LOCK, "User time lock active");
        self.lastUserOperation = currentTime;
    }
    
    fun checkOwnerTimeLock() {
        let currentTime = now();
        require(currentTime >= self.lastOwnerOperation + OWNER_TIME_LOCK, "Owner time lock active");
        self.lastOwnerOperation = currentTime;
    }
    
    fun emitLogEvent(eventType: Int, eventData: Int) {
        if (self.logAddress != null && self.logGas > 0) {
            send(SendParameters{
                to: self.logAddress!!,
                value: self.logGas,
                mode: SendIgnoreErrors,
                body: LogEvent{
                    eventType: eventType,
                    eventData: eventData,
                    timestamp: now(),
                    nonce: self.nonce % 65536
                }.toCell()
            });
        }
    }
    
    // ============================================================
    // GET-МЕТОДЫ
    // ============================================================
    
    get fun fullState(): FullState {
        let balance = myBalance();
        let total = self.amount1 + self.amount2;
        let requiredTotal = total + TOTAL_FEE;
        let minAmount = requiredTotal - AMOUNT_TOLERANCE;
        let maxAmount = requiredTotal + AMOUNT_TOLERANCE;
        let isReady = (total > 0) && (!self.isPaused);
        
        return FullState{
            amount1: self.amount1,
            amount2: self.amount2,
            wallet1: self.wallet1,
            wallet2: self.wallet2,
            owner: self.owner,
            balance: balance,
            total: total,
            requiredTotal: requiredTotal,
            minAmount: minAmount,
            maxAmount: maxAmount,
            isReady: isReady,
            accumulatedFees: self.accumulatedFees,
            logGas: self.logGas
        };
    }

    get fun version(): Int {
        return CONTRACT_VERSION;
    }

    get fun schemaVersion(): Int {
        return DATA_SCHEMA_VERSION;
    }

    get fun isPaused(): Bool {
        return self.isPaused;
    }

    get fun nonce(): Int {
        return self.nonce;
    }
}
