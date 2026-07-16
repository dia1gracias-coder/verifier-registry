import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

// =============================================================
// SeedRound — приём USDT (jetton), регистрация аллокаций и СТАТУСОВ инвесторов.
//
// Контракт = реестр. Хранит, сколько USDT внёс каждый инвестор в seed,
// его seed-уровень (по сумме вклада) и founder-статус (заносится админом,
// т.к. founder-раунд прошёл офчейн). Привилегии (множители, вестинг)
// применяются ПОЗЖЕ на этапе ICO/TGE, читая этот реестр.
//
// Деньги принимаются только в USDT (TEP-74 jetton, 6 знаков).
// =============================================================

// ---------- Статусы (effectiveStatus) ----------
const STATUS_NONE: Int = 0;
const STATUS_SEED_ACCESS: Int = 1;     // от $500
const STATUS_SEED_PRIORITY: Int = 2;   // от $1000
const STATUS_SEED_STRATEGIC: Int = 3;  // от $3000
const STATUS_FOUNDER: Int = 10;        // всегда выше seed

// ---------- TEP-74 jetton messages ----------

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;      // сколько USDT пришло (нано, 6 знаков)
    sender: Address;           // кто инициировал перевод (инвестор)
    forwardPayload: Slice as remaining;
}

message(0x0f8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// ---------- Admin messages ----------

message SetParams {
    priceUsdtPerToken: Int as coins; // USDT-нано за 1 целый токен; 0 = режим "только сумма"
    tokenDecimals: Int as uint8;
    hardCap: Int as coins;           // общий лимит сбора; 0 = без лимита
    minBuy: Int as coins;            // мин. покупка на инвестора; 0 = без огр.
    maxBuy: Int as coins;            // макс. покупка на инвестора; 0 = без огр.
    startTime: Int as uint64;
    endTime: Int as uint64;
    whitelistEnabled: Bool;
}

// Пороги seed-уровней (в USDT-нано).
message SetTiers {
    access: Int as coins;     // мин. сумма для Seed Access
    priority: Int as coins;   // мин. сумма для Seed Priority
    strategic: Int as coins;  // мин. сумма для Seed Strategic
}

// Регистрация founder-статуса (founder-раунд прошёл офчейн).
message SetFounder {
    investor: Address;
    level: Int as uint8;       // 0 = снять статус; >=1 = уровень фаундера
    founderUsdt: Int as coins; // сколько внёс в founder-раунд (для будущего расчёта)
}

// Повышенный потолок покупки для фаундеров (0 = как у всех).
message SetFounderMax {
    maxBuy: Int as coins;
}

// Бонус токенов фаундеру в %, напр. 20 = +20% (×1.2). 0 = без бонуса.
message SetFounderBonus {
    bonusPct: Int as uint16;
}

message SetUsdtWallet {
    wallet: Address;
}

message SetWhitelist {
    investor: Address;
    allowed: Bool;
}

message WithdrawUsdt {
    amount: Int as coins;
    destination: Address;
}

// M-3: вывести застрявшие jetton'ы (неудавшиеся рефанды, прямые переводы, dust),
// которые не попали в учёт totalRaised. Только казна (мультисиг). Не трогает учёт.
message SweepUsdt {
    amount: Int as coins;
    destination: Address;
}

// Сменить казну (адрес, которому разрешён вывод). Только текущая казна.
message SetTreasury {
    treasury: Address;
}

// ---------- Getter return types ----------

struct Allocation {
    usdtContributed: Int;   // внесено USDT (нано)
    tokenAllocation: Int;   // расчётное кол-во токенов (нано), 0 если цена не задана
}

struct InvestorStatus {
    founderLevel: Int;      // 0 = не фаундер
    founderUsdt: Int;       // вклад в founder-раунд (нано)
    seedContributed: Int;   // вклад в seed (нано)
    seedTier: Int;          // 0..3 (none/access/priority/strategic)
    effectiveStatus: Int;   // STATUS_* — итоговый статус (founder перекрывает seed)
}

struct RoundInfo {
    owner: Address;
    treasury: Address;
    usdtWallet: Address?;
    stopped: Bool;
    withdrawn: Int;
    priceUsdtPerToken: Int;
    tokenDecimals: Int;
    hardCap: Int;
    minBuy: Int;
    maxBuy: Int;
    maxBuyFounder: Int;
    founderBonusPct: Int;
    startTime: Int;
    endTime: Int;
    whitelistEnabled: Bool;
    tierAccess: Int;
    tierPriority: Int;
    tierStrategic: Int;
    totalRaised: Int;
    investorsCount: Int;
}

// =============================================================

contract SeedRound with Deployable, OwnableTransferable, Resumable {
    owner: Address;             // рутина: параметры, тиры, вайтлист, пауза (серверный ключ)
    treasury: Address;          // важное: вывод средств (мультисиг) — MED-01
    stopped: Bool;
    withdrawn: Int as coins;    // сколько уже выведено (бэкстоп-инвариант) — INFO-01

    // --- параметры раунда ---
    usdtWallet: Address?;
    priceUsdtPerToken: Int as coins;
    tokenDecimals: Int as uint8;
    hardCap: Int as coins;
    minBuy: Int as coins;
    maxBuy: Int as coins;              // общий макс. на инвестора; 0 = без огр.
    maxBuyFounder: Int as coins;      // повышенный макс. для фаундеров; 0 = как у всех (maxBuy)
    founderBonusPct: Int as uint16;   // бонус токенов фаундеру, % (напр. 20 = +20%, ×1.2); 0 = без бонуса
    startTime: Int as uint64;
    endTime: Int as uint64;
    whitelistEnabled: Bool;

    // --- пороги seed-уровней ---
    tierAccess: Int as coins;
    tierPriority: Int as coins;
    tierStrategic: Int as coins;

    // --- состояние / реестр ---
    totalRaised: Int as coins;
    investorsCount: Int as uint32;
    investors: map<Address, Int>;     // адрес -> внесено USDT в seed (нано)
    whitelist: map<Address, Bool>;
    founderLevel: map<Address, Int>;  // адрес -> уровень фаундера (>0)
    founderUsdt: map<Address, Int>;   // адрес -> вклад в founder-раунд (нано)

    init(owner: Address) {
        self.owner = owner;
        self.treasury = owner;   // до передачи мультисигу вывод у деплоера; затем SetTreasury -> multisig
        self.stopped = false;
        self.withdrawn = 0;
        self.usdtWallet = null;
        self.priceUsdtPerToken = 0;
        self.tokenDecimals = 9;
        self.hardCap = 0;
        self.minBuy = 0;
        self.maxBuy = 0;
        self.maxBuyFounder = 0;
        self.founderBonusPct = 0;
        self.startTime = 0;
        self.endTime = 0;
        self.whitelistEnabled = true;
        // дефолтные пороги: $500 / $1000 / $3000 (USDT 6 знаков)
        self.tierAccess = 500000000;
        self.tierPriority = 1000000000;
        self.tierStrategic = 3000000000;
        self.totalRaised = 0;
        self.investorsCount = 0;
    }

    // ---------- Покупка аллокации (приход USDT) ----------
    receive(msg: JettonTransferNotification) {
        let wallet = self.usdtWallet;
        throwUnless(0xffff, wallet != null && sender() == wallet!!);

        let investor = msg.sender;
        let amount = msg.amount;

        if (!self.isBuyAllowed(investor, amount)) {
            self.refundUsdt(investor, amount);
            return;
        }

        let prev = self.investors.get(investor);
        if (prev == null) {
            self.investorsCount += 1;
            self.investors.set(investor, amount);
        } else {
            self.investors.set(investor, prev!! + amount);
        }
        self.totalRaised += amount;
    }

    fun isBuyAllowed(investor: Address, amount: Int): Bool {
        if (self.stopped) { return false }
        if (amount <= 0) { return false }
        if (self.startTime != 0 && now() < self.startTime) { return false }
        if (self.endTime != 0 && now() > self.endTime) { return false }
        if (self.whitelistEnabled) {
            let wl = self.whitelist.get(investor);
            if (wl == null || !(wl!!)) { return false }
        }
        let prev = self.investors.get(investor);
        let already = (prev == null) ? 0 : prev!!;
        // minBuy — накопительный: суммарный вклад должен быть >= minBuy. Первая покупка
        // не может быть меньше minBuy (напр. $500 — вход в Access), но докупки при апгрейде
        // на следующий уровень могут быть меньше (напр. +$450 при уже внесённых $550).
        if (self.minBuy != 0 && (already + amount) < self.minBuy) { return false }
        // фаундеры — свой (повышенный) потолок, если он задан; иначе общий maxBuy
        let fl = self.founderLevel.get(investor);
        let cap = (fl != null && fl!! > 0 && self.maxBuyFounder != 0) ? self.maxBuyFounder : self.maxBuy;
        if (cap != 0 && (already + amount) > cap) { return false }
        if (self.hardCap != 0 && (self.totalRaised + amount) > self.hardCap) { return false }
        return true;
    }

    fun refundUsdt(to: Address, amount: Int) {
        send(SendParameters {
            to: self.usdtWallet!!,
            value: 0,
            mode: SendRemainingValue,
            body: JettonTransfer {
                queryId: 0,
                amount: amount,
                destination: to,
                responseDestination: to,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).endCell().asSlice(),
            }.toCell(),
        });
    }

    // seed-уровень по сумме вклада
    fun seedTierOf(contributed: Int): Int {
        if (self.tierStrategic != 0 && contributed >= self.tierStrategic) { return STATUS_SEED_STRATEGIC }
        if (self.tierPriority != 0 && contributed >= self.tierPriority) { return STATUS_SEED_PRIORITY }
        if (self.tierAccess != 0 && contributed >= self.tierAccess) { return STATUS_SEED_ACCESS }
        return STATUS_NONE;
    }

    // ---------- Admin ----------
    receive(msg: SetParams) {
        self.requireOwner();
        // INFO-02 / LOW-03: валидация параметров
        require(msg.priceUsdtPerToken >= 0, "price < 0");
        require(msg.tokenDecimals <= 30, "decimals too large"); // pow(10,dec) не должен переполнять 257 бит
        require(msg.startTime == 0 || msg.endTime == 0 || msg.startTime < msg.endTime, "startTime >= endTime");
        require(msg.maxBuy == 0 || msg.minBuy <= msg.maxBuy, "minBuy > maxBuy"); // L-5
        // M-1: цена и decimals влияют на уже начисленные аллокации — после первой покупки заморожены.
        require(self.totalRaised == 0 || (msg.priceUsdtPerToken == self.priceUsdtPerToken && msg.tokenDecimals == self.tokenDecimals), "price frozen after first buy");
        self.priceUsdtPerToken = msg.priceUsdtPerToken;
        self.tokenDecimals = msg.tokenDecimals;
        self.hardCap = msg.hardCap;
        self.minBuy = msg.minBuy;
        self.maxBuy = msg.maxBuy;
        self.startTime = msg.startTime;
        self.endTime = msg.endTime;
        self.whitelistEnabled = msg.whitelistEnabled;
    }

    receive(msg: SetTiers) {
        self.requireOwner();
        require(msg.access <= msg.priority && msg.priority <= msg.strategic, "tiers not monotonic"); // L-4
        self.tierAccess = msg.access;
        self.tierPriority = msg.priority;
        self.tierStrategic = msg.strategic;
    }

    // Повышенный потолок покупки для фаундеров (0 = как у всех). Один уровень фаундеров.
    receive(msg: SetFounderMax) {
        self.requireOwner();
        self.maxBuyFounder = msg.maxBuy;
    }

    // Бонус токенов фаундеру в % (напр. 20 = +20%).
    receive(msg: SetFounderBonus) {
        self.requireOwner();
        require(msg.bonusPct <= 1000, "bonus too large"); // sanity cap 1000%
        // M-1: бонус ретроактивен — после первой покупки заморожен.
        require(self.totalRaised == 0 || msg.bonusPct == self.founderBonusPct, "bonus frozen after first buy");
        self.founderBonusPct = msg.bonusPct;
    }

    receive(msg: SetFounder) {
        self.requireOwner();
        if (msg.level == 0) {
            self.founderLevel.del(msg.investor);
            self.founderUsdt.del(msg.investor);
        } else {
            self.founderLevel.set(msg.investor, msg.level);
            self.founderUsdt.set(msg.investor, msg.founderUsdt);
        }
    }

    // H-3: usdt-кошелёк — критично (через него аутентифицируются платежи), поэтому только казна.
    // При сетапе казна == деплойер, после передачи её мультисигу менять может только мультисиг.
    receive(msg: SetUsdtWallet) {
        throwUnless(140, sender() == self.treasury);
        self.usdtWallet = msg.wallet;
    }

    receive(msg: SetWhitelist) {
        self.requireOwner();
        self.whitelist.set(msg.investor, msg.allowed);
    }

    // MED-01: вывод средств — только казна (мультисиг), НЕ owner.
    receive(msg: WithdrawUsdt) {
        throwUnless(140, sender() == self.treasury);
        throwUnless(0xfffe, self.usdtWallet != null);
        // R4: fail fast (clean revert) if too little TON is attached for a real USDT transfer.
        require(context().value >= ton("0.06"), "attach more TON for the jetton transfer");
        // INFO-01: нельзя вывести больше, чем принято и ещё не выведено
        require(msg.amount > 0 && msg.amount <= self.totalRaised - self.withdrawn, "amount > available");
        self.withdrawn += msg.amount;
        send(SendParameters {
            to: self.usdtWallet!!,
            value: 0,
            mode: SendRemainingValue,
            bounce: true, // R3: if the USDT wallet rejects, it bounces back -> bounced() rolls withdrawn back
            body: JettonTransfer {
                queryId: 1, // R3: tag = withdraw (bounced() decrements withdrawn on this op+queryId)
                amount: msg.amount,
                destination: msg.destination,
                responseDestination: msg.destination,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).endCell().asSlice(),
            }.toCell(),
        });
    }

    // M-3: смести застрявшие jetton'ы сверх учёта totalRaised. Только казна (мультисиг).
    // НЕ трогает totalRaised/withdrawn — это средства вне обычного учёта.
    receive(msg: SweepUsdt) {
        throwUnless(140, sender() == self.treasury);
        throwUnless(0xfffe, self.usdtWallet != null);
        require(context().value >= ton("0.06"), "attach more TON for the jetton transfer"); // R4
        require(msg.amount > 0, "amount <= 0");
        send(SendParameters {
            to: self.usdtWallet!!,
            value: 0,
            mode: SendRemainingValue,
            body: JettonTransfer {
                queryId: 2, // R3: tag = sweep (no withdrawn accounting to roll back)
                amount: msg.amount,
                destination: msg.destination,
                responseDestination: msg.destination,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).endCell().asSlice(),
            }.toCell(),
        });
    }

    // MED-01: сменить казну может ТОЛЬКО текущая казна (мультисиг), не серверный owner —
    // иначе скомпрометированный сервер увёл бы вывод на свой адрес.
    receive(msg: SetTreasury) {
        throwUnless(140, sender() == self.treasury);
        self.treasury = msg.treasury;
    }

    // R3: self-heal the `withdrawn` counter if a WithdrawUsdt jetton transfer bounces back
    // (e.g. the real USDT wallet rejects it). We tagged withdraws with queryId=1; the bounced
    // body carries op(32)+queryId(64)+amount(coins) — well within the 256-bit bounce limit.
    bounced(msg: Slice) {
        let op = msg.loadUint(32);
        if (op == 0x0f8a7ea5) {                 // JettonTransfer
            let qid = msg.loadUint(64);
            if (qid == 1) {                     // our withdraw tag
                let amt = msg.loadCoins();
                if (amt <= self.withdrawn) { self.withdrawn -= amt }
            }
        }
    }

    // ---------- Getters ----------
    get fun allocationOf(investor: Address): Allocation {
        let prev = self.investors.get(investor);
        let contributed = (prev == null) ? 0 : prev!!;
        let tokens = 0;
        if (self.priceUsdtPerToken > 0 && contributed > 0) {
            tokens = contributed * pow(10, self.tokenDecimals) / self.priceUsdtPerToken;
            // Фаундеры получают бонус токенов (+founderBonusPct%). Напр. 20% -> ×1.2.
            let fl = self.founderLevel.get(investor);
            if (fl != null && fl!! > 0 && self.founderBonusPct > 0) {
                tokens = tokens * (100 + self.founderBonusPct) / 100;
            }
        }
        return Allocation { usdtContributed: contributed, tokenAllocation: tokens };
    }

    get fun statusOf(investor: Address): InvestorStatus {
        let fl = self.founderLevel.get(investor);
        let founderLevel = (fl == null) ? 0 : fl!!;
        let fu = self.founderUsdt.get(investor);
        let founderUsdt = (fu == null) ? 0 : fu!!;
        let c = self.investors.get(investor);
        let contributed = (c == null) ? 0 : c!!;
        let tier = self.seedTierOf(contributed);
        let eff = (founderLevel > 0) ? STATUS_FOUNDER : tier;
        return InvestorStatus {
            founderLevel: founderLevel,
            founderUsdt: founderUsdt,
            seedContributed: contributed,
            seedTier: tier,
            effectiveStatus: eff,
        };
    }

    get fun isFounder(investor: Address): Bool {
        let fl = self.founderLevel.get(investor);
        return fl != null && fl!! > 0;
    }

    get fun isWhitelisted(investor: Address): Bool {
        let wl = self.whitelist.get(investor);
        return wl != null && wl!!;
    }

    get fun roundInfo(): RoundInfo {
        return RoundInfo {
            owner: self.owner,
            treasury: self.treasury,
            usdtWallet: self.usdtWallet,
            stopped: self.stopped,
            withdrawn: self.withdrawn,
            priceUsdtPerToken: self.priceUsdtPerToken,
            tokenDecimals: self.tokenDecimals,
            hardCap: self.hardCap,
            minBuy: self.minBuy,
            maxBuy: self.maxBuy,
            maxBuyFounder: self.maxBuyFounder,
            founderBonusPct: self.founderBonusPct,
            startTime: self.startTime,
            endTime: self.endTime,
            whitelistEnabled: self.whitelistEnabled,
            tierAccess: self.tierAccess,
            tierPriority: self.tierPriority,
            tierStrategic: self.tierStrategic,
            totalRaised: self.totalRaised,
            investorsCount: self.investorsCount,
        };
    }
}
