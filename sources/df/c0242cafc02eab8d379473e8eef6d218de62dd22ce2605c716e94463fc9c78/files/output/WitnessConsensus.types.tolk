// Generated from the verified Tact contract ABI.
contract WitnessConsensus {
    storage: WitnessConsensusData
    incomingMessages: WitnessConsensusIncomingMessage
    thrownErrors: WitnessConsensusErrors
}

struct (0x946a98b6) WitnessConsensusDeploy {
    queryId: uint64
}

struct (0x819dbe99) WitnessConsensusChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x2c7b2804) WitnessConsensusOpenRound {
    round: int257
}

struct (0xc6d5d522) WitnessConsensusVote {
    round: int257
    payload: string
}

struct (0x89436476) WitnessConsensusFinalizeRound {
    round: int257
}

struct (0x887e5ca3) WitnessConsensusInternalRoundOpened {
    round: int257
}

struct (0xa6f19e23) WitnessConsensusInternalFinalized {
    round: int257
    winnerPayload: string?
    winnerVotes: int257?
    winnerGuarded: bool
    goodParticipants: map<int257, address>
    goodParticipantsCount: int257
    goodParticipantsVotes: map<address, int257>
    tactContinuation: Cell<WitnessConsensusInternalFinalizedContinuation>
}

struct WitnessConsensusInternalFinalizedContinuation {
    badParticipants: map<int257, address>
    badParticipantsCount: int257
    badParticipantsVotes: map<address, int257>
}

struct (0x473919df) WitnessConsensusPromoteToGuard {
    address: address
}

struct (0x93c4ed56) WitnessConsensusRevokeGuard {
    address: address
}

struct (0x510433f4) WitnessConsensusSetRoundReward {
    amount: coins
}

struct WitnessConsensusData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    stopped: bool
    genesisTimestamp: int257
    roundPeriod: int257
    tactContinuation: Cell<WitnessConsensusDataContinuation>
}

struct WitnessConsensusDataContinuation {
    minStake: int257
    stakeFreezeTime: int257
    minVotesForQuorum: int257
    participants: map<address, int257>
    pendingRewards: map<address, int257>
    guards: map<address, bool>
    tactContinuation: Cell<WitnessConsensusDataContinuation2>
}

struct WitnessConsensusDataContinuation2 {
    unfreeze: map<address, int257>
    openedRound: int257
    rewardsBudget: coins
    roundReward: coins
    version: int257
}

type WitnessConsensusIncomingMessage =
    | WitnessConsensusSetRoundReward
    | WitnessConsensusPromoteToGuard
    | WitnessConsensusRevokeGuard
    | WitnessConsensusFinalizeRound
    | WitnessConsensusInternalFinalized
    | WitnessConsensusOpenRound
    | WitnessConsensusInternalRoundOpened
    | WitnessConsensusVote
    | WitnessConsensusDeploy
    | WitnessConsensusChangeOwner

enum WitnessConsensusErrors {
    /// Stack undeflow
    StackUndeflow = 2
    /// Stack overflow
    StackOverflow = 3
    /// Integer overflow
    IntegerOverflow = 4
    /// Integer out of expected range
    IntegerOutOfExpectedRange = 5
    /// Invalid opcode
    InvalidOpcode = 6
    /// Type check error
    TypeCheckError = 7
    /// Cell overflow
    CellOverflow = 8
    /// Cell underflow
    CellUnderflow = 9
    /// Dictionary error
    DictionaryError = 10
    /// Out of gas error
    OutOfGasError = 13
    /// Method ID not found
    MethodIDNotFound = 32
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Not enough TON
    NotEnoughTON = 37
    /// Not enough extra-currencies
    NotEnoughExtraCurrencies = 38
    /// Null reference exception
    NullReferenceException = 128
    /// Invalid serialization prefix
    InvalidSerializationPrefix = 129
    /// Invalid incoming message
    InvalidIncomingMessage = 130
    /// Constraints error
    ConstraintsError = 131
    /// Access denied
    AccessDenied = 132
    /// Contract stopped
    ContractStopped = 133
    /// Invalid argument
    InvalidArgument = 134
    /// Code of a contract was not found
    CodeOfAContractWasNotFound = 135
    /// Invalid address
    InvalidAddress = 136
    /// Masterchain support is not enabled for this contract
    MasterchainSupportIsNotEnabledForThisContract = 137
    /// only opened rounds can be finalized
    OnlyOpenedRoundsCanBeFinalized = 2768
    /// only passed rounds can be finalized
    OnlyPassedRoundsCanBeFinalized = 5655
    /// not a guard
    NotAGuard = 5681
    /// guard must vote for candidate
    GuardMustVoteForCandidate = 17999
    /// wrong round
    WrongRound = 18736
    /// parent only
    ParentOnly = 20445
    /// already voted
    AlreadyVoted = 23980
    /// unfreeze not passed yet
    UnfreezeNotPassedYet = 25476
    /// invalid round
    InvalidRound = 29552
    /// invalid payload hash by counter
    InvalidPayloadHashByCounter = 34495
    /// unfreeze not found
    UnfreezeNotFound = 36401
    /// min votes not exceeded
    MinVotesNotExceeded = 37813
    /// invalid payload votes by hash
    InvalidPayloadVotesByHash = 38183
    /// too much
    TooMuch = 39981
    /// Contract stopped
    ContractStopped2 = 40368
    /// min stake
    MinStake = 42431
    /// round was finalized
    RoundWasFinalized = 46604
    /// bad sender
    BadSender = 47963
    /// not a participant
    NotAParticipant = 48360
    /// min votes required
    MinVotesRequired = 48930
    /// Contract not stopped
    ContractNotStopped = 53296
    /// unfreeze passed
    UnfreezePassed = 53872
    /// already opened
    AlreadyOpened = 56100
    /// no rewards
    NoRewards = 57037
    /// already finalized
    AlreadyFinalized = 57851
}

get fun openedRound(): int257 {
    throw 0;
}

get fun isParticipant(participant: address): bool {
    throw 0;
}

get fun participantStake(participant: address): int257 {
    throw 0;
}

get fun pendingReward(participant: address): int257? {
    throw 0;
}

get fun checkGuardAddress(address: address): bool {
    throw 0;
}

get fun votingRoundAddress(round: int257): address {
    throw 0;
}

get fun owner(): address {
    throw 0;
}

get fun stopped(): bool {
    throw 0;
}
