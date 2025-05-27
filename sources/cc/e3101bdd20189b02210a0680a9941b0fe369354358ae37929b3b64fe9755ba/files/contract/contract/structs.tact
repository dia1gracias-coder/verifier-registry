struct GameState {
    // contract state
    owner: Address;
    tokenAddress: Address?;
    walletAddress: Address?;
    deployTime: Int as uint64;
    gameStarted: Int as uint64;
    airdropDuration: Int as uint64;
    /// влияет на вознаграждение красным, чем ниже - тем ниже
    streakState: Int as uint64;
    greenCount: Int as uint64;
    redCount: Int as uint64;
    // Remote config
    /// minimum time before new config change is allowed, made for smooth changes
    cpaReward: Int as uint64;
    changeInterval: Int as uint32;
    lastChanged: Int as uint32;
    maxBet: Int as uint64;
    minBet: Int as uint8;
    streakRatio: Int as uint8;
    greenPrice: Int as uint32;
    redPrice: Int as uint32;
    // Game History
    // Each uint256 stores 256 booleans, total capacity 2048 bits for storing last 2000 operations
    gameHistory1: Int as uint256; // Stores entries 0-255
    gameHistory2: Int as uint256; // Stores entries 256-511
    gameHistory3: Int as uint256; // Stores entries 512-767
    gameHistory4: Int as uint256; // Stores entries 768-1023
    gameHistory5: Int as uint256; // Stores entries 1024-1279
    gameHistory6: Int as uint256; // Stores entries 1280-1535
    gameHistory7: Int as uint256; // Stores entries 1536-1791
    gameHistory8: Int as uint256; // Stores entries 1792-2047
    currentHistoryLength: Int as uint16; // Current position in circular buffer (0-1999)
    createAt: Int as uint64;
}

struct PlayerState {
    parent: Address;
    player: Address;
    tokenBalance: Int as uint256;
    initTime: Int as uint64;
    isPlaying: Bool;
    lastRedDate: Int as uint64;
    bet: Int as uint256;
    gameStarted: Int as uint64;
    streakStateOnStart: Int as int64;
    greenCountOnStart: Int as uint64;
    redCountOnStart: Int as uint64;
    playerGreenCount: Int as uint64;
    playerRedCount: Int as uint64;
    refMapSize: Int;
    cpaPaid: Bool;
    referrer: Address?;
    refereesCount: Int as uint32;
    refereesMap: map<Int, Address>;
    arrStart: Int as uint16;
    arrLength: Int as uint16;
    createAt: Int as uint64;
}
