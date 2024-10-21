import "../msgs/pool_msg";
import "../constant";

trait CbRefundMeTrait with PoolBaseTrait {

    router: Address;
    token0Address: Address;
    token1Address: Address;

    receive(msg: CbRefundMe) {
        self.requireMessageFromAccount(msg.userAddress);

        self.payTo(msg.queryId, PAY_TO_CODE_REFUND, msg.userAddress, msg.amount0, msg.amount1);
    }
}
