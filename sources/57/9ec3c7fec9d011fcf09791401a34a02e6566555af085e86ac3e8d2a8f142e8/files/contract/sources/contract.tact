/**
 * @title SubscriptionContract
 * @author @n1203
 * 1. User can pay for the service
 * 2. User can check membership with the contract
 * 3. Owner can change the price of the service
 * 4. Owner can withdraw the balance
 * 5. Membership support pay cycle control, just for the one month or one year or one quarter, etc.
 * 6. Membership support free trial, just for the one day or one week or one month, etc.
 */

import "@stdlib/deploy";

// 订阅周期枚举
message SubscriptionPeriod {
    period: Int as uint32; // 以秒为单位的订阅周期
}

// 修改价格消息
message UpdatePrice {
    newPrice: Int as coins; // 新的订阅价格
}

// 提现消息
message Withdraw {
    amount: Int as coins; // 提现金额
}

// 订阅消息
message Subscribe {}

contract SubscriptionContract with Deployable {
    owner: Address; // 合约拥有者
    price: Int as coins; // 订阅价格
    balance: Int as coins; // 合约余额
    
    // 用户订阅信息映射
    subscriptions: map<Address, Int>; // 地址 => 到期时间戳
    
    // 免费试用期(一周)
    const TRIAL_PERIOD: Int = 7 * 24 * 60 * 60; // 7天(秒)
    
    init(owner: Address) {
        self.owner = owner;
        self.price = ton("1"); // 默认1 TON
        self.balance = 0;
    }

    // 检查发送者是否为合约拥有者
    fun requireOwner() {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner can call");
    }

    // 更新订阅价格
    receive(msg: UpdatePrice) {
        self.requireOwner();
        require(msg.newPrice > 0, "Price must be greater than 0");
        self.price = msg.newPrice;
    }

    // 提现合约余额
    receive(msg: Withdraw) {
        self.requireOwner();
        require(msg.amount <= self.balance, "Balance is not enough");
        self.balance = self.balance - msg.amount;
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendIgnoreErrors
        });
    }
    // 订阅服务
    receive(msg: Subscribe) {
        let ctx: Context = context();
        let sender: Address = ctx.sender;
        
        // 检查支付金额
        require(ctx.value >= self.price, "Payment amount is not enough");
        
        // 更新合约余额
        self.balance = self.balance + ctx.value;
        
        // 获取当前时间戳
        let now: Int = now();
        
        // 如果是新用户且从未使用过免费试用
        if (self.subscriptions.get(sender) == null) {
            // 设置试用期结束时间
            self.subscriptions.set(sender, now + self.TRIAL_PERIOD);
            self.reply("Free trial has started".asComment());
            return;
        }
        
        // 更新订阅到期时间
        let currentExpiry: Int = self.subscriptions.get(sender)!!;
        // 计算订阅时长 - 1个月(30天)
        let subscriptionPeriod: Int = 30 * 24 * 60 * 60; // 30天转换为秒
        let newExpiry: Int = max(currentExpiry, now) + subscriptionPeriod;
        self.subscriptions.set(sender, newExpiry);
        
        self.reply("Subscription successful".asComment());
    }

    // 检查用户订阅状态
    get fun checkSubscription(user: Address): Bool {
        let expiry: Int? = self.subscriptions.get(user);
        if (expiry == null) {
            return false;
        }
        return expiry!! > now();
    }

    // 获取用户订阅到期时间
    get fun getExpiryTime(user: Address): Int {
        let expiry: Int? = self.subscriptions.get(user);
        return expiry!!; // 修复了这里的语法错误,使用!!而不是??
    }

    // 获取当前订阅价格
    get fun getPrice(): Int {
        return self.price;
    }

    // 获取合约余额
    get fun getBalance(): Int {
        return self.balance;
    }
}
