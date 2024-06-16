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
    insufficient_balance: Bool;
    total_payouts: map<Address, Int>;

}

message Finalize {
    outcome_a_wins: Bool;
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
            total_payouts: emptyMap(),
            finalized: false,
            outcome_a_wins: false,
            insufficient_balance: false
            
        };
    }

    receive("1") {
    require(!self.data.finalized, "Betting is over");
    let bet_amount: Int = context().value;
    let sender_address: Address = sender();
    self.handle_bet(true, bet_amount);
    }

    receive("2") {
    require(!self.data.finalized, "Betting is over");
    let bet_amount: Int = context().value;
    let sender_address: Address = sender();
    self.handle_bet(false, bet_amount);
    }



   fun handle_bet(bet_on_a: Bool, bet_amount: Int) {
        require(!self.data.finalized, "Betting is over");

        let sender_address: Address = sender();

        if (bet_on_a) {
            self.data.total_bet_a += bet_amount;
            let current_bet: Int? = self.data.bets_a.get(sender_address);
            let final_bet: Int = current_bet != null ? current_bet!! + bet_amount : bet_amount;
            self.data.bets_a.set(sender_address, final_bet);
            dump(self.data.total_bet_a); // Debugging total_bet_a

        } else {
            self.data.total_bet_b += bet_amount;
            let current_bet_b: Int? = self.data.bets_b.get(sender_address);
            let final_bet_b: Int = current_bet_b != null ? current_bet_b!! + bet_amount : bet_amount;
            self.data.bets_b.set(sender_address, final_bet_b);
            dump(self.data.total_bet_b); // Debugging total_bet_b
        }

        // Calculate odds
        if (self.data.total_bet_a > 0) {
            self.data.odds_a = (self.data.total_bet_b * 1000) / self.data.total_bet_a;
        } else {
            self.data.odds_a = 1000; // Default odds if no bets on B
        }
        dump(self.data.odds_a); // Debugging odds_a

        if (self.data.total_bet_b > 0) {
            self.data.odds_b = (self.data.total_bet_a * 1000) / self.data.total_bet_b;
        } else {
            self.data.odds_b = 1000; // Default odds if no bets on A
        }
        dump(self.data.odds_b); // Debugging odds_b
    }

    receive(msg: Finalize) {
    require(sender() == self.owner, "Only the owner can finalize");
    self.data.finalized = true;
    self.data.outcome_a_wins = msg.outcome_a_wins;
    dump(self.data.outcome_a_wins); // Debugging outcome_a_wins
}

    receive(msg: String) { 
    require(sender() == self.owner, "Only the owner can finalize");
    if (msg == "finalize_true") {
        self.data.outcome_a_wins = true;
        self.data.finalized = true;
    } 
    else if (msg == "PayA") {
    self.data.outcome_a_wins = true;
    self.data.finalized = true;
    self.payout(self.data.bets_a, self.data.odds_a, self.data.total_bet_a);
    }

    else if (msg == "PayB") {
        self.data.finalized = true;
        self.payout(self.data.bets_b, self.data.odds_b, self.data.total_bet_b);
    }
    else {
        dump("Invalid message received");
    }
    }  


   fun payout(bets: map<Address, Int>, odds: Int, total_bet: Int) {
    let total_payout: Int = self.calculate_total_payout(bets, odds);
    let contract_balance: Int = myBalance();
    
    if (contract_balance < total_payout) {
        self.data.insufficient_balance = true;
        return;
    }
    
    let payout_map: map<Address, Int> = emptyMap();
    
    // total payout for each bettor
    foreach (address, bet_amount in bets) {
        if (bet_amount != null) {
            let payout_amount: Int = (bet_amount * odds) / 1000 + bet_amount;
            payout_map.set(address, payout_amount);
        }
    }
    
    // remaining balance calc
    let remaining_balance: Int = myBalance();
    foreach (address, bet_amount in bets) {
        if (bet_amount != null) {
            let additional_payout: Int = (remaining_balance * bet_amount) / total_bet;
            let current_payout: Int? = payout_map.get(address);
            if (current_payout != null) {
                payout_map.set(address, current_payout!! + additional_payout);
            }
        }
    }
    
    // Send
    foreach (address, payout_amount in payout_map) {
        if (payout_amount != null) {
            send(SendParameters{
                to: address,
                value: payout_amount,
                mode: SendRemainingValue + SendIgnoreErrors
            });
        }
    }
    
    // Clear the bets
    if (total_bet == self.data.total_bet_a) {
        self.data.bets_a = emptyMap();
    } else {
        self.data.bets_b = emptyMap();
    }
}

  receive("CalculateA") {
    require(sender() == self.owner, "Only for owner");
    let total_payout_a: Int = self.calculate_total_payout(self.data.bets_a, self.data.odds_a);
    dump(total_payout_a); // Debugging total payout for bets_a
}

    receive("CalculateB") {
    require(sender() == self.owner, "Only for owner");
    let total_payout_a: Int = self.calculate_total_payout(self.data.bets_a, self.data.odds_a);
    dump(total_payout_a); // Debugging total payout for bets_a
}

    fun calculate_total_payout(bets: map<Address, Int>, odds: Int): Int {
    let total_payout: Int = 0;
    foreach (address, bet_amount in bets) {
        if (bet_amount != null) {
            total_payout += (bet_amount * odds) / 1000 + bet_amount;
        }
    }
    return total_payout;
}

    get fun isInsufficientBalance(): Bool {
    return self.data.insufficient_balance;
    }

 
    get fun getTotalBetA(): Int {
        return self.data.total_bet_a;
    }

    get fun getTotalBetB(): Int {
        return self.data.total_bet_b;
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

}