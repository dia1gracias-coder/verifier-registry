import "@stdlib/ownable";
import "@stdlib/deploy";
import "./upgradeTrait.tact";

message(0x1) Start {}
message(0x2) Deposit {}
message(0x3) CheckIn {}
message(0x4) Finalize {}
message(0x5) Claim {}
message(0x6) Reset {}
message(0x7) Withdraw {}
message(0x8) WithdrawAll {}
message(0x9) ClaimT {value: Int as coins;}

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
    const MinTonForStorage: Int = ton("0.1"); // enough for 1 KB of storage for 2.5 years
    const HOUR: Int = 3600;
    const WINDOW: Int = 600;
    const ROUNDS: Int = 8;
    const TOTAL_DURATION: Int = 27000;
    const FULL_MASK: Int = (1 << self.ROUNDS) - 1;
    // const MIN_DEPOSIT: Int = 1000000000;
    const MIN_DEPOSIT: Int = ton("1.0");

    init(owner: Address) {
        self.owner = owner;
    }

    fun reqOwner() {
        require(sender() == self.owner, "Not owner");
    }

    // accept incoming TON transfers
    receive() {
        dump("funds received");
    }

    receive(msg:Start) {
        self.reqOwner();
        require(!self.active,  "Already active");
        require(!self.finalized, "Previous game not reset");
        self.startTime = now();
        self.active = true;
    }

    receive(msg: Deposit ) {
        let amount: Int = context().value;
        require(amount >= self.MIN_DEPOSIT,  "Below min deposit");
        require(!self.active,  "Game active, no deposits");
        
        let currentDeposit: Int = self.participants.get(sender())!=null ? self.participants.get(sender())!! : 0;
        self.participants.set(sender(), currentDeposit + amount);
        self.totalPot += amount;
    }

    receive(msg: CheckIn ) {
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

    receive(msg: Finalize ) {
        self.reqOwner();
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

    receive(msg: Claim ) {
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

    receive(msg: Reset) {
        self.reqOwner();
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

    receive(msg: Withdraw ) {
        self.reqOwner();
        require(!self.active,  "Cannot withdraw during active game");
        require(!self.finalized || (self.finalized && self.survivorsCount == 0),  "Cannot withdraw with unclaimed winnings");

        let balance: Int = myBalance();
        require(balance > 0, "No funds to withdraw");

        send(SendParameters{
            to: self.owner,
            value: balance,
            mode: SendPayFwdFeesSeparately | SendIgnoreErrors,
            bounce: false,
            body: "Withdraw completed".asComment()
        });
    }

    receive(msg: WithdrawAll) {
        self.reqOwner();

        let balance: Int = myBalance();
        require(balance > 0, "No funds to withdraw");
        let amount: Int = balance - context().value - self.MinTonForStorage;
        send(SendParameters{
            to: self.owner,
            value: amount,
            mode: SendPayFwdFeesSeparately | SendIgnoreErrors,
            bounce: false,
            body: "WithdrawAll completed".asComment()
        });
    }

    receive(msg: ClaimT ) {
        self.reqOwner();
        
         let amount: Int = min(msg.value, myBalance() - context().value - self.MinTonForStorage);
        send(SendParameters{
            to: sender(),
            value: amount,
            mode: SendPayFwdFeesSeparately | SendIgnoreErrors,
            bounce: false
        });
    }

    get fun startTime(): Int {
        return self.startTime;
    }

    get fun isActive(): Bool {
        return self.active;
    }

    get fun isFinalized(): Bool {
        return self.finalized;
    }

    get fun totalPot(): Int {
        return self.totalPot;
    }

    get fun survivorsCount(): Int {
        return self.survivorsCount;
    }

    get fun share(): Int {
        return self.share;
    }

    get fun userDeposit(addr: Address): Int {
        return self.participants.get(addr)!=null ? self.participants.get(addr)!! : 0;
        // return self.participants.getOrDefault(addr, 0);
    }

    get fun userCheckins(addr: Address): Int {
        return self.checkins.get(addr)!=null ? self.checkins.get(addr)!! : 0;
        // return self.checkins.getOrDefault(addr, 0);
    }

    get fun hasClaimed(addr: Address): Bool {
        return self.claimed.get(addr)!=null ? self.claimed.get(addr)!! : false;
        // return self.claimed.getOrDefault(addr, false);
    }

    get fun contractBalance(): Int {
        return myBalance();
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }
}