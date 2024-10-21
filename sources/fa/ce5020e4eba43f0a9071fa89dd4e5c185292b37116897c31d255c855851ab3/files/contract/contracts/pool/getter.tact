import "../msgs/pool_msg";
import "../constant";
    
struct PoolData {
    reserve0: Int;
    reserve1: Int;
    token0Address: Address;
    token1Address: Address;
    lpFee: Int as uint16;
    protocolFee: Int as uint16;
    refFee: Int as uint16;
    protocolFeeAddress: Address?;
    collectedToken0ProtocolFee: Int;
    collectedToken1ProtocolFee: Int;
}

struct ExpectedOutputs {
    amountOut: Int;
    protocolFeeOut: Int;
    refFeeOut: Int;
}

struct ExpectedLiquidityOutputs {
    amount0: Int;
    amount1: Int;
}

struct JettonData {
    totalSupply: Int;
    mintable: Int;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

fun getAmountOut(hasRef: Bool, amountIn: Int, reserveIn: Int, reserveOut: Int, lpFee: Int, protocolFee: Int, refFee: Int): ExpectedOutputs {
    let outputs = ExpectedOutputs{
        amountOut: 0,
        protocolFeeOut: 0,
        refFeeOut: 0,
    };
    let amountInWithFee = amountIn * (FEE_DIVIDER - lpFee);
    outputs.amountOut = (amountInWithFee * reserveOut) / (reserveIn * FEE_DIVIDER + amountInWithFee);
    if (protocolFee > 0) {
        outputs.protocolFeeOut = outputs.amountOut * protocolFee / FEE_DIVIDER;
    }
    if (hasRef && refFee > 0) {
        outputs.refFeeOut = outputs.amountOut * refFee / FEE_DIVIDER;
    }
    outputs.amountOut -= (outputs.protocolFeeOut + outputs.refFeeOut);
    outputs.amountOut = max(0, outputs.amountOut);
    return outputs;
}

trait GetterTrait {
    router: Address;
    token0Address: Address;
    token1Address: Address;
    totalSupply: Int;
    reserve0: Int;
    reserve1: Int;
    lpFee: Int;
    protocolFee: Int;
    refFee: Int;
    collectedToken0ProtocolFee: Int;
    collectedToken1ProtocolFee: Int;
    protocolFeeAddress: Address?;

    get fun getPoolData(): PoolData {
        return PoolData {
            reserve0: self.reserve0,
            reserve1: self.reserve1,
            token0Address: self.token0Address,
            token1Address: self.token1Address,
            lpFee: self.lpFee,
            protocolFee: self.protocolFee,
            refFee: self.refFee,
            protocolFeeAddress: self.protocolFeeAddress,
            collectedToken0ProtocolFee: self.collectedToken0ProtocolFee,
            collectedToken1ProtocolFee: self.collectedToken1ProtocolFee,
        }
    }

    get fun getExpectedOutputs(amountIn: Int, tokenWallet: Address) : ExpectedOutputs {
        nativeThrowUnless(NO_LIQUIDITY, self.totalSupply > REQUIRED_MIN_LIQUIDITY);
        let outputs = ExpectedOutputs{
            amountOut: 0,
            protocolFeeOut: 0,
            refFeeOut: 0,
        };
        if (tokenWallet == self.token0Address) {
            return getAmountOut(false, amountIn, self.reserve0, self.reserve1, self.lpFee, self.protocolFee, self.refFee);
        } else if (tokenWallet == self.token1Address) {
            return getAmountOut(false, amountIn, self.reserve1, self.reserve0, self.lpFee, self.protocolFee, self.refFee);
        } else {
            return ExpectedOutputs{amountOut: 0, protocolFeeOut: 0, refFeeOut: 0};
        }
    }

    get fun getExpectedTokens(amount0: Int, amount1: Int): Int {
        if (self.totalSupply == 0) {
            return sqrt(amount0 * amount1) / REQUIRED_MIN_LIQUIDITY;
        } else {
            return min(
                amount0 * self.totalSupply / self.reserve0,
                amount1 * self.totalSupply / self.reserve1,
            );
        }
    }

    get fun getExpectedLiquidity(liquidity: Int): ExpectedLiquidityOutputs {
        nativeThrowUnless(ZERO_OUTPUT, liquidity > 0);
        let outputs = ExpectedLiquidityOutputs{amount0: 0, amount1: 0};
        outputs.amount0 = liquidity * self.reserve0 / self.totalSupply;
        outputs.amount1 = liquidity * self.reserve1 / self.totalSupply;
        nativeThrowUnless(ZERO_OUTPUT, outputs.amount0 > 0 && outputs.amount1 > 0);
        return outputs;
    }

    get fun getLpAccountAddress(owner: Address): Address {
        let lpAccountInit: StateInit = initOf LpAccount(owner, myAddress());
        return contractAddress(lpAccountInit);
    }

    get fun getJettonData(): JettonData {
        let lpWalletInit: StateInit = initOf LpWallet(myAddress(), myAddress());
        let jettonContent = beginComment();
        jettonContent.append("https://lp.ston.fi/");
        jettonContent.append(myAddress().toString());
        jettonContent.append(".json");
        return JettonData {
            totalSupply: self.totalSupply,
            mintable: -1,
            adminAddress: self.router, 
            jettonContent: jettonContent.toCell(),
            jettonWalletCode: lpWalletInit.code,
        }
    }

    get fun get_wallet_address(owner: Address): Address {
        let lpWalletInit: StateInit = initOf LpWallet(owner, myAddress());
        return contractAddress(lpWalletInit);
    }

    receive(msg: GetterPoolData) {
        self.notify(GetterPoolDataResponse {
            queryId: msg.queryId,
            reserve0: self.reserve0,
            reserve1: self.reserve1,
            token0Address: self.token0Address,
            token1Address: self.token1Address,
            lpFee: self.lpFee,
            protocolFee: self.protocolFee,
            refFee: self.refFee,
            protocolFeeAddress: self.protocolFeeAddress,
            collectedToken0ProtocolFee: self.collectedToken0ProtocolFee,
            collectedToken1ProtocolFee: self.collectedToken1ProtocolFee,
        }.toCell());
    }

    receive(msg: GetterExpectedOutputs) {
        let outputs = self.getExpectedOutputs(msg.amount, msg.tokenWallet);
        self.notify(GetterExpectedOutputsResponse {
            queryId: msg.queryId,
            amountOut: outputs.amountOut,
            protocolFeeOut: outputs.protocolFeeOut,
            refFeeOut: outputs.refFeeOut,
        }.toCell());
    }

    receive(msg: GetterLpAccountAddress) {
        let accountAddress = self.getLpAccountAddress(msg.userAddress);
        self.notify(GetterLpAccountAddressResponse {
            queryId: msg.queryId,
            accountAddress: accountAddress,
        }.toCell());
    }

    receive(msg: GetterExpectedTokens) {
        let liquidity = self.getExpectedTokens(msg.amount0, msg.amount1);
        self.notify(GetterExpectedTokensResponse{ 
            queryId: msg.queryId,
            liquidity: liquidity,
        }.toCell());
    }

    receive(msg: GetterExpectedLiquidity) {
        let outputs = self.getExpectedLiquidity(msg.liquidity);
        self.notify(GetterExpectedLiquidityResponse{ 
            queryId: msg.queryId,
            amount0: outputs.amount0,
            amount1: outputs.amount1,
        }.toCell());
    }

    receive(msg: ProvideWalletAddress) {
        let wallet = self.get_wallet_address(msg.owner);
        self.notify(ProvideWalletAddressResponse {
            queryId: msg.queryId,
            wallet: wallet,
        }.toCell());
    }
}
