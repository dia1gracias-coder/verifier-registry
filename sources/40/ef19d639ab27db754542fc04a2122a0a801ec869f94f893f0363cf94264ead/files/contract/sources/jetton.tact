import "@stdlib/ownable";
import "./messages";

// ============================================================================================================ //
@interface("org.ton.jetton.master")
trait Jetton with Ownable {

    total_supply: Int; // Already set initially 
    mintable: Bool;
    owner: Address;
    content: Cell; // metadata
    
    receive(msg: TokenUpdateContent) {
        self.requireOwner();                // Allow changing content only by owner
        self.content = msg.content;         // Update content
    }

    receive(msg: TokenBurnNotification) {
        self.requireSenderAsWalletOwner(msg.response_destination);       // Check wallet
        self.total_supply = self.total_supply - msg.amount; // Update supply
        if (msg.response_destination != null) { // Cashback
            send(SendParameters{
                to: msg.response_destination, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

    // https://github.com/ton-blockchain/TEPs/blob/master/text/0089-jetton-wallet-discovery.md
    receive(msg: ProvideWalletAddress) {
        require(context().value >= ton("0.0061"), "Insufficient gas");
        let init: StateInit = initOf JettonDefaultWallet(msg.owner_address, self.owner);
        let wallet_address: Address = contractAddress(init);

        let response_body: TakeWalletAddress = TakeWalletAddress{
                query_id: msg.query_id,
                wallet_address: wallet_address,
                owner_address: null
            };
        if (msg.include_address) {
            response_body.owner_address = msg.owner_address;
        }
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: response_body.toCell()
        });
    }


    // Private Methods // 
    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.mintable, "Can't Mint Anymore");
        self.total_supply = self.total_supply + amount; // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
            to: contractAddress(winit), 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                query_id: 0,
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

    fun requireSenderAsWalletOwner(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(address, myAddress());
    }

    // ====== Get Methods ====== //
    get fun get_jetton_data(): JettonData {
        return JettonData{ 
            total_supply: self.total_supply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            wallet_code: initOf JettonDefaultWallet(self.owner, myAddress()).code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, myAddress()));
    }
}

// ============================================================ //
@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");

    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    stonRouter: Address;
    feeCollection: Address;
    excludeFee: map<Address, Bool>;
    tradeFee: Int = 0;

    init(owner: Address, master: Address) {
        self.balance = 0;
        self.owner = owner; 
        self.master = master;
        self.stonRouter = address("EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt");
        self.feeCollection = address("UQAgcPZyFBLaMXmyl-Fkv0fszU1OK8_I1f3Zn5DZuAtZYB8R");
    }

    receive(msg: EditTradeFee) {
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");
        self.tradeFee = msg.tradeFee;
    }

    receive(msg: EditExcludeFeeAddr) {
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");
        self.excludeFee.set(msg.excludeAddr, msg.status);
    }

    receive(msg: TokenTransfer) { // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");

        // Gas checks
        let fwd_fee: Int = ctx.readForwardFee() + ctx.readForwardFee();  
        let final: Int = fwd_fee + 2 * self.gasConsumption + self.minTonsForStorage + msg.forward_ton_amount;
        require(ctx.value > final, "Invalid value!!"); 

        // Update balance
        self.balance = self.balance - msg.amount; 
        require(self.balance >= 0, "Invalid balance");

        let msg_value: Int = self.msg_value(ctx.value);  

        let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master);  
        let wallet_address: Address = contractAddress(init);

        if(self.tradeFee == 0 || self.excludeFee.get(wallet_address) == true || self.excludeFee.get(ctx.sender) == true){
            send(SendParameters{
                to: wallet_address, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: false,
                body: TokenTransferInternal{ // 0x178d4519
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload:  msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });
        }else{
            //发送交易代币
            send(SendParameters{
                to: wallet_address, 
                //value: 0,
                //mode: SendRemainingValue, 
                value:msg_value/2,        
                mode: SendPayGasSeparately  + SendIgnoreErrors,
                bounce: false,
                body: TokenTransferInternal{
                    query_id: msg.query_id,
                    amount: msg.amount / 100 * (100 - self.tradeFee),
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            });

            //发送手续费
            //transfer 1% amount to  admin address of Jetton master contract
            let init_admin: StateInit = initOf JettonDefaultWallet(self.feeCollection, self.master);  
            let admin_wallet_address: Address = contractAddress(init_admin);
            send(SendParameters{
                to: admin_wallet_address, 
                //value: 0,
                //mode: SendRemainingValue, 
                value:msg_value/2,        
                mode:  SendIgnoreErrors,
                bounce: false,
                body: TokenTransferInternal{
                    query_id: msg.query_id+1,
                    amount: msg.amount / 100 * self.tradeFee,
                    from: self.owner,
                    // response_destination: newAddress(0,0),
                    // forward_ton_amount: 0,
                    // forward_payload: emptySlice()
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    //forward_ton_amount: 0,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init_admin.code,
                data: init_admin.data
            });
        }
    }

    //这个消息本质上相当于接收到其他用户发送的Jetton会进入这个消息方法处理。
    receive(msg: TokenTransferInternal) { // 0x178d4519
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(msg.from, self.master);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        // Update balance
        self.balance = self.balance + msg.amount;
        require(self.balance >= 0, "Invalid balance"); 
        
        // Get value for gas
        let msg_value: Int = self.msg_value(ctx.value);  
        let fwd_fee: Int = ctx.readForwardFee();
        
         // 0x7362d09c - notify the new owner of JettonToken that the transfer is complete
        if (msg.forward_ton_amount > 0) { 
            msg_value = msg_value - msg.forward_ton_amount - fwd_fee;
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately + SendIgnoreErrors,
                bounce: false,
                 //这个是用户钱包合约的token通知消息,因为只是发一个消息给用户的钱包合约就可以了，方便在区块链浏览器上清晰看到这样一个处理过程。
                 //用户的钱包合约不需要对这个通知消息作任何的处理
                body: TokenNotification {   
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        // 0xd53276db -- Cashback to the original Sender
        if (msg.response_destination != null && msg_value > 0) { 
            send(SendParameters {
                to: msg.response_destination, 
                value: msg_value,  
                bounce: false,
                body: TokenExcesses { query_id: msg.query_id }.toCell(),
                mode: SendIgnoreErrors
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");  // Check sender

        self.balance = self.balance - msg.amount; // Update balance
        require(self.balance >= 0, "Invalid balance");

        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > fwd_fee + 2 * self.gasConsumption + self.minTonsForStorage, "Invalid value - Burn");

        // Burn tokens
        send(SendParameters{  
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                query_id: msg.query_id,
                amount: msg.amount,
                sender: self.owner,
                response_destination: msg.response_destination
            }.toCell()
        });
    }


    fun msg_value(value: Int): Int {
        let msg_value: Int = value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage);
        msg_value = msg_value - (storage_fee + self.gasConsumption);
        return msg_value;
    }

    bounced(msg: bounced<TokenTransferInternal>) {
        self.balance = self.balance + msg.amount;
        self.reply("TokenTransferInternal Occur error".asComment());
    }

    bounced(msg: bounced<TokenBurnNotification>) {
        self.balance = self.balance + msg.amount;
        self.reply("TokenBurnNotification Occur error".asComment());
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            code: (initOf JettonDefaultWallet(self.owner, self.master)).code,
            excludeFee: self.excludeFee,
            tradeFee: self.tradeFee
        };
    }
}