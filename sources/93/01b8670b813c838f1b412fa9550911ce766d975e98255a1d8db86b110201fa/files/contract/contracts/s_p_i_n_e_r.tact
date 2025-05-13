
import "@stdlib/deploy";
import "./messages.tact";

contract SPINER with Deployable {
    // Owner of the contract
    owner: Address;

    // Minimum play cost in nanoTON (1 TON = 1e9 nanoTON)
    const play_cost: Int = 1_000_000_000;


    // Constructor
    init() {
        self.owner = sender();
    }
    fun transfer(localuser: Address, amount: Int){


            send(SendParameters{
                to: localuser,
                value: amount, // Adjust as needed
     
            });
    }
    // Entry point for players
    receive(msg: Play) {
        // Ensure the user sent at least 1 TON
        require(msg.amount >= self.play_cost, "Insufficient play cost");

        // Calculate random win amount
        let win_amount: Int = self.calculate_win();

        // Emit event
        emit (SpinResult{user: sender(), win_amount: win_amount}.toCell());

        // Send win amount to the user (if any)
        if (win_amount > 0) {
            self.transfer(sender(), win_amount);
        }
    }

    // Internal function to calculate a random win amount
    fun calculate_win(): Int {
        let rand: Int = randomInt(); // [0, 999999]

        // Define payout ranges with skewed probabilities
        if (rand < 300000) {
            return 20_000_000; // $0.02
        } else if (rand < 550000) {
            return 50_000_000; // $0.05
        } else if (rand < 700000) {
            return 100_000_000; // $0.10
        } else if (rand < 800000) {
            return 250_000_000; // $0.25
        } else if (rand < 880000) {
            return 500_000_000; // $0.50
        } else if (rand < 940000) {
            return 750_000_000; // $0.75
        } else if (rand < 970000) {
            return 1_000_000_000; // $1.00
        } else if (rand < 985000) {
            return 5_000_000_000; // $5.00
        } else if (rand < 989000) {
            return 10_000_000_000; // $10.00
        } else if (rand < 999000) {
            return 50_000_000_000; // $50.00
        } else {
            return 100_000_000_000; // $100.00
        }
    }


    // Only owner can withdraw accumulated profit
    receive("withdraw") {
        require(sender() == self.owner, "Only owner");
        let bal: Int = myBalance();
        self.transfer(self.owner, bal - 1_000_000_000);
    }
}
