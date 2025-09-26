// ISLAMIC SHIELD (DER) - Simple Wallet Contract
// Easy to use and transfer tokens

import "@stdlib/deploy";

contract SimpleDERWallet with Deployable {
    // === Storage Fields ===
    owner: Address;                      // Wallet owner
    master: Address;                     // Master contract
    balance: Int;                        // Token balance
    treasury: Address;                   // Treasury for fees
    feePercentage: Int;                  // Fee percentage (1% = 100)
    feeDenominator: Int;                 // Fee denominator (10000)
    maxFee: Int;                         // Maximum fee (1500 DER)
    
    // === Initialization ===
    init(owner: Address, master: Address) {
        self.owner = owner;
        self.master = master;
        self.balance = 0;
        
        // Set treasury address
        self.treasury = address("0QCLWPoiYA8WJeuG5QHJ1xTdejaDGu1oYPFArLPVuVaHTOOk");
        
        // Set fee parameters (1% max 1500 DER)
        self.feePercentage = 100;        // 1%
        self.feeDenominator = 10000;     // 10000 basis points
        self.maxFee = 1500000000000;     // 1500 DER with 9 decimals
    }
    
    // === Simple Transfer Function ===
    fun transfer(amount: Int, destination: Address) {
        // Only owner can transfer
        if (sender() != self.owner) {
            throw(100); // Unauthorized
        }
        
        // Check sufficient balance
        if (self.balance < amount) {
            throw(101); // Insufficient balance
        }
        
        // Calculate fee (1% max 1500 DER)
        let calculatedFee = (amount * self.feePercentage) / self.feeDenominator;
        let fee = calculatedFee < self.maxFee ? calculatedFee : self.maxFee;
        let transferAmount = amount - fee;
        
        // Update balance
        self.balance = self.balance - amount;
        
        // Send fee to treasury
        if (fee > 0) {
            self.sendFeeToTreasury(fee);
        }
        
        // Send transfer to destination
        self.sendTransfer(destination, transferAmount);
    }
    
    // === Send Fee to Treasury ===
    inline fun sendFeeToTreasury(fee: Int) {
        let message = beginCell()
            .storeUint(0x178d4519, 32)             // excesses
            .storeUint(0, 64)                      // query_id
            .endCell();
        
        send(SendParameters{
            to: self.treasury,
            value: 10000000,                       // 0.01 TON
            body: message
        });
    }
    
    // === Send Transfer ===
    inline fun sendTransfer(destination: Address, amount: Int) {
        let message = beginCell()
            .storeUint(0xf8a7ea5, 32)              // transfer
            .storeUint(0, 64)                      // query_id
            .storeUint(amount, 64)                 // jetton_amount
            .storeAddress(destination)             // destination
            .storeAddress(self.owner)              // response_destination
            .storeUint(0, 1)                       // custom_payload
            .storeUint(0, 64)                      // forward_ton_amount
            .storeUint(0, 64)                      // total_forwarded_amount
            .endCell();
        
        send(SendParameters{
            to: destination,
            value: 0,
            body: message
        });
    }
    
    // === Add Tokens (from master) ===
    fun addTokens(amount: Int) {
        // Only master can add tokens
        if (sender() != self.master) {
            throw(100); // Unauthorized
        }
        
        // Add to balance
        self.balance = self.balance + amount;
    }
    
    // === Message Handler ===
    receive() {
        let ctx = context();
        if (ctx.raw.bits() > 0) {
            let op = ctx.raw.loadUint(32);
            
            if (op == 0xf8a7ea5) { // transfer
                self.handleTransfer();
            } else if (op == 0x178d4519) { // internal_transfer
                self.handleInternalTransfer();
            } else {
                throw(102); // Unknown operation
            }
        }
    }
    
    // === Handle Transfer ===
    inline fun handleTransfer() {
        let ctx = context();
        let queryId = ctx.raw.loadUint(64);
        let amount = ctx.raw.loadUint(64);
        let destination = ctx.raw.loadAddress();
        let responseDestination = ctx.raw.loadAddress();
        let customPayload = ctx.raw.loadRef();
        let forwardTonAmount = ctx.raw.loadUint(64);
        let totalForwardedAmount = ctx.raw.loadUint(64);
        
        // Only owner can transfer
        if (sender() != self.owner) {
            throw(100); // Unauthorized
        }
        
        // Check sufficient balance
        if (self.balance < amount) {
            throw(101); // Insufficient balance
        }
        
        // Calculate fee (1% max 1500 DER)
        let calculatedFee = (amount * self.feePercentage) / self.feeDenominator;
        let fee = calculatedFee < self.maxFee ? calculatedFee : self.maxFee;
        let transferAmount = amount - fee;
        
        // Update balance
        self.balance = self.balance - amount;
        
        // Send fee to treasury
        if (fee > 0) {
            self.sendFeeToTreasury(fee);
        }
        
        // Send transfer to destination
        self.sendTransfer(destination, transferAmount);
    }
    
    // === Handle Internal Transfer ===
    inline fun handleInternalTransfer() {
        let ctx = context();
        let queryId = ctx.raw.loadUint(64);
        let amount = ctx.raw.loadUint(64);
        let from = ctx.raw.loadAddress();
        let responseDestination = ctx.raw.loadAddress();
        let forwardTonAmount = ctx.raw.loadUint(64);
        let totalForwardedAmount = ctx.raw.loadUint(64);
        
        // Only master can send internal transfers
        if (sender() != self.master) {
            throw(100); // Unauthorized
        }
        
        // Add to balance
        self.balance = self.balance + amount;
        
        // Send excesses back to master
        let message = beginCell()
            .storeUint(0xd53276db, 32)             // excesses
            .storeUint(queryId, 64)                // query_id
            .endCell();
        
        send(SendParameters{
            to: self.master,
            value: 0,
            body: message
        });
    }
    
    // === Get Functions ===
    get fun getBalance(): Int {
        return self.balance;
    }
    
    get fun getOwner(): Address {
        return self.owner;
    }
    
    get fun getMaster(): Address {
        return self.master;
    }
    
    get fun getTreasury(): Address {
        return self.treasury;
    }
    
    get fun getFeePercentage(): Int {
        return self.feePercentage;
    }
    
    get fun getMaxFee(): Int {
        return self.maxFee;
    }
    
    // === Error Codes ===
    // 100: Unauthorized
    // 101: Insufficient balance
    // 102: Unknown operation
}
