import "../msgs/pool_msg";
import "../constant";

trait CollectFeesFromRouterTrait with PoolBaseTrait {

    router: Address;
    collectedToken0ProtocolFee: Int;
    collectedToken1ProtocolFee: Int;
    protocolFeeAddress: Address?;
    token0Address: Address;
    token1Address: Address;

    receive(msg: CollectFeesFromRouter) {
        self.requireMessageFromRouter();
        nativeThrowUnless(INVALID_RECIPIENT, self.protocolFeeAddress != null);

        self.payTo(
            msg.queryId, 
            PAY_TO_CODE_SUCCESS, 
            self.protocolFeeAddress!!, 
            self.collectedToken0ProtocolFee, 
            self.collectedToken1ProtocolFee
        );

        self.collectedToken0ProtocolFee = 0;
        self.collectedToken1ProtocolFee = 0;
    }
}
