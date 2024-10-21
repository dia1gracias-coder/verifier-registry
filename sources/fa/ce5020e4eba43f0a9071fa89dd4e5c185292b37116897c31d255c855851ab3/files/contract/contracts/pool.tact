import "@stdlib/deploy";

import "./pool/swap";
import "./pool/provide_lp_on_single_side";
import "./pool/cb_add_liquidity";
import "./pool/burn_notification";
import "./pool/cb_refund_me";
import "./pool/set_fees_from_router";
import "./pool/reset_pool_gas_from_router";
import "./pool/collect_fees_from_router";
import "./pool/collect_fees_from_anyone";
import "./pool/getter";

contract Pool with 
    Deployable, 
    ProvideLpOnSingleSideTrait, 
    CbAddLiquidityTrait,
    BurnNotificationTrait,
    SwapTrait,
    CbRefundMeTrait,
    SetFeesFromRouterTrait,
    ResetPoolGasFromRouterTrait,
    CollectFeesFromRouterTrait,
    CollectFeesFromAnyoneTrait,
    GetterTrait,
{

    router: Address;
    token0Address: Address;
    token1Address: Address;
    totalSupply: Int = 0;
    reserve0: Int = 0;
    reserve1: Int = 0;
    lpFee: Int as uint16 = 20;
    protocolFee: Int as uint16 = 10;
    refFee: Int as uint16 = 10;
    collectedToken0ProtocolFee: Int = 0;
    collectedToken1ProtocolFee: Int = 0;
    protocolFeeAddress: Address? = null;

    init(router: Address, token0Address: Address, token1Address: Address) {
        self.router = router;
        self.token0Address = token0Address;
        self.token1Address = token1Address;
    }

}
