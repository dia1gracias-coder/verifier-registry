// TEP-62 Standard
const OP_TRANSFER = 0x5fcc3d14
const OP_OWNERSHIP_ASSIGNED = 0x05138d91
const OP_EXCESSES = 0xd53276db

// Custom Admin Operations
const OP_CANCEL_SALE = 0x4c4e434c // "CNCL"
const OP_UPDATE_PRICE = 0x50524943 // "PRIC"
const OP_UPDATE_BENEFICIARY = 0x42454e45 // "BENE"
const OP_ADD_ADMIN = 0x41444441 // "ADDA"
const OP_REMOVE_ADMIN = 0x524d4144 // "RMAD"

// Gas Constants
const GAS_MIN_RESERVE = ton("0.05") // Minimum balance to keep for storage
const GAS_TRANSFER_NFT = ton("0.05") // Est. cost to transfer NFT
const GAS_COMPUTE_FEES = ton("0.02") // Est. compute fees

// Helpers
fun emptyCell(): cell {
    return beginCell().endCell();
}

fun emptySlice(): slice {
    return emptyCell().beginParse();
}
