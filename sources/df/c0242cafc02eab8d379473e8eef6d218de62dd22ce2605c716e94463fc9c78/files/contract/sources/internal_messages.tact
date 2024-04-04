message InternalRoundOpened {
    round: Int;
}

message InternalVote {
    round: Int;
    payload: String; // 540 bytes = 27 addresses (w/o prefix 41) by 20 bytes: e.g. cd8d8ad1b4a5bd7afe46949421d2b411a3601717f279598aff304907ca03b0498c686d010d3d80bb...
    participant: Address;
    guard: Bool;
    votes: Int as coins;
}

message InternalFinalize {
    minVotes: Int;
}

message InternalFinalized {
    round: Int;
    winnerPayload: String?;
    winnerVotes: Int?;
    winnerGuarded: Bool;

    goodParticipants: map<Int, Address>;
    goodParticipantsCount: Int;
    goodParticipantsVotes: map<Address, Int>;

    badParticipants: map<Int, Address>;
    badParticipantsCount: Int;
    badParticipantsVotes: map<Address, Int>;
}
