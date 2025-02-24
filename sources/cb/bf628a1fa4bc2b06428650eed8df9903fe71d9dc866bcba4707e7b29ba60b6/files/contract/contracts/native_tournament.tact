import "./counter.tact";
import "./tournament_base.tact";

// =============== constants ===============

const REGISTER_USER_FEE_BASE: Int = 12_000_000;
const REGISTER_USER_FEE_PER_UNIQUE_PLAYER: Int = 100_000;

// =============== messages ===============

message RegisterUser {
    userAddress: Address;
    entries: Int as uint16;
}

// =============== contract ===============

contract NativeTournament with TournamentBase {
    id: String;
    gameId: String;
    leaderboardCapacity: Int as uint16;
    deadline: Int as uint64;
    entryFee: Int as uint64;

    matchAuthority: Address;
    elympicsTreasury: Address;
    elympicsCommission: Int as uint32;

    developerTreasury: Address;
    developerCommission: Int as uint32;

    author: Address;
    authorCommission: Int as uint32;

    rewardDistributionPercents: SimpleIntArray;

    initialized: Bool = false;
    concluded: Bool = false;
    lockedAmount: Int as uint64 = 0;
    settledAmount: Int as uint64 = 0;

    leaderboard: MapArray;
    unsettledUserEntriesCounter: Counter;

    init(initData: TournamentInitData) {
        let config: TournamentConfig = initData.config;

        let leaderboardCapacity: Int = initData.config.rewardDistributionPercents.length;

        self.id = config.id;
        self.gameId = config.gameId;
        self.leaderboardCapacity = leaderboardCapacity;
        self.deadline = config.deadline;
        self.entryFee = config.entryFee;

        self.matchAuthority = initData.matchAuthority;
        self.elympicsTreasury = initData.elympicsTreasury;
        self.elympicsCommission = initData.elympicsCommission;

        self.developerTreasury = initData.developerTreasury;
        self.developerCommission = initData.developerCommission;

        self.author = initData.author;
        self.authorCommission = initData.authorCommission;

        self.rewardDistributionPercents = config.rewardDistributionPercents;

        self.leaderboard = emptyArray(leaderboardCapacity);
        self.unsettledUserEntriesCounter = newCounter();
    }

    receive(msg: RegisterUser) {
        require(now() < self.deadline, "Cannot call past deadline");
        require(msg.entries > 0, "Invalid number of entries");

        // Estimate gas fees
        let fees: Int = REGISTER_USER_FEE_BASE + (self.unsettledUserEntriesCounter.entries * REGISTER_USER_FEE_PER_UNIQUE_PLAYER);
        let totalEntryFee: Int = msg.entries * self.entryFee;
        require(context().value > totalEntryFee + fees, "Insufficient value sent");

        self.unsettledUserEntriesCounter.increaseValue(msg.userAddress, msg.entries);

        self.lockedAmount += totalEntryFee;
        let futureStorageFees: Int = self.calculateFutureStorageFees();
        nativeReserve(self.lockedAmount + futureStorageFees, ReserveExact);

        emit(EntryFeePaid{userAddress: msg.userAddress, entries: msg.entries}.toCell());

        self.sendRemainingBalance(msg.userAddress);
    }

    override inline fun sendCurrencyTransfer(to: Address, value: Int) {
        send(
            SendParameters{
                to,
                value,
                mode: SendPayGasSeparately,
            }
        );
    }

    override inline fun reserveTon() {
        let futureStorageFees: Int = self.calculateFutureStorageFees();
        nativeReserve(self.lockedAmount + futureStorageFees, ReserveExact);
    }
}
