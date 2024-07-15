import "@stdlib/deploy";

struct Ticket {
    owner: Address;
    winningAmount: Int = 0;
    claimed: Bool = false;
}

struct Round {
    status: Int;
    startTime: Int;
    endTime: Int = 0;
    maximumTicketId: Int;

    tickets: map<Int, Ticket> = emptyMap();
    winnerTickets: map<Int, Int> = emptyMap();
    rewardsDistribution: map<Int, Int> = emptyMap();
    numberOfWinnerTickets: Int = 0;
}

const StatusOpen: Int = 0;
const StatusFinish: Int = 1;
const StatusClaimable: Int = 2;

message StartRound {
    roundId: Int;
    maximumTicketId: Int;
}

message BuyTicket {
    roundId: Int;
    ticketId: Int;
}

message FinishRound {
    roundId: Int;
}

message ClaimRound {
    roundId: Int;
    rewardsDistribution: map<Int, Int>;
    numberOfWinnerTickets: Int;
}

message ClaimTicket {
    roundId: Int;
    ticketId: Int;
}

contract WormLottery with Deployable {
    const maxNumberTicketsPerBuyOrClaim: Int = 100;
    const maximumNumberOfWinnersPerRound: Int = 500;
    const numberOfRandomNumbersPerRound: Int = 5;

    rounds: map<Int, Round> = emptyMap();

    init() {}

    receive(msg: StartRound) {
        require(self.rounds.get(msg.roundId) == null, "Round is already started.");

        self.rounds.set(msg.roundId, Round{
            status: StatusOpen,
            startTime: now(),
            maximumTicketId: msg.maximumTicketId
        });
    }

    receive(msg: BuyTicket) {
        require(self.rounds.get(msg.roundId) != null, "Round is not valid.");

        let round: Round = self.rounds.get(msg.roundId)!!;
        require(round.status == StatusOpen, "Round status is not open.");

        require(1 <= msg.ticketId && msg.ticketId <= round.maximumTicketId, "Ticket is not available.");
        require(round.tickets.get(msg.ticketId) == null, "Ticket is sold already.");

        round.tickets.set(msg.ticketId, Ticket{
            owner: sender()
        });

        self.rounds.set(msg.roundId, round);
    }

    receive(msg: FinishRound) {
        require(self.rounds.get(msg.roundId) != null, "Round is not valid.");

        let round: Round = self.rounds.get(msg.roundId)!!;
        require(round.status == StatusOpen, "Round status is not open.");

        round.status = StatusFinish;
        round.endTime = now();
        self.rounds.set(msg.roundId, round);
    }

    receive(msg: ClaimRound) {
        require(self.rounds.get(msg.roundId) != null, "Round is not valid.");

        let round: Round = self.rounds.get(msg.roundId)!!;
        require(round.status == StatusFinish, "Round status is not finished.");

        let i: Int = 0;
        let winnerTickets: map<Int, Int> = emptyMap();

        let randomNumber: Int = 0;
        let ticket: Ticket? = null;
        let owner: Address = myAddress();
        let hasWon: Bool = false;

        do {
            randomNumber = random(1, round.maximumTicketId);
            ticket = round.tickets.get(randomNumber);
            if (ticket == null) {
                owner = myAddress();
                hasWon = true;
            } else if (ticket!!.winningAmount == 0) {
                owner = ticket!!.owner;
                hasWon = true;
            } else {
                hasWon = false;
            }

            if (hasWon)  {
                ticket = Ticket{
                    owner: owner,
                    winningAmount: msg.rewardsDistribution.get(i)!!
                };

                round.tickets.set(randomNumber, ticket);
                winnerTickets.set(i, randomNumber);
            }

        } until (i < msg.numberOfWinnerTickets);

        round.rewardsDistribution = msg.rewardsDistribution;
        round.numberOfWinnerTickets = msg.numberOfWinnerTickets;
        round.status = StatusClaimable;
        self.rounds.set(msg.roundId, round);
    }

    receive(msg: ClaimTicket) {
        require(self.rounds.get(msg.roundId) != null, "Round is not valid.");

        let round: Round = self.rounds.get(msg.roundId)!!;
        require(round.status == StatusClaimable, "Round status is not claimable.");

        let ticket: Ticket? = round.tickets.get(msg.ticketId);
        require(ticket != null, "Ticket is not valid.");
        require(ticket!!.owner == sender(), "You are not the owner.");
        require(ticket!!.claimed == false, "Ticket has been claimed.");
        require(ticket!!.winningAmount > 0, "You have not won anything.");
        
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: ticket!!.winningAmount,
            mode: SendRemainingValue + SendIgnoreErrors
        });


        round.tickets.set(msg.ticketId, Ticket{
            owner: sender(),
            winningAmount: ticket!!.winningAmount,
            claimed: true
        });
        self.rounds.set(msg.roundId, round);
    }

    get fun round(roundId: Int): Round {
        require(self.rounds.get(roundId) != null, "Round is not valid.");

        return self.rounds.get(roundId)!!;
    }
}
