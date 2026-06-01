enum Errors {
    InvalidOption  = 100
    AlreadyVoted   = 101
    NotFromPoll    = 102
    NotOwner       = 103
    PollClosed     = 104
    InvalidMessage = 0xFFFF
}

// ----- Poll storage -----

struct PollStorage {
    owner:    address
    option0:  uint32
    option1:  uint32
    isClosed: bool
}

fun PollStorage.load(): PollStorage {
    return PollStorage.fromCell(contract.getData());
}

fun PollStorage.save(self) {
    contract.setData(self.toCell());
}

// ----- Voter storage -----

struct VoterStorage {
    poll: address
    voter: address
    hasVoted: bool
}

fun VoterStorage.load(): VoterStorage {
    return VoterStorage.fromCell(contract.getData());
}

fun VoterStorage.save(self) {
}

// ----- Messages -----

struct (0x694d6f6e) Vote {
    option: uint8
}

struct (0x14160e21) ClosePoll {}
