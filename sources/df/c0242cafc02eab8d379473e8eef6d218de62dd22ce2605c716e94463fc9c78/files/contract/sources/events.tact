message NewParticipantEvent {
    address: Address;
    votes: Int;
    unfreezeTime: Int;
}

message ParticipantQuitEvent {
    address: Address;
    votes: Int;
    unfreezeTime: Int;
}