import "./elympics_config.tact";
import "./fundable.tact";
import "./jetton_tournament.tact";
import "./native_tournament.tact";

// =============== constants ===============

const MAX_TOTAL_COMMISSION: Int = 400_000_000;

// =============== messages ===============

message CreateTournament {
    tournamentConfig: TournamentConfig;

    developerTreasury: Address;
    developerCommission: Int as uint32;

    authorCommission: Int as uint32;
}

// =============== events ===============

message TournamentInitCalled {
    tournament: Address;
    initData: TournamentInitData;
}

// =============== contract ===============

contract TournamentFactory with ElympicsConfig, Fundable {
    deployer: Address;

    matchAuthority: Address;
    elympicsTreasury: Address;
    elympicsCommission: Int as uint32;

    init(matchAuthority: Address, elympicsTreasury: Address, elympicsCommission: Int) {
        require(elympicsCommission <= MAX_TOTAL_COMMISSION, "Commission too high");
        self.deployer = sender();
        self.matchAuthority = matchAuthority;
        self.elympicsTreasury = elympicsTreasury;
        self.elympicsCommission = elympicsCommission;
    }

    receive(msg: CreateTournament) {
        require(msg.tournamentConfig.deadline > now(), "Deadline set in the past");
        require(
            self.elympicsCommission + msg.developerCommission + msg.authorCommission <= MAX_TOTAL_COMMISSION,
            "Total commission too high",
        );
        require(
            msg.tournamentConfig.rewardDistributionPercents.length <= HARD_MAX_ARRAY_SIZE,
            "Leaderboard capacity exceeds max size",
        );

        let i: Int = 0;
        let sum: Int = 0;
        repeat (msg.tournamentConfig.rewardDistributionPercents.length) {
            sum += msg.tournamentConfig.rewardDistributionPercents.m.get(i)!!;
            i += 1;
        }
        require(sum == SHARE_PRECISION, "Invalid reward distribution percents sum");

        let msgValue: Int = context().value;

        // Estimate gas fees
        let fees: Int = 2 * INIT_FEE_BASE;
        // Cover processing rewardDistributionPercents
        fees += msg.tournamentConfig.rewardDistributionPercents.length * INIT_FEE_PER_PLAYER;
        // Cover future storage fees
        fees += (msg.tournamentConfig.deadline - now() + ONE_DAY_IN_SECONDS) * CREATION_FEE_PER_SECOND;

        require(msgValue > fees, "Insufficient value sent");

        let initData: TournamentInitData = TournamentInitData{
            config: msg.tournamentConfig,
            matchAuthority: self.matchAuthority,
            elympicsTreasury: self.elympicsTreasury,
            elympicsCommission: self.elympicsCommission,
            developerTreasury: msg.developerTreasury,
            developerCommission: msg.developerCommission,
            author: sender(),
            authorCommission: msg.authorCommission,
        };
        let init: StateInit = self.getTournamentInit(initData);
        let address: Address = contractAddress(init);

        nativeReserve(myBalance() - msgValue, ReserveExact);

        emit(TournamentInitCalled{tournament: address, initData}.toCell());

        send(
            SendParameters{
                to: address,
                value: 0,
                mode: SendRemainingBalance,
                code: init.code,
                data: init.data,
                body: Deploy{cashbackAddress: sender()}.toCell(),
            }
        );
    }

    fun getTournamentInit(initData: TournamentInitData): StateInit {
        if (
            initData.config.jettonMinterAddress == null ||
            initData.config.jettonWalletCode == null ||
            initData.config.jettonImplementationVersion == null
        ) {
            return initOf NativeTournament(initData);
        }
        return initOf JettonTournament(initData);
    }

    get fun tournamentAddressOf(initData: TournamentInitData): Address {
        return contractAddress(self.getTournamentInit(initData));
    }

    get fun tournamentAddressOfUnflattenedJetton(
        id: String,
        gameId: String,
        deadline: Int,
        entryFee: Int,
        rewardDistribution: map<Int as uint16, Int as uint64>,
        leaderboardCapacity: Int,
        jettonMinterAddress: Address,
        jettonWalletCode: Cell,
        jettonImplementationVersion: Int,
        developerTreasury: Address,
        developerCommission: Int,
        author: Address,
        authorCommission: Int,
    ): Address {
        let initData: TournamentInitData = TournamentInitData{
            config: TournamentConfig{
                id: id,
                gameId: gameId,
                deadline: deadline,
                entryFee: entryFee,
                rewardDistributionPercents:  SimpleIntArray{
                    m: rewardDistribution,
                    length: leaderboardCapacity
                },
                jettonMinterAddress: jettonMinterAddress,
                jettonWalletCode: jettonWalletCode,
                jettonImplementationVersion: jettonImplementationVersion,
            },
            matchAuthority: self.matchAuthority,
            elympicsTreasury: self.elympicsTreasury,
            elympicsCommission: self.elympicsCommission,
            developerTreasury: developerTreasury,
            developerCommission: developerCommission,
            author: author,
            authorCommission: authorCommission,
        };
        return contractAddress(self.getTournamentInit(initData));
    }

    get fun tournamentAddressOfUnflattened(
        id: String,
        gameId: String,
        deadline: Int,
        entryFee: Int,
        rewardDistribution: map<Int as uint16, Int as uint64>,
        leaderboardCapacity: Int,
        developerTreasury: Address,
        developerCommission: Int,
        author: Address,
        authorCommission: Int,
    ): Address {
        let initData: TournamentInitData = TournamentInitData{
            config: TournamentConfig{
                id: id,
                gameId: gameId,
                deadline: deadline,
                entryFee: entryFee,
                rewardDistributionPercents:  SimpleIntArray{
                    m: rewardDistribution,
                    length: leaderboardCapacity
                },
                jettonMinterAddress: null,
                jettonWalletCode: null,
                jettonImplementationVersion: null,
            },
            matchAuthority: self.matchAuthority,
            elympicsTreasury: self.elympicsTreasury,
            elympicsCommission: self.elympicsCommission,
            developerTreasury: developerTreasury,
            developerCommission: developerCommission,
            author: author,
            authorCommission: authorCommission,
        };
        return contractAddress(self.getTournamentInit(initData));
    }
}
