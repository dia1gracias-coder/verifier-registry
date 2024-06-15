import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

struct Bet {
    address: Address;
    amount: Int as uint32;
}

struct Data {
    total_bet_a: Int as uint32;
    total_bet_b: Int as uint32;
    odds_a: Int as uint32;
    odds_b: Int as uint32;
    bets_a: map<Address, Int>;
    bets_b: map<Address, Int>;
    finalized: Bool;
    outcome_a_wins: Bool;
}

message Finalize {
    outcome_a_wins: Bool;
}

message PayoutBatch {
    startIndex: Int;
    batchSize: Int;
}

contract TestContract with Deployable, Ownable, Stoppable {
    owner: Address;
    stopped: Bool;
    data: Data;

    init() {
        self.owner = sender();
        self.stopped = false;
        self.data = Data{
            total_bet_a: 0,
            total_bet_b: 0,
            odds_a: 1000,
            odds_b: 1000,
            bets_a: emptyMap(),
            bets_b: emptyMap(),
            finalized: false,
            outcome_a_wins: false
        };
    }

    receive("1") {
        require(!self.data.finalized, "Betting is over");
        let bet_amount: Int = context().value;
        self.handle_bet(true, bet_amount);
        dump("Bet Received!"); 
    }

    receive("2") {
        require(!self.data.finalized, "Betting is over");
        let bet_amount: Int = context().value;
        self.handle_bet(false, bet_amount);
        dump("Bet Received!");  
    }

    fun handle_bet(bet_on_a: Bool, bet_amount: Int) {
        require(!self.data.finalized, "Betting is over");

        let sender_address: Address = sender();

        if (bet_on_a) {
            self.data.total_bet_a += bet_amount;
            let current_bet: Int? = self.data.bets_a.get(sender_address);
            let final_bet: Int = current_bet != null ? current_bet!! + bet_amount : bet_amount;
            self.data.bets_a.set(sender_address, final_bet);
            dump("Bet registered!"); 
        } else {
            self.data.total_bet_b += bet_amount;
            let current_bet_b: Int? = self.data.bets_b.get(sender_address);
            let final_bet_b: Int = current_bet_b != null ? current_bet_b!! + bet_amount : bet_amount;
            self.data.bets_b.set(sender_address, final_bet_b);
            dump("Bet registered!"); 
        }

        // Calculate odds
         if (self.data.total_bet_a > 0) {
            self.data.odds_a = 1000 + ((self.data.total_bet_b * 1000) / self.data.total_bet_a);
        } else {
            self.data.odds_a = 1000; // Default odds if no bets on B
        }

        if (self.data.total_bet_b > 0) {
            self.data.odds_b = 1000 + ((self.data.total_bet_a * 1000) / self.data.total_bet_b);
        } else {
            self.data.odds_b = 1000; // Default odds if no bets on A
        }
    }

    receive(msg: String) { 
        require(sender() == self.owner, "Only the owner can finalize");
        if (msg == "finalize_true") {
            self.data.outcome_a_wins = true;
            self.data.finalized = true;
        } else if (msg == "PayA") {
            self.data.finalized = true;
            self.data.outcome_a_wins = true;
            self.payoutA(self.data.bets_a, self.data.odds_a);
            dump("Outcome A wins"); 
        } else if (msg == "PayB") {
            self.data.finalized = true;
            self.data.outcome_a_wins = false;
            self.payoutB(self.data.bets_b, self.data.odds_b);
            dump("Outcome B wins"); 
        } else {
            dump("Invalid message received");
        }
    }

   fun payoutA(bets: map<Address, Int>, odds: Int) {
    let i: Int = 0;
    foreach (address, bet_amount in bets) {
        if (bet_amount != null) {
            let payout_amount: Int = bet_amount * odds;
            send(SendParameters{
                to: address,
                value: payout_amount,
                mode: SendRemainingValue + SendIgnoreErrors
            });
        }
        i += 1;
    }
    bets = emptyMap();
}

   fun payoutB(bets: map<Address, Int>, odds: Int) {
    let i: Int = 0;
    foreach (address, bet_amount in bets) {
        if (bet_amount != null) {
            let payout_amount: Int = bet_amount * odds;
            send(SendParameters{
                to: address,
                value: payout_amount,
                mode: SendRemainingValue + SendIgnoreErrors
            });
        }
        i += 1;
    }
    bets = emptyMap();
}
 


    get fun isFinalized(): Bool {
        return self.data.finalized;
    }


    get fun getBetAmountA(address: Address): Int {
    let betAmount: Int? = self.data.bets_a.get(address);
    return betAmount != null ? betAmount!! : 0;
}

    get fun getBetAmountB(address: Address): Int {
    let betAmount: Int? = self.data.bets_b.get(address);
    return betAmount != null ? betAmount!! : 0;
}


    get fun getoddA(): Int {
        return self.data.odds_a;
    }

    get fun getoddB(): Int {
        return self.data.odds_b;
    }

    get fun outcome(): Bool {
        return self.data.outcome_a_wins;
    }

    get fun getBetsA(): map<Address, Int> {
        return (self.data.bets_a);
    }

     get fun getBetsB(): map<Address, Int> {
        return (self.data.bets_b);
    }

}

