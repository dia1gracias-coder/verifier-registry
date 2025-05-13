import "@stdlib/deploy";
import "@stdlib/ownable";

message Deposit {
    sender: Address;
    amount: Int as coins;    // Amount after fee deduction
    data: String;
}

message Withdraw {
    amount: Int as coins;
    to: Address;
}

message WithdrawFee {
    to: Address;
}

message SetFee {
    fee: Int as coins;       // Exact fee amount in nanoTONs
}

contract Bridge with Deployable, Ownable {
    owner: Address;
    lockedAmount: Int;
    collectedFees: Int;
    feeAmount: Int;          // Fixed fee amount in nanoTONs
    
    init() {
        self.owner = sender();
        self.lockedAmount = 0;
        self.collectedFees = 0;
        self.feeAmount = 0;   
    }
    
    // Set exact fee amount
    receive(msg: SetFee) {
        self.requireOwner();
        require(msg.fee >= 0, "Fee cannot be negative");
        self.feeAmount = msg.fee;
    }
    
    // Receive and lock TON
    receive(msg:Deposit) {
        let amount = context().value;
        require(amount == msg.amount, "Amount Is Not Matching");
        require(amount > 0, "Amount must be greater than zero");
        require(amount > self.feeAmount, "Deposit must be greater than fee");
        
        // Apply fixed fee
        let fee = self.feeAmount;
        let amountAfterFee = amount - fee;
        
        // Update state
        self.lockedAmount += amountAfterFee;
        self.collectedFees += fee;
        
        // Emit deposit event with fee information
        emit(Deposit {
            sender: sender(),
            amount: amountAfterFee,
            data: msg.data
        }.toCell());
    }
    
    // Withdraw function - only owner can call
    receive(msg: Withdraw) {
        // Ensure only owner can withdraw
        self.requireOwner();
        
        // Validate withdrawal amount
        require(msg.amount > 0, "Withdrawal amount must be greater than zero");
        require(msg.amount <= self.lockedAmount, "Insufficient locked funds");
        
        // Update locked amount before sending
        self.lockedAmount -= msg.amount;
        
        // Send funds to specified address
        send(SendParameters{
            to: msg.to,
            value: msg.amount,
            bounce: false
        });
    }
    
    // Withdraw collected fees - only owner can call
    receive(msg:WithdrawFee) {
    self.requireOwner();
  
    require(self.collectedFees > 0, "No fees to withdraw");

     send(SendParameters{
            to: msg.to,
            value: self.collectedFees,
            bounce: false,
            mode: SendRemainingValue + SendIgnoreErrors
        });

    self.collectedFees = 0;
}

    
    // Get balance of locked funds (excluding fees)
    get fun getLockedAmount(): Int {
        return self.lockedAmount;
    }
    
    // Get balance of collected fees
    get fun getCollectedFees(): Int {
        return self.collectedFees;
    }
    
    // Get current fee amount
    get fun getFeeAmount(): Int {
        return self.feeAmount;
    }
}