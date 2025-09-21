import "@stdlib/ownable";
import "@stdlib/stoppable";
import "@stdlib/deploy";

// ============================================================================================================ //
// MESSAGES
// ============================================================================================================ //

// TEP-74 Messages
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}

// Jetton Master Messages
message TokenUpdateContent {
    content: Cell?;
}

message ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}

message TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Address;
}

// Minting message
message Mint {
    amount: Int;
    receiver: Address;
}

// ============================================================================================================ //
// STRUCTS
// ============================================================================================================ //

struct JettonData {
    total_supply: Int;
    mintable: Bool;
    admin_address: Address;
    jetton_content: Cell?;
    jetton_wallet_code: Cell;
}

struct WalletData {
    balance: Int;
    owner: Address;
    jetton: Address;
    jetton_wallet_code: Cell;
}

// ============================================================================================================ //
// JETTON WALLET CONTRACT
// ============================================================================================================ //

contract TaxJettonWallet with Deployable {
    balance: Int;
    owner: Address;
    jetton: Address;
    dev_address: Address;
    
    init(owner: Address, jetton: Address, dev_address: Address) {
        self.balance = 0;
        self.owner = owner;
        self.jetton = jetton;
        self.dev_address = dev_address;
    }
    
    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(msg.amount > 0, "Invalid amount");
        require(self.balance >= msg.amount, "Insufficient balance");
        
        // Check if this is the dev wallet (exempt from tax)
        let is_dev_wallet: Bool = (self.owner == self.dev_address);
        
        // Calculate tax (10%) - but exempt dev wallet
        let tax_amount: Int = 0;
        let transfer_amount: Int = msg.amount;
        
        if (!is_dev_wallet) {
            tax_amount = msg.amount / 10;
            transfer_amount = msg.amount - tax_amount;
        }
        
        // Update balance
        self.balance = self.balance - msg.amount;
        
        // Simple gas check
        require(ctx.value >= ton("0.15"), "Insufficient gas for transfer");
        
        // Send remaining amount to destination first
        if (transfer_amount > 0) {
            let init: StateInit = self.getJettonWalletInit(msg.destination);
            let wallet_address: Address = contractAddress(init);
            send(SendParameters{
                to: wallet_address,
                value: ton("0.05"),
                mode: SendPayGasSeparately,
                bounce: true,
                body: TokenTransferInternal{
                    query_id: msg.query_id,
                    amount: transfer_amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });
        }
        
        // Send tax to jetton master (dev)
        if (tax_amount > 0) {
            send(SendParameters{
                to: self.jetton,
                value: ton("0.05"),
                mode: SendPayGasSeparately,
                bounce: false,
                body: TokenTransferInternal{
                    query_id: msg.query_id,
                    amount: tax_amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell()
            });
        }
    }
    
    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();
        
        if (ctx.sender != self.jetton) {
            let sinit: StateInit = self.getJettonWalletInit(msg.from);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender");
        }
        
        // Update balance
        self.balance = self.balance + msg.amount;
        
        // Ensure min storage
        require(myBalance() >= self.minTonsForStorage, "Insufficient gas");
        
        // Forward notification if needed
        if (msg.forward_ton_amount > 0) {
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                body: TokenNotification{
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }
        
        // Send excesses back
        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{query_id: msg.query_id}.toCell()
            });
        }
    }
    
    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(msg.amount > 0, "Invalid amount");
        require(self.balance >= msg.amount, "Insufficient balance");
        
        self.balance = self.balance - msg.amount;
        
        let fwd_fee: Int = ctx.readForwardFee();
        require(ctx.value > fwd_fee + 2 * self.gasConsumption + self.minTonsForStorage, "Insufficient gas");
        
        send(SendParameters{
            to: self.jetton,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                query_id: msg.query_id,
                amount: msg.amount,
                from: self.owner,
                response_destination: msg.response_destination
            }.toCell()
        });
    }
    
    bounced(src: bounced<TokenTransferInternal>) {
        self.balance = self.balance + src.amount;
    }
    
    bounced(src: bounced<TokenBurnNotification>) {
        self.balance = self.balance + src.amount;
    }
    
    get fun get_wallet_data(): WalletData {
        return WalletData{
            balance: self.balance,
            owner: self.owner,
            jetton: self.jetton,
            jetton_wallet_code: self.getJettonWalletInit(self.owner).code
        };
    }
    
    get fun getJettonWalletInit(owner: Address): StateInit {
        return initOf TaxJettonWallet(owner, self.jetton, self.dev_address);
    }
    
    const gasConsumption: Int = ton("0.01");
    const minTonsForStorage: Int = ton("0.01");
    override const storageReserve: Int = ton("0.01");
}

// ============================================================================================================ //
// JETTON MASTER CONTRACT
// ============================================================================================================ //

contract TaxJettonMaster with Deployable, Ownable, Stoppable {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;
    dev_address: Address; // Address to receive tax fees
    stopped: Bool;
    
    init(content: Cell?, dev_address: Address) {
        self.total_supply = 0;
        self.mintable = true;
        self.content = content;
        self.dev_address = dev_address;
        self.owner = dev_address;
        self.stopped = false;
    }
    
    receive(msg: Mint) {
        self.requireOwner();
        require(self.mintable, "Not mintable");
        
        self.mint(msg.receiver, msg.amount, self.owner);
    }
    
    receive(msg: TokenUpdateContent) {
        self.requireOwner();
        self.content = msg.content;
    }
    
    receive(msg: TokenBurnNotification) {
        require(self.total_supply >= msg.amount, "Invalid burn amount");
        self.total_supply = self.total_supply - msg.amount;
        
        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{query_id: msg.query_id}.toCell()
            });
        }
    }
    
    receive(msg: ProvideWalletAddress) {
        require(context().value >= ton("0.0061"), "Insufficient gas");
        
        let init: StateInit = self.getJettonWalletInit(msg.owner_address);
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TakeWalletAddress{
                query_id: msg.query_id,
                wallet_address: contractAddress(init),
                owner_address: msg.owner_address
            }.toCell()
        });
    }
    
    // Receive tax payments from wallets
    receive(msg: TokenTransferInternal) {
        // This is tax payment - add to dev wallet balance
        let init: StateInit = self.getJettonWalletInit(self.dev_address);
        let dev_wallet: Address = contractAddress(init);
        
        send(SendParameters{
            to: dev_wallet,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TokenTransferInternal{
                query_id: msg.query_id,
                amount: msg.amount,
                from: msg.from,
                response_destination: msg.response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: init.code,
            data: init.data
        });
    }
    
    fun mint(to: Address, amount: Int, response_destination: Address?) {
        require(self.mintable, "Not mintable");
        self.total_supply = self.total_supply + amount;
        
        let init: StateInit = self.getJettonWalletInit(to);
        send(SendParameters{
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TokenTransferInternal{
                query_id: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: init.code,
            data: init.data
        });
    }
    
    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return JettonData{
            total_supply: self.total_supply,
            mintable: self.mintable,
            admin_address: self.owner,
            jetton_content: self.content,
            jetton_wallet_code: code
        };
    }
    
    get fun get_wallet_address(owner: Address): Address {
        let init: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(init);
    }
    
    get fun get_dev_address(): Address {
        return self.dev_address;
    }
    
    get fun getJettonWalletInit(owner: Address): StateInit {
        return initOf TaxJettonWallet(owner, myAddress(), self.dev_address);
    }
}
