import "@stdlib/deploy";
import "@stdlib/ownable";

const StatusStarted: Int = 0;
const StatusFinished: Int = 1;

const MinTonForStorage: Int = ton("0.2"); //Minimal paid for alive contract

struct LotteryState {
    status: Int;
    players: map<Int, Address>;
    tickets: map<Int, Address>;
    winnerTicket: Int?;
}

struct LotteryMeta {
    ticketPrice: Int;
    comissionAmount: Int;
}

contract LotteryGame with Deployable, OwnableTransferable {
    seqno: Int as uint64; //Unique identifcator of game
    owner: Address;
    comissionAddress: Address;

    meta: LotteryMeta;
    state: LotteryState;

    playersCount: Int = 0;
    ticketsCount: Int = 0;

    init(seqno: Int, comissionAddress: Address, ticketPrice: Int, comissionAmount: Int) {
        self.seqno = seqno;
        self.owner = sender();

        self.comissionAddress = comissionAddress;

        self.state = LotteryState{
            status: StatusStarted,
            players: emptyMap(),
            tickets: emptyMap(),
            winnerTicket: null
        };

        self.meta = LotteryMeta{
            ticketPrice: ticketPrice,
            comissionAmount: comissionAmount
        };
    }

    receive("Buying a tickets") {
        let value: Int = context().value;

        require(self.state.status != StatusFinished, "Game is finished");
        require(value >= self.meta.ticketPrice, "Empty bet is forbidden");
        require(value % self.meta.ticketPrice == 0, "You are not buying a number of belts");

        if (self.isAlreadyParticipate(sender()) == false) {
            self.state.players.set(self.playersCount, sender());
            self.playersCount = self.playersCount + 1;
        }

        let ticketsCount: Int = value / self.meta.ticketPrice;

        // Добавляем тикеты контракта к общим тикетам
        let i: Int = 0;

        while (i < ticketsCount) {
           // Билеты начинаем с единицы 
           self.state.tickets.set(self.ticketsCount + 1, sender());
           self.ticketsCount = self.ticketsCount + 1;
           i = i + 1;
        }
    }

    receive("Finish") {
        require(sender() == self.owner, "Only owner is allowed to finish game");
        require(self.state.status == StatusStarted, "Only started game is allowed to finish");

        nativeRandomizeLt(); //Randomizes the random number generator with the current logical time. 

        let wonAmount: Int = (self.ticketsCount * self.meta.ticketPrice * (100 - self.meta.comissionAmount) / 100);

        let winnerTicket: Int = random(1, self.ticketsCount + 1);

        let winner: Address = self.state.tickets.get(winnerTicket)!!;

        self.state.winnerTicket = winnerTicket;
        self.state.status = StatusFinished;

        send(SendParameters{
            to: winner,
            bounce: false,
            value: wonAmount,
            body: "Congratulation!".asComment(),
            mode: SendIgnoreErrors
        });
    }

    receive("Collect") {
        require(sender() == self.owner, "Only owner is allowed to collect");
        require(self.state.status == StatusFinished, "Only finished game can be collected");

        self.playersCount = 0;
        self.ticketsCount = 0;

        self.state.status = StatusStarted;
        self.state.players = emptyMap();
        self.state.tickets = emptyMap();
        self.state.winnerTicket = null;

        let amount: Int = myBalance() - MinTonForStorage;

        if (amount > 0) {
            send(SendParameters{
                to: self.comissionAddress,
                bounce: false,
                value: amount,
                body: "System comission".asComment(),
                mode: SendIgnoreErrors
            });
        }
    }

    fun isAlreadyParticipate(address: Address): Bool {
        let i: Int = 0;

        while (i < self.playersCount) {
            if (self.state.players.get(i) == address) {
                return true;
            }

            i = i + 1;
        }

        return false;
    }

    get fun state(): LotteryState {
        return self.state;
    }

    get fun meta(): LotteryMeta {
        return self.meta;
    }
}
