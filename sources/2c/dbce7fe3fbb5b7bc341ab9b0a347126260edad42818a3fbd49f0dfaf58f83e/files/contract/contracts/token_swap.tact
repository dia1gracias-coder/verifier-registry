import "@stdlib/deploy";
import "@stdlib/ownable";

// Jetton Transfer Message
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// Jetton Transfer Notification
message(0x7362d09c) TokenTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

// Admin Messages
message UpdateTokenXPrice {
    newPrice: Int as uint64; // Price in USDT (with 6 decimals)
}

message UpdateTonPrice {
    newPrice: Int as uint64; // Price of 1 TON in USDT (with 6 decimals)
}

message SetTokenXWallet {
    wallet: Address;
}

message SetUSDTWallet {
    wallet: Address;
}

message DepositTon {
    amount: Int as coins;
}

message WithdrawTon {
    amount: Int as coins;
}

message WithdrawTokenX {
    amount: Int as coins;
}

message WithdrawUSDT {
    amount: Int as coins;
}

// Swap operation identifiers in forwardPayload
const OP_SWAP_TOKENX_TO_TON: Int = 1;
const OP_SWAP_TOKENX_TO_USDT: Int = 2;
const OP_SWAP_USDT_TO_TOKENX: Int = 3;

contract FixedPriceSwap with Deployable, Ownable {
    owner: Address;
    
    // Price of 1 TokenX in USDT (with 6 decimals, e.g., 3000000 = 3 USDT)
    tokenXPriceUSDT: Int as uint64;
    
    // Price of 1 TON in USDT (with 6 decimals, e.g., 5000000 = 5 USDT)
    tonPriceUSDT: Int as uint64;
    
    // Jetton wallet addresses
    tokenXWallet: Address?;
    usdtWallet: Address?;
    
    // TON reserve for payouts
    tonReserve: Int as coins;
    
    init(owner: Address, initialTokenXPrice: Int, initialTonPrice: Int) {
        self.owner = owner;
        self.tokenXPriceUSDT = initialTokenXPrice;
        self.tonPriceUSDT = initialTonPrice;
        self.tokenXWallet = null;
        self.usdtWallet = null;
        self.tonReserve = 0;
    }
    
    // ========================================
    // SWAP: TON -> TokenX
    // ========================================
    receive(msg: DepositTon) {
        self.requireOwner();
        self.tonReserve = self.tonReserve + msg.amount;
    }
    
    receive() {
        // User sends TON to buy TokenX
        let tonAmount: Int = context().value;
        require(tonAmount > ton("0.1"), "Minimum 0.1 TON required");
        
        // Calculate TokenX amount to send
        // tokenXAmount = (tonAmount * tonPriceUSDT) / tokenXPriceUSDT
        let usdtValue: Int = (tonAmount * self.tonPriceUSDT) / 1000000000; // Convert TON to USDT value
        let tokenXAmount: Int = (usdtValue * 1000000000) / self.tokenXPriceUSDT;
        
        require(self.tokenXWallet != null, "TokenX wallet not set");
        
        // Add TON to reserve
        self.tonReserve = self.tonReserve + tonAmount - ton("0.05"); // Keep 0.05 TON for fees
        
        // Send TokenX to user
        send(SendParameters{
            to: self.tokenXWallet!!,
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                queryId: 0,
                amount: tokenXAmount,
                destination: sender(),
                responseDestination: sender(),
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: emptySlice()
            }.toCell()
        });
    }
    
    // ========================================
    // SWAP: TokenX -> TON or TokenX -> USDT (via Notification)
    // ========================================
    receive(msg: TokenTransferNotification) {
        let operation: Int = 0;
        
        // Parse operation from forwardPayload
        if (!msg.forwardPayload.empty()) {
            operation = msg.forwardPayload.loadUint(32);
        }
        
        if (sender() == self.tokenXWallet) {
            // TokenX received
            if (operation == OP_SWAP_TOKENX_TO_TON) {
                // Swap TokenX -> TON
                self.swapTokenXToTon(msg.amount, msg.sender);
            } else if (operation == OP_SWAP_TOKENX_TO_USDT) {
                // Swap TokenX -> USDT
                self.swapTokenXToUSDT(msg.amount, msg.sender);
            }
        } else if (sender() == self.usdtWallet && operation == OP_SWAP_USDT_TO_TOKENX) {
            // USDT received, swap to TokenX
            self.swapUSDTToTokenX(msg.amount, msg.sender);
        }
    }
    
    // ========================================
    // Internal Swap Functions
    // ========================================
    fun swapTokenXToTon(tokenXAmount: Int, user: Address) {
        // Calculate TON amount to send
        // tonAmount = (tokenXAmount * tokenXPriceUSDT) / tonPriceUSDT
        let usdtValue: Int = (tokenXAmount * self.tokenXPriceUSDT) / 1000000000;
        let tonAmount: Int = (usdtValue * 1000000000) / self.tonPriceUSDT;
        
        require(tonAmount <= self.tonReserve, "Insufficient TON reserve");
        
        self.tonReserve = self.tonReserve - tonAmount;
        
        // Send TON to user
        send(SendParameters{
            to: user,
            value: tonAmount,
            mode: SendPayGasSeparately
        });
    }
    
    fun swapTokenXToUSDT(tokenXAmount: Int, user: Address) {
        require(self.usdtWallet != null, "USDT wallet not set");
        
        // Calculate USDT amount to send
        // usdtAmount = (tokenXAmount * tokenXPriceUSDT) / 1000000000 (normalize decimals)
        let usdtAmount: Int = (tokenXAmount * self.tokenXPriceUSDT) / 1000000000;
        
        // Send USDT to user
        send(SendParameters{
            to: self.usdtWallet!!,
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                queryId: 0,
                amount: usdtAmount,
                destination: user,
                responseDestination: user,
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: emptySlice()
            }.toCell()
        });
    }
    
    fun swapUSDTToTokenX(usdtAmount: Int, user: Address) {
        require(self.tokenXWallet != null, "TokenX wallet not set");
        
        // Calculate TokenX amount to send
        // tokenXAmount = (usdtAmount * 1000000000) / tokenXPriceUSDT
        let tokenXAmount: Int = (usdtAmount * 1000000000) / self.tokenXPriceUSDT;
        
        // Send TokenX to user
        send(SendParameters{
            to: self.tokenXWallet!!,
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                queryId: 0,
                amount: tokenXAmount,
                destination: user,
                responseDestination: user,
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: emptySlice()
            }.toCell()
        });
    }
    
    // ========================================
    // Admin Functions
    // ========================================
    receive(msg: UpdateTokenXPrice) {
        self.requireOwner();
        require(msg.newPrice > 0, "Price must be positive");
        self.tokenXPriceUSDT = msg.newPrice;
    }
    
    receive(msg: UpdateTonPrice) {
        self.requireOwner();
        require(msg.newPrice > 0, "Price must be positive");
        self.tonPriceUSDT = msg.newPrice;
    }
    
    receive(msg: SetTokenXWallet) {
        self.requireOwner();
        self.tokenXWallet = msg.wallet;
    }
    
    receive(msg: SetUSDTWallet) {
        self.requireOwner();
        self.usdtWallet = msg.wallet;
    }
    
    receive(msg: WithdrawTon) {
        self.requireOwner();
        require(msg.amount <= self.tonReserve, "Insufficient reserve");
        self.tonReserve = self.tonReserve - msg.amount;
        
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendPayGasSeparately
        });
    }
    
    receive(msg: WithdrawTokenX) {
        self.requireOwner();
        require(self.tokenXWallet != null, "TokenX wallet not set");
        
        send(SendParameters{
            to: self.tokenXWallet!!,
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                queryId: 0,
                amount: msg.amount,
                destination: self.owner,
                responseDestination: self.owner,
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: emptySlice()
            }.toCell()
        });
    }
    
    receive(msg: WithdrawUSDT) {
        self.requireOwner();
        require(self.usdtWallet != null, "USDT wallet not set");
        
        send(SendParameters{
            to: self.usdtWallet!!,
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            body: TokenTransfer{
                queryId: 0,
                amount: msg.amount,
                destination: self.owner,
                responseDestination: self.owner,
                customPayload: null,
                forwardTonAmount: ton("0.01"),
                forwardPayload: emptySlice()
            }.toCell()
        });
    }
    
    // ========================================
    // Getters
    // ========================================
    get fun tokenXPrice(): Int {
        return self.tokenXPriceUSDT;
    }
    
    get fun tonPrice(): Int {
        return self.tonPriceUSDT;
    }
    
    get fun tokenXWalletAddress(): Address? {
        return self.tokenXWallet;
    }
    
    get fun usdtWalletAddress(): Address? {
        return self.usdtWallet;
    }
    
    get fun tonReserveAmount(): Int {
        return self.tonReserve;
    }
    
    get fun calculateTonToTokenX(tonAmount: Int): Int {
        let usdtValue: Int = (tonAmount * self.tonPriceUSDT) / 1000000000;
        return (usdtValue * 1000000000) / self.tokenXPriceUSDT;
    }
    
    get fun calculateTokenXToTon(tokenXAmount: Int): Int {
        let usdtValue: Int = (tokenXAmount * self.tokenXPriceUSDT) / 1000000000;
        return (usdtValue * 1000000000) / self.tonPriceUSDT;
    }
    
    get fun calculateTokenXToUSDT(tokenXAmount: Int): Int {
        return (tokenXAmount * self.tokenXPriceUSDT) / 1000000000;
    }
    
    get fun calculateUSDTToTokenX(usdtAmount: Int): Int {
        return (usdtAmount * 1000000000) / self.tokenXPriceUSDT;
    }
}