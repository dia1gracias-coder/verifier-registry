struct Config {
    amount: Int as coins;                // jetton amount
    receiver: Address;                   // receiver wallet address
    description: Cell;                   // description about config
    cliffPeriodDuration: Int as uint64;  // cliff duration in seconds
    cycleReleaseDuration: Int as uint64; // cycle release duration in seconds
    cycleReleasePercent: Int as uint64;  // cycle release percent (with decimals PERCENT_DECIMALS)
}

struct AllocateData {
    isCliffPeriodEnded: Bool;           // indicates if the cliff period has ended
    cycleReleaseNumber: Int as uint16;  // number of release cycles
    totalJettons: Int as coins;         // total number of jettons
    totalAllocateJettons: Int as coins; // total number of allocated jettons
    totalUnlockedJettons: Int as coins; // total number of unlocked jettons
    totalLockedJettons: Int as coins;   // total number of locked jettons
}
