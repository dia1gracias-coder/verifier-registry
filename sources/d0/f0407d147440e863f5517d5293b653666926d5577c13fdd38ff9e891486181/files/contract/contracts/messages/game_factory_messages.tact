// ============================================
// Messages
// ============================================

message CreateEmptyGameMsg {
    gameId: Int as uint256;
}

message SetServiceFeeMsg {
    newValue: Int as uint32;
}

message SetReferrerFeeMsg {
    newValue: Int as uint32;
}

message SetFeeReceiverMsg {
    newReceiver: Address;
}

message SetLowestBidMsg {
    newValue: Int as uint256;
}

message SetHighestBidMsg {
    newValue: Int as uint256;
}

message SetWaitingForOpenBidSecondsMsg {
    newValue: Int as uint256;
}

message SetMinReferrerPayoutValueMsg {
    newValue: Int as uint256;
}

message GameCreatedResponse {
    gameId: Int as uint256;
    gameAddress: Address;
}

// ============================================
// Batch Operations
// ============================================

// Create game and open multiple existing games in one transaction
message CreateGameAndOpenBidsMsg {
    bidValue: Int as coins; // Exact bid amount for the new game
    secret: Int as uint256;
    referrer: Address?;
    gameIdsToOpen: map<Int as uint16, Int as uint256>;
    keysToOpen: map<Int as uint16, Int as uint256>;
    count: Int as uint16;
}

// Join game and open multiple existing games in one transaction
message JoinGameAndOpenBidsMsg {
    gameId: Int as uint256;
    bidValue: Int as coins; // Exact bid amount to match game
    secret: Int as uint256;
    referrer: Address?;
    gameIdsToOpen: map<Int as uint16, Int as uint256>;
    keysToOpen: map<Int as uint16, Int as uint256>;
    count: Int as uint16;
}

// Just open multiple games (no create/join)
message OpenMultipleGamesMsg {
    gameIdsToOpen: map<Int as uint16, Int as uint256>;
    keysToOpen: map<Int as uint16, Int as uint256>;
    count: Int as uint16;
}

// ============================================
// Simple Operations (TON way - use multiple parallel messages)
// ============================================

// Create new game
message CreateGameMsg {
    bidValue: Int as coins; // Exact bid amount (e.g., 5 TON)
    secret: Int as uint256;
    referrer: Address?;
}

// Forward OpenBid to specific game (via Factory)
message ForwardOpenBidMsg {
    gameId: Int as uint256;
    key: Int as uint256;
}

// Join game and forward join to another game (via Factory)
// This is a convenience wrapper for clients
message ForwardJoinGameMsg {
    gameId: Int as uint256;
    bidValue: Int as coins; // Exact bid amount to match game
    secret: Int as uint256;
    referrer: Address?;
}

// ============================================
// Events - С timestamps для индексации
// ============================================

message GameDeployedEvent {
    gameId: Int as uint256;
    gameAddress: Address;
    creator: Address;
    timestamp: Int as uint32;
}

message GameInitializedEvent {
    gameId: Int as uint256;
    playerOne: Address;
    bidValue: Int as coins;
    timestamp: Int as uint32;
}

message GameStartedEvent {
    gameId: Int as uint256;
    playerOne: Address;
    playerTwo: Address;
    totalGainings: Int as coins;
    timestamp: Int as uint32;
}

message GameFinishedEvent {
    gameId: Int as uint256;
    winner: Address;
    looser: Address;
    totalGainings: Int as coins;
    timestamp: Int as uint32;
}

message GameCancelledEvent {
    gameId: Int as uint256;
    playerOne: Address;
    timestamp: Int as uint32;
}

message DrawEvent {
    gameId: Int as uint256;
    timestamp: Int as uint32;
}

message ServiceFeeChangedEvent {
    newValue: Int as uint32;
    timestamp: Int as uint32;
}

message ReferrerFeeChangedEvent {
    newValue: Int as uint32;
    timestamp: Int as uint32;
}

message FeeReceiverChangedEvent {
    newReceiver: Address;
    timestamp: Int as uint32;
}

message LowestBidChangedEvent {
    newValue: Int as uint256;
    timestamp: Int as uint32;
}

message HighestBidChangedEvent {
    newValue: Int as uint256;
    timestamp: Int as uint32;
}

message WaitingForOpenBidSecondsChangedEvent {
    newValue: Int as uint256;
    timestamp: Int as uint32;
}

message MinReferrerPayoutValueChangedEvent {
    newValue: Int as uint256;
    timestamp: Int as uint32;
}

message SystemStoppedEvent {
    timestamp: Int as uint32;
}

message SystemResumeEvent {
    timestamp: Int as uint32;
}

message BouncedMessageEvent {
    op: Int as uint32;
    gameId: Int as uint64;
    timestamp: Int as uint32;
}
