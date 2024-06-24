message StageEpidemic {
    signature: Slice;
    data: Cell;
    //seqno: UInt32;
    //users: UInt32;
}

message StageClaim {
    signature: Slice;
    data: Cell;
    //seqno: UInt32;
    //tickets: UInt32;
}

message SendRewards {
    winners: map<Int, Address>;
}

message ClaimIfSeasonFailed {

}

message UpdateSettings {
    season_end_date: Int;
    days_for_claim: Int;
}