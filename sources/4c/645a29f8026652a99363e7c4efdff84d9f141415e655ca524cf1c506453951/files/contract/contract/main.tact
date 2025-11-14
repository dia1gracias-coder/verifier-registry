import "@stdlib/deploy";

message OwnerSetBasePrice { newPrice: Int; }
message OwnerSetLevelMultiplier { level: Int; k: Int; }
message OwnerWithdraw { amount: Int; recipient: Address; }
message OwnerTransferOwnership { newOwner: Address; }
message OwnerStartMega { } // trigger MEGA JACKPOT manually

// ----------------- CONSTANTS -----------------

const LEVEL_MINING: Int   = 0;  // 5 USDT
const LEVEL_GOLD: Int     = 1;  // 10 USDT
const LEVEL_TREASURE: Int = 2;  // 20 USDT

const MAX_TICKETS: Int = 777;

// Multipliers for jackpot distribution
const JACKPOT_MULT: Int     = 100;  // main jackpot X100
const MULT_4X_COUNT: Int    = 16;   // count of X4 winners
const MULT_2X_COUNT: Int    = 62;   // count of X2 winners
const MULT_1X_COUNT: Int    = 125;  // count of X1 winners

// Total number of winners
const TOTAL_WINNERS: Int =
    1 + MULT_4X_COUNT + MULT_2X_COUNT + MULT_1X_COUNT; // 1 main + others

// Bonuses
const BNSS_FOR10_REF: Int = ton("1");   // bonus for each 10 referrals
const BNSS_FOR3_WINS: Int = ton("10");  // bonus for 3 wins in a row

// ----------------- STRUCTS -----------------

struct LevelConfig {
    k: Int; // multiplier: 1,2,4 -> X = basePrice * k
}

// Cycle per level
struct Cycle {
    id: Int;
    ticketsSold: Int;
    isFinished: Bool;
    tickets: map<Int, Address>; // ticketId -> owner
}

// Tickets for one user in one level
struct UserTickets {
    cycleId: Int;
    count: Int;
    ticketsOwned: map<Int, Bool>; // ticketId -> owned
}

// Main player info
struct PlayerInfo {
    referrer: Address;              // who invited this player
    userLevel: Int;                 // 1..3
    winningJackpotAmount: Int;      // total jackpot (normal + mega)

    ticketsBought: map<Int, UserTickets>; // level -> UserTickets
    referredCount: Int;             // how many people he invited

    consecutiveWins: map<Int, Int>; // level -> wins in a row
    lastWinCycle: map<Int, Int>;    // level -> last win cycle id

    inRowBonus: Int;                // sum of "3 wins in row" bonus
    buyBonus: map<Int, Int>;        // level -> sum of buy bonuses
    soldBonus: Int;                 // sum of sold-by-referrals bonuses
    referralBonus: Int;             // all referral bonuses (level 1+2+3)
    ticketsSoldByReferrals: Int;    // total tickets sold by direct referrals
}

// Saved winners per level & cycle
struct WinningTicketsList {
    winningTicketIds: map<Int, Int>;     // idx -> ticketId
    winningTicketAmounts: map<Int, Int>; // idx -> amount
}

// ----------------- MESSAGES -----------------

message Register {
    user: Address;
    referrer: Address;
}

message BuyTicket {
    level: Int;
    count: Int;
}

// ----------------- CONTRACT -----------------

contract MultiLevelLottery with Deployable {

    // Config & state
    owner: Address;
    basePrice: Int; // price of level 0 ticket in nanotons (5 USDT equivalent)

    levelCfg: map<Int, LevelConfig> = emptyMap();
    cycles: map<Int, Cycle> = emptyMap(); // level -> cycle

    winningTickets: map<Int, WinningTicketsList> = emptyMap(); // level -> last winners

    players: map<Address, PlayerInfo> = emptyMap();

    megaJackpot: Int = 0;      // 3% from all ticket sales
    megaJackpotStart: Int = 0; // timestamp when mega started

    // ----------------- INIT -----------------

    init(owner: Address) {
        self.owner = owner;
        self.basePrice = ton("5");
        self.megaJackpotStart = now();

        // level configs
        self.levelCfg.set(LEVEL_MINING,   LevelConfig{ k: 1 });
        self.levelCfg.set(LEVEL_GOLD,     LevelConfig{ k: 2 });
        self.levelCfg.set(LEVEL_TREASURE, LevelConfig{ k: 4 });

        // initial cycles per level
        self.cycles.set(LEVEL_MINING,   Cycle{ id: 1, ticketsSold: 0, isFinished: false, tickets: emptyMap() });
        self.cycles.set(LEVEL_GOLD,     Cycle{ id: 1, ticketsSold: 0, isFinished: false, tickets: emptyMap() });
        self.cycles.set(LEVEL_TREASURE, Cycle{ id: 1, ticketsSold: 0, isFinished: false, tickets: emptyMap() });
    }

    // ----------------- REGISTER -----------------

    // register user with referrer; only owner can call
    receive(msg: Register) {
        require(sender() == self.owner, "ONLY_OWNER");
        require(!self.players.exists(msg.user), "ALREADY_REGISTERED");

        let p = PlayerInfo{
            referrer: msg.referrer,
            userLevel: 1,
            winningJackpotAmount: 0,
            ticketsBought: emptyMap(),
            referredCount: 0,
            consecutiveWins: emptyMap(),
            lastWinCycle: emptyMap(),
            inRowBonus: 0,
            buyBonus: emptyMap(),
            soldBonus: 0,
            referralBonus: 0,
            ticketsSoldByReferrals: 0
        };
        self.players.set(msg.user, p);

        // increment referrer count & give 1 TON (or USDT-equivalent) per 10 referrals
        if (msg.referrer != self.owner && self.players.exists(msg.referrer)) {
            let ref = self.players.get(msg.referrer)!!;
            ref.referredCount += 1;
            if (ref.referredCount % 10 == 0) {
                ref.referralBonus += BNSS_FOR10_REF;
                self.sendTon(msg.referrer, BNSS_FOR10_REF, "Referral milestone bonus");
            }
            self.players.set(msg.referrer, ref);
        }
    }

    // ----------------- BUY TICKET -----------------

    receive(msg: BuyTicket) {
        require(msg.count > 0, "BAD_COUNT");

        // user must be registered
        require(self.players.exists(sender()), "NOT_REGISTERED");
        let player = self.players.get(sender())!!;

        // level config
        require(self.levelCfg.exists(msg.level), "BAD_LEVEL");
        let cfg = self.levelCfg.get(msg.level)!!;

        // current cycle
        require(self.cycles.exists(msg.level), "NO_CYCLE");
        let cycle = self.cycles.get(msg.level)!!;
        require(!cycle.isFinished, "CYCLE_FINISHED");

        // pricing
        let pricePerTicket = self.basePrice * cfg.k;
        let totalPrice = pricePerTicket * msg.count;

        require(context().value >= totalPrice, "NOT_ENOUGH_TON");

        // max tickets check
        let newSold = cycle.ticketsSold + msg.count;
        require(newSold <= MAX_TICKETS, "TOO_MANY_TICKETS");

        // user tickets per level
        let userTicketsOpt = player.ticketsBought.get(msg.level);
        let userTickets: UserTickets =  UserTickets{
                cycleId: 1,
                count: 0,
                ticketsOwned: emptyMap()
            };

        if (userTicketsOpt == null || userTicketsOpt!!.cycleId != cycle.id) {
            // new cycle tickets
            userTickets = UserTickets{
                cycleId: cycle.id,
                count: msg.count,
                ticketsOwned: emptyMap()
            };
        } else {
            userTickets = userTicketsOpt!!;
            userTickets.count += msg.count;
        }

        // write tickets
        let ticketsMap = cycle.tickets;
        let i: Int = 1;
        while (i <= msg.count) {
            let ticketId = cycle.ticketsSold + i; // 1..777
            ticketsMap.set(ticketId, sender());
            userTickets.ticketsOwned.set(ticketId, true);
            i += 1;
        }

        // update cycle
        let newCycle = Cycle{
            id: cycle.id,
            ticketsSold: newSold,
            isFinished: (newSold == MAX_TICKETS),
            tickets: ticketsMap
        };
        self.cycles.set(msg.level, newCycle);

        // 3% to mega jackpot
        let megaPart = (totalPrice * 3) / 100;
        self.megaJackpot += megaPart;

        // save player tickets
        player.ticketsBought.set(msg.level, userTickets);
        self.players.set(sender(), player);

        // bonuses on buy
        self.processPlayerBuy(msg.level, sender(), msg.count);
        self.processSoldBonus(sender(), msg.count, totalPrice);

        // if cycle full -> execute jackpot for this level
        if (newSold == MAX_TICKETS) {
            self.executeJackpot(msg.level, cycle.id);
        }

        // mega-jackpot trigger (example: once in 30 days)
        if (now() - self.megaJackpotStart >= 30 * 24 * 3600) {
            self.executeMegaCalculation();
        }
    }

    // ----------------- BUY BONUSES -----------------

    inline fun processPlayerBuy(level: Int, buyer: Address, count: Int) {
        let p = self.players.get(buyer)!!;
        let cfg = self.levelCfg.get(level)!!;

        let ticketsOpt = p.ticketsBought.get(level);
        let prevCount: Int =
            ticketsOpt == null ? 0 : ticketsOpt!!.count;
        let newBought = prevCount + count;

        let x = self.basePrice * cfg.k;
        let allBuyBonus: Int = 0;

        // Level up & bonuses:
        // Level 1 -> 2: after 10 tickets
        if (p.userLevel == 1 && newBought >= 10) {
            allBuyBonus += x / 5;  // X/5
            p.userLevel = 2;
        }

        // Level 2 -> 3: after 60 tickets (10 + 50)
        if (p.userLevel == 2 && newBought >= 60) {
            allBuyBonus += x * 2;  // 2X
            p.userLevel = 3;
        }

        // Level 3: every extra 100 tickets after 60 gives 6X
        if (p.userLevel == 3 && newBought > 60) {
            let extra = newBought - 60;
            let blocks = extra / 100;
            if (blocks > 0) {
                allBuyBonus += blocks * x * 6;
            }
        }

        if (allBuyBonus > 0) {
            let prevBonus = p.buyBonus.get(level);
            let prevVal: Int = prevBonus == null ? 0 : prevBonus!!;
            p.buyBonus.set(level, prevVal + allBuyBonus);

            self.sendTon(buyer, allBuyBonus, "Buy bonus");
        }

        self.players.set(buyer, p);
    }

    inline fun processSoldBonus(buyer: Address, count: Int, totalPrice: Int) {
        let p = self.players.get(buyer)!!;
        let refAddr = p.referrer;

        if (refAddr == self.owner || !self.players.exists(refAddr)) {
            return;
        }

        let ref = self.players.get(refAddr)!!;
        ref.ticketsSoldByReferrals += count;

        let b: Int = 0;
        if (ref.ticketsSoldByReferrals > 25) {
            b = totalPrice / 10;      // 10%
        } else if (ref.ticketsSoldByReferrals > 10) {
            b = totalPrice / 20;      // 5%
        } else {
            b = (totalPrice * 3) / 100; // 3%
        }

        if (b > 0) {
            ref.soldBonus += b;
            self.sendTon(refAddr, b, "Sold bonus");
        }

        self.players.set(refAddr, ref);
    }

    // ----------------- JACKPOT -----------------

    inline fun executeJackpot(level: Int, cycleId: Int) {
        // generate unique random ticket ids for TOTAL_WINNERS
        let randoms = self.randomGenerator(TOTAL_WINNERS, MAX_TICKETS);

        let winnersAmounts: map<Int, Int> = emptyMap();

        let cfg = self.levelCfg.get(level)!!;
        let ticketPrice = self.basePrice * cfg.k;

        let i: Int = 1;
        while (i <= TOTAL_WINNERS) {
            let ticketId = randoms.get(i)!!;
            let cycle = self.cycles.get(level)!!; // current cycle (finished)
            let winnerAddrOpt = cycle.tickets.get(ticketId);
            if (winnerAddrOpt == null) {
                i += 1;
            }else{
            let winner = winnerAddrOpt!!;

            let bonus: Int  = 0;

            if (i == 1) {
                bonus = ticketPrice * JACKPOT_MULT;
            } else if (i > 1 && i <= 1 + MULT_4X_COUNT) {
                bonus = ticketPrice * 4;
            } else if (i > 1 + MULT_4X_COUNT && i <= 1 + MULT_4X_COUNT + MULT_2X_COUNT) {
                bonus = ticketPrice * 2;
            } else {
                bonus = ticketPrice * 1;
            }

            winnersAmounts.set(i, bonus);

            self.deliveryWinning(winner, level, bonus, cycleId);

            i += 1;
            }
        }

        self.winningTickets.set(
            level,
            WinningTicketsList{
                winningTicketIds: randoms,
                winningTicketAmounts: winnersAmounts
            }
        );

        // start new cycle
        let oldCycle = self.cycles.get(level)!!;
        self.cycles.set(
            level,
            Cycle{
                id: oldCycle.id + 1,
                ticketsSold: 0,
                isFinished: false,
                tickets: emptyMap()
            }
        );
    }

    fun deliveryWinning(winner: Address, level: Int, bonus: Int, cycleId: Int) {
        // pay jackpot
        self.sendTon(winner, bonus, "Jackpot bonus");

        let p = self.players.get(winner)!!;
        p.winningJackpotAmount += bonus;

        // consecutive wins per level
        let lastCycleOpt = p.lastWinCycle.get(level);
        let lastCycle: Int = lastCycleOpt == null ? 0 : lastCycleOpt!!;

        let prevStreakOpt = p.consecutiveWins.get(level);
        let prevStreak: Int = prevStreakOpt == null ? 0 : prevStreakOpt!!;

        let newStreak: Int = 0;

        if (lastCycle + 1 == cycleId) {
            newStreak = prevStreak + 1;
        } else {
            newStreak = 1;
        }

        if (newStreak >= 3) {
            // give bonus & reset streak
            p.inRowBonus += BNSS_FOR3_WINS;
            self.sendTon(winner, BNSS_FOR3_WINS, "3 wins in a row bonus");
            newStreak = 0;
        }

        p.consecutiveWins.set(level, newStreak);
        p.lastWinCycle.set(level, cycleId);

        self.players.set(winner, p);

        // multi-level referral rewards: 10% / 5% / 2%
        self.payReferralChain(winner, bonus);
    }

    inline fun payReferralChain(winner: Address, bonus: Int) {
        let p1 = self.players.get(winner)!!;
        let r1 = p1.referrer;

        // 1st level: 10%
        if (r1 != self.owner && self.players.exists(r1)) {
            let ref1 = self.players.get(r1)!!;
            let amount1 = bonus / 10;
            if (amount1 > 0) {
                ref1.referralBonus += amount1;
                self.sendTon(r1, amount1, "Referral L1 bonus");
                self.players.set(r1, ref1);
            }

            // 2nd level: 5%
            let r2 = ref1.referrer;
            if (r2 != self.owner && self.players.exists(r2)) {
                let ref2 = self.players.get(r2)!!;
                let amount2 = bonus / 20;
                if (amount2 > 0) {
                    ref2.referralBonus += amount2;
                    self.sendTon(r2, amount2, "Referral L2 bonus");
                    self.players.set(r2, ref2);
                }

                // 3rd level: 2%
                let r3 = ref2.referrer;
                if (r3 != self.owner && self.players.exists(r3)) {
                    let ref3 = self.players.get(r3)!!;
                    let amount3 = bonus / 50;
                    if (amount3 > 0) {
                        ref3.referralBonus += amount3;
                        self.sendTon(r3, amount3, "Referral L3 bonus");
                        self.players.set(r3, ref3);
                    }
                }
            }
        }
    }

    // ----------------- RANDOM -----------------
    // same logic as you had: unique random ids with checkMap

    fun randomGenerator(count: Int, limit: Int): map<Int, Int> {
        let result: map<Int, Int> = emptyMap();
        let used: map<Int, Bool> = emptyMap();

        let i: Int = 1;
        while (i <= count) {
            // NOTE: adjust nativeRandomizeLt() to correct signature for your stdlib if needed
            nativeRandomizeLt();
            let idk = random(1, limit + 1);

            if (!used.exists(idk)) {
                used.set(idk, true);
                result.set(i, idk);
                i += 1;
            }
        }

        return result;
    }

    // ----------------- SEND TON -----------------

    fun sendTon(recipient: Address, amount: Int, comment: String) {
        send(SendParameters{
            to: recipient,
            value: amount,
            bounce: true,
            body: comment.asComment()
        });
    }

    // ----------------- MEGA JACKPOT (STUB) -----------------

    inline fun executeMegaCalculation() {
        // TODO: implement your mega jackpot distribution using self.megaJackpot
        // reset timer
        self.megaJackpotStart = now();
    }

    // -------------------- OWNER FUNCTIONS --------------------

    // Set base ticket price for level 0 (others = price * k)
    receive(msg: OwnerSetBasePrice) {
        require(sender() == self.owner, "ONLY_OWNER");
        require(msg.newPrice > 0, "BAD_PRICE");
        self.basePrice = msg.newPrice;
    }

    // Set multiplier k for level (1,2,4 etc)
    receive(msg: OwnerSetLevelMultiplier) {
        require(sender() == self.owner, "ONLY_OWNER");
        require(self.levelCfg.exists(msg.level), "BAD_LEVEL");
        require(msg.k > 0, "BAD_MULT");

        let cfg = self.levelCfg.get(msg.level)!!;
        cfg.k = msg.k;
        self.levelCfg.set(msg.level, cfg);
    }

    // Withdraw TON from contract
    receive(msg: OwnerWithdraw) {
        require(sender() == self.owner, "ONLY_OWNER");
        require(msg.amount > 0, "BAD_AMOUNT");

        self.sendTon(msg.recipient, msg.amount, "Owner withdraw");
    }

    // Transfer ownership
    receive(msg: OwnerTransferOwnership) {
        require(sender() == self.owner, "ONLY_OWNER");
        require(msg.newOwner != newAddress(0, 0), "BAD_OWNER");

        self.owner = msg.newOwner;
    }

    // Manually trigger mega jackpot (logic implemented later)
    receive(msg: OwnerStartMega) {
        require(sender() == self.owner, "ONLY_OWNER");

        self.executeMegaCalculation();
    }

    // -------------------- Get FUNCTIONS --------------------
    get fun getPlayerInfo(user: Address): PlayerInfo? {
        if (!self.players.exists(user)) {
            return null;
        }
        return self.players.get(user)!!;
    }

    get fun getCycle(level: Int): Cycle? {
        if (!self.cycles.exists(level)) {
            return null;
        }
        return self.cycles.get(level)!!;
    }   
    get fun getLevelConfig(level: Int): LevelConfig? {
        if (!self.levelCfg.exists(level)) {
            return null;
        }
        return self.levelCfg.get(level)!!;

    }

    get fun getWinningTickets(level: Int): WinningTicketsList? {
        if (!self.winningTickets.exists(level)) {
            return null;
        }
        return self.winningTickets.get(level)!!;
    }

    get fun getMegaJackpot(): Int {
        return self.megaJackpot;
    }

    get fun getOwner(): Address {
        return self.owner;
    }




}
