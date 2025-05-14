
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

    fun calculate_win(): Int {
        let rand: Int = randomInt(); // [0, 999999]

        // Skewed payout ranges — designed for profit (~$0.45 EV)
        if (rand < 400000) {
            return 20_000_000; // $0.02 (40%)
        } else if (rand < 650000) {
            return 50_000_000; // $0.05 (25%)
        } else if (rand < 800000) {
            return 100_000_000; // $0.10 (15%)
        } else if (rand < 880000) {
            return 250_000_000; // $0.25 (8%)
        } else if (rand < 930000) {
            return 500_000_000; // $0.50 (5%)
        } else if (rand < 960000) {
            return 750_000_000; // $0.75 (3%)
        } else if (rand < 980000) {
            return 1_000_000_000; // $1.00 (2%)
        } else if (rand < 993000) {
            return 5_000_000_000; // $5.00 (1.3%)
        } else if (rand < 997000) {
            return 10_000_000_000; // $10.00 (0.4%)
        } else if (rand < 999500) {
            return 50_000_000_000; // $50.00 (0.25%)
        } else {
            return 100_000_000_000; // $100.00 (0.05%)
        }
    }
    // Only owner can withdraw accumulated profit
    receive("withdraw") {
        require(sender() == self.owner, "Only owner");
        let bal: Int = myBalance();
        self.transfer(self.owner, bal - 1_000_000_000);
    }

    get fun getRandomNumber(): Int{
        return randomInt(); 
    }
}
