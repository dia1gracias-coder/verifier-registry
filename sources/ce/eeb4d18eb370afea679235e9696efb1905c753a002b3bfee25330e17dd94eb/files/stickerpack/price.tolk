import "storage"
import "@stdlib/common"

const PRECISION: int = 1000000;
const PRECISION_PIPS: int = 10000;

const PRICE_ALGO_QUADRATIC = 0;
const PRICE_ALGO_SIGMOID = 1;
const PRICE_ALGO_LINEAR_SIMPLE = 2;
const PRICE_ALGO_LINEAR_ACCELERATING = 3;
const PRICE_ALGO_LINEAR_SLOWING = 4;

fun getPrice(storage: Storage, atSupply:uint16): coins {
    if (atSupply < 1) {
        return storage.startPrice;
    }
    if (storage.priceAlgo == PRICE_ALGO_SIGMOID) {
        return sigmoidPrice(storage, atSupply);
    } else if (storage.priceAlgo == PRICE_ALGO_LINEAR_SIMPLE) {
        return linearPriceSimple(storage, atSupply);
    } else if (storage.priceAlgo == PRICE_ALGO_LINEAR_ACCELERATING) {
        return linearAccelerating(storage, atSupply);
    } else if (storage.priceAlgo == PRICE_ALGO_LINEAR_SLOWING) {
        return linearSlowing(storage, atSupply);
    } else {
        // PRICE_ALGO_QUADRATIC
        var multiplier = (1 + atSupply) * (1 + atSupply);
        return storage.startPrice * multiplier;
    }
}

@inline
fun linearPriceSimple(storage:Storage, atSupply: uint16):coins {
    return storage.startPrice + (storage.endPrice - storage.startPrice) * (atSupply / storage.packThreshold);
}

@inline
fun sigmoidPrice(storage: Storage, atSupply: uint16): coins {
    val coefficientNormalized = storage.priceCoefficient * PRECISION / PRECISION_PIPS;

    val g_min = (-coefficientNormalized) * PRECISION / (PRECISION + coefficientNormalized);
    val z = coefficientNormalized * (2 * ((atSupply * PRECISION) / storage.packThreshold) - PRECISION) / PRECISION;

    return storage.startPrice + (storage.endPrice - storage.startPrice) * (
        ((z * PRECISION / (PRECISION + abs(z ))) - g_min) * PRECISION / ((coefficientNormalized * PRECISION / (PRECISION + coefficientNormalized)) - g_min)
    ) / PRECISION;

    // Full version (for reading, not optimized)
    // val xNormalized = (atSupply * PRECISION) / storage.packThreshold;
    //
    // // z = coefficient * (2*x - 1)
    // val z = coefficientNormalized * (2 * xNormalized - PRECISION) / PRECISION;
    //
    // // sigmoid function: g(z) = z / (1 + |z|)
    // val g_z = z * PRECISION / (PRECISION + (z >= 0 ? z : -z));
    //
    // // g_max = coefficient / (1 + coefficient)
    // val g_max = coefficientNormalized * PRECISION / (PRECISION + coefficientNormalized);
    //
    // // g_min = -coefficient / (1 + coefficient)
    // val g_min = (-coefficientNormalized) * PRECISION / (PRECISION + coefficientNormalized);
    //
    // val normalized = (g_z - g_min) * PRECISION / (g_max - g_min);
    //
    // return storage.startPrice + (storage.endPrice - storage.startPrice) * normalized / PRECISION;
}

@inline
fun linearAccelerating(storage:Storage, atSupply: uint16):coins {
    // startPrice + (atSupply² × (endPrice - startPrice)) / packThreshold²
    return storage.startPrice + atSupply * atSupply * (storage.endPrice - storage.startPrice) / storage.packThreshold / storage.packThreshold;
}

@inline
fun linearSlowing(storage:Storage, atSupply: uint16):coins {
    val ratio = mulDivRound(atSupply,PRECISION, storage.packThreshold);
    val xxx = PRECISION - ratio;
    val factor = mulDivRound(ratio, 2*xxx, PRECISION);
    val adjustedFactor = factor / PRECISION;
    return storage.startPrice + ((storage.endPrice - storage.startPrice) * adjustedFactor as coins) + atSupply;
}

