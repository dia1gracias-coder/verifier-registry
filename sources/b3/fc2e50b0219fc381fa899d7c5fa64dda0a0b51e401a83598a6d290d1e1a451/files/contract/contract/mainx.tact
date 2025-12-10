import "@stdlib/deploy";
import "@stdlib/ownable";

// ==================== 结构体定义 ====================

struct TokenData {
    name: String;
    symbol: String;
    decimals: Int;
}

struct VestingData {
    startTime: Int;
    duration: Int;
    cliff: Int;
}

// Jetton 标准数据结构
struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

struct WalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

// ==================== 代币基础消息结构 ====================

// Jetton标准消息 - 内部转账
message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;           // 查询ID
    amount: Int as coins;              // 转账金额
    from: Address;                     // 发送者地址
    responseAddress: Address?;         // 响应地址
    forwardTonAmount: Int as coins;    // 转发的TON金额
    forwardPayload: Slice as remaining; // 转发的载荷
}

// Jetton标准消息 - 转账
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;            // 查询ID
    amount: Int as coins;               // 转账金额
    destination: Address;               // 目标地址
    responseAddress: Address;           // 响应地址
    customPayload: Cell?;               // 自定义载荷
    forwardTonAmount: Int as coins;     // 转发的TON金额
    forwardPayload: Slice as remaining; // 转发的载荷
}

// Jetton标准消息 - 销毁代币
message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;             // 查询ID
    amount: Int as coins;                // 销毁金额
    responseAddress: Address;            // 响应地址
    customPayload: Cell?;                // 自定义载荷
}

// Jetton标准消息 - 转账通知（TEP-74）
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;             // 查询ID
    amount: Int as coins;               // 转账金额
    sender: Address;                    // 发送者地址
    forwardPayload: Slice as remaining; // 转发的载荷
}

// Jetton标准消息 - 多余的 TON 退款（TEP-74）
message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;             // 查询ID
}

// ==================== 自定义管理消息 ====================

// 用积分兑换代币消息
message RedeemPoints {
    queryId: Int as uint64;             // 查询ID
    points: Int as uint64;              // 兑换的积分数量
    recipient: Address;                 // 接收代币的地址
}

// 铸造代币消息（仅管理员）
message Mint {
    queryId: Int as uint64;             // 查询ID
    amount: Int as coins;                // 铸造数量
    recipient: Address;                  // 接收者地址
}

// 更新兑换率消息（仅管理员）
message UpdateExchangeRate {
    queryId: Int as uint64;             // 查询ID
    newRate: Int as uint64;             // 新的兑换率（多少积分兑换1个代币）
}

// 暂停/恢复合约消息（仅管理员）
message SetPaused {
    queryId: Int as uint64;             // 查询ID
    paused: Bool;                        // 是否暂停
}

// 设置交易权限消息（仅管理员）
message SetTransferEnabled {
    queryId: Int as uint64;             // 查询ID
    enabled: Bool;                       // 是否允许交易
}

// 添加白名单地址（仅管理员）
message AddWhitelist {
    queryId: Int as uint64;             // 查询ID
    address: Address;                    // 要添加的地址
}

// 移除白名单地址（仅管理员）
message RemoveWhitelist {
    queryId: Int as uint64;             // 查询ID
    address: Address;                    // 要移除的地址
}

// 设置释放参数（仅管理员）
message SetVestingParams {
    queryId: Int as uint64;             // 查询ID
    startTime: Int as uint32;           // 释放开始时间
    duration: Int as uint32;            // 释放持续时间（秒）
    cliffDuration: Int as uint32;       // 锁定期（秒）
}

// ==================== 主代币合约 ====================

contract TokenMaster with Deployable, Ownable {
    
    // ===== 基础代币信息 =====
    owner: Address;                     // 合约所有者
    totalSupply: Int as coins;          // 总供应量
    mintable: Bool;                     // 是否可铸造
    name: String;                       // 代币名称
    symbol: String;                     // 代币符号
    decimals: Int as uint8;             // 代币精度
    
    // ===== 兑换系统 =====
    exchangeRate: Int as uint64;        // 积分兑换率（多少积分兑换1个代币，精度18位）
    totalPointsRedeemed: Int as uint64; // 已兑换的总积分数
    
    // ===== 权限控制 =====
    paused: Bool;                       // 合约是否暂停
    transferEnabled: Bool;              // 是否允许代币转账
    whitelist: map<Address, Bool>;      // 白名单地址映射
    
    // ===== 线性释放参数 =====
    vestingStartTime: Int as uint32;    // 释放开始时间戳
    vestingDuration: Int as uint32;     // 释放持续时间（秒）
    vestingCliff: Int as uint32;        // 锁定期（秒）
    
    // ===== 用户钱包映射 =====
    walletCode: Cell;                   // 钱包合约代码
    jettonContent: Cell;                // Jetton metadata content (存储在合约中)
    
    // 初始化合约
    // 修改：接受 content Cell 参数，这样可以通过 Blueprint 传入正确的 metadata
    init(owner: Address, name: String, symbol: String, content: Cell) {
        self.owner = owner;
        self.totalSupply = 0;
        self.mintable = true;
        self.name = name;
        self.symbol = symbol;
        self.decimals = 9;  // TON标准精度
        
        // 初始兑换率：1000积分 = 1个代币（1e9最小单位）
        self.exchangeRate = 1000;
        self.totalPointsRedeemed = 0;
        
        // 默认权限设置
        self.paused = false;
        self.transferEnabled = false;  // 默认关闭转账，需要管理员开启
        
        // 线性释放参数（默认值，需要管理员设置）
        self.vestingStartTime = 0;
        self.vestingDuration = 31536000;  // 默认1年（365天）
        self.vestingCliff = 2592000;      // 默认锁定30天
        
        // 初始化钱包代码
        self.walletCode = initOf TokenWallet(myAddress(), owner).code;
        
        // 使用传入的 content Cell
        // 这个 Cell 应该由 Blueprint 脚本使用正确的 TEP-64 格式构建
        self.jettonContent = content;
    }
    
    // ===== 接收消息处理 =====
    
    // 处理积分兑换请求
    receive(msg: RedeemPoints) {
        let ctx: Context = context();
        let incoming: Int = ctx.value;
        
        // 检查合约是否暂停
        require(!self.paused, "Contract is paused");
        
        // 检查兑换率是否设置
        require(self.exchangeRate > 0, "Exchange rate not set");
        
        // 计算可兑换的代币数量（积分 * 1e9 / 兑换率）
        let tokenAmount: Int = (msg.points * 1000000000) / self.exchangeRate;
        
        // 检查是否有足够的代币可供兑换
        require(tokenAmount > 0, "Invalid points amount");
        
        // 更新已兑换的积分总数
        self.totalPointsRedeemed = self.totalPointsRedeemed + msg.points;
        
        // 使用用户发送的 value 来支付钱包部署
        let walletValue: Int = ton("0.05");
        self._mint(msg.recipient, tokenAmount, walletValue);
        
        // 退还多余的传入 value（_mint 使用了 0.05 TON）
        let tonFee: Int = ton("0.01"); // 保留少量作为交易费用
        let refund: Int = incoming - walletValue - tonFee;
        if (refund > 0) {
            send(SendParameters{
                to: ctx.sender,
                value: refund,
                mode: SendIgnoreErrors,
                bounce: false,
                body: TokenExcesses{ queryId: msg.queryId }.toCell()
            });
        }
    }
    
    // 处理铸造请求（仅管理员）
    receive(msg: Mint) {
        let ctx: Context = context();
        let incoming: Int = ctx.value;
        
        // 检查调用者是否为管理员
        self.requireOwner();
        
        // 检查合约是否暂停
        require(!self.paused, "Contract is paused");
        
        // 检查是否可铸造
        require(self.mintable, "Minting is disabled");
        
        // 铸造代币（使用用户发送的 value）
        let walletValue: Int = ton("0.02");
        self._mint(msg.recipient, msg.amount, walletValue);
        
        // 退还多余的传入 value
        let usedForWallet: Int = walletValue;
        let tonFee: Int = ton("0.01");
        let refund: Int = incoming - usedForWallet - tonFee;
        if (refund > 0) {
            send(SendParameters{
                to: ctx.sender,
                value: refund,
                mode: SendIgnoreErrors,
                bounce: false
            });
        }
    }
    
    // 更新兑换率（仅管理员）
    receive(msg: UpdateExchangeRate) {
        self.requireOwner();
        require(msg.newRate > 0, "Invalid exchange rate");
        self.exchangeRate = msg.newRate;
    }
    
    // 暂停/恢复合约（仅管理员）
    receive(msg: SetPaused) {
        self.requireOwner();
        self.paused = msg.paused;
    }
    
    // 设置转账权限（仅管理员）
    receive(msg: SetTransferEnabled) {
        self.requireOwner();
        self.transferEnabled = msg.enabled;
    }
    
    // 添加白名单（仅管理员）
    receive(msg: AddWhitelist) {
        self.requireOwner();
        self.whitelist.set(msg.address, true);
    }
    
    // 移除白名单（仅管理员）
    receive(msg: RemoveWhitelist) {
        self.requireOwner();
        self.whitelist.set(msg.address, null); // 使用 null 删除键
    }
    
    // 设置线性释放参数（仅管理员）
    receive(msg: SetVestingParams) {
        self.requireOwner();
        self.vestingStartTime = msg.startTime;
        self.vestingDuration = msg.duration;
        self.vestingCliff = msg.cliffDuration;
    }
    
    // 接收普通 TON 转账（空接收器）
    // 修复问题1：TokenMaster 可以接受来自 faucet 的 TON
    receive() {
        // 接受 TON，用于合约运营和 gas 费用
    }
    
    // ===== 内部函数 =====
    
    // 内部铸造函数（使用调用者提供的 value）
    fun _mint(to: Address, amount: Int, value: Int) {
        // 更新总供应量
        self.totalSupply = self.totalSupply + amount;
        
        // 获取或创建用户钱包
        let walletInit: StateInit = initOf TokenWallet(myAddress(), to);
        let walletAddress: Address = contractAddress(walletInit);
        
        // 向钱包发送内部转账消息（使用传入的 value）
        send(SendParameters{
            to: walletAddress,
            value: value,  // 使用传入的 value 而非合约余额
            mode: SendIgnoreErrors,
            bounce: false,
            body: TokenTransferInternal{
                queryId: 0,
                amount: amount,
                from: myAddress(),
                responseAddress: to,
                forwardTonAmount: 0,
                forwardPayload: emptySlice()
            }.toCell(),
            code: walletInit.code,
            data: walletInit.data
        });
    }
    
    // ===== Get方法（查询函数） =====
    
    // 获取代币总供应量
    get fun totalSupply(): Int {
        return self.totalSupply;
    }
    
    // 获取代币信息 - 修复：返回 Struct
    get fun tokenInfo(): TokenData {
        return TokenData{
            name: self.name,
            symbol: self.symbol,
            decimals: self.decimals
        };
    }
    
    // 获取兑换率
    get fun exchangeRate(): Int {
        return self.exchangeRate;
    }
    
    // 获取已兑换的总积分
    get fun totalPointsRedeemed(): Int {
        return self.totalPointsRedeemed;
    }
    
    // 检查合约是否暂停
    get fun isPaused(): Bool {
        return self.paused;
    }
    
    // 检查转账是否启用
    get fun isTransferEnabled(): Bool {
        return self.transferEnabled;
    }
    
    // 检查地址是否在白名单中
    get fun isWhitelisted(address: Address): Bool {
        return self.whitelist.get(address) != null;
    }
    
    // 获取释放参数 - 修复：返回 Struct
    get fun vestingParams(): VestingData {
        return VestingData{
            startTime: self.vestingStartTime,
            duration: self.vestingDuration,
            cliff: self.vestingCliff
        };
    }
    
    // 获取用户钱包地址
    get fun walletAddress(owner: Address): Address {
        let walletInit: StateInit = initOf TokenWallet(myAddress(), owner);
        return contractAddress(walletInit);
    }
    
    // 计算当前可释放的代币比例（0-10000，表示0%-100%）
    get fun calculateVestedPercentage(currentTime: Int): Int {
        // 如果还未开始释放
        if (currentTime < self.vestingStartTime) {
            return 0;
        }
        
        // 如果还在锁定期内
        if (currentTime < self.vestingStartTime + self.vestingCliff) {
            return 0;
        }
        
        // 计算从开始释放到现在的时间
        let elapsed: Int = currentTime - self.vestingStartTime;
        
        // 如果已经完全释放
        if (elapsed >= self.vestingDuration) {
            return 10000;  // 100%
        }
        
        // 计算线性释放比例
        return (elapsed * 10000) / self.vestingDuration;
    }
    
    // ===== Jetton 标准方法 =====
    
    // 获取 Jetton 数据（Tonkeeper 等钱包需要）
    // 符合 TEP-74 标准
    get fun get_jetton_data(): JettonData {
        // 直接返回存储的 content
        // content 在 init() 时已经构建好了
        return JettonData{
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            owner: self.owner,
            content: self.jettonContent,  // 使用存储的 content
            walletCode: self.walletCode
        };
    }
}

// ==================== 用户钱包合约 ====================

contract TokenWallet {
    
    master: Address;           // 主合约地址
    owner: Address;            // 钱包所有者
    balance: Int as coins;     // 钱包余额
    
    // 初始化钱包
    init(master: Address, owner: Address) {
        self.master = master;
        self.owner = owner;
        self.balance = 0;
    }
    
    // 接收内部转账 - 符合 TEP-74 标准
    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        
        if (ctx.sender == self.master) {
            // 1. 来自主合约的铸造
            self.balance = self.balance + msg.amount;
        } else {
            // 2. 来自其他钱包的转账 - 验证发送者
            let sinit: StateInit = initOf TokenWallet(self.master, msg.from);
            let expectedSender: Address = contractAddress(sinit);
            require(ctx.sender == expectedSender, "Invalid sender");
            
            self.balance = self.balance + msg.amount;
        }
        
        // TEP-74 标准：处理 forward_ton_amount（转发通知）
        if (msg.forwardTonAmount > 0) {
            send(SendParameters{
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: TokenNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }
        
        // TEP-74 标准：退还剩余 TON 给 response_address
        if (msg.responseAddress != null) {
            // 计算需要保留的最小 TON（用于存储和 gas）
            let minStorage: Int = ton("0.01");
            let forwardCost: Int = msg.forwardTonAmount;
            let gasFee: Int = ton("0.008");  // 预留 gas 费用
            
            let totalCost: Int = minStorage + forwardCost + gasFee;
            
            // 如果有剩余，发送 excesses 消息退款
            if (msgValue > totalCost) {
                send(SendParameters{
                    to: msg.responseAddress!!,
                    value: 0,
                    mode: SendRemainingValue,  // 使用 mode 64：发送剩余价值
                    bounce: false,
                    body: TokenExcesses{
                        queryId: msg.queryId
                    }.toCell()
                });
            }
        }
    }
    
    // 处理转账请求
    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        
        // 只有所有者可以发起转账
        require(ctx.sender == self.owner, "Only owner can transfer");
        
        // 检查余额是否足够
        require(self.balance >= msg.amount, "Insufficient balance");
        
        // 扣除余额
        self.balance = self.balance - msg.amount;
        
        // 发送给目标钱包
        let walletInit: StateInit = initOf TokenWallet(self.master, msg.destination);
        send(SendParameters{
            to: contractAddress(walletInit),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                responseAddress: msg.responseAddress,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: walletInit.code,
            data: walletInit.data
        });
    }
    
    // 处理销毁请求
    receive(msg: TokenBurn) {
        let ctx: Context = context();
        
        // 只有所有者可以销毁
        require(ctx.sender == self.owner, "Only owner can burn");
        
        // 检查余额是否足够
        require(self.balance >= msg.amount, "Insufficient balance");
        
        // 扣除余额
        self.balance = self.balance - msg.amount;
        
        // 这里可以通知主合约更新总供应量
    }
    
    // 接收普通 TON 转账（空接收器）
    // 用于接受来自 faucet 或其他来源的 TON，用于支付 gas
    receive() {
        // 什么都不做，只是接受 TON
        // 这些 TON 会增加合约余额，用于未来的 gas 费用
    }
    
    // ===== Get方法 =====
    
    // 获取钱包余额
    get fun balance(): Int {
        return self.balance;
    }
    
    // 获取钱包所有者
    get fun owner(): Address {
        return self.owner;
    }
    
    // 获取主合约地址
    get fun master(): Address {
        return self.master;
    }
    
    // 计算可用余额（考虑线性释放）
    get fun availableBalance(currentTime: Int): Int {
        // TODO: 从主合约获取释放参数并计算
        // 这里暂时返回全部余额
        return self.balance;
    }
    
    // ===== Jetton 标准方法 =====
    
    // 获取钱包数据（Tonkeeper 等钱包需要）
    get fun get_wallet_data(): WalletData {
        let walletInit: StateInit = initOf TokenWallet(self.master, self.owner);
        return WalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: walletInit.code
        };
    }
}
