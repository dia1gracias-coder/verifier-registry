import "../msgs/pool_msg";
import "../constant";

trait SetFeesFromRouterTrait with PoolBaseTrait {

    router: Address;
    token0Address: Address;
    token1Address: Address;
    lpFee: Int;
    protocolFee: Int;
    refFee: Int;
    protocolFeeAddress: Address?;

    receive(msg: SetFeesFromRouter) {
        self.requireMessageFromRouter();

        nativeThrowUnless(FEE_OUT_RANGE, (MIN_FEE <= msg.newLpFee) && (msg.newLpFee <= MAX_FEE));
        nativeThrowUnless(FEE_OUT_RANGE, (MIN_FEE <= msg.newProtocolFee) && (msg.newProtocolFee <= MAX_FEE));
        nativeThrowUnless(FEE_OUT_RANGE, (MIN_FEE <= msg.newRefFee) && (msg.newRefFee <= MAX_FEE));
        
        self.lpFee = msg.newLpFee;
        self.protocolFee = msg.newProtocolFee;
        self.refFee = msg.newRefFee;
        self.protocolFeeAddress = msg.newProtocolFeeAddress;
    }
}
