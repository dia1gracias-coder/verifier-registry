import "@stdlib/deploy";

// Constants
const SECONDS_PER_HOUR: Int = 3600;
const TICKET_DIGITS: Int = 5;
const MAX_TICKET_NUMBER: Int = 99999;

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

message PoolCreated {
    poolId: Int;
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

message RoundCreated {
    roundId: Int;
    poolId: Int;
    ticketPrice: Int as uint32;
    startTime: Int;
    endTime: Int;
}

message BuyTicket {
    poolId: Int;
    roundId: Int;
    quantity: Int;
}

// Main contract
contract Lottery with Deployable {
    owner: Address;
    tokenPool: Int ;
    currentRoundId: Int;
    currentPoolId: Int;
    rounds: map<Int, RoundConfig>;
    winningNumbers: map<Int,Int>;
    pools: map<Int, Pool>;
    nextPoolId: Int;
    tokenCost:Int as uint256= ton("1");
    usersTicket: map<Address,TicketPayoutResponse>;
    ticketsUser: map<Int,Ticket>;
    ticketsIndex: map<Int,Int>;
    ticketArrayLength:Int=0;
    balance: Int as uint256 =0;


    init() {
        self.owner = sender();
        self.tokenPool = 0;
        self.currentRoundId = 0;
        self.currentPoolId = 0;
        self.nextPoolId = 1;
    }

    // ----------------- Admin functions ----------------- //

    fun createPool(initialRounds: Int, config: RoundConfig) {
        require(sender() == self.owner, "Only owner can create pool");

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
        repeat (initialRounds) {
            let roundConfig: RoundConfig = RoundConfig{
                roundId: index,
                poolId: poolId,
                ticketPrice: config.ticketPrice,
                startTime: config.startTime + (index - 1) * SECONDS_PER_HOUR * 24, // Mỗi vòng kéo dài 1 ngày
                endTime: config.startTime + index * SECONDS_PER_HOUR * 24,
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

    // TODO
    fun addRound(config: RoundConfig) {
    require(sender() == self.owner, "Only owner can add rounds");
    // Implementation for adding a new round
    }

    // ---------------- User functions ---------------- //
    fun asciiToChar(ascii: Int): String {
        if (ascii >= 48 && ascii <= 57) {
            // Chuyển đổi số (0-9)
            return (ascii - 48).toString();
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
            let isDigit: Bool = random(0, 1) == 0;
            let randomInt: Int = 0;
            if (isDigit) {
                randomInt = random(48, 57);
            } else {
                randomInt = random(65, 90);
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
            let rs: RandomTicketResponse = self.generateRandomASCIIString(5);
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
        let pool: Pool = self.pools.get(poolId)!!;
        require(pool.active, "Pool is not active");

        let round: RoundConfig = pool.rounds.get(roundId)!!;
        require(round.active, "Round is not active");
        require(now() >= round.startTime && now() < round.endTime, "Round is not open for ticket purchases");

        require(quantity > 0, "Quantity must be positive");

        let user: Address = sender();
        let totalCost: Int = round.ticketPrice * quantity;

        require(context().value >= totalCost, "Insufficient funds sent");

        // gen random ticket code
        self.createTicket(user, quantity);
        self.balance += totalCost;

        // Send any excess funds back to the user
        if (context().value > totalCost) {
            send(SendParameters{
                to: user,
                value: context().value - totalCost,
                mode: SendIgnoreErrors
            });
        }
    }

    fun clear() {
        self.usersTicket = emptyMap();
        self.ticketsUser = emptyMap();
        self.ticketsIndex = emptyMap();
        self.ticketArrayLength = 0;
        self.balance = 0;
    }

    fun claimPrize(roundId: Int) {
    // Implementation for claiming prizes
    }

    // Internal functions

    fun drawWinningNumbers(roundId: Int) {
    // Implementation for drawing winning numbers
    }

    fun calculatePrizes(roundId: Int) {
    // Implementation for calculating and distributing prizes
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

    // Getter functions

    get fun owner(): Address {
        return self.owner;
    }

    get fun currentPool(): Pool {
        return self.pools.get(self.currentPoolId)!!;
    }

    get fun usersTicket(user: Address): TicketPayoutResponse? {
        return self.usersTicket.get(user)!!;
    }

    get fun currentRound(): RoundConfig? {
        return self.rounds.get(self.currentRoundId)!!;
    }

    get fun roundConfig(roundId: Int): RoundConfig? {
        return self.rounds.get(roundId);
    }

    get fun winningNumbers(roundId: Int): Int? {
        return self.winningNumbers.get(roundId);
    }
}
