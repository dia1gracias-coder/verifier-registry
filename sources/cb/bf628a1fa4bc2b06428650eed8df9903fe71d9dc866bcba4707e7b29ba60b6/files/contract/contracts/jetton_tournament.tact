import "./counter.tact";
import "./jetton_utils.tact";
import "./tournament_base.tact";

// =============== constants ===============

const JETTON_TRANSFER_GAS: Int = 50_000_000;

const REGISTER_USER_FEE: Int = 55_000_000;

const JETTON_TRANSFER_OP: Int = 0x0f8a7ea5;

// =============== messages ===============

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

// =============== contract ===============

fun validateJettonImplementationVersion(version: Int): Bool {
    return version == 1 || version == 2;
}

contract JettonTournament with TournamentBase {
    id: String;
    gameId: String;
    leaderboardCapacity: Int as uint8;
    deadline: Int as uint64;

    entryFee: Int as uint64;
    jettonWallet: Address;

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

    nextQueryId: Int as uint256 = 0;

    init(initData: TournamentInitData) {
        let config: TournamentConfig = initData.config;
        require(
            validateJettonImplementationVersion(config.jettonImplementationVersion!!),
            "Invalid Jetton implementation version"
        );

        let leaderboardCapacity: Int = initData.config.rewardDistributionPercents.length;

        self.id = config.id;
        self.gameId = config.gameId;
        self.leaderboardCapacity = leaderboardCapacity;
        self.deadline = config.deadline;

        self.entryFee = config.entryFee;
        self.jettonWallet = calculateUserJettonWalletAddress(
            myAddress(),
            config.jettonMinterAddress!!,
            config.jettonWalletCode!!,
            config.jettonImplementationVersion!!
        );

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

    receive(msg: JettonTransferNotification) {
        require(sender() == self.jettonWallet, "Unauthorized caller");

        if (now() >= self.deadline) {
            self.sendJettonBack(msg.sender, msg.amount, "Registration failed: deadline has passed");
            return;
        }

        let entries: Int = msg.amount / self.entryFee;
        if (entries == 0) {
            self.sendJettonBack(msg.sender, msg.amount, "Registration failed: insufficient Jettons");
            return;
        }

        let jettonsRemainder: Int = msg.amount % self.entryFee;
        let fees: Int = REGISTER_USER_FEE + (jettonsRemainder > 0 ? JETTON_TRANSFER_GAS : 0);
        if (context().value < fees) {
            self.sendJettonBack(msg.sender, msg.amount, "Registration failed: insufficient TON");
            return;
        }

        self.unsettledUserEntriesCounter.increaseValue(msg.sender, entries);
        self.lockedAmount += entries * self.entryFee;
        emit(EntryFeePaid{userAddress: msg.sender, entries: entries}.toCell());

        if (jettonsRemainder > 0) {
            self.sendJettonTransfer(msg.sender, jettonsRemainder, msg.sender, JETTON_TRANSFER_GAS, SendPayGasSeparately);
        }

        self.reserveTon();
        self.sendRemainingBalance(msg.sender);
    }

    override inline fun sendCurrencyTransfer(to: Address, value: Int) {
        self.sendJettonTransfer(to, value, self.matchAuthority, JETTON_TRANSFER_GAS, SendPayGasSeparately);
    }

    override inline fun reserveTon() {
        nativeReserve(self.calculateFutureStorageFees(), ReserveExact);
    }

    inline fun sendJettonBack(to: Address, amount: Int, reason: String) {
        self.sendJettonTransferWithPayload(to, amount, to, 0, SendRemainingValue, 1, beginCell().storeUint(0, 32).storeSlice(reason.asSlice()).endCell());
    }

    inline fun sendJettonTransfer(to: Address, amount: Int, cashbackAddress: Address, tonValue: Int, msgMode: Int) {
        self.sendJettonTransferWithPayload(to, amount, cashbackAddress, tonValue, msgMode, 0, null);
    }

    inline fun sendJettonTransferWithPayload(
        to: Address,
        amount: Int,
        cashbackAddress: Address,
        tonValue: Int,
        msgMode: Int,
        forwardTonAmount: Int,
        forwardPayload: Cell?,
    ) {
        let msgBody: Builder = beginCell()
            .storeUint(JETTON_TRANSFER_OP, 32)
            .storeUint(self.nextQueryId, 64)
            .storeCoins(amount)
            .storeAddress(to)
            .storeAddress(cashbackAddress)
            .storeBool(false)
            .storeCoins(forwardTonAmount);

        if (forwardTonAmount > 0) {
            msgBody = msgBody
                .storeBool(true)
                .storeRef(forwardPayload!!);
        } else {
            msgBody = msgBody.storeBool(false);
        }

        send(
            SendParameters{
                to: self.jettonWallet,
                value: tonValue,
                mode: msgMode,
                body: msgBody.endCell(),
            }
        );
        self.nextQueryId += 1;
    }

    get fun jettonWallet(): Address {
        return self.jettonWallet;
    }

    get fun nextQueryId(): Int {
        return self.nextQueryId;
    }
}
