import "@stdlib/deploy";

// -------------------- Constants --------------------
const NANO: Int = 1000000000;
const PRECISION: Int = 1000000000000; // 1e12

// Timer
const START_TIMER: Int = 86400;      // 24h
const CAP_72H: Int = 259200;         // 72h
const SOFT_LOCK_10M: Int = 600;      // 10:00
const CHAOS_THRESHOLD: Int = 180;    // 3:00

// Cooldowns
const BUY_COOLDOWN_NORMAL: Int = 30;
const BUY_COOLDOWN_CHAOS: Int = 10;
const SELL_COOLDOWN_NORMAL: Int = 600; 
const SELL_COOLDOWN_CHAOS: Int = 120;  

// Limits
const MAX_ACTIVE_TICKETS_PER_WALLET: Int = 3;
const INTERMISSION: Int = 7200; // 120 minutes

// Prices
const PRICE_LOW: Int = 1000000000;  // 1.0 TON
const PRICE_HIGH: Int = 2000000000; // 2.0 TON

// BP Config
const STAKE_BP: Int = 80; 
const BUY_DIV_BP: Int = 6;
const BUY_DEV_BP: Int = 2;
const BUY_NEXT_BP: Int = 2;
const BUY_REF_BP: Int = 10;

const SURPLUS_WINNERS_BP: Int = 60;
const SURPLUS_DEV_BP: Int = 20;
const SURPLUS_NEXT_BP: Int = 20;

const WIN1_BP: Int = 50;
const WIN2_BP: Int = 30;
const WIN3_BP: Int = 20;

// Safety
const DEV_WITHDRAW_SAFETY_MARGIN: Int = 500000000; // 0.5 TON

// Status Constants
const ROUND_IDLE: Int = 0;
const ROUND_ACTIVE: Int = 1;
const ROUND_ENDED: Int = 2;

// -------------------- Storage structs --------------------
struct Player {
    epoch: Int as uint32;       
    shares: Int as coins;       // 124 bits
    divDebt: Int;               // 257 bits (нужна точность)
    claimableDiv: Int as coins; // 124 bits

    lastBuyTs: Int as uint32;
    lastSellTs: Int as uint32;

    t0: Int as coins;
    t1: Int as coins;
    t2: Int as coins;
    activeCount: Int as uint8;  
    everBought: Bool;           
}

message SetReferrer { referrer: Address; }
message Buy { } 
message Sell { slot: Int as uint8; }   
message ClaimAll { }
message WithdrawDev { to: Address; amount: Int as coins; }

contract TonExpress with Deployable {
    owner: Address;

    // Round State
    status: Int as uint8 = 0; // 0:IDLE, 1:ACTIVE, 2:ENDED
    roundId: Int as uint32 = 0;

    roundStartTs: Int as uint32 = 0;
    endedAt: Int as uint32 = 0;

    timer: Int as uint32 = 0;        
    lastUpdateTs: Int as uint32 = 0; 

    capCurrent: Int as uint32 = 259200; // CAP_72H
    soft10Triggered: Bool = false;
    chaosTriggered: Bool = false;

    passengers: Int as uint32 = 0;
    activePlayers: Int as uint32 = 0; 

    // Economics
    totalShares: Int as coins = 0;    
    divPerShare: Int = 0;             
    devPool: Int as coins = 0;        
    nextRoundPotStored: Int as coins = 0; 

    // Winners
    lastBuy1: Address? = null;
    lastBuy2: Address? = null;
    lastBuy3: Address? = null;

    // Maps
    players: map<Address, Player>;
    referrerOf: map<Address, Address>;

    init(owner: Address) {
        self.owner = owner;
        self.capCurrent = CAP_72H;
    }

    // -------------------- Helpers --------------------
    fun nowTs(): Int { return now(); }
    fun bank(): Int { return myBalance(); }

    fun emptyPlayer(epoch: Int): Player {
        return Player{
            epoch: epoch,
            shares: 0,
            divDebt: self.divPerShare,
            claimableDiv: 0,
            lastBuyTs: 0,
            lastSellTs: 0,
            t0: 0, t1: 0, t2: 0,
            activeCount: 0,
            everBought: false
        };
    }

    fun getP(a: Address): Player {
        let pOpt: Player? = self.players.get(a);
        if (pOpt == null) {
            return self.emptyPlayer(self.roundId);
        }
        let p: Player = pOpt!!;
        if (p.epoch != self.roundId) {
            let ever: Bool = p.everBought;
            p = self.emptyPlayer(self.roundId);
            p.everBought = ever;
        }
        return p;
    }

    fun putP(a: Address, p: Player) {
        self.players.set(a, p);
    }

    fun settle(p: Player): Player {
        let owedScaled: Int = self.divPerShare - p.divDebt;
        if (owedScaled > 0 && p.shares > 0) {
            let accrued: Int = (p.shares * owedScaled) / PRECISION;
            p.claimableDiv = p.claimableDiv + accrued;
        }
        p.divDebt = self.divPerShare;
        return p;
    }

    fun addDividends(amount: Int) {
        if (amount <= 0) { return; }
        if (self.totalShares > 0) {
            self.divPerShare = self.divPerShare + (amount * PRECISION / self.totalShares);
        } else {
            self.nextRoundPotStored = self.nextRoundPotStored + amount;
        }
    }

    fun ticketPrice(): Int {
        if (self.passengers < 100) { return PRICE_LOW; }
        return PRICE_HIGH;
    }

    fun lifeLineBuyDelta(): Int {
        if (self.passengers <= 100) { return 30; }
        if (self.passengers <= 200) { return 15; }
        return 5;
    }
    fun lifeLineSellDelta(): Int {
        if (self.passengers <= 100) { return 10; }
        if (self.passengers <= 200) { return 15; }
        return 20;
    }

    fun chaosBuyDelta(sender: Address): Int {
        let c: Cell = beginCell().storeAddress(sender).storeInt(self.nowTs(), 32).endCell();
        let h: Int = c.hash();
        return (h % 6) + 2; // 2..7
    }

    fun applySoftLocks() {
        if (!self.soft10Triggered && self.timer < SOFT_LOCK_10M) {
            self.soft10Triggered = true;
            if (self.capCurrent > SOFT_LOCK_10M) { self.capCurrent = SOFT_LOCK_10M; }
        }
        if (!self.chaosTriggered && self.timer < CHAOS_THRESHOLD) {
            self.chaosTriggered = true;
            if (self.capCurrent > CHAOS_THRESHOLD) { self.capCurrent = CHAOS_THRESHOLD; }
        }
        if (self.timer > CAP_72H) { self.timer = CAP_72H; }
    }

    fun updateTimerDecay() {
        if (self.status != ROUND_ACTIVE) { return; }
        let dt: Int = self.nowTs() - self.lastUpdateTs;
        if (dt > 0) {
            self.timer = self.timer - dt;
            if (self.timer < 0) { self.timer = 0; }
            self.lastUpdateTs = self.nowTs();
        }
        self.applySoftLocks();
        if (self.timer == 0) {
            self.endRound();
        }
    }

    // -------------------- Transitions --------------------
    fun endRound() {
        if (self.status != ROUND_ACTIVE) { return; }

        self.status = ROUND_ENDED;
        self.endedAt = self.nowTs();

        let refundReserve: Int = self.totalShares / 2;
        let b: Int = self.bank();
        let surplus: Int = b - refundReserve;
        if (surplus < 0) { surplus = 0; }

        let winnersPool: Int = (surplus * SURPLUS_WINNERS_BP) / 100;
        let devAdd: Int = (surplus * SURPLUS_DEV_BP) / 100;
        let nextAdd: Int = (surplus * SURPLUS_NEXT_BP) / 100;

        self.devPool = self.devPool + devAdd;
        self.nextRoundPotStored = self.nextRoundPotStored + nextAdd;

        if (winnersPool > 0) {
            if (self.lastBuy1 != null) {
                send(SendParameters{to: self.lastBuy1!!, value: (winnersPool * WIN1_BP) / 100, mode: 1});
            }
            if (self.lastBuy2 != null) {
                send(SendParameters{to: self.lastBuy2!!, value: (winnersPool * WIN2_BP) / 100, mode: 1});
            }
            if (self.lastBuy3 != null) {
                send(SendParameters{to: self.lastBuy3!!, value: (winnersPool * WIN3_BP) / 100, mode: 1});
            }
        }
    }

    fun canStartNextRound(): Bool {
        return self.status == ROUND_ENDED && self.nowTs() >= (self.endedAt + INTERMISSION);
    }

    fun startNextRoundIfNeeded() {
        if (!self.canStartNextRound()) { return; }

        let b: Int = self.bank();
        let np: Int = b - self.devPool;
        if (np < 0) { np = 0; }
        self.nextRoundPotStored = np;

        self.roundId = self.roundId + 1;
        self.status = ROUND_IDLE;
        
        // Reset Globals
        self.timer = 0;
        self.lastUpdateTs = 0;
        self.capCurrent = CAP_72H;
        self.soft10Triggered = false;
        self.chaosTriggered = false;

        self.passengers = 0;
        self.activePlayers = 0;

        self.totalShares = 0;
        self.divPerShare = 0;

        self.lastBuy1 = null;
        self.lastBuy2 = null;
        self.lastBuy3 = null;
    }

    // -------------------- Messages --------------------
    receive(msg: SetReferrer) {
        let s: Address = sender();
        let p: Player = self.getP(s);

        require(!p.everBought, "REF_LOCKED");
        require(msg.referrer != s, "BAD_REF");

        self.referrerOf.set(s, msg.referrer);
    }

    receive(msg: Buy) {
        self.startNextRoundIfNeeded();

        let s: Address = sender();
        let val: Int = context().value;

        let launchingBuy: Bool = (self.status == ROUND_IDLE);
        if (launchingBuy) {
            self.status = ROUND_ACTIVE;
            self.roundStartTs = self.nowTs();
            self.timer = START_TIMER;
            self.lastUpdateTs = self.nowTs();
            self.capCurrent = CAP_72H;
            self.soft10Triggered = false;
            self.chaosTriggered = false;
        }

        require(self.status == ROUND_ACTIVE, "NOT_ACTIVE");
        self.updateTimerDecay();
        require(self.status == ROUND_ACTIVE, "ENDED_BY_DECAY");

        let p0: Player = self.getP(s);
        let p: Player = self.settle(p0);

        let buyCd: Int = (self.timer < CHAOS_THRESHOLD) ? BUY_COOLDOWN_CHAOS : BUY_COOLDOWN_NORMAL;
        require(self.nowTs() >= p.lastBuyTs + buyCd, "BUY_CD");
        require(p.activeCount < MAX_ACTIVE_TICKETS_PER_WALLET, "MAX_TICKETS");

        let P: Int = self.ticketPrice();
        require(val >= P, "BAD_PRICE");

        let stake: Int = (P * STAKE_BP) / 100;
        
        if (p.t0 == 0) { p.t0 = stake; }
        else if (p.t1 == 0) { p.t1 = stake; }
        else { p.t2 = stake; }

        if (p.activeCount == 0) { self.activePlayers = self.activePlayers + 1; }
        p.activeCount = p.activeCount + 1;
        self.passengers = self.passengers + 1;

        self.totalShares = self.totalShares + stake;
        p.shares = p.shares + stake;
        p.divDebt = self.divPerShare;

        self.lastBuy3 = self.lastBuy2;
        self.lastBuy2 = self.lastBuy1;
        self.lastBuy1 = s;

        let div6: Int = (P * BUY_DIV_BP) / 100;
        let dev2: Int = (P * BUY_DEV_BP) / 100;
        let next2: Int = (P * BUY_NEXT_BP) / 100;
        let ref10: Int = (P * BUY_REF_BP) / 100;

        self.devPool = self.devPool + dev2;
        self.nextRoundPotStored = self.nextRoundPotStored + next2;

        if (launchingBuy) {
            self.nextRoundPotStored = self.nextRoundPotStored + div6;
            self.nextRoundPotStored = self.nextRoundPotStored + ref10;
        } else {
            self.addDividends(div6);
            let refOpt: Address? = self.referrerOf.get(s);
            if (refOpt != null && refOpt!! != s) {
                let ref: Address = refOpt!!;
                let rp0: Player = self.getP(ref);
                let rp: Player = self.settle(rp0);
                rp.claimableDiv = rp.claimableDiv + ref10;
                self.putP(ref, rp);
            } else {
                self.addDividends(ref10);
            }
        }

        if (self.timer < CHAOS_THRESHOLD) {
            let d: Int = self.chaosBuyDelta(s);
            self.timer = self.timer + d;
            if (self.timer > CHAOS_THRESHOLD) { self.timer = CHAOS_THRESHOLD; }
        } else {
            let d: Int = self.lifeLineBuyDelta();
            self.timer = self.timer + d;
            if (self.timer > self.capCurrent) { self.timer = self.capCurrent; }
            if (self.timer > CAP_72H) { self.timer = CAP_72H; }
        }

        self.applySoftLocks();

        p.lastBuyTs = self.nowTs();
        p.everBought = true;
        self.putP(s, p);

        // Return change
        if (val > P) {
            send(SendParameters{to: s, value: val - P, mode: 1});
        }
    }

    receive(msg: Sell) {
        require(self.status == ROUND_ACTIVE, "NOT_ACTIVE");
        self.updateTimerDecay();
        require(self.status == ROUND_ACTIVE, "ENDED_BY_DECAY");

        let s: Address = sender();
        let p0: Player = self.getP(s);
        let p: Player = self.settle(p0);

        let sellCd: Int = (self.timer < CHAOS_THRESHOLD) ? SELL_COOLDOWN_CHAOS : SELL_COOLDOWN_NORMAL;
        require(self.nowTs() >= p.lastSellTs + sellCd, "SELL_CD");

        let stake: Int = 0;
        if (msg.slot == 0) { stake = p.t0; }
        else if (msg.slot == 1) { stake = p.t1; }
        else if (msg.slot == 2) { stake = p.t2; }
        require(stake > 0, "EMPTY_SLOT");

        let rate: Int = 30;
        if (self.timer >= 600) { rate = 15; }
        else if (self.timer >= 180) { rate = 25; }

        let payout: Int = (stake * (100 - rate)) / 100;

        if (rate == 15) {
            self.addDividends((stake * 10) / 100);
            self.devPool = self.devPool + (stake * 3) / 100;
            self.nextRoundPotStored = self.nextRoundPotStored + (stake * 2) / 100;
        } else if (rate == 25) {
            self.addDividends((stake * 17) / 100);
            self.devPool = self.devPool + (stake * 5) / 100;
            self.nextRoundPotStored = self.nextRoundPotStored + (stake * 3) / 100;
        } else {
            self.addDividends((stake * 20) / 100);
            self.devPool = self.devPool + (stake * 6) / 100;
            self.nextRoundPotStored = self.nextRoundPotStored + (stake * 4) / 100;
        }

        if (msg.slot == 0) { p.t0 = 0; }
        if (msg.slot == 1) { p.t1 = 0; }
        if (msg.slot == 2) { p.t2 = 0; }

        p.activeCount = p.activeCount - 1;
        self.passengers = self.passengers - 1;

        p.shares = p.shares - stake;
        self.totalShares = self.totalShares - stake;
        p.divDebt = self.divPerShare;

        if (p.activeCount == 0) { self.activePlayers = self.activePlayers - 1; }

        if (self.timer < CHAOS_THRESHOLD) { self.timer = self.timer - 20; }
        else { self.timer = self.timer - self.lifeLineSellDelta(); }

        if (self.timer < 0) { self.timer = 0; }
        self.applySoftLocks();

        send(SendParameters{to: s, value: payout, mode: 1});

        p.lastSellTs = self.nowTs();
        self.putP(s, p);

        if (self.timer == 0) {
            self.endRound();
        }
    }

    receive(msg: ClaimAll) {
        require(self.status == ROUND_ENDED, "NOT_ENDED");
        require(self.nowTs() < self.endedAt + INTERMISSION, "CLAIM_OVER");

        let s: Address = sender();
        let p0: Player = self.getP(s);
        let p: Player = self.settle(p0);

        let refund: Int = p.shares / 2;
        let divs: Int = p.claimableDiv;
        let total: Int = refund + divs;

        require(total > 0, "NOTHING");

        if (p.activeCount > 0) {
            self.activePlayers = self.activePlayers - 1;
            self.passengers = self.passengers - p.activeCount;
        }
        self.totalShares = self.totalShares - p.shares;

        p.shares = 0;
        p.t0 = 0; p.t1 = 0; p.t2 = 0;
        p.activeCount = 0;
        p.claimableDiv = 0;
        p.divDebt = self.divPerShare;

        self.putP(s, p);

        send(SendParameters{to: s, value: total, mode: 1});
    }

    receive(msg: WithdrawDev) {
        require(sender() == self.owner, "ONLY_OWNER");
        require(self.status == ROUND_ENDED, "DEV_WITHDRAW_ONLY_ENDED");
        require(self.nowTs() < self.endedAt + INTERMISSION, "DEV_WITHDRAW_WINDOW_OVER");
        require(msg.amount > 0, "BAD_AMOUNT");
        require(msg.amount <= self.devPool, "GT_DEVPOOL");

        let refundReserve: Int = self.totalShares / 2;
        let b: Int = self.bank();
        
        require(
            b - msg.amount >= refundReserve + DEV_WITHDRAW_SAFETY_MARGIN, 
           "INSUFFICIENT_BAL_AFTER_DEV_WITHDRAW"
        );

        self.devPool = self.devPool - msg.amount;
        send(SendParameters{to: msg.to, value: msg.amount, mode: 1});
    }

    // -------------------- Getters --------------------
    get fun getRound(): Int { return self.roundId; }
    get fun getStatus(): Int { return self.status; }
    get fun getTimer(): Int { return self.timer; }
    get fun getPrice(): Int { return self.ticketPrice(); }
    get fun getPot(): Int { return self.nextRoundPotStored; }
    
    // Безопасный расчет джекпота для UI
    get fun getJackpot(): Int {
        let refundReserve: Int = self.totalShares / 2;
        let b: Int = self.bank();
        let surplus: Int = b - refundReserve;
        if (surplus < 0) { surplus = 0; }
        return (surplus * SURPLUS_WINNERS_BP) / 100;
    }
}