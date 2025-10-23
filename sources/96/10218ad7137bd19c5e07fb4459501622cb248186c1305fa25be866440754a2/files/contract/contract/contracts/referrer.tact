// ===================================== 
// 1. 导入依赖：标准库模块与自定义通用组件 
// ===================================== 
// 导入 Tact 标准库的「部署模块」（提供 Deployable trait 等部署相关工具） 
// 用于支持合约的部署逻辑 
import "@stdlib/deploy";

// 导入通用 trait 和消息结构（跨合约复用的基础组件） 
// import "./common/traits.tact";
// import "./common/messages.tact";
import "./common/address.tact";


// ===================================== 
// 2. 数据结构定义：推荐系统的核心数据模型 
// ===================================== 
// 推荐人统计数据结构体：记录推荐人的业绩指标
struct ReferrerStats {
    referredUserCount: Int as int257;  // 推荐的用户总数
    totalRewards: Int as int257;       // 累计获得的奖励
    lastRewardTime: Int as int257;     // 最后一次获得奖励的时间
}

// 用户推荐关系结构体：记录用户与其推荐人之间的绑定关系
struct UserReferral {
    referrer: Address;       // 推荐人地址
    referralTime: Int;       // 推荐时间（使用区块时间）
}


// ===================================== 
// 3. 消息类型定义：合约的外部接口规范 
// ===================================== 
// 绑定推荐人消息：用户设置自己的推荐人
message(0x12345678) BindReferrer {
    queryId: Int as uint64;  // 查询标识符：用于请求-响应匹配
    referrer: Address;       // 推荐人地址
}

// 添加奖励消息：为推荐人增加奖励（仅限所有者调用）
message(0x23456789) AddReward {
    queryId: Int as uint64;  // 查询标识符：用于请求-响应匹配
    referrer: Address;       // 推荐人地址
    amount: Int as coins;    // 奖励金额（以 TON 币为单位）
}

// 减少奖励消息：为推荐人减少奖励（仅限所有者调用）
message(0x78901234) RemoveReward {
    queryId: Int as uint64;  // 查询标识符：用于请求-响应匹配
    referrer: Address;       // 推荐人地址
    amount: Int as coins;    // 减少的奖励金额（以 TON 币为单位）
}

// GetUserReferrer已被改为get函数，不再需要消息类型定义

// 查询推荐人统计数据消息：获取推荐人的业绩统计
message(0x45678901) GetReferrerStats {
    queryId: Int as uint64;  // 查询标识符：用于请求-响应匹配
    referrer: Address;       // 要查询的推荐人地址
}


// ===================================== 
// 4. 响应消息定义：合约的返回数据格式 
// ===================================== 
// UserReferrerResponse响应消息已不再需要，因为GetUserReferrer已改为get函数

// 推荐人统计数据响应：返回推荐人的业绩指标
message(0x67890123) ReferrerStatsResponse {
    queryId: Int as uint64;  // 查询标识符：与请求匹配
    referredUserCount: Int;  // 推荐的用户总数
    totalRewards: Int;       // 累计获得的奖励
    lastRewardTime: Int;     // 最后一次获得奖励的时间
}


// ===================================== 
// 5. 推荐人合约：实现推荐系统核心逻辑 
// 功能：管理用户推荐关系、记录推荐统计、发放推荐奖励 
// 核心特性：支持推荐关系绑定、奖励发放、数据查询 
// ===================================== 
contract ReferrerContract with Deployable {  // 实现 Deployable trait，支持合约部署
    // 合约核心存储字段（持久化状态）
    userReferrers: map<Address, UserReferral>;  // 用户-推荐人映射
    referrerStats: map<Address, ReferrerStats>; // 推荐人-统计数据映射
    owner: Address;                             // 合约所有者地址（用于权限控制）

    // ------------------------------ 
    // 初始化函数：合约部署时执行，设置初始状态 
    // 参数：owner - 部署者地址（默认成为合约所有者） 
    // ------------------------------ 
    init(owner: Address) {
        self.owner = owner;  // 存储所有者地址，用于后续权限校验
    }

    // ------------------------------ 
    // 绑定推荐关系函数：用户设置自己的推荐人
    // 触发时机：用户发送 BindReferrer 类型消息时执行
    // 约束：用户只能绑定一次推荐人，且不能推荐自己
    // ------------------------------ 
    receive(msg: BindReferrer) {
        let user = sender();  // 获取消息发送者地址（即要绑定推荐人的用户）
        let referrer = msg.referrer;  // 获取推荐人地址
        
        // 检查用户是否已绑定推荐人
        if (self.userReferrers.get(user) != null) {
            // 错误码 1：用户已绑定推荐人
            send(SendParameters{
                to: sender(),
                value: 0,
                bounce: false,
                body: "Error: User already has a referrer".asComment(),
            });
            return;
        }
        
        // 检查不能推荐自己
        if (user == referrer) {
            // 错误码 2：不能推荐自己
            send(SendParameters{
                to: sender(),
                value: 0,
                bounce: false,
                body: "Error: Cannot refer yourself".asComment(),
            });
            return;
        }
        
        // 记录推荐关系 - 使用直接方式更新映射
        self.userReferrers.set(user, UserReferral {
            referrer: referrer,
            referralTime: now()  // 记录当前区块时间作为推荐时间
        });
        
        // 更新推荐人统计数据 - 使用直接方式更新映射
        let currentStats = self.referrerStats.get(referrer);
        let newStats: ReferrerStats = ReferrerStats { referredUserCount: 0, totalRewards: 0, lastRewardTime: 0 };
        
        if (currentStats == null) {
            // 首次推荐，初始化统计数据
            newStats = ReferrerStats {
                referredUserCount: 1,
                totalRewards: 0,
                lastRewardTime: 0
            };
        } else {
            // 已有推荐记录，更新统计数据
            newStats = ReferrerStats {
                referredUserCount: currentStats!!.referredUserCount + 1,
                totalRewards: currentStats!!.totalRewards,
                lastRewardTime: currentStats!!.lastRewardTime
            };
        }
        
        // 直接更新映射
        self.referrerStats.set(referrer, newStats);
        
        // 发送成功响应
        send(SendParameters{
            to: sender(),
            value: 0,
            bounce: false,
            body: "Referrer bound successfully".asComment(),
        });
    }

    // ------------------------------ 
    // 添加奖励函数：为推荐人增加奖励（仅限所有者调用）
    // 触发时机：所有者发送 AddReward 类型消息时执行
    // 功能：增加推荐人的累计奖励，并更新最后奖励时间
    // ------------------------------ 
    receive(msg: AddReward) {
        // 权限检查：只有合约所有者可以添加奖励
        if (sender() != self.owner) {
            // 错误码 3：只有所有者可以添加奖励
            send(SendParameters{
                to: sender(),
                value: 0,
                bounce: false,
                body: "Error: Only owner can add rewards".asComment(),
            });
            return;
        }
        
        let referrer = msg.referrer;  // 获取要奖励的推荐人地址
        let amount = msg.amount;      // 获取奖励金额
        
        let currentStats = self.referrerStats.get(referrer);
        let newStats: ReferrerStats = ReferrerStats { referredUserCount: 0, totalRewards: 0, lastRewardTime: 0 };
        
        if (currentStats == null) {
            // 如果推荐人没有统计数据，创建新记录
            newStats = ReferrerStats {
                referredUserCount: 0,
                totalRewards: amount,
                lastRewardTime: now()
            };
        } else {
            // 更新现有推荐人的奖励数据
            newStats = ReferrerStats {
                referredUserCount: currentStats!!.referredUserCount,
                totalRewards: currentStats!!.totalRewards + amount,
                lastRewardTime: now()
            };
        }
        
        self.referrerStats.set(referrer, newStats);
        
        // 发送成功响应
        send(SendParameters{
            to: sender(),
            value: 0,
            bounce: false,
            body: "Reward added successfully".asComment(),
        });
    }

    // ------------------------------ 
    // 减少奖励函数：为推荐人减少奖励（仅限所有者调用）
    // 触发时机：所有者发送 RemoveReward 类型消息时执行
    // 功能：减少推荐人的累计奖励，并更新最后奖励时间
    // ------------------------------ 
    receive(msg: RemoveReward) {
        // 权限检查：只有合约所有者可以减少奖励
        if (sender() != self.owner) {
            // 错误响应：只有所有者可以减少奖励
            send(SendParameters{
                to: sender(),
                value: 0,
                bounce: false,
                body: "Error: Only owner can remove rewards".asComment(),
            });
            return;
        }
        
        let referrer = msg.referrer;  // 获取要减少奖励的推荐人地址
        let amount = msg.amount;      // 获取减少的奖励金额
        
        // 检查减少金额是否为正数
        if (amount <= 0) {
            send(SendParameters{
                to: sender(),
                value: 0,
                bounce: false,
                body: "Error: Amount must be positive".asComment(),
            });
            return;
        }
        
        let currentStats = self.referrerStats.get(referrer);
        
        // 检查推荐人是否存在统计数据
        if (currentStats == null) {
            send(SendParameters{
                to: sender(),
                value: 0,
                bounce: false,
                body: "Error: Referrer not found".asComment(),
            });
            return;
        }
        
        // 检查奖励是否足够减少
        if (currentStats!!.totalRewards < amount) {
            send(SendParameters{
                to: sender(),
                value: 0,
                bounce: false,
                body: "Error: Insufficient rewards to remove".asComment(),
            });
            return;
        }
        // 更新现有推荐人的奖励数据
        let newStats: ReferrerStats = ReferrerStats { referredUserCount: 0, totalRewards: 0, lastRewardTime: 0 };
        newStats = ReferrerStats {
                referredUserCount: currentStats!!.referredUserCount,
                totalRewards: currentStats!!.totalRewards - amount,
                lastRewardTime: now()
            };
        // 更新统计数据：减少奖励金额，更新最后奖励时间
        // currentStats.totalRewards = currentStats!!.totalRewards - amount;
        // currentStats.lastRewardTime = now();
        
        // 保存更新后的统计数据
        self.referrerStats.set(referrer, newStats);
        
        // 成功响应
        send(SendParameters{
            to: sender(),
            value: 0,
            bounce: false,
            body: "Reward successfully removed".asComment(),
        });
    }

    // ------------------------------ 
    // 查询用户推荐人函数：获取特定用户的推荐人信息
    // 触发时机：调用get方法时执行
    // 返回：用户的推荐人地址（若未绑定则为空）
    // ------------------------------ 
    get fun getUserReferrer(user: Address): Address? {
        let referral = self.userReferrers.get(user);
        return referral == null ? null : referral!!.referrer;
    }

    // ------------------------------ 
    // 查询推荐人统计数据函数：获取推荐人的业绩指标
    // 触发时机：发送 GetReferrerStats 类型消息时执行
    // 返回：推荐的用户数、累计奖励、最后奖励时间
    // ------------------------------ 
    receive(msg: GetReferrerStats) {
        let referrer = msg.referrer;  // 获取要查询的推荐人地址
        let stats = self.referrerStats.get(referrer);
        
        // 发送响应消息
        send(SendParameters{
            to: sender(),
            value: 0,
            bounce: true,
            body: ReferrerStatsResponse {
                queryId: msg.queryId,
                referredUserCount: stats == null ? 0 : stats!!.referredUserCount,
                totalRewards: stats == null ? 0 : stats!!.totalRewards,
                lastRewardTime: stats == null ? 0 : stats!!.lastRewardTime
            }.toCell()
        });
    }

    // ------------------------------ 
    // 消息接收默认处理：处理未匹配的消息
    // 功能：接受任何转账但不做额外处理
    // ------------------------------ 
    receive() {
        // 接受任何转账但不做处理
    }

    // ------------------------------ 
    // 视图函数：获取合约版本（无副作用，仅返回数据）
    // 用途：外部查询合约当前版本
    // ------------------------------ 
    get fun version(): String {
        return "v1";  // 基础版版本标识
    }
    
    // ------------------------------ 
    // 获取所有推荐关系函数：返回系统中所有的推荐关系
    // 触发时机：调用get方法时执行
    // 返回：所有用户的推荐关系映射
    // ------------------------------ 
    // get fun getAllReferrals(): map<Address, UserReferral> {
    //     // 直接返回存储的所有推荐关系
    //     return self.userReferrers;
    // }
}

// // 部署配置
// deployer<ReferrerContract>({
//     params: [deployerAddress],
// });
    