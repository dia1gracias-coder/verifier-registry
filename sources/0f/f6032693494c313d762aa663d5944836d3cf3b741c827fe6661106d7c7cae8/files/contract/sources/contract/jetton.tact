import "@stdlib/ownable";
import "./messages";
// ============================================================================================================ //
@interface("org.ton.jetton.master")
trait Jetton with Ownable {
    total_supply: Int; // 总供应量
    mintable: Bool; // 是否可以铸币
    owner: Address; // 所有者
    content: Cell; // metadata 元数据

    // 接收更新消息
    receive(msg: TokenUpdateContent){
        self.requireOwner(); // Allow changing content only by owner 仅允许所有者修改内容
        self.content = msg.content; // Update content （代币名称等）
    }

    // 接收销毁消息
    receive(msg: TokenBurnNotification){
        self.requireSenderAsWalletOwner(msg.response_destination!!); // Check wallet  检查钱包所有者是否为发送者
        self.total_supply = (self.total_supply - msg.amount); // Update supply 总供应量减少
        if (msg.response_destination != null) {
            // Cashback
            send(SendParameters{
                    to: msg.response_destination!!, // 发送消息给发送者，通知销毁成功
                    value: 0,
                    bounce: false,
                    mode: SendRemainingValue,
                    body: TokenExcesses{query_id: msg.query_id}.toCell()
                }
            );
        }
    }

    // https://github.com/ton-blockchain/TEPs/blob/master/text/0089-jetton-wallet-discovery.md
    receive(msg: ProvideWalletAddress){
        // 0x2c76b973
        require(context().value >= ton("0.0061"), "Insufficient gas");
        let init: StateInit = initOf JettonDefaultWallet(msg.owner_address, myAddress());
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
    // @to The Address receive the Jetton token after minting 接收铸币后的master代币地址
    // @amount The amount of Jetton token being minted 铸币数量
    // @response_destination The previous owner address 铸币前所有者的地址
    fun mint(to: Address, amount: Int, response_destination: Address) {
        require(self.mintable, "Can't Mint Anymore"); // 检查是否可以铸币
        self.total_supply = (self.total_supply + amount); // Update total supply 当前供应+增加供应量

        let winit: StateInit = self.getJettonWalletInit(to); // Create message
        send(SendParameters{
                to: contractAddress(winit),
                value: 0,
                bounce: true,
                mode: SendRemainingValue,
                body: TokenTransferInternal{
                    query_id: 0,
                    amount: amount,
                    from: myAddress(), //从当前合约地址发送
                    response_destination: response_destination,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell(),
                code: winit.code,
                data: winit.data
            }
        );
    }

    // 权限检查，当前发送者是否为钱包所有者

    fun requireSenderAsWalletOwner(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    //  master 钱包状态初始化

    virtual fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonDefaultWallet(address, myAddress());
    }

    // ====== Get Methods ====== // 获取代币信息

    get fun get_jetton_data(): JettonData {
        return
            JettonData{
                total_supply: self.total_supply,
                mintable: self.mintable,
                owner: self.owner,
                content: self.content,
                wallet_code: initOf JettonDefaultWallet(self.owner, myAddress()).code
            };
    }
    // 获取钱包地址

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(initOf JettonDefaultWallet(owner, myAddress()));
    }
}

// 子钱包合约
// ============================================================ //
@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet
{
    const minTonsForStorage: Int = ton("0.019"); //gas消耗
    const gasConsumption: Int = ton("0.013");
    balance: Int as coins = 0; // 余额
    owner: Address; // 当前所有者地址
    master: Address; // master 代币合约地址

    // owner 转给目标的地址
    // master 代币合约地址
    init(owner: Address, master: Address){
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    // // 向外转账
    receive(msg: TokenTransfer){
        // msg.amount = 20;
        // 0xf8a7ea5
        let ctx: Context = context(); // Check sender
        require(ctx.sender == self.owner, "Invalid sender"); //检查权限，钱包所有者发消息转账给别人

        // 根据0074标准的公式，计算gas是否符合要求
        let final: Int =
            (((ctx.readForwardFee() * 2 + 2 * self.gasConsumption) + self.minTonsForStorage) + msg.forward_ton_amount); // Gas checks, forward_ton = 0.152
        require(ctx.value > final, "Invalid value");
        // Update balance
        // 发送转账：子钱包往外转账，减少余额
        self.balance = (self.balance - msg.amount);
        require(self.balance >= 0, "Invalid balance"); //判断是否溢出
        // 转账目标地址，master代币合约地址
        let init: StateInit = initOf JettonDefaultWallet(msg.sender, self.master);
        let wallet_address: Address = contractAddress(init); // 计算出目标子钱包代币地址
        send(SendParameters{
                to: wallet_address,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: TokenTransferInternal{ // 0x178d4519 // 发送转账成功消息
                    query_id: msg.query_id,
                    amount: msg.amount, //
                    from: self.owner, // 转账者
                    response_destination: msg.response_destination, // 转账成功后的回调地址
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload // 转账附加信息
                }.toCell(),
                code: init.code,
                data: init.data
            }
        );
    }

    // 接收转账消息
    receive(msg: TokenTransferInternal){
        // 0x178d4519
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf JettonDefaultWallet(msg.from, self.master);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!"); // 判断master地址和发送者是否一致
        }
        // 接收代币
        // Update balance
        self.balance = (self.balance + msg.amount);
        require(self.balance >= 0, "Invalid balance");
        // Get value for gas
        let msg_value: Int = self.msg_value(ctx.value);
        let fwd_fee: Int = ctx.readForwardFee();
        if (msg.forward_ton_amount > 0) {
            msg_value = ((msg_value - msg.forward_ton_amount) - fwd_fee);
            send(SendParameters{
                    to: self.owner, // 发送给收款人收款消息
                    value: msg.forward_ton_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: TokenNotification{ // 0x7362d09c -- Remind the new Owner
                        query_id: msg.query_id,
                        amount: msg.amount, // 收到金额
                        from: msg.from,
                        forward_payload: msg.forward_payload // 自定义转账附加信息
                    }.toCell()
                }
            );
        }
        // 给转账发起人消息
        // 0xd53276db -- Cashback to the original Sender
        if (msg.response_destination != null && msg_value > 0) {
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: msg_value, // 退还剩余的钱
                    bounce: false,
                    body: TokenExcesses{query_id: msg.query_id}.toCell(),
                    mode: SendPayGasSeparately
                }
            );
        }
    }

    // token销毁
    receive(msg: TokenBurn){
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender"); // Check sender 只能是自己发起消息才能销毁

        self.balance = (self.balance - msg.amount); // Update balance
        require(self.balance >= 0, "Invalid balance");
        let fwd_fee: Int = ctx.readForwardFee(); // Gas checks
        require(ctx.value > ((fwd_fee + 2 * self.gasConsumption) + self.minTonsForStorage), "Invalid value - Burn");
        // Burn tokens
        send(SendParameters{
                to: self.master, // 发送给master合约消息
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: TokenBurnNotification{
                    query_id: msg.query_id,
                    amount: msg.amount, //销毁了多少代币
                    sender: self.owner,
                    response_destination: msg.response_destination!!
                }.toCell()
            }
        );
    }

    fun msg_value(value: Int): Int {
        let msg_value: Int = value;
        let ton_balance_before_msg: Int = (myBalance() - msg_value);
        let storage_fee: Int = (self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage));
        msg_value = (msg_value - (storage_fee + self.gasConsumption));
        return msg_value;
    }

    // 转账失败回弹消息，将金额加回

    bounced(msg: bounced<TokenTransferInternal>){
        self.balance = (self.balance + msg.amount);
    }

    // 销毁失败回弹消息
    bounced(msg: bounced<TokenBurnNotification>){
        self.balance = (self.balance + msg.amount);
    }

    // 放回当前账户余额，当前子钱包地址，master合约地址
    get fun get_wallet_data(): JettonWalletData {
        return
            JettonWalletData{
                balance: self.balance,
                owner: self.owner,
                master: self.master,
                code: initOf JettonDefaultWallet(self.owner, self.master).code
            };
    }
}