import "@stdlib/ownable";
import "@stdlib/deploy";

// 定义消息操作码，遵循TEP-74 Jetton标准
const OP_TOKEN_NOTIFICATION: Int = 0x7362d09c; // Jetton转账通知
const OP_TOKEN_TRANSFER: Int = 0xf8a7ea5;    // Jetton转账请求

// 存储用户的存款记录
struct DepositRecord {
    user: Address;
    amount: Int as coins;
}

// 用户余额映射（用于嵌套映射的命名类型）
struct UserBalances {
    balances: map<Address, Int>;
}

// Jetton存款和提现合约
contract JettonDepositWithdraw with Deployable, Ownable {
    // 状态变量
    owner: Address;                     // 合约拥有者
    jetton_wallets: map<Address, Address>; // Jetton主合约地址到合约Jetton钱包地址的映射
    deposits: map<Address, UserBalances>; // Jetton主合约地址 -> 用户余额
    total_deposited: map<Address, Int>; // Jetton主合约地址 -> 总存款金额

    // 初始化函数，设置拥有者
    init(owner: Address) {
        self.owner = owner;
        self.jetton_wallets = emptyMap();
        self.deposits = emptyMap();
        self.total_deposited = emptyMap();
    }

    // 处理Jetton转账通知（存款）
    receive(msg: TokenNotification) {
        let ctx: Context = context();
        // 获取Jetton主合约地址（假设通过外部调用或 wallet 查询）
        let jetton_master: Address = msg.from; // 假设 msg.from 是 Jetton 钱包的 master 地址（需验证）
        let user: Address = msg.from; // 用户地址
        require(msg.queryId == 0, "Invalid query ID");
        require(msg.amount > 0, "Amount must be positive");

        // 验证 sender 是本合约的 Jetton 钱包
        let stored_wallet: Address? = self.jetton_wallets.get(jetton_master);
        if (stored_wallet == null) {
            // 首次存款，存储 Jetton 钱包地址
            self.jetton_wallets.set(jetton_master, ctx.sender);
        } else {
            require(ctx.sender == stored_wallet!!, "Invalid sender: not from Jetton wallet");
        }

        // 更新用户存款记录
        let user_balances: UserBalances? = self.deposits.get(jetton_master);
        let new_user_balances: map<Address, Int> = emptyMap();
        if (user_balances != null) {
            new_user_balances = user_balances!!.balances;
        }
        let current_balance: Int? = new_user_balances.get(user);
        let balance: Int = 0;
        if (current_balance == null) {
            balance = 0;
        } else {
            balance = current_balance!!;
        }
        new_user_balances.set(user, balance + msg.amount);
        self.deposits.set(jetton_master, UserBalances{balances: new_user_balances});

        // 更新总存款
        let total: Int? = self.total_deposited.get(jetton_master);
        let new_total: Int = 0;
        if (total == null) {
            new_total = 0;
        } else {
            new_total = total!!;
        }
        self.total_deposited.set(jetton_master, new_total + msg.amount);

        // 触发存款事件
        emit(DepositEvent{user: user, jetton_master: jetton_master, amount: msg.amount}.toCell());
    }

    // 仅限owner提取指定数量的Jetton代币
    receive(msg: WithdrawRequest) {
        let ctx: Context = context();
        // 验证调用者是owner
        require(ctx.sender == self.owner, "Only owner can withdraw");
        let jetton_master: Address = msg.jetton_master;
        let amount: Int = msg.amount;
        let jetton_wallet: Address? = self.jetton_wallets.get(jetton_master);
        require(jetton_wallet != null, "Jetton wallet not set for this token");
        require(amount > 0, "Withdraw amount must be positive");
        let total: Int? = self.total_deposited.get(jetton_master);
        let current_total: Int = 0;
        if (total == null) {
            current_total = 0;
        } else {
            current_total = total!!;
        }
        require(amount <= current_total, "Insufficient balance");

        // 构造Jetton转账消息
        let transfer_msg: TokenTransfer = TokenTransfer {
            queryId: 0,
            amount: amount,
            destination: self.owner,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"), // 支付少量TON作为转发费用
            forwardPayload: emptySlice()
        };

        // 发送转账请求到Jetton钱包
        send(SendParameters{
            to: jetton_wallet!!,
            value: ton("0.05"), // 支付交易费用
            mode: 64, // PayGasSeparately
            body: transfer_msg.toCell()
        });

        // 更新总存款
        self.total_deposited.set(jetton_master, current_total - amount);

        // 触发提现事件
        emit(WithdrawEvent{jetton_master: jetton_master, amount: amount}.toCell());
    }

    // 设置本合约的Jetton钱包地址（首次存款后由外部调用）
    receive("SetJettonWallet") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner can set Jetton wallet");
        let jetton_master: Address = ctx.sender; // 假设消息包含 Jetton 主合约地址
        require(self.jetton_wallets.get(jetton_master) == null, "Jetton wallet already set");

        let wallet: Address = ctx.sender; // 假设owner提供了正确的Jetton钱包地址
        self.jetton_wallets.set(jetton_master, wallet);
    }

    // 查询用户存款余额
    get fun get_balance(jetton_master: Address, user: Address): Int {
        let user_balances: UserBalances? = self.deposits.get(jetton_master);
        if (user_balances == null) {
            return 0;
        }
        let balance: Int? = user_balances!!.balances.get(user);
        if (balance == null) {
            return 0;
        }
        return balance!!;
    }

    // 查询总存款金额
    get fun get_total_deposited(jetton_master: Address): Int {
        let total: Int? = self.total_deposited.get(jetton_master);
        if (total == null) {
            return 0;
        }
        return total!!;
    }

    // 查询合约的Jetton钱包地址
    get fun get_jetton_wallet(jetton_master: Address): Address? {
        return self.jetton_wallets.get(jetton_master);
    }
}

// 定义Jetton转账通知消息结构（TEP-74）
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

// 定义Jetton转账消息结构（TEP-74）
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// 定义存款事件
message DepositEvent {
    user: Address;
    jetton_master: Address;
    amount: Int as coins;
}

// 定义提现请求消息
message WithdrawRequest {
    jetton_master: Address;
    amount: Int as coins;
}

// 定义提现事件
message WithdrawEvent {
    jetton_master: Address;
    amount: Int as coins;
}