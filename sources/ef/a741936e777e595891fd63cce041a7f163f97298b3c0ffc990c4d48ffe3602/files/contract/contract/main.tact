import "@stdlib/deploy";

// Message types
message Purchase {
    amount: Int as coins;
}

message Claim {
    amount: Int as uint64;
}

message AdminWithdraw {
    to: Address;
}

// Struct for presale information
struct PresaleInfo {
    presaleStart: Int;
    presaleEnd: Int;
    rate: Int;              // Tokens per nanoTON (scaled by 10^9)
    minPurchase: Int;
    maxPurchase: Int;
    hardcap: Int;
    totalRaised: Int;
}

// Contract state structure
contract TokenPresale with Deployable {
    // Contract owner address
    owner: Address;
    
    // Token contract address that will be distributed
    token: Address;
    
    // Presale parameters
    presaleStart: Int = 0;
    presaleEnd: Int = 0;
    rate: Int = 0;         // Tokens per nanoTON (scaled by 10^9)
    minPurchase: Int = 0;  // Minimum purchase in nanoTON
    maxPurchase: Int = 0;  // Maximum purchase in nanoTON
    hardcap: Int = 0;      // Maximum amount of TON to collect in nanoTON
    
    // State variables
    totalRaised: Int = 0;  // Total raised in nanoTON
    claimed: Bool = false;
    
    // Mapping to store user contributions
    contributions: map<Address, Int>;

    init(owner: Address, token: Address, presaleStart: Int, presaleEnd: Int, 
         rate: Int, minPurchase: Int, maxPurchase: Int, hardcap: Int) {
        self.owner = owner;
        self.token = token;
        self.presaleStart = presaleStart;
        self.presaleEnd = presaleEnd;
        self.rate = rate;
        self.minPurchase = minPurchase;
        self.maxPurchase = maxPurchase;
        self.hardcap = hardcap;
    }
    
    // Helper function to process purchase
    fun processPurchase(amount: Int, sender: Address) {
        // Check if presale is active
        let now: Int = now();
        require(now >= self.presaleStart, "Presale has not started yet");
        require(now <= self.presaleEnd, "Presale has ended");
        
        // Check purchase amount
        require(amount >= self.minPurchase, "Purchase amount below minimum");
        
        // Get user's current contribution
        let currentContribution: Int = self.getContribution(sender);
        let newContribution: Int = currentContribution + amount;
        
        // Check if user's total contribution exceeds maximum
        require(newContribution <= self.maxPurchase, "Purchase exceeds maximum allowed");
        
        // Check if hardcap is reached
        let newTotalRaised: Int = self.totalRaised + amount;
        require(newTotalRaised <= self.hardcap, "Hardcap reached");
        
        // Update state
        self.contributions.set(sender, newContribution);
        self.totalRaised = newTotalRaised;
    }

    // Receive TON for token purchase
    receive(msg: Purchase) {
        self.processPurchase(msg.amount, sender());
    }

    // Default receiver for plain TON transfers
    receive() {
        // Treat plain TON transfers as purchases
        let amount: Int = context().value;
        self.processPurchase(amount, sender());
    }

    // Claim tokens after presale ends
    receive(msg: Claim) {
        // Check if presale has ended
        require(now() > self.presaleEnd, "Presale has not ended yet");
        
        // Get user's contribution
        let sender: Address = sender();
        let contribution: Int = self.getContribution(sender);
        require(contribution > 0, "No contribution found");
        
        // Calculate tokens to distribute
        // For fractional rates, we need to calculate precisely
        let tokensAmount: Int = (contribution * self.rate) / 1000000000; // Divide by 10^9 to get actual token amount
        
        // Reset user's contribution
        self.contributions.set(sender, 0);
        
        // Send the tokens (implementation depends on your token contract)
        // This would typically involve sending a message to the token contract
        // Example (pseudocode):
        // send(SendParameters{
        //     to: self.token,
        //     value: ton("0.05"),
        //     mode: SendIgnoreErrors,
        //     body: TokenTransfer{
        //         to: sender,
        //         amount: tokensAmount
        //     }.toCell()
        // });
    }

    // Admin function to withdraw collected TON
    receive(msg: AdminWithdraw) {
        // Only owner can withdraw
        require(sender() == self.owner, "Only owner can withdraw");
        
        // Check if presale has ended
        require(now() > self.presaleEnd, "Presale has not ended yet");
        
        // Send TON to the specified address
        send(SendParameters{
            to: msg.to,
            value: myBalance() - ton("0.1"), // Leave some TON for gas
            mode: SendIgnoreErrors
        });
    }

    // Get function to check user's contribution
    get fun getContribution(address: Address): Int {
        if (self.contributions.get(address) != null) {
            return self.contributions.get(address)!!;
        } else {
            return 0;
        }
    }
    
    // Get functions for contract parameters
    get fun getPresaleInfo(): PresaleInfo {
        return PresaleInfo{
            presaleStart: self.presaleStart,
            presaleEnd: self.presaleEnd,
            rate: self.rate,
            minPurchase: self.minPurchase,
            maxPurchase: self.maxPurchase,
            hardcap: self.hardcap,
            totalRaised: self.totalRaised
        };
    }
    
    // Check if presale is active
    get fun isActive(): Bool {
        let now: Int = now();
        return now >= self.presaleStart && now <= self.presaleEnd;
    }
    
    // Calculate tokens for a given TON amount
    get fun calculateTokens(tonAmount: Int): Int {
        return (tonAmount * self.rate) / 1000000000;
    }
}