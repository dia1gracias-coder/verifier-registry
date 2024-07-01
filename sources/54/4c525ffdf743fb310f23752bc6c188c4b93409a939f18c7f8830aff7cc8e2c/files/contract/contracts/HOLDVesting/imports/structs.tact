struct Config {
    amount: Int as coins;                // jetton amount
    receiver: Address;                   // receiver wallet address
    cliffDuration: Int as uint64;        // cliff duration in seconds
    cycleReleaseDuration: Int as uint64; // cycle release duration in seconds
    cycleReleasePercent: Int as uint64;  // cycle release percent (with decimals PERCENT_DECIMALS)
}
