import "../msgs/pool_msg";
import "../constant";

trait ResetPoolGasFromRouterTrait with PoolBaseTrait {

    router: Address;
    token0Address: Address;
    token1Address: Address;

    receive(msg: ResetPoolGasFromRouter) {
        self.requireMessageFromRouter();

        send(
            SendParameters {
                to: self.router,
                value: myBalance() - REQUIRED_TON_RESERVE,
                bounce: true,
            }
        );
    }
}
