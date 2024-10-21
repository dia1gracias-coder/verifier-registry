import "../msgs/pool_msg";
import "../lp_account";
import "../constant";

trait ProvideLpOnSingleSideTrait with PoolBaseTrait {
    router: Address;
    token0Address: Address;
    token1Address: Address;

    receive(msg: ProvideLpOnSingleSide) {
        self.requireMessageFromRouter();

        let lpAccountInit: StateInit = initOf LpAccount(msg.ownerAddress, myAddress());
        let lpAccountAddress: Address = contractAddress(lpAccountInit);
        send(
            SendParameters{
                to: lpAccountAddress,
                value: 0,
                mode: SendRemainingValue,
                body: AddLiquidity {
                    queryId: msg.queryId,
                    newAmount0: msg.amount0,
                    newAmount1: msg.amount1,
                    minLPOut: msg.minLpOut,
                }.toCell(),
                code: lpAccountInit.code,
                data: lpAccountInit.data,
            }
        );
    }
}
