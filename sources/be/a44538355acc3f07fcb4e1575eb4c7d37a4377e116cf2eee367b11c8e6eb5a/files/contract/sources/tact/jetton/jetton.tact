import "@stdlib/ownable";
import "./messages";
// ============================================================================================================ //
@interface("org.ton.jetton.master")
trait Jetton with Ownable {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;

    receive(msg: TokenUpdateContent){
        self.requireOwner(); // Allow changing content only by owner
        self.content = msg.content; // Update content
    }

    receive(msg: TokenBurnNotification){
        self.requireSenderAsWalletOwner(msg.sender, self.owner); // Check wallet
        self.total_supply = (self.total_supply - msg.amount); // Update supply
        if (msg.response_destination != null) {
            // Cashback
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: 0,
                    bounce: false,
                    mode: SendRemainingValue,
                    body: TokenExcesses{query_id: msg.query_id}.toCell()
                }
            );
        }
        emit(LogBurnEvent{masterAddr:myAddress(), owner: msg.sender, amount: msg.amount, receiver: msg.receiver}.toCell());
    }

    // https://github.com/ton-blockchain/TEPs/blob/master/text/0089-jetton-wallet-discovery.md
    receive(msg: ProvideWalletAddress){
        // 0x2c76b973
        require(context().value >= ton("0.0061"), "Insufficient gas");
        let init: StateInit = initOf JettonDefaultWallet(msg.owner_address, myAddress(), msg.owner_address);
        if (msg.include_address) {
            send(SendParameters{
                    to: sender(),
                    value: 0,
                    mode: SendRemainingValue,
                    body: TakeWalletAddress{
                        query_id: msg.query_id,
                        wallet_address: contractAddress(init),
                        owner_address: beginCell().storeBool(true).storeAddress(msg.owner_address).endCell().asSlice()
                    }.toCell()
                }
            );
        } else {
            send(SendParameters{
                    to: sender(),
                    value: 0,
                    mode: SendRemainingValue,
                    body: TakeWalletAddress{ // 0xd1735400
                        query_id: msg.query_id,
                        wallet_address: contractAddress(init),
                        owner_address: beginCell().storeBool(false).endCell().asSlice()
                    }.toCell()
                }
            );
        }
    }

    // Private Methods //
    // @to The Address receive the Jetton token after minting
    // @amount The amount of Jetton token being minted
    // @response_destination The previous owner address
    fun mint(to: Address, amount: Int, response_destination: Address, seqNo:Int, btcBridge: Address) {
        require(self.mintable, "Can't Mint Anymore");
        self.total_supply = (self.total_supply + amount); // Update total supply

        let winit: StateInit = self.getJettonWalletInit(to, btcBridge); // Create message
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    query_id: seqNo,
                    amount: amount,
                    from: myAddress(),
                    response_destination: response_destination,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    fun requireSenderAsWalletOwner(owner: Address, btcBridge: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner, btcBridge);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    virtual fun getJettonWalletInit(address: Address, btcBridge: Address): StateInit {
        return initOf JettonDefaultWallet(address, myAddress(), btcBridge);
    }

    // ====== Get Methods ====== //

    get fun get_jetton_data(): JettonData {
        return
            JettonData{
                total_supply: self.total_supply,
                mintable: self.mintable,
                owner: self.owner,
                content: self.content,
                wallet_code: initOf JettonDefaultWallet(self.owner, myAddress(), self.owner).code
            };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, myAddress(), self.owner));
    }
}

// ============================================================ //
@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet
{
    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");
//    const crossWithdrawFee: Int = ton("0.05");
    balance: Int as coins = 0;
    owner: Address;
    master: Address;
    btcBridge: Address;
    withdrawID:Int as uint64 = 0;
    withdrawIDProcessed:Int as uint64 = 0;
    withdrawInfo: map<Int, TokenBurn>; //只保存处于提币过程中的信息，一旦提币完成，则直接删除相关信息

    init(owner: Address, master: Address, btcBridge: Address){
        self.balance = 0;
        self.owner = owner;
        self.master = master;
        self.btcBridge = btcBridge;
    }

    receive(msg: TokenTransfer){
        dump("token transfer start");
        // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender");
        let final: Int =
            (((ctx.readForwardFee() * 2 + 2 * self.gasConsumption) + self.minTonsForStorage) + msg.forward_ton_amount); // Gas checks, forward_ton = 0.152
        dump(ctx.value);
        dump(final);
        require(ctx.value > final, "Invalid value");
        dump(self.balance);
        // Update balance
        self.balance = (self.balance - msg.amount);
        dump(self.balance);
        require(self.balance >= 0, "Invalid balance");
        let init: StateInit = initOf JettonDefaultWallet(msg.destination, self.master, self.btcBridge);
        let wallet_address: Address = contractAddress(init);
        send(SendParameters{
                to: wallet_address,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenTransferInternal{ // 0x178d4519
                    query_id: msg.query_id,
                    amount: msg.amount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
        dump("token transfer end");
    }

    receive(msg: TokenTransferInternal){
        dump("token transfer internal");
        // 0x178d4519
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(msg.from, self.master, self.btcBridge);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }
        // Update balance
        self.balance = (self.balance + msg.amount);
        dump(self.balance);
        require(self.balance >= 0, "Invalid balance");
        // Get value for gas
        let msg_value: Int = self.msg_value(ctx.value);
        let fwd_fee: Int = ctx.readForwardFee();
        if (msg.forward_ton_amount > 0) {
            msg_value = ((msg_value - msg.forward_ton_amount) - fwd_fee);
            send(SendParameters{
                    to: self.owner,
                    value: msg.forward_ton_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: TokenNotification{ // 0x7362d09c -- Remind the new Owner
                        query_id: msg.query_id,
                        amount: msg.amount,
                        from: msg.from,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }
            );
        }
        // 0xd53276db -- Cashback to the original Sender
        if (msg.response_destination != null && msg_value > 0) {
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: msg_value,
                    bounce: false,
                    body: TokenExcesses{query_id: msg.query_id}.toCell(),
                    mode: SendPayGasSeparately
                }
            );
        }
        dump("token transfer internal success");
    }

    receive(msg: TokenBurn){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender"); // Check sender
        require(msg.withdrawID == self.withdrawID+1, "Invalid withdrawID");
        require(self.balance >= msg.amount, "Invalid balance");
//        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        //to do: 提币费用从配置合约读取
//        require(ctx.value > ((fwd_fee + 2 * self.gasConsumption) + self.minTonsForStorage + self.crossWithdrawFee), "Invalid value - Burn");

        send(SendParameters{
            to: self.btcBridge,
            body: "queryWithDrawConfig".asComment(),
            value: ton("0.1"),              // pay for message and potential deployment
            mode: SendIgnoreErrors,
        });
        self.withdrawID += 1;
        self.withdrawInfo.set(self.withdrawID, msg);
    }

    receive(msg: WithDrawConfig){
        let ctx: Context = context();
        let tokenBurn:TokenBurn = self.withdrawInfo.get(self.withdrawIDProcessed + 1)!!;

        self.balance = (self.balance - tokenBurn.amount); // Update balance
        require(self.balance >= 0, "Invalid balance");
        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        //to do: 提币费用从配置合约读取
        require(myBalance() > ((fwd_fee + 2 * self.gasConsumption) + self.minTonsForStorage + msg.withdrawFee), "Invalid value - Burn");
        // Burn tokens
        send(SendParameters{
            to: self.master,
            value: (fwd_fee + 2 * self.gasConsumption),
            mode: SendIgnoreErrors,
            bounce: true,
            body: TokenBurnNotification{
                query_id: tokenBurn.withdrawID,
                amount: tokenBurn.amount,
                sender: self.owner,
                response_destination: tokenBurn.response_destination,
                receiver: tokenBurn.receiver,
            }.toCell()
        });

        send(SendParameters{
            bounce: false,
            to: msg.feeReceiver,
            value: msg.withdrawFee,
            mode: SendIgnoreErrors,
        });
        self.withdrawIDProcessed = +1;
        self.withdrawInfo.del(self.withdrawIDProcessed);
    }

//    receive(msg: TokenBurn){
//        let ctx: Context = context();
//        require(ctx.sender == self.owner, "Invalid sender"); // Check sender
//        require(msg.withdrawID == self.withdrawID+1, "Invalid withdrawID");
//
//
//
//        self.balance = (self.balance - msg.amount); // Update balance
//        require(self.balance >= 0, "Invalid balance");
//        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
//        //to do: 提币费用从配置合约读取
//        require(ctx.value > ((fwd_fee + 2 * self.gasConsumption) + self.minTonsForStorage + self.crossWithdrawFee), "Invalid value - Burn");
//        // Burn tokens
//        send(SendParameters{
//        to: self.master,
//        value: 0,
//        mode: SendRemainingValue,
//        bounce: true,
//        body: TokenBurnNotification{
//        query_id: msg.query_id,
//        amount: msg.amount,
//        sender: self.owner,
//        response_destination: msg.response_destination,
//        receiver: msg.receiver,
//        }.toCell()
//        }
//        );
//    }

    fun msg_value(value: Int): Int {
        let msg_value_tmp: Int = value;
        let ton_balance_before_msg: Int = (myBalance() - msg_value_tmp);
        let storage_fee: Int = (self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage));
        msg_value_tmp = (msg_value_tmp - (storage_fee + self.gasConsumption));
        return msg_value_tmp;
    }

    bounced(msg: bounced<TokenTransferInternal>){
        self.balance = (self.balance + msg.amount);
    }

    bounced(msg: bounced<TokenBurnNotification>){
        self.balance = (self.balance + msg.amount);
    }

    get fun get_wallet_data(): JettonWalletData {
        return
            JettonWalletData{
                balance: self.balance,
                owner: self.owner,
                master: self.master,
                code: initOf JettonDefaultWallet(self.owner, self.master, self.btcBridge).code
            };
    }

    get fun get_withdraw_id(): Int {
        return self.withdrawID;
    }

    get fun get_withdraw_id_processed(): Int {
        return self.withdrawIDProcessed;
    }
}