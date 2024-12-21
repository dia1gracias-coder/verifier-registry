import "@stdlib/deploy";
import "@stdlib/ownable";
import "./test_token";

const MIN_TICK: Int = -887272;
const MAX_TICK: Int = 887272;
const MIN_SQRT_PRICE: Int = 4295128739;
const MAX_SQRT_PRICE: Int = 1461446703485210103287273052203988822378723970342;

const Q32: Int = 1 << 32;
const Q96: Int = 1 << 96;
const Q192: Int = 1 << 192;
const Q128: Int = 1 << 128;
// Add message types
message SetFeeTier {
    fee: Int;
    tickSpacing: Int;
}

message SetProtocolFee {
    newFee: Int;
}

message CollectFees {
    positionId: Int;
}
message AddLiquidity {
    amount0Desired: Int as coins;
    amount1Desired: Int as coins;
    amount0Min: Int as coins;
    amount1Min: Int as coins;
    tickLower: Int;
    tickUpper: Int;
    recipient: Address;
}

message Swap {
    tokenIn: Address;
    amountIn: Int as coins;
    amountOutMinimum: Int as coins;
    recipient: Address;
}

struct Position {
    owner: Address;
    liquidity: Int as coins;
    tickLower: Int;
    tickUpper: Int;
    tokensOwed0: Int as coins;
    tokensOwed1: Int as coins;
    feeGrowthInside0LastX128: Int;
    feeGrowthInside1LastX128: Int;
}

struct PoolData {
    token0: Address;
    token1: Address;
    fee: Int;
    tickSpacing: Int;
    sqrtPriceX96: Int;
    tick: Int;
    liquidity: Int;
    reserve0: Int as coins;
    reserve1: Int as coins;
}

struct AmountPair {
    amount0: Int;
    amount1: Int;
}

struct SwapAmounts {
    amount0: Int as coins;
    amount1: Int as coins;
}

struct FeeGrowthGlobal {
    feeGrowthGlobal0X128: Int;
    feeGrowthGlobal1X128: Int;
}

struct FeeTier {
    fee: Int;  // Fee in basis points (1 = 0.01%)
    tickSpacing: Int;
    active: Bool;
}

contract CLMM with Deployable, Ownable, Jetton {
    owner: Address;
    token0: Address;
    token1: Address;
    fee: Int;
    tickSpacing: Int;
    mintable: Bool;
    content: Cell;
    max_supply: Int as coins;
    totalSupply: Int;
    // Current state
    sqrtPriceX96: Int;
    tick: Int;
    liquidity: Int;
    reserve0: Int;
    reserve1: Int;
    
    // Position tracking
    positions: map<Int, Position>;
    nextPositionId: Int;

    // Add new state variables
    feeGrowthGlobal: FeeGrowthGlobal;
    feeTiers: map<Int, FeeTier>;
    protocolFee: Int;  // Protocol fee percentage (e.g., 5 = 5%)
    protocolFeeRecipient: Address;
    
    init(owner: Address, token0: Address, token1: Address, fee: Int, tickSpacing: Int) {
        self.owner = owner;
        self.token0 = token0;
        self.token1 = token1;
        self.fee = fee;
        self.tickSpacing = tickSpacing;
        
        // Initialize with minimum price
        self.sqrtPriceX96 = MIN_SQRT_PRICE;
        self.tick = MIN_TICK;
        self.liquidity = 0;
        self.reserve0 = 0;
        self.reserve1 = 0;
        self.nextPositionId = 0;
        
        // Initialize missing Jetton fields
        self.mintable = true;  // or false depending on your needs
        self.content = beginCell().endCell();  // empty content or add your desired content
        self.max_supply = 1000000000000;  // set your desired max supply
        self.totalSupply = 0;  // start with 0 supply

        // Add new state variables
        self.feeGrowthGlobal = FeeGrowthGlobal{
            feeGrowthGlobal0X128: 0,
            feeGrowthGlobal1X128: 0
        };
        self.protocolFee = 5;  // 5% default protocol fee
        self.protocolFeeRecipient = owner;
        
        // Initialize default fee tier
        self.feeTiers.set(fee, FeeTier{
            fee: fee,
            tickSpacing: tickSpacing,
            active: true
        });
    }

    // Helper functions for token transfers
    fun transferToken(token: Address, to: Address, amount: Int) {
        send(SendParameters{
            to: token,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            body: TokenTransfer{
                queryId: 0,
                amount: amount,
                destination: to,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: emptySlice()
            }.toCell()
        });
    }

    fun transferTokenFrom(token: Address, from: Address, amount: Int) {
        let walletInit: StateInit = initOf JettonDefaultWallet(token, from);
        let walletAddress: Address = contractAddress(walletInit);
        
        send(SendParameters{
            to: walletAddress,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            body: TokenTransfer{
                queryId: 0,
                amount: amount,
                destination: myAddress(),
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: emptySlice()
            }.toCell()
        });
    }

    receive(msg: TokenNotification) {
        let ctx: Context = context();
        
        dump("TokenNotification received");
        dump("Previous reserves: ");
        dump(self.reserve0);
        dump(self.reserve1);
        
        if (ctx.sender == self.token0) {
            self.reserve0 = self.reserve0 + msg.amount;
            dump("Updated reserve0: ");
            dump(self.reserve0);
        } else if (ctx.sender == self.token1) {
            self.reserve1 = self.reserve1 + msg.amount;
            dump("Updated reserve1: ");
            dump(self.reserve1);
        }
        
        dump("Final reserves: ");
        dump(self.reserve0);
        dump(self.reserve1);
    }

    receive(msg: AddLiquidity) {
        let ctx: Context = context();
        
        dump("AddLiquidity - Start");
        dump("Initial reserves: ");
        dump(self.reserve0);
        dump(self.reserve1);
        
        // First liquidity provider
        if (self.liquidity == 0) {
            self.reserve0 = msg.amount0Desired;
            self.reserve1 = msg.amount1Desired;
            self.liquidity = self.sqrt(msg.amount0Desired * msg.amount1Desired);
            self.sqrtPriceX96 = self.sqrt((msg.amount1Desired * Q96) / msg.amount0Desired);
        } else {
            // Subsequent liquidity providers
            let amount0 = msg.amount0Desired;
            let amount1 = msg.amount1Desired;
            
            // Calculate proportional amounts
            let liquidity = min(
                (amount0 * self.liquidity) / self.reserve0,
                (amount1 * self.liquidity) / self.reserve1
            );
            
            self.reserve0 = self.reserve0 + amount0;
            self.reserve1 = self.reserve1 + amount1;
            self.liquidity = self.liquidity + liquidity;
        }
        
        // Create position
        self.positions.set(self.nextPositionId, Position{
            owner: msg.recipient,
            liquidity: self.liquidity,
            tickLower: msg.tickLower,
            tickUpper: msg.tickUpper,
            tokensOwed0: 0,
            tokensOwed1: 0,
            feeGrowthInside0LastX128: 0,
            feeGrowthInside1LastX128: 0
        });
        
        // Update pool state
        self.nextPositionId = self.nextPositionId + 1;
        
        // Transfer tokens from user
        self.transferTokenFrom(self.token0, ctx.sender, msg.amount0Desired);
        self.transferTokenFrom(self.token1, ctx.sender, msg.amount1Desired);
    }

    // Calculate amounts needed for given tick range
    fun calculateAmountsForTicks(
        tickLower: Int,
        tickUpper: Int,
        amount0Desired: Int,
        amount1Desired: Int
    ): AmountPair {
        let sqrtPriceLowerX96: Int = self.getSqrtRatioAtTick(tickLower);
        let sqrtPriceUpperX96: Int = self.getSqrtRatioAtTick(tickUpper);
        
        let liquidity: Int = self.getLiquidityForAmounts(
            self.sqrtPriceX96,
            tickLower,
            tickUpper,
            amount0Desired,
            amount1Desired
        );

        return self.getAmountsForLiquidity(
            self.sqrtPriceX96,
            sqrtPriceLowerX96,
            sqrtPriceUpperX96,
            liquidity
        );
    }

    // Calculate liquidity for given amounts
    fun getLiquidityForAmounts(
        sqrtPriceX96: Int,
        tickLower: Int,
        tickUpper: Int,
        amount0: Int,
        amount1: Int
    ): Int {
        let sqrtPriceLowerX96: Int = self.getSqrtRatioAtTick(tickLower);
        let sqrtPriceUpperX96: Int = self.getSqrtRatioAtTick(tickUpper);

        // Calculate liquidity contributions from both tokens
        let liquidity0: Int = (amount0 * (sqrtPriceUpperX96 - sqrtPriceLowerX96)) / Q96;
        let liquidity1: Int = amount1 * Q96 / (sqrtPriceUpperX96 - sqrtPriceLowerX96);

        return min(liquidity0, liquidity1);
    }

    // Get amounts for given liquidity
    fun getAmountsForLiquidity(
        sqrtPriceX96: Int,
        sqrtPriceLowerX96: Int,
        sqrtPriceUpperX96: Int,
        liquidity: Int
    ): AmountPair {
        let amount0: Int = 0;
        let amount1: Int = 0;

        if (sqrtPriceX96 <= sqrtPriceLowerX96) {
            amount0 = liquidity * (sqrtPriceUpperX96 - sqrtPriceLowerX96) / Q96;
        } else if (sqrtPriceX96 < sqrtPriceUpperX96) {
            amount0 = liquidity * (sqrtPriceUpperX96 - sqrtPriceX96) / Q96;
            amount1 = liquidity * (sqrtPriceX96 - sqrtPriceLowerX96) / Q96;
        } else {
            amount1 = liquidity * (sqrtPriceUpperX96 - sqrtPriceLowerX96) / Q96;
        }

        return AmountPair{
            amount0: amount0,
            amount1: amount1
        };
    }

    // Get position by ID
    get fun getPosition(id: Int): Position? {
        return self.positions.get(id);
    }

    // Get all positions
    get fun getPositions(): map<Int, Position> {
        return self.positions;
    }

    // Tick Math Functions
    fun getSqrtRatioAtTick(tick: Int): Int {
        require(tick >= MIN_TICK && tick <= MAX_TICK, "T");
        
        let absTick: Int = tick < 0 ? -tick : tick;
        
        let ratio: Int = ((absTick & 0x1) != 0) ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        
        let check2: Int = absTick & 0x2;
        if (check2 != 0) { ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128; }
        
        let check4: Int = absTick & 0x4;
        if (check4 != 0) { ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128; }
        
        let check8: Int = absTick & 0x8;
        if (check8 != 0) { ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128; }
        
        let check16: Int = absTick & 0x10;
        if (check16 != 0) { ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128; }
        
        let check32: Int = absTick & 0x20;
        if (check32 != 0) { ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128; }
        
        let check64: Int = absTick & 0x40;
        if (check64 != 0) { ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128; }
        
        let check128: Int = absTick & 0x80;
        if (check128 != 0) { ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128; }
        
        let check256: Int = absTick & 0x100;
        if (check256 != 0) { ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128; }
        
        let check512: Int = absTick & 0x200;
        if (check512 != 0) { ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128; }
        
        let check1024: Int = absTick & 0x400;
        if (check1024 != 0) { ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128; }
        
        let check2048: Int = absTick & 0x800;
        if (check2048 != 0) { ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128; }
        
        let check4096: Int = absTick & 0x1000;
        if (check4096 != 0) { ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128; }
        
        let check8192: Int = absTick & 0x2000;
        if (check8192 != 0) { ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128; }
        
        let check16384: Int = absTick & 0x4000;
        if (check16384 != 0) { ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128; }
        
        let check32768: Int = absTick & 0x8000;
        if (check32768 != 0) { ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128; }
        
        let check65536: Int = absTick & 0x10000;
        if (check65536 != 0) { ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128; }
        
        let check131072: Int = absTick & 0x20000;
        if (check131072 != 0) { ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128; }
        
        let check262144: Int = absTick & 0x40000;
        if (check262144 != 0) { ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128; }
        
        let check524288: Int = absTick & 0x80000;
        if (check524288 != 0) { ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128; }
        
        if (tick > 0) { ratio = MAX_SQRT_PRICE / ratio; }
        
        return ratio;
    }

    // Swap Functions
    receive(msg: Swap) {
        let ctx: Context = context();
        
        // Validate input token
        require(msg.tokenIn == self.token0 || msg.tokenIn == self.token1, "Invalid input token");
        let zeroForOne: Bool = msg.tokenIn == self.token0;
        
        // Calculate amounts
        let amountIn: Int = msg.amountIn;
        // Calculate target price based on direction
        let sqrtPriceTargetX96: Int = zeroForOne ? 
            min(self.sqrtPriceX96 - 1, MAX_SQRT_PRICE) : 
            max(self.sqrtPriceX96 + 1, MIN_SQRT_PRICE);
        
        // Compute swap step
        let step: SwapAmounts = self.computeSwapStep(
            self.sqrtPriceX96,
            sqrtPriceTargetX96,
            self.liquidity
        );
        
        // Update reserves and price
        if (zeroForOne) {
            self.reserve0 = self.reserve0 + amountIn;
            self.reserve1 = self.reserve1 - step.amount1;
        } else {
            self.reserve0 = self.reserve0 - step.amount0;
            self.reserve1 = self.reserve1 + amountIn;
        }
        
        // Update price and tick
        self.sqrtPriceX96 = sqrtPriceTargetX96;
        self.tick = self.getTickAtSqrtRatio(sqrtPriceTargetX96);
        
        // Collect fees
        self.collectFees(amountIn, zeroForOne);
        
        // Transfer tokens
        if (zeroForOne) {
            self.transferToken(self.token1, msg.recipient, step.amount1);
        } else {
            self.transferToken(self.token0, msg.recipient, step.amount0);
        }
    }

    // Price calculation functions
    fun getNextSqrtPrice(amountIn: Int, zeroForOne: Bool, sqrtPriceX96: Int, liquidity: Int): Int {
        require(amountIn > 0, "AI");
        require(liquidity > 0, "L");
        
        let numerator: Int = liquidity * Q96;
        let product: Int = amountIn * sqrtPriceX96;
        
        if (zeroForOne) {
            let denominator: Int = numerator + product;
            return (numerator * sqrtPriceX96) / denominator;
        } else {
            let denominator: Int = numerator - product;
            return (numerator * sqrtPriceX96) / denominator;
        }
    }

    fun computeSwapStep(
        sqrtPriceCurrentX96: Int,
        sqrtPriceTargetX96: Int,
        liquidity: Int
    ): SwapAmounts {
        let amount0: Int = 0;
        let amount1: Int = 0;
        
        if (sqrtPriceCurrentX96 < sqrtPriceTargetX96) {
            // Price increasing, consuming token1
            amount1 = ((liquidity * (sqrtPriceTargetX96 - sqrtPriceCurrentX96)) / Q96);
            amount0 = ((liquidity * Q96) * (sqrtPriceTargetX96 - sqrtPriceCurrentX96)) / 
                     (sqrtPriceCurrentX96 * sqrtPriceTargetX96);
        } else {
            // Price decreasing, consuming token0
            amount0 = ((liquidity * Q96) * (sqrtPriceCurrentX96 - sqrtPriceTargetX96)) / 
                     (sqrtPriceCurrentX96 * sqrtPriceTargetX96);
            amount1 = ((liquidity * (sqrtPriceCurrentX96 - sqrtPriceTargetX96)) / Q96);
        }
        
        return SwapAmounts{
            amount0: amount0,
            amount1: amount1
        };
    }

    fun getTickAtSqrtRatio(sqrtPriceX96: Int): Int {
        // Binary search to find the tick for a sqrt price
        let tick: Int = 0;
        let r: Int = sqrtPriceX96;
        let found: Bool = false;
        
        while (tick < MAX_TICK && !found) {
            let nextSqrtPrice: Int = self.getSqrtRatioAtTick(tick + 1);
            if (r < nextSqrtPrice) {
                found = true;
            } else {
                tick = tick + 1;
            }
        }
        
        return tick;
    }

    // internal sqrt func
    fun sqrt(y: Int): Int {
        if (y > 3) {
            let z: Int = y;
            let x: Int = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
            return z;
        } else if (y != 0) {
            return 1;
        }
        return 0;
    }

    get fun getPoolData(): PoolData {
        return PoolData{
            token0: self.token0,
            token1: self.token1,
            fee: self.fee,
            tickSpacing: self.tickSpacing,
            sqrtPriceX96: self.sqrtPriceX96,
            tick: self.tick,
            liquidity: self.liquidity,
            reserve0: self.reserve0,
            reserve1: self.reserve1
        };
    }

    // Add fee management functions
    receive(msg: SetFeeTier) {
        self.requireOwner();
        self.feeTiers.set(msg.fee, FeeTier{
            fee: msg.fee,
            tickSpacing: msg.tickSpacing,
            active: true
        });
    }

    receive(msg: SetProtocolFee) {
        self.requireOwner();
        require(msg.newFee <= 50, "Fee too high");  // Max 50%
        self.protocolFee = msg.newFee;
    }

    // Update swap function to handle fees
    fun collectFees(amount: Int, zeroForOne: Bool) {
        let totalFee: Int = (amount * self.fee) / 10000;  // fee is in basis points
        let protocolFeeAmount: Int = (totalFee * self.protocolFee) / 100;
        let lpFeeAmount: Int = totalFee - protocolFeeAmount;

        // Update global fee trackers
        if (zeroForOne) {
            self.feeGrowthGlobal.feeGrowthGlobal0X128 = 
                self.feeGrowthGlobal.feeGrowthGlobal0X128 + 
                (lpFeeAmount * Q128) / self.liquidity;
            
            // Transfer protocol fee
            if (protocolFeeAmount > 0) {
                self.transferToken(
                    self.token0,
                    self.protocolFeeRecipient,
                    protocolFeeAmount
                );
            }
        } else {
            self.feeGrowthGlobal.feeGrowthGlobal1X128 = 
                self.feeGrowthGlobal.feeGrowthGlobal1X128 + 
                (lpFeeAmount * Q128) / self.liquidity;
            
            if (protocolFeeAmount > 0) {
                self.transferToken(
                    self.token1,
                    self.protocolFeeRecipient,
                    protocolFeeAmount
                );
            }
        }
    }

    // Update position to include collected fees
    fun updatePositionFees(positionId: Int) {
        let position: Position? = self.positions.get(positionId);
        if (position == null) {
            return;
        }

        let feeGrowthInside0X128: Int = self.getFeeGrowthInside(
            position!!.tickLower,
            position!!.tickUpper,
            self.tick,
            self.feeGrowthGlobal.feeGrowthGlobal0X128
        );
        
        let feeGrowthInside1X128: Int = self.getFeeGrowthInside(
            position!!.tickLower,
            position!!.tickUpper,
            self.tick,
            self.feeGrowthGlobal.feeGrowthGlobal1X128
        );

        // Calculate fees earned
        let tokensOwed0: Int = position!!.liquidity * 
            (feeGrowthInside0X128 - position!!.feeGrowthInside0LastX128) / Q128;
        let tokensOwed1: Int = position!!.liquidity * 
            (feeGrowthInside1X128 - position!!.feeGrowthInside1LastX128) / Q128;

        // Update position
        self.positions.set(positionId, Position{
            owner: position!!.owner,
            liquidity: position!!.liquidity,
            tickLower: position!!.tickLower,
            tickUpper: position!!.tickUpper,
            tokensOwed0: position!!.tokensOwed0 + tokensOwed0,
            tokensOwed1: position!!.tokensOwed1 + tokensOwed1,
            feeGrowthInside0LastX128: feeGrowthInside0X128,
            feeGrowthInside1LastX128: feeGrowthInside1X128
        });
    }

    // Add fee collection endpoint
    receive(msg: CollectFees) {
        let position: Position? = self.positions.get(msg.positionId);
        require(position != null, "Invalid position");
        require(position!!.owner == context().sender, "Not owner");

        // Update fees first
        self.updatePositionFees(msg.positionId);
        position = self.positions.get(msg.positionId);

        // Transfer collected fees
        if (position!!.tokensOwed0 > 0) {
            self.transferToken(self.token0, position!!.owner, position!!.tokensOwed0);
        }
        if (position!!.tokensOwed1 > 0) {
            self.transferToken(self.token1, position!!.owner, position!!.tokensOwed1);
        }

        // Reset owed amounts
        self.positions.set(msg.positionId, Position{
            owner: position!!.owner,
            liquidity: position!!.liquidity,
            tickLower: position!!.tickLower,
            tickUpper: position!!.tickUpper,
            tokensOwed0: 0,
            tokensOwed1: 0,
            feeGrowthInside0LastX128: position!!.feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: position!!.feeGrowthInside1LastX128
        });
    }

    // Add this function before updatePositionFees
    get fun getFeeGrowthInside(
        tickLower: Int,
        tickUpper: Int,
        currentTick: Int,
        feeGrowthGlobalX128: Int
    ): Int {
        // For simplicity, we'll start with a basic implementation
        // that returns global fee growth if position spans current tick
        if (currentTick >= tickLower && currentTick < tickUpper) {
            return feeGrowthGlobalX128;
        }
        return 0;
    }

    get fun getFeeGrowthGlobal(): FeeGrowthGlobal {
        return self.feeGrowthGlobal;
    }

    // Add these getter functions
    get fun getToken0(): Address {
        return self.token0;
    }

    get fun getToken1(): Address {
        return self.token1;
    }

    fun validateReserves(amount: Int): Bool {
        return amount <= 1_000_000_000_000_000;  // Reasonable max value
    }

    
}
