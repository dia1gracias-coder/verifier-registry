import "utils"

type ForwardPayloadRemainder = RemainingBitsAndRefs

struct (0x13370010) RaffleRegisterCandidate {
    telegramID: uint64;
}

struct (0x13370011) RaffleSetConditions {
    userAddress: address;
    conditions: bits256;
}

struct (0x13370012) RaffleApprove {
    recipientAddress: address;
    userAddress: address;
}

struct (0x13370013) RaffleNext {
    forwardAmount: coins;
    forwardPayload: SnakeString;
}

struct (0x13370020) RaffleCandidateInitialize {
    recipientAddress: address;
    telegramID: uint64;
}

struct (0x13370021) RaffleCandidateRegistrationNotification {
    recipientAddress: address;
}

struct (0x13370022) RaffleCandidateSetConditions {
    recipientAddress: address;
    conditions: bits256;
    isMatched: bool;
}

struct (0x13370023) RaffleCandidateSetParticipantIndex {
    participantIndex: uint64;
}

struct (0x13370030) RaffleParticipantInitialize {
    recipientAddress: address;
    userAddress: address;
}

struct (0x13370031) RaffleParticipantRegistrationNotification {
    recipientAddress: address;
}

struct (0x13370031) RaffleParticipantWinnerNotification {
    winnerIndex: uint8;
    forwardAmount: coins;
    forwardPayload: SnakeString;
}