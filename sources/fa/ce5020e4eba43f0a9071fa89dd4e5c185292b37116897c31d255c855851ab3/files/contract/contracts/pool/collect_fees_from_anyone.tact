import "../msgs/pool_msg";
import "../constant";
import "../utils";

trait CollectFeesFromAnyoneTrait with PoolBaseTrait {

    router: Address;
    collectedToken0ProtocolFee: Int;
    collectedToken1ProtocolFee: Int;
    protocolFeeAddress: Address?;
    token0Address: Address;
    token1Address: Address;

    receive(msg: CollectFeesFromAnyone) {
        nativeThrowUnless(NO_LIQUIDITY, self.collectedToken0ProtocolFee > 0 && self.collectedToken1ProtocolFee > 0);
        nativeThrowUnless(INVALID_RECIPIENT, self.protocolFeeAddress != null);

        let gasRequired = getComputeFee(40000, false);
        let msgValue = context().value;
        nativeThrowUnless(INSUFFICIENT_GAS, (msgValue - gasRequired) > 1000000000);
        let gas = (msgValue - gasRequired) / 4;

        let reward0 = self.collectedToken0ProtocolFee / 1000;
        let reward1 = self.collectedToken1ProtocolFee / 1000;
        self.collectedToken0ProtocolFee -= reward0;
        self.collectedToken1ProtocolFee -= reward1;
        nativeThrowUnless(ZERO_OUTPUT, reward0 > 0 && reward1 > 0 && self.collectedToken0ProtocolFee > 0 && self.collectedToken1ProtocolFee > 0);

        self.payToWithValueAndMode(
            msg.queryId, 
            PAY_TO_CODE_SUCCESS, 
            self.protocolFeeAddress!!, 
            self.collectedToken0ProtocolFee, 
            self.collectedToken1ProtocolFee,
            gas * 3,
            0, //NORMAL
        );
        self.payToWithValueAndMode(
            msg.queryId, 
            PAY_TO_CODE_SUCCESS, 
            sender(), 
            reward0, 
            reward1,
            gas,
            SendRemainingValue,
        );

        self.collectedToken0ProtocolFee = 0;
        self.collectedToken1ProtocolFee = 0;
    }
}
