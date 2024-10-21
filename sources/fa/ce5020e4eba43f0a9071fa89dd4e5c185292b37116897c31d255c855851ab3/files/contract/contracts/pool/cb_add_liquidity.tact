import "../msgs/wallet_msg";
import "../msgs/pool_msg";
import "../lp_account";
import "../lp_wallet";
import "../constant";
import "../utils";
import "./base";

const MIN_TON: Int = ton("0.000001");

trait CbAddLiquidityTrait with PoolBaseTrait {
    router: Address;
    token0Address: Address;
    token1Address: Address;
    totalSupply: Int;
    reserve0: Int;
    reserve1: Int;

    receive(msg: CbAddLiquidity) {
        let ctx: Context = context();
        let accountStateInit = self.requireMessageFromAccount(msg.userAddress);

        let liquidity: Int = 0;
        let refund0: Int = 0;
        let refund1: Int = 0;
        if (self.totalSupply == 0) {
            liquidity = sqrt(msg.amount0 * msg.amount1);
        } else {
            let liquidity0 = msg.amount0 * self.totalSupply / self.reserve0;
            let liquidity1 = msg.amount1 * self.totalSupply / self.reserve1;
            liquidity = min(liquidity0, liquidity1);
            if (liquidity0 < liquidity1) {
                refund1 = calcLiquidityRefund(liquidity, MIN_TON, msg.amount1, self.reserve1, self.totalSupply);
            } else {
                refund0 = calcLiquidityRefund(liquidity, MIN_TON, msg.amount0, self.reserve0, self.totalSupply);
            }
        }

        if (liquidity < msg.minLpOut || msg.amount0 > MAX_COINS || msg.amount1 > MAX_COINS) {
            //refund account, the minLPOut is zero, so account will not send back
            send(
                SendParameters{
                    to: accountStateInit.address,
                    value: 0,
                    bounce: true,
                    mode: SendRemainingValue | SendIgnoreErrors,
                    body: AddLiquidity {
                        queryId: msg.queryId,
                        newAmount0: msg.amount0,
                        newAmount1: msg.amount1,
                        minLPOut: 0,
                    }.toCell(),
                    code: accountStateInit.stateInit.code,
                    data: accountStateInit.stateInit.data,
                }
            );
            return;
        }
        let tonAmount: Int = 0;
        let mode = SendRemainingValue;
        if (refund0 + refund1 > 0) {
            tonAmount = (ctx.value - getComputeFee(50000, false)) / 5; // 3/5 goes to refund; 2/5 goes to mint
            mode = 0;
            send(
                SendParameters{
                    to: self.router,
                    value: tonAmount * 3, // 3 messages for refund
                    mode: mode | SendIgnoreErrors,
                    body: PayTo {
                        queryId: msg.queryId,
                        owner: msg.userAddress,
                        exitCode: 0,
                        amount0Out: refund0,
                        token0Address: self.token0Address,
                        amount1Out: refund1,
                        token1Address: self.token1Address,
                    }.toCell(),
                }
            )
        }

        self.reserve0 += msg.amount0 - refund0;
        self.reserve1 += msg.amount1 - refund1;
        self.totalSupply += liquidity;
        if (self.totalSupply == liquidity) {
            liquidity -= REQUIRED_MIN_LIQUIDITY;
        }
        let myAddress = myAddress();
        let lpWalletInit: StateInit = initOf LpWallet(msg.userAddress, myAddress);
        let lpWalletAddress: Address = contractAddress(lpWalletInit);
        send(
            SendParameters {
                to: lpWalletAddress,
                value: tonAmount * 2, // 2 messages for mint, 0 value if SendRemainingValue
                bounce: true,
                mode: mode | SendIgnoreErrors,
                body: TokenTransferInternal {
                    queryId: msg.queryId ,
                    amount: liquidity,
                    from: myAddress,
                    responseDestination: msg.userAddress,
                    forwardTonAmount: 0,
                    forwardPayload: null,
                }.toCell(),
                code: lpWalletInit.code,
                data: lpWalletInit.data,
            }
        );
    }
}
