/// Fixed-point math library (Q64.64 format)
/// Provides exp, ln, log2, pow2, mul, div operations for LMSR pricing

/// Q64.64 fixed-point unit: 2^64
const ONE: int = 18446744073709551616;

/// log2(e) in Q64.64 ≈ 1.4427 * 2^64
const LOG2_E: int = 26613026195688644984;

/// ln(2) in Q64.64 ≈ 0.6931 * 2^64
const LN_2: int = 12786308645202655660;

/// Maximum safe exponent input (~3.4 * ONE)
const EXP_LIMIT: int = 62771017353866807638;

/// Fixed-point multiplication: (a * b) >> 64
fun fixed_mul(a: int, b: int): int {
    return (a * b) >> 64;
}

/// Fixed-point division: (a << 64) / b
fun fixed_div(a: int, b: int): int {
    assert(b != 0) throw 400;
    return (a << 64) / b;
}

/// Binary logarithm in Q64.64 format
/// Returns log2(x) where x is in Q64.64 (x must be > 0)
fun fixed_log2(x: int): int {
    assert(x > 0) throw 401;

    var result = 0;
    var v = x;

    // Integer part: normalize v into [ONE, 2*ONE)
    if (v >= ONE) {
        while (v >= 2 * ONE) {
            v = v >> 1;
            result += ONE;
        }
    } else {
        while (v < ONE) {
            v = v << 1;
            result -= ONE;
        }
    }

    // Fractional part: iterative squaring (64 iterations for 64 fractional bits)
    var bit = ONE >> 1; // 0.5 in Q64.64
    var i = 0;
    while (i < 64) {
        // Square v in Q64.64
        v = (v * v) >> 64;
        if (v >= 2 * ONE) {
            v = v >> 1;
            result += bit;
        }
        bit = bit >> 1;
        i += 1;
    }

    return result;
}

/// Power of 2 in Q64.64 format
/// Returns 2^x where x is in Q64.64
fun fixed_pow2(x: int): int {
    if (x == 0) {
        return ONE;
    }

    // Handle negative exponents
    val negative = x < 0;
    var absX = x;
    if (negative) {
        absX = -x;
    }

    // Split into integer and fractional parts
    val intPart = absX >> 64;
    val fracPart = absX & ((1 << 64) - 1);

    // Taylor series coefficients for 2^f (c_k = ln(2)^k / k! in Q64.64)
    val c1 = 12786308645202655660;  // ln(2)
    val c2 = 4431396893595737425;   // ln(2)^2 / 2!
    val c3 = 1023870087579328453;   // ln(2)^3 / 3!
    val c4 = 177423166116318949;    // ln(2)^4 / 4!
    val c5 = 24596073471909060;     // ln(2)^5 / 5!
    val c6 = 2841449829983171;      // ln(2)^6 / 6!
    val c7 = 281363276907910;       // ln(2)^7 / 7!
    val c8 = 24378270262728;        // ln(2)^8 / 8!
    val c9 = 1877525477726;         // ln(2)^9 / 9!

    // Evaluate polynomial using Horner's method: 2^f = 1 + c1*f + c2*f^2 + ...
    var fracResult = c9;
    fracResult = c8 + ((fracResult * fracPart) >> 64);
    fracResult = c7 + ((fracResult * fracPart) >> 64);
    fracResult = c6 + ((fracResult * fracPart) >> 64);
    fracResult = c5 + ((fracResult * fracPart) >> 64);
    fracResult = c4 + ((fracResult * fracPart) >> 64);
    fracResult = c3 + ((fracResult * fracPart) >> 64);
    fracResult = c2 + ((fracResult * fracPart) >> 64);
    fracResult = c1 + ((fracResult * fracPart) >> 64);
    fracResult = ONE + ((fracResult * fracPart) >> 64);

    // Combine: 2^x = 2^int * 2^frac
    var result = fracResult << intPart;

    if (negative) {
        // 2^(-x) = ONE^2 / 2^x = (ONE << 64) / result
        result = (ONE << 64) / result;
    }

    return result;
}

/// Natural logarithm: ln(x) = log2(x) * ln(2)
fun fixed_ln(x: int): int {
    assert(x > 0) throw 401;
    return fixed_mul(fixed_log2(x), LN_2);
}

/// Exponential: e^x = 2^(x * log2(e))
fun fixed_exp(x: int): int {
    return fixed_pow2(fixed_mul(x, LOG2_E));
}

/// Maximum element in a cell-encoded array of integers
/// The cell stores: count (uint32), followed by count int257 values
fun fixed_max(arr: cell): int {
    var s = arr.beginParse();
    val count = s.loadUint(32);
    assert(count > 0) throw 402;
    var maxVal = s.loadInt(257);
    var i = 1;
    while (i < count) {
        val v = s.loadInt(257);
        if (v > maxVal) {
            maxVal = v;
        }
        i += 1;
    }
    return maxVal;
}
