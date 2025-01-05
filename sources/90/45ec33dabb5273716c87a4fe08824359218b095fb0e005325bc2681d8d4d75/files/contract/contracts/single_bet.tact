import "@stdlib/deploy";


// BetArray is a struct that represents an array of bets
struct BetArray {
    m: map<Int as uint16, Bet>;
    length: Int = 0;
}

const MaxArraySize: Int = 50000; 

extends mutates fun append(self: BetArray, item: Bet) {
    require(self.length + 1 <= MaxArraySize, "No space in the array left for new items!");

    self.m.set(self.length, item);
    self.length += 1;
}

extends mutates fun insert(self: BetArray, item: Bet, idx: Int) {
    require(self.length + 1 <= MaxArraySize, "No space in the array left for new items!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    let i: Int = self.length;
    while (i > idx) {
        self.m.set(i, self.m.get(i - 1)!!);
        i -= 1;
    }

    self.m.set(idx, item); 
    self.length += 1;
}

extends fun getIdx(self: BetArray, idx: Int): Bet {
    require(self.length > 0, "No items in the array!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    return self.m.get(idx)!!;
}

extends fun getLast(self: BetArray): Bet {
    require(self.length > 0, "No items in the array!");

    return self.m.get(self.length - 1)!!;
}

extends mutates fun deleteIdx(self: BetArray, idx: Int): Bet {
    require(self.length > 0, "No items in the array to delete!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    let memorized: Bet = self.m.get(idx)!!;

    let i: Int = idx;
    while (i + 1 < self.length) {
        self.m.set(i, self.m.get(i + 1)!!);
        i += 1;
    }

    self.m.set(self.length - 1, null);
    self.length -= 1;

    return memorized;
}

extends fun deleteLast(self: BetArray): Bet {
    require(self.length > 0, "No items in the array!");

    let lastItem: Bet = self.m.get(self.length - 1)!!;
    self.m.set(self.length - 1, null);
    self.length -= 1;

    return lastItem;
}

extends mutates fun deleteAll(self: BetArray) {
    self.m = emptyMap();
    self.length = 0;
}

fun emptyArray(): BetArray {
    return BetArray{m: emptyMap(), length: 0};
}

message Bet {
    user: Address;
    amount: Int as coins;
    coef: Int as uint32;
    result: Bool;
}

message EventBet {
    eventId: Int as uint32;
    bet: Bet;
}

message ResolveBet {
    eventId: Int as uint32; 
    result: Bool;
}

message RevokeBet {
    eventId: Int as uint32;
    user: Address;
}

message Withdraw {
    amount: Int as coins;
}

contract SingleBet with Deployable {
    const minTonForStorage:  Int = ton("0.01");

    nonce: Int = 0;
    owner: Address;

    activeBets: map<Int as uint64, BetArray>;

    init() {
        self.owner = sender();
        self.activeBets = emptyMap();
    }

    fun onlyOwner() {
        require(sender() == self.owner, "Only owner can call this function");
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun bets(): map<Int as uint64, BetArray> {
        return self.activeBets;
    }

    receive() {

    }

    receive("withdraw all") {
        self.onlyOwner();

        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
        });
    }

    receive("withdraw safe") {
        self.onlyOwner();

        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.minTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    receive(msg: Withdraw) {
        self.onlyOwner();

        require(myBalance() >= msg.amount + self.minTonForStorage, "Not enough balance");

        let amount: Int = msg.amount;
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors,
        });
    }

    receive(eventBet: EventBet) {
        if (self.activeBets.exists(eventBet.eventId)) {
            let betArray = self.activeBets.get(eventBet.eventId)!!;
            betArray.append(eventBet.bet);
            self.activeBets.set(eventBet.eventId, betArray);
        } else {
            let betArray = emptyArray();
            betArray.append(eventBet.bet);
            self.activeBets.set(eventBet.eventId, betArray);
        }
    }

    receive(resolveBet: ResolveBet) {
        if (self.activeBets.exists(resolveBet.eventId)) {
            let betArray: BetArray = self.activeBets.get(resolveBet.eventId)!!;
            
            let i: Int = 0;
            repeat(betArray.length) {
                let bet = betArray.getIdx(i);
                
                if (resolveBet.result == bet.result) {
                    let winAmount: Int = (bet.amount * bet.coef) / 1000;

                    require(myBalance() >= winAmount + self.minTonForStorage, "Not enough balance to pay the win amount");

                    send(SendParameters{
                        to: bet.user,
                        bounce: true,
                        value: winAmount,
                        mode: SendRemainingValue + SendIgnoreErrors,
                    })
                } else {
                    require(myBalance() >= bet.amount + self.minTonForStorage, "Not enough balance to pay the win amount");

                    send(SendParameters{
                        to: self.owner,
                        bounce: true,
                        value: bet.amount,
                        mode: SendRemainingValue + SendIgnoreErrors,
                    })
                }

                i += 1;
            }

            self.activeBets.del(resolveBet.eventId);
        }
    }

    receive(revokeBet: RevokeBet) {
        if (self.activeBets.exists(revokeBet.eventId)) {
            let betArray: BetArray = self.activeBets.get(revokeBet.eventId)!!;
            
            let i: Int = 0;
            repeat(betArray.length) {
                let bet = betArray.getIdx(i);

                if (bet.user == revokeBet.user) {
                    require(myBalance() >= bet.amount + self.minTonForStorage, "Not enough balance to pay the win amount");

                    send(SendParameters{
                        to: bet.user,
                        bounce: true,
                        value: bet.amount,
                        mode: SendRemainingValue + SendIgnoreErrors,
                    });

                    let deletedBet: Bet = betArray.deleteIdx(i);
                }

                i += 1;
            }

            self.activeBets.set(revokeBet.eventId, betArray);
        }
    }
}
