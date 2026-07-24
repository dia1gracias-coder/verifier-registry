enum Errors {
    InvalidOption = 100
    AlreadyVoted = 101
    NotFromPoll = 102
    NotOwner
    PollClosed
    InvalidMessage = 0xffff
}

struct PollStorage {
    owner: address
    option0: uint32
    option1: uint32
    isClosed: bool
}

fun PollStorage.load(): PollStorage {
    return PollStorage.fromCell(contract.getData());
}

fun PollStorage.save(self): void {
    contract.setData(self.toCell());
}

struct VoterStorage {
    poll: address
    voter: address
    hasVoted: bool
}

fun VoterStorage.load(): VoterStorage {
    return VoterStorage.fromCell(contract.getData());
}

fun VoterStrorage.save(self) {
    contract.setData(self.toCell());
}

//messages

struct (0x694d6f6e) Vote {
    option: uint8 // TODO: why uint8, not bool? Only two options..
}

struct (0x14160e21) ClosePoll {}



