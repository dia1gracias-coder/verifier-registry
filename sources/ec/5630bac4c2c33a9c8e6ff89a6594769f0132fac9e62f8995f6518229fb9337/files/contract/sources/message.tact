
// 订单状态枚举（统一状态码）
// 0=待发起签约/待支付, 1=待卖方确认签约并支付, 2=待买家确认签约并支付, 3=待卖家交付/待发货, 10=待验收/待收货, 12=订单完成, -1=已取消 

// 退款和解约通过refundFlag字段单独处理：0=无,1=申请中,2=已退款


// 订单信息结构 - 统一押金概念
struct OrderInfo {
    orderId: Int as uint64;                    // 订单编号
    objType: Int as uint8;              // 类型：0=商品，1=任务
    
    // 金额信息（统一押金概念）
    orderAmount: Int as coins;         // 真正的赏金或者商品金额（USDT最小单位）
    price: Int as coins;               // 最开始的商品/任务价格
    buyerDeposit: Int as coins;        // 买方押金（商品订单=商品价格，任务订单=雇主押金）
    sellerDeposit: Int as coins;       // 卖方押金（商品订单=0，任务订单=服务方押金）
    buyerDepositPaid: Int as coins;    // 买方已支付押金
    sellerDepositPaid: Int as coins;   // 卖方已支付押金
    settlementType: Int as uint8;        // 结算方式：0=平台保证金结算，1=私下结算
    
    // 状态信息
    status: Int as int8;                // 订单状态（支持负数）
    
    
    // 参与方
    buyerAddress: Address;              // 买方钱包地址（商品订单买方，任务订单雇主）
    sellerAddress: Address;             // 卖方钱包地址（商品订单卖方，任务订单服务方）
    
    // 时间戳
    createTime:  Int as uint32;        // 创建时间
    sellerPayTime:  Int as uint32;            // 支付时间
    buyerPayTime:  Int as uint32;            // 支付时间
    okTime: Int as uint32; 
    deliveryTime:  Int as uint32;       // 发货时间
    acceptTime:  Int as uint32;       // 验收时间
  
    completeTime: Int as uint32;  // 完成时间


    refunds: map<Int, RefundRecord>;   // 用 map 模拟 list
    refundCount: Int as uint32 = 0;
    refundFlag: Int as uint8; //退款状态：0=无,1=申请中,2=已退款 3=已拒绝

    cancelTime:  Int as uint32;     // 取消时间
    cancelAddress: Address? = null;     // 取消地址

    jettonMasterAddress: Address? = null;
}

struct RefundRecord {
    applicant: Address; //退款人
    handler: Address; //处理人
    refundAmount: Int as coins; //退款人金额
    otherAmount: Int as coins; //对方金额
    status: Int as uint8; //状态：0=待处理,1=已批准,2=已拒绝
    requestTime: Int as uint32;
    handleTime: Int as uint32;
}

struct PaymentRecord {
    sender: Address;
    amount: Int;
    orderId: Int;
    timestamp: Int;
    reason: String; // 记录异常原因
}


message(0xd53276db) Excesses {}


// 消息定义
message CreateOrder {
    orderId: Int as uint64;
    objType: Int as uint8;
    price: Int as coins;
    buyerAddress: Address?;
    sellerAddress: Address?;
    jettonMasterAddress: Address;
}

// 任务订单消息
message InitiateContract {               // 甲方发起签约
    orderId: Int as uint64;
    orderAmount: Int as coins;
    buyerDeposit: Int as coins;         // 雇主押金
    sellerDeposit: Int as coins;        // 服务方押金
    settlementType: Int as uint8;        // 结算方式：0=平台保证金结算，1=私下结算
    jettonMasterAddress: Address;
}

// 商品订单编辑
message ProductOrderEdit {
    orderId: Int as uint64;
    orderAmount: Int as coins;
    jettonMasterAddress: Address;
}


message SellerSignContract {                     // 乙方签约无需支付版
   orderId: Int as uint64;
}


message CompleteDelivery {               // 完成交付
   orderId: Int as uint64;
}

message ConfirmAcceptance {              // 确认验收
   orderId: Int as uint64;
}

// 通用消息
message CancelOrder {                    // 取消订单
   orderId: Int as uint64;
}

message RequestRefund {                  // 申请退款
   orderId: Int as uint64;
    refundAmount: Int as coins;
}

message ProcessRefund {                  // 处理退款
   orderId: Int as uint64;
    approve: Bool;
}




/////////============ Jetton  ====================

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;         // 钱包拥有者
    jettonMasterAddress: Address;  // 代币 Master
    jettonWalletCode: Cell;        // Jetton Wallet 模板代码
}

struct UsdtJettonWalletData {
    status: Int as uint4;
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
}

message JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message RescueErrorPayments {
    jettonMasterAddress: Address;
    to: Address;
    amount: Int as coins;
}