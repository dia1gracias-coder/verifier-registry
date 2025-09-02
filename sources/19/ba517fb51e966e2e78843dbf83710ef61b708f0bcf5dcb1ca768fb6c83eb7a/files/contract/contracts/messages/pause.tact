// Admin message to set pause state
message SetPaused {
    paused: Bool;
}

// Wallet queries master for pause state
message(0x6b8f2d1a) PauseStateRequest {
    queryId: Int as uint64;
}

// Master responds with pause state
message(0x7c9e3b2d) PauseStateResponse {
    queryId: Int as uint64;
    isPaused: Bool;
}

message PausedChangedEvent {
    oldState: Bool;
    newState: Bool;
}