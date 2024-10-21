fun sqrt(a: Int): Int {
    if (a == 0) {
        return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    //
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
    //
    // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
    // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
    // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
    //
    // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
    let result = 1 << (log2(a) >> 1);

    // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
    // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
    // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
    // into the expected uint128 result.
    repeat(7) {
        result = (result + a / result) >> 1;
    }
    return min(result, a / result);
}

fun calcLiquidityRefund(liquidity: Int, minRefund: Int, amount: Int, reserve: Int, totalSupply: Int): Int {
    if (totalSupply > 0) {
        let recover = liquidity * reserve / totalSupply;
        if (recover + minRefund < amount) {
            return amount - recover;
        }
    }
    return 0;
}

struct AmountOut {
    swapOut: Int;
    protocolFeeOut: Int;
    refFeeOut: Int;
}

fun calculateAmountOut(refAddress: Address?, amountIn: Int, reserveIn: Int, reserveOut: Int, lpFee: Int, protocolFee: Int, refFee: Int): AmountOut {
    let amountInWithFee = amountIn * (FEE_DIVIDER - lpFee);
    let swapOut = (amountInWithFee * reserveOut) / (reserveIn * FEE_DIVIDER + amountInWithFee);
    let protocolFeeOut = 0;
    let refFeeOut = 0;

    if (protocolFee > 0) {
        protocolFeeOut = swapOut * protocolFee / FEE_DIVIDER;
    }

    if (refAddress != null && refFee > 0) {
        refFeeOut = swapOut * refFee / FEE_DIVIDER;
    }

    swapOut -= (protocolFeeOut + refFeeOut);
    return AmountOut {
        swapOut,
        protocolFeeOut,
        refFeeOut,
    }
}
