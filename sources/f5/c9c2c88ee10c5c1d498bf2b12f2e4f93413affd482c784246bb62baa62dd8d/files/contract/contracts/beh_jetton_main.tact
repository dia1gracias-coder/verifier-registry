import "@stdlib/ownable";

message Mint {
    amount: Int;
    receiver: Address;
}


contract BehJetton with Jetton {
    totalSupply: Int;
    owner: Address;
    content: Cell;
    mintable: Bool;

    max_supply: Int; 
    initInit: Int;

    init(owner: Address, content: Cell, max_supply: Int, _initInit: Int) {
        self.totalSupply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;

        self.max_supply = max_supply; // Initial Setting for max_supply
        self.initInit = _initInit;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    // Owner can lock a specific wallet's funds until a timestamp
    receive(msg: OwnerLockWallet) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");

        let winit: StateInit = self.getJettonWalletInit(msg.wallet_owner);
        // Forward remaining attached value to the wallet to pay for gas
        send(SendParameters{
            to: contractAddress(winit),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: AdminLockFunds{ amount: msg.amount, until_ts: msg.until_ts }.toCell(),
            code: winit.code,
            data: winit.data
        });
        self.reply("Address is Lock".asComment());
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        self.mintable = false;
    }

    // Empty receiver to allow deploy/receive of plain messages
    receive() {
        // intentionally empty - accepts plain inbound messages (deploy/forward)
    }
} 

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

// ============================================================================================================ //
@interface("org.ton.jetton.master")
trait Jetton with Ownable {

    totalSupply: Int; // Already set initially 
    mintable: Bool;
    owner: Address;
    content: Cell;

    max_supply: Int; // This is not in the TEP-74 interface

    receive(msg: TokenUpdateContent) {
        self.requireOwner();                // Allow changing content only by owner
        self.content = msg.content;         // Update content
    }

    receive(msg: TokenBurnNotification) {
        self.requireWallet(msg.owner);                     // Check wallet
        self.totalSupply = self.totalSupply - msg.amount; // Update supply

        if (msg.response_destination != null) { // Cashback
            send(SendParameters{
                to: msg.response_destination!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.totalSupply + amount <= self.max_supply, "The total supply will be overlapping.");
        self.totalSupply = self.totalSupply + amount; // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                queryId: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(myAddress(), address);
    }

    // ====== Get Methods ====== //
    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return JettonData{ 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            walletCode: code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }
}
// ============================================================ //
@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int;
    owner: Address;
    master: Address;
    // Lock fields: separate user (self) and admin (master) locks
    userLockedAmount: Int;
    userLockUntil: Int;
    adminLockedAmount: Int;
    adminLockUntil: Int;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
        self.userLockedAmount = 0;
        self.userLockUntil = 0;
        self.adminLockedAmount = 0;
        self.adminLockUntil = 0;
    }

    receive(msg: TokenTransfer) { // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");

        // Gas checks
        let fwdFee: Int = ctx.readForwardFee() + ctx.readForwardFee();  
        let final: Int =  2 * self.gasConsumption + self.minTonsForStorage + fwdFee;
    require(ctx.value > min(final, ton("0.01")), "Invalid value!!"); 

        // Check available balance w.r.t. active locks (admin or user)
        let current: Int = now();
        let aLocked: Int = current < self.adminLockUntil ? self.adminLockedAmount : 0;
        let uLocked: Int = current < self.userLockUntil ? self.userLockedAmount : 0;
        // Add both locks together - both should be enforced
        let effectiveLocked: Int = aLocked + uLocked;
        let available: Int = self.balance - effectiveLocked;
        require(available >= msg.amount, "Locked or insufficient balance");

        // Update balance
        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Invalid balance");

        let init: StateInit = initOf JettonDefaultWallet(self.master, msg.destination);  
        let walletAddress: Address = contractAddress(init);
        send(SendParameters{
                to: walletAddress, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: TokenTransferInternal{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });
    }

    receive(msg: TokenTransferInternal) { // 0x178d4519
        let ctx: Context = context();

        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(self.master, msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 
        
    // Get value for gas
    let msgValue: Int = self.msgValue(ctx.value);  
        let fwdFee: Int = ctx.readForwardFee();
        msgValue = msgValue - msg.forward_ton_amount - fwdFee;
        
         // 0x7362d09c - notify the new owner of JettonToken that the transfer is complete
        if (msg.forward_ton_amount > 0) { 
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TokenNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        // 0xd53276db -- Cashback to the original Sender
        if (msg.response_destination != null) { 
            send(SendParameters {
                to: msg.response_destination!!, 
                value: msgValue,  
                bounce: false,
                body: TokenExcesses { 
                    queryId: msg.queryId
                }.toCell(),
                mode: SendIgnoreErrors
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");  // Check sender

        // Check available balance w.r.t. active locks (admin or user)
        let current: Int = now();
        let aLocked: Int = current < self.adminLockUntil ? self.adminLockedAmount : 0;
        let uLocked: Int = current < self.userLockUntil ? self.userLockedAmount : 0;
        // Add both locks together - both should be enforced
        let effectiveLocked: Int = aLocked + uLocked;
        let available: Int = self.balance - effectiveLocked;
        require(available >= msg.amount, "Locked or insufficient balance");

        self.balance = self.balance - msg.amount; // Update balance
        require(self.balance >= 0, "Invalid balance");

        let fwdFee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > fwdFee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        // Burn tokens
        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
        self.reply("Jetton is Burn".asComment());
    }

    get fun msgValue(value: Int): Int {
        let mv: Int = value;
        let tonBalanceBeforeMsg: Int = myBalance() - mv;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        let res: Int = mv - (storageFee + self.gasConsumption);
        return res;
    }

    bounced(src: bounced<TokenTransferInternal>) {
        self.balance = self.balance + src.amount;
    }

    bounced(src: bounced<TokenBurnNotification>) {
        self.balance = self.balance + src.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf JettonDefaultWallet(self.master, self.owner)).code
        };
    }
    
    // Lock/unlock funds until a unix timestamp (wallet owner self-lock only)
    receive(msg: LockFunds) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        // if until_ts is in the past, clear lock
        let current: Int = now();
        if (msg.until_ts <= current) {
            self.userLockedAmount = 0;
            self.userLockUntil = 0;
            return;
        }

        require(msg.amount >= 0, "Invalid amount");
        // cannot lock more than current balance
        require(msg.amount <= self.balance, "Lock amount exceeds balance");

        self.userLockedAmount = msg.amount;
        self.userLockUntil = msg.until_ts;
        self.reply("Wallet is Lock".asComment());
    }

    // Admin lock initiated by master (token owner via master)
    receive(msg: AdminLockFunds) {
        let ctx: Context = context();
        require(ctx.sender == self.master, "Invalid sender");

        // if until_ts is in the past, clear admin lock
        let current: Int = now();
        if (msg.until_ts <= current) {
            self.adminLockedAmount = 0;
            self.adminLockUntil = 0;
            return;
        }

        require(msg.amount >= 0, "Invalid amount");
        // Remove balance check - owner can lock any amount even if user doesn't have balance yet

        self.adminLockedAmount = msg.amount;
        self.adminLockUntil = msg.until_ts;
        self.reply("Wallet is Lock".asComment());
    }

    // Return lock info
    get fun get_lock_data(): LockData {
        let current: Int = now();
        let aLocked: Int = current < self.adminLockUntil ? self.adminLockedAmount : 0;
        let uLocked: Int = current < self.userLockUntil ? self.userLockedAmount : 0;
        // Add both locks together instead of taking max - both should be enforced
        let effectiveLocked: Int = aLocked + uLocked;
        let untilTime: Int = 0;
        // Return the later unlock time
        if (aLocked > 0 && uLocked > 0) {
            untilTime = max(self.adminLockUntil, self.userLockUntil);
        } else if (aLocked > 0) {
            untilTime = self.adminLockUntil;
        } else if (uLocked > 0) {
            untilTime = self.userLockUntil;
        }
        return LockData{ lockedAmount: effectiveLocked, lockUntil: untilTime };
    }
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

struct LockData {
    lockedAmount: Int;
    lockUntil: Int;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}

message LockFunds {
    amount: Int as coins;
    until_ts: Int; // unix timestamp
}

// Owner-initiated lock request at master level (specifies which wallet to lock)
message OwnerLockWallet {
    wallet_owner: Address; // wallet owner address to be locked
    amount: Int as coins;  // amount to lock (<= current balance)
    until_ts: Int;         // unlock timestamp; <= now clears lock
}

// Message delivered to wallet by master to set/clear admin lock
message AdminLockFunds {
    amount: Int as coins;
    until_ts: Int;
}

message TokenUpdateContent {
    content: Cell;
}