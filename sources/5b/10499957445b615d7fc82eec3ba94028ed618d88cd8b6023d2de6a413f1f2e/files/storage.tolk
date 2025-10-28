import "constants"
import "utils"

struct RaffleStorage {
    // state init:
    ownerAddress: address;
    minParticipantQuantity: uint32; // candidate quantity needs to start raffle coundown
    conditions: bits256;
    duration: uint32;
    candidateCode: cell;
    participantCode: cell;
    // after initialization state
    minParticipantReachedLt: uint64; // default: 0
    minParticipantReachedUnixTime: int64; // default: 0
    candidatesQuantity: uint64; // default: 0
    participantsQuantity: uint64; // default: 0
    winnersQuantity: uint8; // default: 0
    winners: dict;
}

fun RaffleStorage.load() {
    return RaffleStorage.fromCell(contract.getData());
}

fun RaffleStorage.save(self) {
    contract.setData(self.toCell());
}

struct RaffleCandidateStorage {
    // state init:
    raffleAddress: address;
    userAddress: address;
    // after initialization state
    conditions: bits256;
    isMatched: bool;
    telegramID: uint64?;
    participantIndex: uint64?;
}

fun RaffleCandidateStorage.load() {
    return RaffleCandidateStorage.fromCell(contract.getData())
}

fun RaffleCandidateStorage.save(self) {
    contract.setData(self.toCell())
}

struct RaffleParticipantStorage {
    // state init:
    raffleAddress: address;
    participantIndex: uint64;
    // after initialization state
    userAddress: address?;
    winnerIndex: uint8?;
}

fun RaffleParticipantStorage.load() {
    return RaffleParticipantStorage.fromCell(contract.getData())
}

fun RaffleParticipantStorage.save(self) {
    contract.setData(self.toCell())
}

fun calculateRaffleCandidateAddress(raffleAddress: address, userAddress: address, code: cell): AutoDeployAddress {
    val data: RaffleCandidateStorage = { raffleAddress, userAddress, conditions: createBits256None(), isMatched: false, telegramID: null, participantIndex: null };

    return {
        workchain: MY_WORKCHAIN,
        stateInit: {
            code,
            data: data.toCell()
        }
    }
}

fun calculateRaffleParticipantAddress(raffleAddress: address, participantIndex: uint64, code: cell): AutoDeployAddress {
    val data: RaffleParticipantStorage = { raffleAddress, participantIndex, userAddress: null, winnerIndex: null };

    return {
        workchain: MY_WORKCHAIN,
        stateInit: {
            code,
            data: data.toCell()
        }
    }
}