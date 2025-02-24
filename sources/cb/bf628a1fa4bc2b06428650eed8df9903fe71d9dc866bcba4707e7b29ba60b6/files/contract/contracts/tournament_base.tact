import "./counter.tact";
import "./leaderboard.tact";

// =============== constants ===============

const SHARE_PRECISION: Int = 1_000_000_000;

const ONE_DAY_IN_SECONDS: Int = 24 * 60 * 60;

const INIT_FEE_PER_PLAYER: Int = 500_000;
const CREATION_FEE_PER_SECOND: Int = 15;

const INIT_FEE_BASE: Int = 50_000_000;

const SETTLE_MATCH_FEE_BASE: Int = 15_000_000;
const SETTLE_MATCH_FEE_PER_LEADERBOARD_PLACE: Int = 4_500_000;

// =============== messages ===============

message Deploy {
    cashbackAddress: Address;
}

message SettleMatch {
    userAddress: Address;
    result: Int as int64;
}

message Conclude {}

// =============== events ===============

message EntryFeePaid {
    userAddress: Address;
    entries: Int as uint16;
}

message MatchSettled {
    userAddress: Address;
    result: Int as int64;
}

message TournamentConcluded {
    rewardedPlayers: map<Address, Int as uint64>;
}

// =============== structures ===============

// Assumes `m` keys contain only numbers {0, ..., length - 1}
struct SimpleIntArray {
    m: map<Int as uint16, Int as uint64>;
    length: Int as uint16;
}

struct TournamentConfig {
    id: String;
    gameId: String;
    deadline: Int as uint64;
    entryFee: Int as uint64;

    jettonMinterAddress: Address?;
    jettonWalletCode: Cell?;
    jettonImplementationVersion: Int?;

    rewardDistributionPercents: SimpleIntArray;
}

struct TournamentInitData {
    config: TournamentConfig;

    matchAuthority: Address;
    elympicsTreasury: Address;
    elympicsCommission: Int as uint32;

    developerTreasury: Address;
    developerCommission: Int as uint32;

    author: Address;
    authorCommission: Int as uint32;
}

trait TournamentBase with Leaderboard {
    id: String;
    gameId: String;
    leaderboardCapacity: Int;
    deadline: Int;
    entryFee: Int;

    matchAuthority: Address;
    elympicsTreasury: Address;
    elympicsCommission: Int;

    developerTreasury: Address;
    developerCommission: Int;

    author: Address;
    authorCommission: Int;

    rewardDistributionPercents: SimpleIntArray;

    initialized: Bool;
    concluded: Bool;
    lockedAmount: Int;

    leaderboard: MapArray;
    unsettledUserEntriesCounter: Counter;

    receive(msg: Deploy) {
        require(!self.initialized, "Already initialized");

        let computeFeesEstimate: Int = INIT_FEE_BASE + self.rewardDistributionPercents.length * INIT_FEE_PER_PLAYER;
        let futureStorageFees: Int = self.calculateFutureStorageFees();
        require(context().value > computeFeesEstimate + futureStorageFees, "Insufficient value sent");

        self.initialized = true;
        nativeReserve(futureStorageFees, ReserveExact);

        self.sendRemainingBalance(msg.cashbackAddress);
    }

    receive(msg: SettleMatch) {
        require(!self.concluded, "Invalid tournament state");
        require(sender() == self.matchAuthority, "Unauthorized caller");

        let unsettledUserEntries = self.unsettledUserEntriesCounter.getValue(msg.userAddress);
        require(unsettledUserEntries > 0, "Insufficient number of unsettled entries");

        let computeFees: Int = SETTLE_MATCH_FEE_BASE + (self.leaderboard.length * SETTLE_MATCH_FEE_PER_LEADERBOARD_PLACE);
        require(context().value >= computeFees, "Insufficient value sent");

        self.unsettledUserEntriesCounter.decrementValue(msg.userAddress);
        self.processUser(PlayerRecord{userAddress: msg.userAddress, score: msg.result});

        self.reserveTon();

        emit(MatchSettled{userAddress: msg.userAddress, result: msg.result}.toCell());

        self.sendRemainingBalance(sender());
    }

    receive(msg: Conclude) {
        require(!self.concluded, "Invalid tournament state");
        require(now() >= self.deadline, "Cannot call earlier than deadline");
        require(sender() == self.matchAuthority, "Unauthorized caller");

        self.concluded = true;

        let someoneJoined: Bool = self.lockedAmount > 0;

        // Pay out Elympics commission
        let elympicsCommission: Int = (self.lockedAmount * self.elympicsCommission) / SHARE_PRECISION;
        if (someoneJoined && elympicsCommission > 0) {
            self.sendCurrencyTransfer(self.elympicsTreasury, elympicsCommission);
        }

        // Pay out Developer commission
        let developerCommission: Int = (self.lockedAmount * self.developerCommission) / SHARE_PRECISION;
        if (someoneJoined && developerCommission > 0) {
            self.sendCurrencyTransfer(self.developerTreasury, developerCommission);
        }

        // Pay out Author commission
        let authorCommission: Int = (self.lockedAmount * self.authorCommission) / SHARE_PRECISION;
        if (someoneJoined && authorCommission > 0) {
            self.sendCurrencyTransfer(self.author, authorCommission);
        }

        // Recalculate rewards positional proportions if leaderboard is not full
        let proportionsSum: Int = SHARE_PRECISION;
        if (someoneJoined && self.leaderboard.length < self.leaderboard.maxSize) {
            proportionsSum = 0;
            let i: Int = 0;
            repeat(self.leaderboard.length) {
                proportionsSum += self.rewardDistributionPercents.m.get(i)!!;
                i += 1;
            }
        }

        // Pay out winners
        let rewards: Int = self.lockedAmount - elympicsCommission - developerCommission - authorCommission;

        let i: Int = 0;
        let rewardedPlayers: map<Address, Int as uint64> = emptyMap();
        let totalPayout: Int = 0;
        repeat(self.leaderboard.length) {
            let payout: Int = (rewards * self.rewardDistributionPercents.m.get(i)!!) / proportionsSum;
            totalPayout += payout;

            if (i == self.leaderboard.length - 1) {
                payout += rewards - totalPayout;
            }

            rewardedPlayers.set(self.leaderboard.get(i).userAddress, payout);
            self.sendCurrencyTransfer(self.leaderboard.get(i).userAddress, payout);

            i += 1;
        }
        emit(TournamentConcluded{rewardedPlayers}.toCell());

        // Send all remaining balance to Match Authority
        self.sendRemainingBalance(self.matchAuthority);
    }

    abstract fun sendCurrencyTransfer(to: Address, value: Int);

    abstract fun reserveTon();

    inline fun calculateFutureStorageFees(): Int {
        let timeToCoverStorageFor: Int = self.max(self.deadline - now() + ONE_DAY_IN_SECONDS, 0);
        return timeToCoverStorageFor * CREATION_FEE_PER_SECOND;
    }

    inline fun sendRemainingBalance(to: Address) {
        send(
            SendParameters{
                to,
                value: 0,
                mode: SendRemainingBalance,
            }
        );
    }

    inline fun max(a: Int, b: Int): Int {
        if (a > b) {
            return a;
        }
        return b;
    }

    get fun id(): String {
        return self.id;
    }

    get fun gameId(): String {
        return self.gameId;
    }

    get fun leaderboardCapacity(): Int {
        return self.leaderboardCapacity;
    }

    get fun deadline(): Int {
        return self.deadline;
    }

    get fun entryFee(): Int {
        return self.entryFee;
    }

    get fun matchAuthority(): Address {
        return self.matchAuthority;
    }

    get fun elympicsTreasury(): Address {
        return self.elympicsTreasury;
    }

    get fun elympicsCommission(): Int {
        return self.elympicsCommission;
    }

    get fun developerTreasury(): Address {
        return self.developerTreasury;
    }

    get fun developerCommission(): Int {
        return self.developerCommission;
    }

    get fun author(): Address {
        return self.author;
    }

    get fun authorCommission(): Int {
        return self.authorCommission;
    }

    get fun rewardDistributionPercents(): SimpleIntArray {
        return self.rewardDistributionPercents;
    }

    get fun concluded(): Bool {
        return self.concluded;
    }

    get fun lockedAmount(): Int {
        return self.lockedAmount;
    }

    get fun leaderboard(): MapArray {
        return self.leaderboard;
    }

    get fun unsettledUserEntries(userAddress: Address): Int {
        return self.unsettledUserEntriesCounter.getValue(userAddress);
    }
}
