import "@stdlib/deploy";
import "@stdlib/ownable";

message Deposit {
    sender: Address;
    recipient: String;
    amount: Int as coins;    
    data: String;
}

message Revert {
    amount: Int as coins;
    to: Address;
}


message Withdraw {
    amount: Int as coins;
    to: Address;
}

message WithdrawFee {
    to: Address;
}

message SetFee {
    fee: Int as coins;       
}

message SetFeeMultiplier {
    val:Int
}


contract Bridge with Deployable, Ownable {
    owner: Address;
    lockedAmount: Int;
    collectedFees: Int;
    feeAmount: Int; 
    feeMultiplier: Int;  
    
    init() {
        self.owner = sender();
        self.lockedAmount = 0;
        self.collectedFees = 0;
        self.feeAmount = 0;
        self.feeMultiplier = 100;   
       
    }
    
    // Set exact fee amount
    receive(msg: SetFee) {
        self.requireOwner();
        require(msg.fee >= 0, "Fee cannot be negative");
        self.feeAmount = msg.fee;
    }
    
  

 receive(msg: Deposit) {
    let amount: Int = context().value;
    let fwdFee: Int = context().readForwardFee();
    let storageFee: Int = myStorageDue();
  
    
    // Input validation first (before any state changes)
    require(amount > 0, "Amount must be greater than zero");
    
    
    
    let gasUsed: Int = gasConsumed();
    let gasFeeCalc: Int = getComputeFee(gasUsed, false);

    let origFwdFee2: Int = getOriginalFwdFee(fwdFee, false);
    let baseDynamicFees: Int = origFwdFee2 + storageFee + gasFeeCalc;
    let dynamicFees: Int = (baseDynamicFees * self.feeMultiplier) / 100;
        
    let totalRequired: Int = self.feeAmount + dynamicFees;
    

    require(amount >= totalRequired, "Insufficient amount for fees");  
  
  
    let netAmount: Int = amount - totalRequired;
    require(netAmount > 0, "Net amount must be positive");
    
    self.lockedAmount += netAmount; 
    self.collectedFees += self.feeAmount;
    
    
    emit(Deposit {
        sender: sender(),
        recipient: msg.recipient,
        amount: netAmount,
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
        
        
       
        self.lockedAmount -= msg.amount;
        
        // Send funds to specified address
        send(SendParameters{
            to: msg.to,
            value: msg.amount,
            bounce: true,
            mode: SendPayGasSeparately
        });

        cashback(sender());

        
    }

    receive(msg: Revert) {
        // Ensure only owner can withdraw
        self.requireOwner();
        
        let balance = self.lockedAmount + self.feeAmount;
        // Validate withdrawal amount
        require(msg.amount > 0, "Withdrawal amount must be greater than zero");
        require(msg.amount <= balance, "Insufficient locked funds");
        
        
        self.lockedAmount -= msg.amount;

        if(self.collectedFees > 0) {
            self.collectedFees -= self.feeAmount;
        }
        
        // Send funds  to specified address
        send(SendParameters{
            to: msg.to,
            value: msg.amount,
            bounce: true,
            mode: SendPayGasSeparately
        });

         cashback(sender());
    }
    
    // Withdraw collected fees - only owner can call
    receive(msg:WithdrawFee) {
        self.requireOwner();
    
        require(self.collectedFees > 0, "No fees to withdraw");

        send(SendParameters{
                to: msg.to,
                value: self.collectedFees,
                bounce: false,
                mode: SendPayGasSeparately
            });

        self.collectedFees = 0;
        cashback(sender());
    }

    receive(msg:SetFeeMultiplier) {
        self.requireOwner();
    
        self.feeMultiplier = msg.val;

        cashback(sender());
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

    get fun getFeeMultiplier(): Int {
        return self.feeMultiplier;
    }


}