// ============================================
// Structs
// ============================================

struct DetailedStats {
    totalGamesCreated: Int as uint64;
    totalGamesInitialized: Int as uint64;
    totalGamesFinished: Int as uint64;
    totalGamesCancelled: Int as uint64;
    totalGamesDrawn: Int as uint64;
    totalSecretsOpened: Int as uint64;
    totalInsufficientBalance: Int as uint64;
}

struct FactoryConfig {
    serviceFeeNumerator: Int as uint32;
    referrerFeeNumerator: Int as uint32;
    waitingForOpenBidSeconds: Int as uint32;
    feeReceiver: Address;
    stopped: Bool;
}

struct GameAddressBatch {
    startId: Int as uint32;
    addresses: map<Int as uint32, Address>;
}

struct GameInfo {
    gameId: Int as uint256;
    status: Int as uint8;
    playerOne: Address;
    playerTwo: Address;
    bidValue: Int as coins;
    totalGainings: Int as coins;
    playerOneChosenSide: Int as uint2;
    playerTwoChosenSide: Int as uint2;
    gameCreatedTimestamp: Int as uint32;
    gameStartedTimestamp: Int as uint32;
    winner: Address;
    configReceived: Bool;
}

struct PlayerInfo {
    playerOne: Address;
    playerTwo: Address;
}

struct GameConfig {
    serviceFeeNumerator: Int as uint32;
    referrerFeeNumerator: Int as uint32;
    waitingForOpenBidSeconds: Int as uint32;
    feeReceiver: Address;
}
