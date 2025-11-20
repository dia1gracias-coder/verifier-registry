// ============================================
// Messages
// ============================================

message InitGameMsg {
    playerOne: Address; // The player creating the game
    bidValue: Int as coins; // The exact bid amount for this game
    secret: Int as uint256;
    referrer: Address?;

    // Config parameters from factory
    serviceFeeNumerator: Int as uint32;
    referrerFeeNumerator: Int as uint32;
    waitingForOpenBidSeconds: Int as uint32;
    lowestBid: Int as coins;
    highestBid: Int as coins;
    feeReceiver: Address;
}

message JoinGameMsg {
    playerTwo: Address; // The player joining the game
    secret: Int as uint256;
    referrer: Address?;
}

message OpenBidMsg {
    key: Int as uint256;
}

// Batch operation: open multiple bids at once
message OpenMultipleBidsMsg {
    gameIds: map<Int as uint16, Int as uint256>; // index -> gameId
    keys: map<Int as uint16, Int as uint256>; // index -> key
    count: Int as uint16;
}

message CancelGameMsg {
    gameId: Int as uint256;
}

message FinishGameMsg {
    gameId: Int as uint256;
}

message GameInitializedNotify {
    gameId: Int as uint256;
    playerOne: Address;
    bidValue: Int as coins;
}

message GameStartedNotify {
    gameId: Int as uint256;
    playerOne: Address;
    playerTwo: Address;
    totalGainings: Int as coins;
}

message GameFinishedNotify {
    gameId: Int as uint256;
    winner: Address;
    looser: Address;
    totalGainings: Int as coins;
}

message GameCancelledNotify {
    gameId: Int as uint256;
    playerOne: Address;
}

message SecretOpenedNotify {
    gameId: Int as uint256;
    player: Address;
    coinSide: Int as uint8;
}

message DrawNotify {
    gameId: Int as uint256;
}

message InsufficientBalanceNotify {
    gameId: Int as uint256;
    required: Int as coins;
    actual: Int as coins;
}
