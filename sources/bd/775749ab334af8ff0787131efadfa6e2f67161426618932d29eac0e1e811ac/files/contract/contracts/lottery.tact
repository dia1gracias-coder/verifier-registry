import "@stdlib/deploy";
import "@stdlib/ownable";

// Constants
const SECONDS_PER_HOUR: Int = 3600;
const TICKET_DIGITS: Int = 5;
const MAX_TICKET_NUMBER: Int = 99999;

// Main contract
contract Lottery with Deployable, Ownable {
    owner: Address;
    currentRoundId: Int;
    currentPoolId: Int;
    pools: map<Int, Pool>;
    nextPoolId: Int;
    usersTicket: map<Address,TicketPayoutResponse>;
    ticketsUser: map<Int,Ticket>;
    ticketsIndex: map<Int,Int>;
    ticketArrayLength:Int=0;
    rewardSettings: map<Int,Int>;
    result: Int;
    rewardPools: map<Int,Int>;
    publicKey: Int?;
    jettonWalletAddress: Address?;
    isClaim: map<Address, Bool>;

    init() {
        self.owner = sender();
        self.currentRoundId = 1;
        self.currentPoolId = 1;
        self.nextPoolId = 1;
        self.result = 0;
        // Default reward settings
        self.rewardSettings.set(1, 10);
        self.rewardSettings.set(2, 20);
        self.rewardSettings.set(3, 30);
        self.rewardSettings.set(4, 40);
        self.rewardSettings.set(5, 50);
    }

    // =============== Private Methods ============== //

    fun getLength(content: Slice): Int {
        let i: Int = 0;
        let length: Int = 0;
        let needBreak: Bool = false;
        do {
            let char: Int = content.loadUint(8);
            needBreak = char == 0;
            if (!needBreak) {
                i = i + 8;
                length = length + 1;
            }
        } until (needBreak);
        require(i != 0, "Invalid content");
        return length;
    }


    fun createPool(initialRounds: Int, config: RoundConfig) {
        self.requireOwner();

        let poolId: Int = self.nextPoolId;
        self.nextPoolId += 1;

        let pool: Pool = Pool{
            poolId: poolId,
            creator: sender(),
            rounds: emptyMap(),
            startTime: config.startTime,
            endTime: config.endTime,
            active: true
        };

        let index: Int = 1;
        self.currentRoundId = index;
        repeat (initialRounds) {
            let startTime: Int = config.startTime + (index - 1) * SECONDS_PER_HOUR * 24;
            let endRoundTime: Int = config.startTime + index * SECONDS_PER_HOUR * 24;
            let roundConfig: RoundConfig = RoundConfig{
                roundId: index,
                poolId: poolId,
                ticketPrice: config.ticketPrice,
                startTime: startTime,
                endTime: config.endTime < endRoundTime ? config.endTime : endRoundTime,
                active: true
            };
            pool.rounds.set(index, roundConfig);
            index += 1;
        }
        self.pools.set(poolId, pool);
        self.currentPoolId = poolId;

        emit(PoolCreatedEvent{
            poolId: poolId,
            ticketPrice: config.ticketPrice,
            initialRounds: initialRounds,
            startTime: config.startTime,
            endTime: config.endTime,
            active: true,
            creator: sender()
        }.toCell());
    }

    fun rewardSettings(match:Int, percent: Int) {
        self.requireOwner();
        require(match >= 1 && match <= TICKET_DIGITS, "Invalid match number");
        require(percent >= 0 && percent <= 100, "Invalid reward percentage");
        self.rewardSettings.set(match, percent);
    }

    // ---------------- User functions ---------------- //
    fun asciiToChar(ascii: Int): String {
        if (ascii >= 48 && ascii <= 57) {
            // Chuyển đổi số (0-9)
            // return (ascii - 48).toString()
            return ascii.toString();
        } else if (ascii >= 65 && ascii <= 90) {
            // Chuyển đổi chữ cái in hoa (A-Z)
            return ascii.toString();
        } else {
            return "";
        }
    }
    // Function to generate a random ASCII string
    fun generateRandomASCIIString(length: Int): RandomTicketResponse {
        let result: StringBuilder = beginString();
        let asciiNumber: Int = 0;
        // ASCII range (48-57 for numbers, 65-90 for upper letters)
        repeat(length) {
            let isDigit: Bool = random(0, 2) == 0;
            let randomInt: Int = 0;
            if (isDigit) {
                randomInt = random(48, 58); // [48-58)
            } else {
                randomInt = random(65, 91); // [65-91)
            }
            asciiNumber = asciiNumber * 100 + randomInt;
            result.append(self.asciiToChar(randomInt));
        }
        return RandomTicketResponse{
            ASCIINumber: asciiNumber,
            ticket: result.toString()
        };
    }

    fun convertTicketNumberToString(ticketNumber: Int): String {
        let ticketNumberTmp = ticketNumber;
        let result: StringBuilder = beginString();
        let base: Int = pow(100, TICKET_DIGITS);
        while(ticketNumberTmp > 0) {
            let asciiChar = ticketNumberTmp / base;
            if (asciiChar >= 48 && asciiChar <= 57) || (asciiChar >= 65 && asciiChar <= 90) {
                result.append(self.asciiToChar(asciiChar));
            }
            ticketNumberTmp = ticketNumberTmp % base;
        }
        return result.toString();
    }

    fun convertStringToTicketNumber(ticket: String): Int? {
        return 0;
    }

    fun createTicket(user: Address, quantity: Int) {
        let sb: StringBuilder = beginString();
        repeat (quantity) {
            let rs: RandomTicketResponse = self.generateRandomASCIIString(TICKET_DIGITS);
            let ticketNumber: Int = rs.ASCIINumber;
            let ticket: String = rs.ticket;
            if(self.usersTicket.get(user)!=null){
                let ticketPayoutResponse: TicketPayoutResponse = self.usersTicket.get(user)!!;
                sb.append(ticket);
                sb.append(",");
                sb.append(ticketPayoutResponse.ticket);
            }else{
                sb.append(ticket);
            }
            let ticketData: Ticket = Ticket {
                ticket,
                ticketNumber,
                owner: user
            };
            self.ticketsUser.set(ticketNumber,ticketData);
            self.ticketArrayLength= self.ticketArrayLength + 1;
            self.ticketsIndex.set(self.ticketArrayLength,ticketNumber);
        }
        self.usersTicket.set(user,TicketPayoutResponse {
            ticket:sb.toString()
        });
    }

    fun buyTicket(poolId: Int, roundId: Int, quantity: Int) {
        let pool: Pool? = self.pools.get(poolId);
        if (pool == null) {
            require(false, "Pool does not exist");
        }
        let poolInfo = pool!!;
        require(poolInfo.active, "Pool is not active");

        let round: RoundConfig? = poolInfo.rounds.get(roundId);
        if (round == null) {
            require(false, "Round does not exist");
        }
        let roundInfo = round!!;
        require(roundInfo.active, "Round is not active");

        require(now() >= roundInfo.startTime && now() < roundInfo.endTime, "Round is not open for ticket purchases");
        require(quantity > 0, "Quantity must be positive");

        let user: Address = sender();
        let totalCost: Int = roundInfo.ticketPrice * quantity;
        require(context().value >= totalCost, "Insufficient funds sent");

        // gen random ticket code
        self.createTicket(user, quantity);

        // Send any excess funds back to the user
        if (context().value > totalCost) {
            send(SendParameters{
                to: user,
                value: context().value - totalCost,
                mode: SendIgnoreErrors
            });
        }

        emit(TicketBoughtEvent{
            roundId: roundId,
            poolId: poolId,
            quantity: quantity,
            buyer: user,
            tickets: self.usersTicket.get(user)!!
        }.toCell());
    }

    // Internal functions

    // Function to calculate the number of matching digits between the result and the ticket
    fun calculateMatching(result: Int, ticket: Int): Int {
        let base: Int = pow(100, TICKET_DIGITS);
        while (result > 0 && ticket > 0) {
            if (result % base == ticket % base) {
                return 1 + self.calculateMatching(result / 100, ticket / 100);
            }
            result /= 100;
            ticket /= 100;
        }
        return 0;
    }

    // Function to calculate the prize for a ticket
    fun drawWinningNumbers(latestTxHash: String?) {
        self.requireOwner();
        require(self.result == 0, "Winning numbers already drawn");
        let round = self.currentRound();
        require(round != null, "Round does not exist");

        let roundInfo = round!!;
        require(now() >= roundInfo.endTime, "Round is still active");

        let rs: RandomTicketResponse = self.generateRandomASCIIString(TICKET_DIGITS);
        let ticketNumber = rs.ASCIINumber;
        self.result = ticketNumber;

        emit(WinningNumbersDrawnEvent{
            poolId: roundInfo.poolId,
            roundId: roundInfo.roundId,
            winningNumber: ticketNumber
        }.toCell());
    }

    fun calculatePrizes(roundId: Int) {
        // Implementation for calculating and distributing prizes

    }

    fun clear() {
        self.usersTicket = emptyMap();
        self.ticketsUser = emptyMap();
        self.ticketsIndex = emptyMap();
        self.ticketArrayLength = 0;
        self.result = 0;
    }

    fun claimPrize(roundId: Int) {
    // Implementation for claiming prizes
    }

    receive(msg: PoolCreated) {
        let initialRounds: Int = msg.initialRounds;
        let ticketPrice: Int = msg.ticketPrice;
        let startTime: Int = msg.startTime;
        let endTime: Int = msg.endTime;

        let config: RoundConfig = RoundConfig{
            roundId: 0, // Sẽ được set trong hàm createPool
            poolId: 0, // Sẽ được set trong hàm createPool
            ticketPrice: ticketPrice,
            startTime: startTime,
            endTime: endTime,
            active: true
        };

        self.createPool(initialRounds, config);
    }

    receive(msg: RewardSetting) {
        let match: Int = msg.match;
        let percent: Int = msg.percent;
        self.rewardSettings(match, percent);
    }

    receive(msg: BuyTicket) {
        let poolId: Int = msg.poolId;
        let roundId: Int = msg.roundId;
        let quantity: Int = msg.quantity;
        self.buyTicket(poolId, roundId, quantity);
    }

    // Getter functions

    get fun currentPool(): Int {
        return self.currentPoolId;
    }

    get fun poolById(poolId: Int): Pool? {
        return self.pools.get(poolId);
    }

    get fun usersTicket(): map<Address,TicketPayoutResponse> {
        return self.usersTicket;
    }

    get fun userTicketByAddress(user: Address): TicketPayoutResponse? {
        return self.usersTicket.get(user);
    }

    get fun currentRound(): RoundConfig? {
        return self.pools.get(self.currentPoolId)!!.rounds.get(self.currentRoundId)!!;
    }

    get fun roundById(poolId: Int, roundId: Int): RoundConfig? {
        return self.pools.get(poolId)!!.rounds.get(roundId)!!;
    }
}

struct Pool {
    poolId: Int as uint32;
    creator: Address;
    rounds: map<Int, RoundConfig>;
    startTime: Int as uint32;
    endTime: Int as uint32;
    active: Bool;
}

// Struct to represent a round configuration
struct RoundConfig {
    roundId: Int as uint32;
    poolId: Int as uint32;
    ticketPrice: Int as coins;
    startTime: Int as uint32;
    endTime: Int as uint32;
    active: Bool;
}

struct TicketPayoutResponse {
    ticket: String;
}

struct RandomTicketResponse {
    ASCIINumber: Int;
    ticket: String;
}

struct Ticket {
    ticket: String;
    ticketNumber: Int;
    owner: Address;
}

struct Winner {
    ticket: String;
    owner: Address;
    prize: Int as coins;
}

message PoolCreated {
    ticketPrice: Int as uint32;
    initialRounds: Int as uint8;
    startTime: Int as uint32;
    endTime: Int as uint32;
    active: Bool;
}

message PoolCreatedEvent {
    poolId: Int;
    ticketPrice: Int as uint32;
    initialRounds: Int as uint8;
    startTime: Int as uint32;
    endTime: Int as uint32;
    active: Bool;
    creator: Address;
}

message WinningNumbersDrawnEvent {
    poolId: Int;
    roundId: Int;
    winningNumber: Int;
}

message RoundCreated {
    roundId: Int;
    poolId: Int;
    ticketPrice: Int as uint32;
    startTime: Int as uint32;
    endTime: Int as uint32;
}

message RewardSetting {
    match: Int;
    percent: Int;
}

message BuyTicket {
    poolId: Int;
    roundId: Int;
    quantity: Int;
}

message TicketBoughtEvent {
    poolId: Int;
    roundId: Int;
    quantity: Int;
    buyer: Address;
    tickets: TicketPayoutResponse
}
