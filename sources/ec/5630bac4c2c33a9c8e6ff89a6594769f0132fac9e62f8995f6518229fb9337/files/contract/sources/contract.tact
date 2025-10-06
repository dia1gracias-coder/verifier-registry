// 导入Tact标准库的部署功能
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./message.tact";


// 订单托管合约主体
contract OrderEscrowContract with Deployable, Ownable {
    // 平台配置
    platformFeeRate: Int as uint16 = 100;                  // 平台费率（基点，100=1%）
    
    // 订单存储
    orders: map<Int as uint64, OrderInfo>;                        // 订单ID -> 订单信息映射
     
     // 订单ID -> 订单信息映射

    jettonWallets: map<Address, Address>;                          // token -> token钱包地址

    jettonWalletCode: Cell;

    lastQueryId: Int as uint64 = 0;

    jettonTransferGas: Int as coins = ton("0.05");

    usdtJettonMaster: Address? = null;

    paymentErrorRecords: map<Int as uint64, PaymentRecord> = emptyMap();
    paymentErrorRecordsLength: Int as uint64 = 0;

    paymentErrorAmountMaps: map<Address, Int as coins> = emptyMap();


    owner: Address;
    
    // 合约初始化函数
    init(jettonWalletCode: Cell, owner: Address) {
        self.jettonWalletCode = jettonWalletCode;
        self.orders = map<Int as uint64, OrderInfo>{};
        self.jettonWallets = map<Address, Address>{};
        self.owner = owner;
    }

    receive() {
        cashback(sender());
    }

    // 创建订单
    receive(msg: CreateOrder) {
        require(msg.objType == 0 || msg.objType == 1, "Invalid object type");
        require(msg.orderId > 0, "Order no is required");
        require(!self.orders.exists(msg.orderId), "Order already exists");
        require(msg.price >= 1, "Price must be greater than 0");
        let buyerAddress: Address? = null;
        let sellerAddress: Address? = null;
        let buyerDeposit: Int = 0;
        if (msg.objType == 0) {
            // 商品订单：买方是当前用户，卖方是商品所有者
            buyerAddress = sender();
            sellerAddress = msg.sellerAddress;
             // 从商品信息传入
            buyerDeposit = msg.price;
        } 
        if (msg.objType == 1) {
            // 任务订单：买方是雇主，卖方是当前用户
            buyerAddress = msg.buyerAddress;
            sellerAddress = sender();
            // 从任务信息传入
     
        }
        let order: OrderInfo = OrderInfo{
            orderId: msg.orderId,
            objType: msg.objType,
            orderAmount: msg.price,
            price: msg.price,
            buyerDeposit: buyerDeposit,
            sellerDeposit: 0,
            buyerDepositPaid: 0,
            sellerDepositPaid: 0,
            settlementType: 0,
            status: 0,
            buyerAddress: buyerAddress!!,
            sellerAddress: sellerAddress!!,
            createTime: now(),
            sellerPayTime: 0,
            buyerPayTime: 0,
            okTime: 0,
            deliveryTime: 0,
            acceptTime: 0,
            completeTime: 0,
            refunds: map<Int, RefundRecord>{},
            refundCount: 0,
            refundFlag: 0,
            cancelTime: 0,
            cancelAddress: null,
            jettonMasterAddress: msg.jettonMasterAddress,
        };
        require(order.buyerAddress != order.sellerAddress, "Buyer and seller cannot be the same");
            
        self.orders.set(msg.orderId, order);

        // 
        self.refundGas()
    }

    // ==================== 任务订单流程 ====================
    
    // 甲方发起签约 
    receive(msg: InitiateContract) {
        require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
        require( order.status == 0, "Order not in correct state");
    
        require(msg.orderId > 0, "Order no is required");
        require(msg.orderAmount >= 1, "Order amount must be greater than 1");
        require(msg.buyerDeposit >= 1, "Buyer deposit must be greater than 1");
        require(msg.settlementType == 0 || msg.settlementType == 1, "Invalid settlement type");
        require(order.objType == 1, "Not a task order");           // 取消注释
        require(order.buyerAddress == sender(), "Not the buyer");  // 取消注释
        require(msg.sellerDeposit >= 0, "Seller deposit must be greater than 0");

        if (msg.settlementType == 0) {
            require(msg.buyerDeposit >= msg.orderAmount, "Buyer deposit must be greater than order amount");
        } 
       
        order.orderAmount = msg.orderAmount;
        order.buyerDeposit = msg.buyerDeposit;     // 雇主押金
        order.settlementType = msg.settlementType;
        order.sellerDeposit = msg.sellerDeposit;   // 服务方押金
        order.status = 1; // 待乙方确认签约并支付
        order.jettonMasterAddress = msg.jettonMasterAddress;

        self.orders.set(msg.orderId, order);
        self.refundGas()
    }


    receive(msg: ProductOrderEdit) {

        require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
        //卖家才能改
        require(sender() == order.sellerAddress, "Not the seller");
        //必须买家还未支付
        require(order.status == 0, "Order not in correct state");
        require(order.objType == 0, "Not a product order");
        require(msg.orderAmount >= 1, "Order amount must be greater than 1");
       
        order.jettonMasterAddress = msg.jettonMasterAddress;
        order.orderAmount = msg.orderAmount;
        order.buyerDeposit = msg.orderAmount;

        self.orders.set(msg.orderId, order);
        self.refundGas()
    }

    //支付处理
    receive(msg: JettonTransferNotification) {

      
       
        let orderId: Int = msg.forwardPayload.loadUint(64);
        let jettonMasterAddress: Address = msg.forwardPayload.loadAddress();
      
        // 防恶意攻击
        require(sender() == self.calculateMyJettonWalletAddress(jettonMasterAddress), "Sender address not correct");
      
        let paymentRecord: PaymentRecord = PaymentRecord{
            orderId: orderId,
            sender: sender(),
            amount: msg.amount,
            timestamp: now(),
            reason: ""
        };
    
        let isOrderExists: Bool = self.orders.exists(orderId);
    
        if (isOrderExists) {

            
            let canUpdateOrder: Bool = false;
            let order: OrderInfo = self.orders.get(orderId)!!;
            require(jettonMasterAddress == order.jettonMasterAddress, "Jetton master address not correct");

            if (order.objType == 0 || order.objType == 1) {
                if(order.status >= 0 && order.status <= 2){
                    //商品
                    if(order.status == 0 && msg.amount == order.buyerDeposit && order.buyerDepositPaid == 0){
                        order.status = 3;
                        order.buyerPayTime = now();
                        order.okTime = now();
                        order.buyerDepositPaid = msg.amount;
                        canUpdateOrder = true;
                    } else if(order.status == 1 && msg.amount == order.sellerDeposit && order.sellerDepositPaid == 0){
                        order.status = 2;
                        order.sellerPayTime = now();
                        order.sellerDepositPaid = msg.amount;
                        canUpdateOrder = true;
                    } else if(order.status == 2 && msg.amount == order.buyerDeposit && order.buyerDepositPaid == 0){
                        order.status = 3;
                        order.buyerPayTime = now();
                        order.buyerDepositPaid = msg.amount;
                        order.okTime = now();
                        canUpdateOrder = true;
                    } else {
                        paymentRecord.reason = "amount error";
                    }
                } else {
                    paymentRecord.reason = "order status error";
                }
            } else {
                paymentRecord.reason = "order type error";
            }
    
            if(canUpdateOrder){
                self.orders.set(orderId, order);
            }
    
        } else {
            paymentRecord.reason = "order not found";
        }
    
        // 记录异常支付
        if(paymentRecord.reason != ""){
            self.paymentErrorRecordsLength += 1;
            self.paymentErrorRecords.set(self.paymentErrorRecordsLength, paymentRecord);


            let current: Int = paymentRecord.amount;
            if(self.paymentErrorAmountMaps.exists(jettonMasterAddress)){
                current += self.paymentErrorAmountMaps.get(jettonMasterAddress)!!;
            }
            self.paymentErrorAmountMaps.set(jettonMasterAddress, current);
        }
        self.refundGas()
    }


    //乙方签约无需支付版
    receive(msg: SellerSignContract) {
        
        require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
      
        require(order.status == 1, "Order not in correct state");
        require(order.sellerAddress == sender(), "Seller address not correct");
        require(order.objType == 1, "Not a task order");
        require(order.sellerDeposit == 0, "Seller deposit is not 0");
        order.status = 2; 
        order.sellerPayTime = now();
        order.sellerDepositPaid = 0;
         // 5️⃣ 写回订单映射
        self.orders.set(msg.orderId, order);
        self.refundGas()
    }


    // 完成交付/发货
    receive(msg: CompleteDelivery) {
        require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
        require(order.status == 3, "Order not in correct state");
        require(sender() == order.sellerAddress, "Not the seller");

        order.status = 10; // 待验收/待收货（统一状态码）
        order.deliveryTime = now();
        self.orders.set(msg.orderId, order);
        self.refundGas()
    }

    // 确认验收/收货
    receive(msg: ConfirmAcceptance) {
         require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
        require(order.status == 10, "Order not in correct state");
        require(sender() == order.buyerAddress, "Not the buyer");
        order.status = 12; // 订单完成（统一状态码）
        order.completeTime = now();
        self.orders.set(msg.orderId, order);

         // 分配资金给卖方

        if (order.objType == 0) {
          // 商品订单：将押金分配给卖方
          let jettonMasterAddress: Address = order.jettonMasterAddress!!;
          self.transferJetton(jettonMasterAddress, order.sellerAddress, order.buyerDepositPaid);
        }
        else if(order.objType == 1) {
          if (order.settlementType == 0) {
              // 平台保证金结算：
              let jettonMasterAddress: Address = order.jettonMasterAddress!!;
              //退乙方压惊
              self.transferJetton(jettonMasterAddress, order.sellerAddress, order.sellerDepositPaid);
              //分配上架
              self.transferJetton(jettonMasterAddress, order.sellerAddress, order.orderAmount);
              self.transferJetton(jettonMasterAddress, order.buyerAddress, order.buyerDepositPaid - order.orderAmount);
          }
          else {
          // 私下结算：将押金退还双方
              let jettonMasterAddress: Address = order.jettonMasterAddress!!;
              self.transferJetton(jettonMasterAddress, order.sellerAddress, order.sellerDepositPaid);
              self.transferJetton(jettonMasterAddress, order.buyerAddress, order.buyerDepositPaid);
          }
        }

        self.refundGas()
    }

    // ==================== 通用操作 ====================
    
    // 取消订单
    receive(msg: CancelOrder) {
        require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
        require(order.status >= 0 && order.status <= 2, "Order cannot be cancelled");
        
        order.status = -1; // 已取消
        order.cancelTime = now();
        order.cancelAddress = sender();


       self.orders.set(msg.orderId, order);

       //取消订单时，如果乙方已支付，则退还乙方押金
        if(order.sellerDepositPaid > 0) {
            let jettonMasterAddress: Address = order.jettonMasterAddress!!;
            let sellerAddress: Address = order.sellerAddress;

            self.transferJetton(jettonMasterAddress,sellerAddress, order.sellerDepositPaid);
        }
        self.refundGas()
    }

    // 申请退款（统一处理任务订单和商品订单）
    receive(msg: RequestRefund) {
        require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
        require(msg.refundAmount >= 1, "Refund amount must be greater than 1");


        //商品订单只能买家退款
        if(order.objType == 0) {
            require(sender() == order.buyerAddress, "Not the buyer");
        }


        //待发货或待验收的订单才能申请
        require(order.status == 3 || order.status == 10, "Order cannot be refunded");
        //没有正在申请中和已退款完成的的单子
        require(order.refundFlag != 1 && order.refundFlag != 2, "Refund already requested");
         // 验证退款金额不超过已支付的押金总额
        let totalPaidDeposits = order.buyerDepositPaid + order.sellerDepositPaid;
        require(msg.refundAmount <= totalPaidDeposits, "Refund amount exceeds paid deposits");
        
        let handler: Address? = null;
        if (sender() == order.buyerAddress) {
            handler = order.sellerAddress;
        } else {
            handler = order.buyerAddress;
        }
        //添加退款记录
        let refundRecord = RefundRecord{
            applicant: sender(),
            handler: handler!!,
            refundAmount: msg.refundAmount,
            otherAmount: totalPaidDeposits - msg.refundAmount,
            status: 0, //待处理
            requestTime: now(),
            handleTime: 0,
        };
        order.refundCount += 1;
        let idx = order.refundCount;
        order.refunds.set(idx, refundRecord);
        order.refundFlag = 1; // 退款申请中（不改变订单状态）
       self.orders.set(msg.orderId, order);
       self.refundGas()
    }

    // 处理退款（统一处理任务订单和商品订单）
    receive(msg: ProcessRefund) {
       require(self.orders.exists(msg.orderId), "Order not found");
        let order:OrderInfo = self.orders.get(msg.orderId)!!;
        require(order.refundFlag == 1, "No refund request");

        let refundRecord:RefundRecord = order.refunds.get(order.refundCount)!!;

        require(sender() == refundRecord.handler, "Not the handler");
        
        if (msg.approve) {
            refundRecord.status = 1; // 已批准
            refundRecord.handleTime = now();
            order.refundFlag = 2; // 退款完成
            order.status = -1;
            order.cancelTime = now();
        } else {
            refundRecord.status = 2; // 已拒绝
            refundRecord.handleTime = now();
            order.refundFlag = 3; // 拒绝
        }
        order.refunds.set(order.refundCount, refundRecord);
        self.orders.set(msg.orderId, order);

        if(msg.approve){
            // 这里可以添加资金释放逻辑,根据退款金额和押金比例分配资金给买方和卖方
            let jettonMasterAddress: Address = order.jettonMasterAddress!!;
            if(refundRecord.refundAmount > 0){
                self.transferJetton(jettonMasterAddress, refundRecord.applicant, refundRecord.refundAmount);
            }
            if(refundRecord.otherAmount > 0){
                self.transferJetton(jettonMasterAddress, refundRecord.handler, refundRecord.otherAmount);
            }
        }
        self.refundGas()
    }

       //救援
    receive(msg: RescueErrorPayments) {
        self.requireOwner(); // ✅ 检查调用者是否为 owne
        require(msg.amount > 0, "Amount must be greater than 0");
        require(self.paymentErrorAmountMap(msg.jettonMasterAddress)!! >= msg.amount, "Jetton master error amount is not enough");
        self.paymentErrorAmountMaps.set(msg.jettonMasterAddress, self.paymentErrorAmountMap(msg.jettonMasterAddress)!! - msg.amount);
        self.transferJetton(msg.jettonMasterAddress, msg.to, msg.amount);
    }

    fun refundGas(){
        self.notify(Excesses{}.toCell());
    }

    fun transferJetton(jettonMasterAddress: Address, to: Address, amount: Int) {
        require(amount > 0, "Amount must be greater than 0");
        self.lastQueryId += 1;
        send(SendParameters {
               to: self.calculateMyJettonWalletAddress(jettonMasterAddress),
               value: self.jettonTransferGas,
               body: JettonTransfer{
                   queryId: self.lastQueryId,
                   amount: amount,
                   destination: to,
                   responseDestination: null,
                   customPayload: null,
                   forwardTonAmount: 0,
                   forwardPayload: emptySlice(),
               }.toCell()
        });
    }

    inline fun calculateJettonWalletAddress(ownerAddress: Address,jettonMasterAddress: Address): Address {
       
        if (self.jettonWallets.exists(jettonMasterAddress)) {
            return self.jettonWallets.get(jettonMasterAddress)!!;
        }
    

        let walletAddress: Address? = null;
        let jettonWalletCode:Cell = self.jettonWalletCode;

        if (jettonMasterAddress == self.usdtJettonMaster) {
           
           let initData = UsdtJettonWalletData {
                status: 0,
                balance: 0,
                ownerAddress: ownerAddress,
                jettonMasterAddress,
            };

            walletAddress = contractAddress(StateInit{
                code: jettonWalletCode,
                data: initData.toCell(),
            });
        }else{
    
            let initData = JettonWalletData{
                balance: 0,
                ownerAddress: ownerAddress,
                jettonMasterAddress,
                jettonWalletCode,
            };

            // contractAddress 根据 StateInit(code + data) 计算合约地址
             walletAddress = contractAddress(StateInit{
                code: jettonWalletCode,
                data: initData.toCell(),
            });

        }

           
        self.jettonWallets.set(jettonMasterAddress, walletAddress);
        return walletAddress!!;
    }

    fun calculateMyJettonWalletAddress(jettonMasterAddress: Address): Address {
        return self.calculateJettonWalletAddress(myAddress(), jettonMasterAddress);
    }


    //获取异常记录
    get fun paymentErrorRecord(index: Int): PaymentRecord {
        return self.paymentErrorRecords.get(index)!!;
    }

    //获取异常记录长度
    get fun paymentErrorRecordsLength(): Int {
        return self.paymentErrorRecordsLength;
    }

     // 获取订单信息
    get fun order(orderId: Int): OrderInfo? {
        return self.orders.get(orderId);
    }

    // 获取平台配置
    get fun platformFeeRate(): Int {
        return self.platformFeeRate;
    }

    //获取订单退款记录
    get fun orderRefunds(orderId: Int): map<Int, RefundRecord> {
        let order:OrderInfo = self.orders.get(orderId)!!;
        return order.refunds;
    }

    // 获取异常记录金额
    get fun paymentErrorAmountMap(jettonMasterAddress: Address): Int? {
        return self.paymentErrorAmountMaps.get(jettonMasterAddress);
    }


 
  
}