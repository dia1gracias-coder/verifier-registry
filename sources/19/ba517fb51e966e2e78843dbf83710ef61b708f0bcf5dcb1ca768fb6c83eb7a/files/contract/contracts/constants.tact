const GasTransfer: Int = ton("0.05"); // Gas for wallet-to-wallet transfer
const GasFeeTransfer: Int = ton("0.03"); // Gas for fee transfer to fee receiver
const GasNotification: Int = ton("0.02"); // Gas for transfer notification
const GasExcesses: Int = ton("0.01"); // Gas for returning excesses

// Fee limits and defaults
const MaxFeeBps: Int = 10000; // Maximum 100% fee (10000 basis points)
const DefaultFeeBps: Int = 500; // Default 5% fee (500 basis points)
const BasisPointsDivisor: Int = 10000; // 10,000 basis points = 100%

// Minimum transfer amounts to prevent dust attacks
const MinTransferAmount: Int = ton("0.01"); // Minimum 0.01 TON worth of jettons

// Binary sizes for data validation
const BitsPerUint16: Int = 16; // Size of uint16 in bits
const BitsPerUint64: Int = 64; // Size of uint64 in bits
const BitsPerAddress: Int = 267; // Size of address in bits (2 + 8 + 256 + 1)
const BitsPerCoins: Int = 124; // VarUInteger 16 - up to 124 bits for coins

// Zero address for validation
fun isZeroAddress(addr: Address): Bool {
    return addr == newAddress(0, 0);
}

// Standalone function for fee calculation with ceiling rounding
inline fun calculateFee(amount: Int, feeRateBps: Int): Int {
    if (feeRateBps == 0) {
        return 0;
    }

    // Use ceiling division: (amount * feeRateBps + divisor - 1) / divisor
    let feeAmount: Int = (amount * feeRateBps + BasisPointsDivisor - 1) / BasisPointsDivisor;
    return feeAmount;
}

inline fun hashCell(c: Cell): Int {
    // sha256 accepts Slice or String; wrap the cell into a Slice
    return sha256(beginCell().storeRef(c).endCell().beginParse());
}

inline fun hashUint256(x: Int): Int {
    return sha256(beginCell().storeInt(x, 256).endCell().beginParse());
}
