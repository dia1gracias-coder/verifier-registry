import "@stdlib/deploy";
import "@stdlib/ownable";

message PayMessage {
    seller: Address;
    groupOwner: Address;
    orderId: String;
    billAmount: Int;
}

message ChangePlatformAddress {
    newAddress: Address;
}

// ✅ 新增：设置合约激活状态的消息
message SetActive {
    active: Bool;
}

contract PaymentSplitter with Deployable, Ownable {
    owner: Address;
    platformFeeAddress: Address;
    // ✅ 新增：合约开关，默认为 true（开启）
    isActive: Bool = true;

    // 平台费率 0.16%（= 160/100000）
    platformFeeNumerator: Int = 160;
    // 群主费率 0.2%（= 200/100000）
    groupOwnerFeeNumerator: Int = 200;
    feeDenominator: Int = 100000;

    init(platformFeeAddress: Address) {
        self.owner = sender();
        self.platformFeeAddress = platformFeeAddress;
        // isActive 默认 true，无需显式赋值
    }

    receive(msg: PayMessage) {
        // ✅ 检查合约开关状态
        require(self.isActive, "Contract is temporarily disabled, please try again later");

        let totalReceived: Int = context().value;

        require(msg.billAmount > 0, "Invalid bill amount");
        require(totalReceived >= msg.billAmount + ton("0.015"), "Insufficient payment for bill and gas");

        // 计算各项费用
        let platformFee: Int = (msg.billAmount * self.platformFeeNumerator) / self.feeDenominator;
        let groupOwnerFee: Int = (msg.billAmount * self.groupOwnerFeeNumerator) / self.feeDenominator;
        let sellerAmount: Int = msg.billAmount - platformFee - groupOwnerFee;

        // 判断群主地址是否为空（零地址）
        let zeroAddress = address("0:0000000000000000000000000000000000000000000000000000000000000000");
        let isGroupOwnerEmpty = msg.groupOwner == zeroAddress;

        // 1. 转给卖家（携带 orderId 用于对账）
        if (sellerAmount > 0) {
            send(SendParameters{
                to: msg.seller,
                value: sellerAmount,
                bounce: false,
                mode: SendPayGasSeparately,
                body: msg.orderId.asComment()
            });
        }

        // 2. 根据群主是否绑定，决定费用发送方式
        if (isGroupOwnerEmpty) {
            // 群主未绑定：合并所有费用一次性发给平台地址
            let totalFee = platformFee + groupOwnerFee;
            if (totalFee > 0) {
                send(SendParameters{
                    to: self.platformFeeAddress,
                    value: totalFee,
                    bounce: false,
                    mode: SendPayGasSeparately
                });
            }
        } else {
            // 群主已绑定：分别发送
            if (platformFee > 0) {
                send(SendParameters{
                    to: self.platformFeeAddress,
                    value: platformFee,
                    bounce: false,
                    mode: SendPayGasSeparately
                });
            }
            if (groupOwnerFee > 0) {
                send(SendParameters{
                    to: msg.groupOwner,
                    value: groupOwnerFee,
                    bounce: false,
                    mode: SendPayGasSeparately
                });
            }
        }

        // 3. 退回多余 Gas（保留 0.005 TON 缓冲）
        let totalSentOut: Int = sellerAmount + platformFee + groupOwnerFee;
        let refundAmount: Int = totalReceived - totalSentOut - ton("0.005");
        if (refundAmount > 0) {
            send(SendParameters{
                to: sender(),
                value: refundAmount,
                bounce: false,
                mode: SendPayGasSeparately
            });
        }
    }

    receive(msg: ChangePlatformAddress) {
        self.requireOwner();
        self.platformFeeAddress = msg.newAddress;
    }

    // ✅ 新增：设置合约开关（仅 owner）
    receive(msg: SetActive) {
        self.requireOwner();
        self.isActive = msg.active;
    }

    // 可选：查询当前状态（如果需要前端展示）
    get fun isActive(): Bool {
        return self.isActive;
    }

    get fun platformFeeAddress(): Address {
        return self.platformFeeAddress;
    }
}   