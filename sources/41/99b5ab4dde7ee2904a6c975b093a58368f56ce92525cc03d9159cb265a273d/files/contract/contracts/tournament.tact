import "./leaderboard.tact";
import "./nonce_handler.tact";

// =============== constants ===============

const SHARE_PRECISION: Int = 1_000_000_000;

const ONE_HOUR_IN_SECONDS: Int = 24 * 60 * 60;

const INIT_FEE_PER_PLAYER: Int = 500_000;
const CREATION_FEE_PER_SECOND: Int = 15;

const REGISTER_USER_FEE_BASE: Int = 12_000_000;
const REGISTER_USER_FEE_PER_UNIQUE_PLAYER: Int = 100_000;

const SETTLE_MATCH_FEE_BASE: Int = 15_000_000;
const SETTLE_MATCH_FEE_PER_LEADERBOARD_PLACE: Int = 4_500_000;

const SELFDESTRUCT_PAYLOAD: Int = 5_000_000;

// =============== messages ===============

message RegisterUser {
    userAddress: Address;
    nonce: Int as uint64;
}

message SettleMatch {
    userAddress: Address;
    result: Int as int64;
    nonce: Int as uint64; // same nonce as in PoE to emit event and process on backend
}

message Conclude {}

// =============== events ===============

message EntryFeePaid {
    userAddress: Address;
    nonce: Int as uint64;
}

message MatchSettled {
    userAddress: Address;
    result: Int as int64;
    nonce: Int as uint64;
}

message PaidOutWinners {
    rewardedPlayers: map<Address, Int as uint64>;
}

message UserReimbursed {
    userAddress: Address;
    unsettledEntries: Int as uint16;
}

// =============== structures ===============

// Assumes `m` keys contain only numbers {0, ..., length - 1}
struct SimpleIntArray {
    m: map<Int as uint16, Int as uint64>;
    length: Int as uint16;
}

struct TournamentInitData {
    id: Int as uint64;
    leaderboardCapacity: Int as uint8;
    deadline: Int as uint64;
    matchAuthority: Address;
    entryFee: Int as uint64;
    elympicsTreasury: Address;
    elympicsCommission: Int as uint32;
    rewardDistributionPercents: SimpleIntArray;
}

contract Tournament with Leaderboard {
    id: Int as uint64;
    leaderboardCapacity: Int as uint8;
    deadline: Int as uint64;
    matchAuthority: Address;
    entryFee: Int as uint64;
    elympicsTreasury: Address;
    elympicsCommission: Int as uint32;
    rewardDistributionPercents: SimpleIntArray;

    processedFirstCall: Bool = false;
    reservedAmount: Int as uint64 = 0;
    settledAmount: Int as uint64 = 0;

    leaderboard: MapArray;
    registrationNonceHandler: NonceHandler;
    settlementNonceHandler: NonceHandler;

    init(initData: TournamentInitData) {
        require(initData.deadline > now(), "Invalid init data");
        require(initData.elympicsCommission < SHARE_PRECISION, "Invalid init data");

        let i: Int = 0;
        let sum: Int = 0;
        repeat (initData.rewardDistributionPercents.length) {
            sum += initData.rewardDistributionPercents.m.get(i)!!;
            i += 1;
        }
        require(sum == SHARE_PRECISION, "Invalid init data");

        self.id = initData.id;
        self.leaderboardCapacity = initData.leaderboardCapacity;
        self.deadline = initData.deadline;
        self.matchAuthority = initData.matchAuthority;
        self.entryFee = initData.entryFee;
        self.elympicsTreasury = initData.elympicsTreasury;
        self.elympicsCommission = initData.elympicsCommission;
        self.rewardDistributionPercents = initData.rewardDistributionPercents;

        self.leaderboard = emptyArray(initData.leaderboardCapacity);
        self.registrationNonceHandler = newNonceHandler();
        self.settlementNonceHandler = newNonceHandler();
    }

    receive(msg: RegisterUser) {
        require(now() < self.deadline, "Cannot call past deadline");
        require(self.registrationNonceHandler.getNextNonce(msg.userAddress) == msg.nonce, "Invalid nonce");

        let messageValue = context().value;
        let fees: Int = REGISTER_USER_FEE_BASE + (self.registrationNonceHandler.entries * REGISTER_USER_FEE_PER_UNIQUE_PLAYER);
        if (!self.processedFirstCall) {
            // Cover processing rewardDistributionPercents
            fees += self.rewardDistributionPercents.length * INIT_FEE_PER_PLAYER;
            // Cover future storage fees
            fees += (self.deadline - now() + ONE_HOUR_IN_SECONDS) * CREATION_FEE_PER_SECOND;

            self.processedFirstCall = true;
        }
        require(messageValue > self.entryFee + fees, "Insufficient value sent");

        self.registrationNonceHandler.consumeNonce(msg.userAddress);

        self.reservedAmount += self.entryFee;
        nativeReserve(self.reservedAmount, ReserveExact);

        emit(EntryFeePaid{userAddress: msg.userAddress, nonce: msg.nonce}.toCell());

        let cashback: Int = messageValue - self.entryFee - fees;
        send(
            SendParameters{
                to: msg.userAddress,
                value: cashback,
                mode: SendPayGasSeparately,
            }
        );
    }

    receive(msg: SettleMatch) {
        require(now() < self.deadline, "Cannot call past deadline");
        require(sender() == self.matchAuthority, "Unauthorized caller");

        let nextRegistrationNonce = self.registrationNonceHandler.getNextNonce(msg.userAddress);
        let nextSettlementNonce = self.settlementNonceHandler.getNextNonce(msg.userAddress);
        require(nextRegistrationNonce > msg.nonce, "Invalid nonce");
        require(nextSettlementNonce == msg.nonce, "Invalid nonce");

        let computeFees: Int = SETTLE_MATCH_FEE_BASE + (self.leaderboard.length * SETTLE_MATCH_FEE_PER_LEADERBOARD_PLACE);
        require(context().value >= computeFees, "Insufficient value sent");

        self.settlementNonceHandler.consumeNonce(msg.userAddress);

        self.settledAmount += self.entryFee;
        self.processUser(PlayerRecord{userAddress: msg.userAddress, score: msg.result});

        emit(MatchSettled{userAddress: msg.userAddress, result: msg.result, nonce: msg.nonce}.toCell());

        send(
            SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
            }
        );
    }

    receive(msg: Conclude) {
        require(now() >= self.deadline, "Cannot call earlier than deadline");
        require(sender() == self.matchAuthority, "Unauthorized caller");

        // Pay out Elympics commission
        let elympicsCommissionPerEntry: Int = (self.entryFee * self.elympicsCommission) / SHARE_PRECISION;
        let elympicsCommission: Int = (self.reservedAmount * self.elympicsCommission) / SHARE_PRECISION;
        send(
            SendParameters{
                to: self.elympicsTreasury,
                value: elympicsCommission,
                mode: SendPayGasSeparately,
            }
        );

        // Recalculate rewards positional proportions if leaderboard is not full
        let proportionsSum: Int = SHARE_PRECISION;
        if (self.leaderboard.length < self.leaderboard.maxSize) {
            proportionsSum = 0;
            let i: Int = 0;
            repeat(self.leaderboard.length) {
                proportionsSum += self.rewardDistributionPercents.m.get(i)!!;
                i += 1;
            }
        }

        // Pay out winners
        let settledMatchesCount: Int = self.settledAmount / self.entryFee;
        let rewards: Int = self.settledAmount - (settledMatchesCount * elympicsCommissionPerEntry);

        let i: Int = 0;
        let rewardedPlayers: map<Address, Int as uint64> = emptyMap();
        repeat(self.leaderboard.length) {
            let payout: Int = (rewards * self.rewardDistributionPercents.m.get(i)!!) / proportionsSum;
            rewardedPlayers.set(self.leaderboard.get(i).userAddress, payout);

            send(
                SendParameters{
                    to: self.leaderboard.get(i).userAddress,
                    value: payout,
                    mode: SendPayGasSeparately,
                }
            );

            i += 1;
        }
        emit(PaidOutWinners{rewardedPlayers}.toCell());

        // Reimburse users who registered, but didn't play
        let reimbursementPerUnusedNonce: Int = self.entryFee - elympicsCommissionPerEntry;
        foreach (userAddress, nextRegistrationNonce in self.registrationNonceHandler.m) {
            let nextSettlementNonce: Int? = self.settlementNonceHandler.m.get(userAddress);
            if (nextSettlementNonce == null) {
                nextSettlementNonce = 0;
            }

            let unusedNonces: Int = nextRegistrationNonce - nextSettlementNonce!!;
            if (unusedNonces > 0) {
                let reimbursement: Int = unusedNonces * reimbursementPerUnusedNonce;
                send(
                    SendParameters{
                        to: userAddress,
                        value: reimbursement,
                        mode: SendPayGasSeparately,
                    }
                );
                emit(UserReimbursed{userAddress, unsettledEntries: unusedNonces}.toCell());
            }
        }

        // Send all remaining balance to Match Authority and self-destruct
        send(
            SendParameters{
                to: self.matchAuthority,
                value: 0,
                mode: SendRemainingBalance | SendDestroyIfZero,
            }
        );
    }

    get fun id(): Int {
        return self.id;
    }

    get fun leaderboardCapacity(): Int {
        return self.leaderboardCapacity;
    }

    get fun entryFee(): Int {
        return self.entryFee;
    }

    get fun deadline(): Int {
        return self.deadline;
    }

    get fun reservedAmount(): Int {
        return self.reservedAmount;
    }

    get fun settledAmount(): Int {
        return self.settledAmount;
    }

    get fun leaderboard(): MapArray {
        return self.leaderboard;
    }
}
