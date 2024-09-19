import "@stdlib/deploy";

// TokenNotification message structure
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;  // Slice containing additional data (e.g., comment text)
}

message SetAllowedAddress {
    allowedAdress: Address;  
}

// Main contract: JettonDex
contract JettonDex with Deployable {
    jettonABalance: Int as coins;  // Ensure consistent type for jetton A balance
    jettonBalance: Int as coins;
    fails: Int as uint32;
    allowedAddress: Address?;  // Total failed attempts

    // Initialize contract with owner's address and initial jetton balances
    init() {
        self.jettonABalance = 0;
        self.jettonBalance = 0;
        self.fails = 0;
        self.allowedAddress = address("0QDoKkeydaB-dQV2eqgch6ZzT70MoBvQC8GC0Jk7mj2rcsMh");
    }

    // Handle receiving jettons via TokenNotification message
    receive(msg: TokenNotification) {

        require(self.allowedAddress != null, "null check");  
        require(msg.from == self.allowedAddress!!, "wrong addr");
        
        let ctx: Context = context();
        let queryId: Int = msg.queryId;
        let value: Int = 15;
        let address: Address = msg.from;
        let amount: Int = msg.amount;

        self.addJetton(amount);
     
    }

    receive(msg: SetAllowedAddress) {
        require(self.allowedAddress == address("0QDoKkeydaB-dQV2eqgch6ZzT70MoBvQC8GC0Jk7mj2rcsMh"), "Already here");
        self.allowedAddress = msg.allowedAdress;  // Set the new allowed address
    }


    // Function to add jettons to balance
    fun addJetton(amount: Int) {
        self.jettonABalance += amount;  // Update balance with the received amount
    }

    // Getter for Jetton A balance
    get fun getJettonABalance(): Int {
        return self.jettonABalance;
    }

    // Getter for the total jetton balance
    get fun getJettonBalance(): Int {
        return self.jettonBalance;
    }

    // Getter for the total fails
    get fun getFails(): Int {
        return self.fails;
    }

    get fun getAddr(): Address? {
        return self.allowedAddress;
    }
}
