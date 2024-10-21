import "../msgs/wallet_msg";
import "../msgs/router_msg";
import "../msgs/pool_msg";
import "../utils";
import "./base";

trait BurnNotificationTrait with PoolBaseTrait {

    router: Address;
    token0Address: Address;
    token1Address: Address;
    totalSupply: Int;
    reserve0: Int;
    reserve1: Int;

    receive(msg: TokenBurnNotification) {
        self.requireMessageFromWallet(msg.sender);

        let gasRequired = getComputeFee(100000, false);
        let msgValue = context().value;
        let forwardFee = context().readForwardFee();
        nativeThrowUnless(INSUFFICIENT_GAS, msgValue > gasRequired && msgValue > forwardFee * 6);
        let gasRemain = msgValue - gasRequired;

        let amount0Out = (msg.amount * self.reserve0) / self.totalSupply;
        let amount1Out = (msg.amount * self.reserve1) / self.totalSupply;
        nativeThrowUnless(ZERO_OUTPUT, msg.amount > 0 && amount0Out > 0 && amount1Out > 0);

        self.reserve0 -= amount0Out;
        self.reserve1 -= amount1Out;
        self.totalSupply -= msg.amount;
        
        //half of remain value for excesses gas if exist, remain for user pay
        if (msg.responseDestination != null) {
            let gas = gasRemain / 2;
            send(
                SendParameters {
                    to: msg.responseDestination!!,
                    value: gas,
                    bounce: false,
                    mode: SendIgnoreErrors,
                    body: TokenExcesses {
                        queryId: msg.queryId,
                    }.toCell(),
                }
            );
            gasRemain -= gas;
        }
        if (msg.responseDestination != null) {
            self.payToWithValueAndMode(msg.queryId, PAY_TO_CODE_SUCCESS, msg.sender, amount0Out, amount1Out, gasRemain, 0);
        } else {
            self.payTo(msg.queryId, PAY_TO_CODE_SUCCESS, msg.sender, amount0Out, amount1Out);
        }
    }
}
