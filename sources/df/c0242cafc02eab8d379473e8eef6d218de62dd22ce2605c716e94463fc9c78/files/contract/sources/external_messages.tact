message OpenRound {
    round: Int;
}

message Vote {
    round: Int;
    payload: String;
}

message FinalizeRound {
    round: Int;
}