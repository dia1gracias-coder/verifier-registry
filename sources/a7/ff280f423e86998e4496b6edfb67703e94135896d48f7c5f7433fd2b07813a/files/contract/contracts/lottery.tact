import "@stdlib/deploy";
import "@stdlib/ownable";

struct Lottery {
    winningTickets: map<Int, Int>; 
}

message PlayNewLottery {
    lotteryId: Int;
    totalNumberOfTickets: Int;
    numberOfWinningTickets: Int;
}

contract WinLotteryManager with Deployable, Ownable {
    id: Int as uint32;
    lotteries: map<Int, Lottery>;
    owner: Address;

    init(id: Int) {
        self.id = id;
        self.owner = sender();
        self.lotteries = emptyMap();
    }

    receive(msg: PlayNewLottery) {
        require(self.owner == sender(), "Only the owner can increase the value!");
        let usedTicketNumbers: map<Int, Int> = emptyMap();
        let sequence: map<Int, Int> = emptyMap();
        let winningTicketNumber = random(1, msg.totalNumberOfTickets);

        sequence.set(1, winningTicketNumber);
        usedTicketNumbers.set(winningTicketNumber, winningTicketNumber);
        let createdTickets: Int = 1;
        while (createdTickets < msg.numberOfWinningTickets) {
            let ticketNumber = random(1, msg.totalNumberOfTickets);
            if (usedTicketNumbers.get(ticketNumber) == null) {
                sequence.set(createdTickets + 1, ticketNumber);
                usedTicketNumbers.set(ticketNumber, ticketNumber);
                createdTickets += 1;
            }
        }
        

        self.lotteries.set(msg.lotteryId, Lottery{ winningTickets: sequence });
        // Notify the caller that the receiver was executed and forward remaining value back
        self.notify("Cashback".asComment());
    }

    get fun lotteryResults(lotteryId: Int): map<Int, Int> {
        let lottery: Lottery? = self.lotteries.get(lotteryId);
        if (lottery == null) {
            return emptyMap();
        }
        return lottery!!.winningTickets;
    }

    get fun id(): Int {
        return self.id;
    }
}
