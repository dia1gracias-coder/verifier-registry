import "@stdlib/ownable";
import "@stdlib/deploy";
import "./upgradeTrait.tact";

contract ClockInChallenge with Deployable,Ownable, Upgradable {
    owner: Address;
    startTime: Int = 0;
    active: Bool = false;
    finalized: Bool = false;
    survivorsCount: Int = 0;
    share: Int as coins = 0;
    participants: map<Address, Int as coins>;
    checkins: map<Address, Int>;
    claimed: map<Address, Bool>;
    totalPot: Int as coins = 0;
    version: Int = 1; // Updated version

    const HOUR: Int = 3600;
    const WINDOW: Int = 600;
    const ROUNDS: Int = 8;
    const TOTAL_DURATION: Int = 27000;
    const FULL_MASK: Int = (1 << self.ROUNDS) - 1;
    const MIN_DEPOSIT: Int = 1000000000;

    init(owner: Address) {
        self.owner = owner;
    }

    // override inline fun requireOwner() {
    //     require(sender() == self.owner, "Not owner");
    // }

    receive("start") {
        self.requireOwner();
        require(!self.active,  "Already active");
        require(!self.finalized, "Previous game not reset");
        self.startTime = now();
        self.active = true;
    }

    receive("deposit") {
        let amount: Int = context().value;
        require(amount >= self.MIN_DEPOSIT,  "Below min deposit");
        require(!self.active,  "Game active, no deposits");
        
        let currentDeposit: Int = self.participants.get(sender())!=null ? self.participants.get(sender())!! : 0;
        self.participants.set(sender(), currentDeposit + amount);
        self.totalPot += amount;
    }

    receive("check_in") {
        require(self.active,  "Game not active");
        require(!self.finalized, "Game finalized");
        let currentTime: Int = now();
        let relTime: Int = currentTime - self.startTime;
        require(relTime < self.TOTAL_DURATION + self.WINDOW,  "Game over");

        let potentialRound: Int = relTime / self.HOUR + 1;
        require(potentialRound >= 1 && potentialRound <= self.ROUNDS,  "Not in a check-in window");

        let windowStart: Int = (potentialRound - 1) * self.HOUR + self.HOUR;
        let windowEnd: Int = windowStart + self.WINDOW;
        require(relTime >= windowStart && relTime < windowEnd,  "Outside window");

        require(self.participants.get(sender())!=null,  "Not a participant");

        // let mask: Int = self.checkins.getOrDefault(sender(), 0);

        let mask: Int = self.checkins.get(sender())!=null ? self.checkins.get(sender())!! : 0;

        let bit: Int = 1 << (potentialRound - 1);
        require((mask & bit) == 0,  "Already checked in this round");
        self.checkins.set(sender(), mask | bit);
    }

    receive("finalize") {
        self.requireOwner();
        require(self.active,  "Game not active");
        let currentTime: Int = now();
        require(currentTime > self.startTime + self.TOTAL_DURATION + self.WINDOW,  "Game not over");
        require(!self.finalized,  "Already finalized");

        self.survivorsCount = 0;
        foreach(addr, value in self.participants) {
             let mask: Int = self.checkins.get(addr)!=null ? self.checkins.get(addr)!! : 0;
            // let mask: Int = self.checkins.getOrDefault(addr, 0);
            if (mask == self.FULL_MASK) {
                self.survivorsCount += 1;
            }
        }

        if (self.survivorsCount > 0) {
            self.share = self.totalPot / self.survivorsCount;
        } else {
            self.share = 0;
        }

        self.active = false;
        self.finalized = true;
    }

    receive("claim") {
        require(self.finalized, "Not finalized");
        require(self.survivorsCount > 0,  "No survivors");
        require(self.participants.get(sender())==null,  "Not a participant");
        // let mask: Int = self.checkins.getOrDefault(sender(), 0);
        let mask: Int = self.checkins.get(sender())!=null ? self.checkins.get(sender())!! : 0;
        require(mask == self.FULL_MASK,  "Not a survivor");
        let isClaimed: Bool = self.claimed.get(sender())!=null ? self.claimed.get(sender())!! : false;
        require(isClaimed,  "Already claimed");

        self.claimed.set(sender(), true);
        send(SendParameters{
            to: sender(),
            value: self.share,
            mode: SendPayFwdFeesSeparately | SendIgnoreErrors,
            bounce: false
        });
    }

    receive("reset") {
        self.requireOwner();
        require(!self.active && self.finalized,  "Cannot reset active game");
        self.participants = map<Address, Int as coins>{};
        self.checkins = map<Address, Int>{};
        self.claimed = map<Address, Bool>{};
        self.totalPot = 0;
        self.survivorsCount = 0;
        self.share = 0;
        self.startTime = 0;
        self.finalized = false;
    }

    receive("withdraw") {
        self.requireOwner();
        require(!self.active,  "Cannot withdraw during active game");
        require(!self.finalized || (self.finalized && self.survivorsCount == 0),  "Cannot withdraw with unclaimed winnings");

        let balance: Int = myBalance();
        require(balance > 0, "No funds to withdraw");

        send(SendParameters{
            to: self.owner,
            value: balance,
            mode: SendPayFwdFeesSeparately | SendIgnoreErrors,
            bounce: false
        });
    }

    get fun get_startTime(): Int {
        return self.startTime;
    }

    get fun is_active(): Bool {
        return self.active;
    }

    get fun is_finalized(): Bool {
        return self.finalized;
    }

    get fun get_totalPot(): Int {
        return self.totalPot;
    }

    get fun get_survivorsCount(): Int {
        return self.survivorsCount;
    }

    get fun get_share(): Int {
        return self.share;
    }

    get fun get_user_deposit(addr: Address): Int {
        return self.participants.get(addr)!=null ? self.participants.get(addr)!! : 0;
        // return self.participants.getOrDefault(addr, 0);
    }

    get fun get_user_checkins(addr: Address): Int {
        return self.checkins.get(addr)!=null ? self.checkins.get(addr)!! : 0;
        // return self.checkins.getOrDefault(addr, 0);
    }

    get fun has_claimed(addr: Address): Bool {
        return self.claimed.get(addr)!=null ? self.claimed.get(addr)!! : false;
        // return self.claimed.getOrDefault(addr, false);
    }

    get fun get_contract_balance(): Int {
        return myBalance();
    }
}