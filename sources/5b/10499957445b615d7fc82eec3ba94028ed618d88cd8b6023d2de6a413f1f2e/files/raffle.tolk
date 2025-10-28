tolk 1.0

import "@stdlib/tvm-dicts"
import "@stdlib/common"
import "@stdlib/gas-payments"
import "constants"
import "errors"
import "storage"
import "messages"
import "utils"

type AllowedMessageRaffleParticipant = RaffleRegisterCandidate | RaffleCandidateRegistrationNotification | RaffleSetConditions | RaffleApprove | RaffleNext;

fun onInternalMessage(inMessage: InMessage) {
    val inMessageBody = lazy AllowedMessageRaffleParticipant.fromSlice(inMessage.body);
    var storage = lazy RaffleStorage.load();

    match (inMessageBody) {
        RaffleRegisterCandidate => {
            assert (inMessage.valueCoins >= MIN_TONS_FOR_RAFFLE_CANDIDATE_STORAGE + RAFFLE_CANDIDATE_INITIALIZE_OPERATION_FEE) throw ERROR_NOT_ENOUGH_TONS;

            val deployRaffleCandidateMessage = createMessage({
                bounce: false,
                dest: calculateRaffleCandidateAddress(contract.getAddress(), inMessage.senderAddress, storage.candidateCode),
                value: 0,
                body: RaffleCandidateInitialize {
                    recipientAddress: inMessage.senderAddress,
                    telegramID: inMessageBody.telegramID,
                }
            });

            reserveToncoinsOnBalance(MIN_TONS_FOR_RAFFLE_STORAGE, RESERVE_MODE_EXACT_AMOUNT);
            deployRaffleCandidateMessage.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
        RaffleCandidateRegistrationNotification => {
            assert (inMessage.valueCoins >= RAFFLE_CANDIDATE_REGISTERATION_NOTIFICATION_OPERATION_FEE) throw ERROR_NOT_ENOUGH_TONS;

            storage.candidatesQuantity += 1;
            storage.save();

            val excessMessage = createMessage({
                bounce: false,
                dest: inMessageBody.recipientAddress,
                value: 0,
                body: createEmptyCell(),
            });

            reserveToncoinsOnBalance(MIN_TONS_FOR_RAFFLE_STORAGE, RESERVE_MODE_EXACT_AMOUNT);
            excessMessage.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
        RaffleSetConditions => {
            assert (inMessage.valueCoins >= MIN_TONS_FOR_RAFFLE_CANDIDATE_STORAGE + RAFFLE_SET_CONDITIONS_OPERATION_FEE) throw ERROR_NOT_ENOUGH_TONS;
            assert (inMessage.senderAddress == storage.ownerAddress) throw ERROR_NOT_AUTHORIZED;

            if (storage.minParticipantReachedUnixTime > 0) {
                assert (blockchain.now() < storage.minParticipantReachedUnixTime + storage.duration) throw ERROR_EXPIRED;
            }

            val candidate = calculateRaffleCandidateAddress(contract.getAddress(), inMessageBody.userAddress, storage.candidateCode);
            val candidateAddress = address.fromValidBuilder(candidate.buildAddress());

            val setConditionsMessage = createMessage({
                bounce: false,
                dest: candidateAddress,
                value: 0,
                body: RaffleCandidateSetConditions {
                    recipientAddress: inMessage.senderAddress,
                    conditions: inMessageBody.conditions,
                    isMatched: (storage.conditions as slice).bitsEqual(inMessageBody.conditions as slice)
                },
            });

            reserveToncoinsOnBalance(MIN_TONS_FOR_RAFFLE_STORAGE, RESERVE_MODE_EXACT_AMOUNT);
            setConditionsMessage.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
        RaffleApprove => {
            assert (
            inMessage.valueCoins >= (
                RAFFLE_CANDIDATE_SET_PARTICIPANT_INDEX_OPERATION_FEE +
                MIN_TONS_FOR_RAFFLE_PARTICIPANT_STORAGE +
                RAFFLE_PARTICIPANT_SET_USER_ADDRESS_OPERATION_FEE
            )
            ) throw ERROR_NOT_ENOUGH_TONS;

            val raffleCandidate = calculateRaffleCandidateAddress(contract.getAddress(), inMessageBody.userAddress, storage.candidateCode);
            val raffleCandidateAddress = address.fromValidBuilder(raffleCandidate.buildAddress());
            assert (inMessage.senderAddress == raffleCandidateAddress) throw ERROR_NOT_AUTHORIZED;

            val setParticipantIndexMessage = createMessage({
                bounce: true,
                dest: raffleCandidateAddress,
                value: RAFFLE_CANDIDATE_SET_PARTICIPANT_INDEX_OPERATION_FEE,
                body: RaffleCandidateSetParticipantIndex {
                    participantIndex: storage.participantsQuantity
                },
            });
            setParticipantIndexMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);

            val deployParticipantMessage = createMessage({
                bounce: false,
                dest: calculateRaffleParticipantAddress(contract.getAddress(), storage.participantsQuantity, storage.participantCode),
                value: MIN_TONS_FOR_RAFFLE_PARTICIPANT_STORAGE + RAFFLE_PARTICIPANT_SET_USER_ADDRESS_OPERATION_FEE,
                body: RaffleParticipantInitialize {
                    recipientAddress: inMessageBody.recipientAddress,
                    userAddress: inMessageBody.userAddress,
                },
            });
            deployParticipantMessage.send(SEND_MODE_PAY_FEES_SEPARATELY);

            val excessMessage = createMessage({
                bounce: false,
                dest: inMessageBody.recipientAddress,
                value: 0,
                body: createEmptyCell(),
            });

            storage.participantsQuantity += 1;
            if (storage.participantsQuantity >= storage.minParticipantQuantity && storage.minParticipantReachedLt == 0) {
                storage.minParticipantReachedLt = blockchain.logicalTime();
                storage.minParticipantReachedUnixTime = blockchain.now();
            }
            storage.save();

            reserveToncoinsOnBalance(MIN_TONS_FOR_RAFFLE_STORAGE, RESERVE_MODE_EXACT_AMOUNT);
            excessMessage.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
        RaffleNext => {
            assert (inMessage.valueCoins >= MIN_TONS_FOR_RAFFLE_PARTICIPANT_STORAGE + RAFFLE_NEXT_OPERATION_FEE) throw ERROR_NOT_ENOUGH_TONS;
            assert (blockchain.logicalTime() > storage.minParticipantReachedLt) throw ERROR_NOT_READY;
            assert (storage.participantsQuantity > storage.winnersQuantity + 1) throw ERROR_NOT_ENOUGH_USERS;

            random.initialize();

            var winnerParticipantIndex: uint64;
            var index = 0;

            var success: bool = false;
            winnerParticipantIndex = random.range(storage.participantsQuantity);

            // random first
            (_, success) = storage.winners.uDictGetRef(64, winnerParticipantIndex);

            // if already winner, wide search nearest participants before-first, after-last
            while (success) {
                index += 1;

                val isInBoundaryStart = winnerParticipantIndex - index >= 0;
                if (isInBoundaryStart) {
                    (_, success) = storage.winners.uDictGetRef(64, winnerParticipantIndex - index);
                    if (!success) {
                        winnerParticipantIndex -= index;
                    }
                }

                val isInBoundaryEnd = winnerParticipantIndex + index < storage.participantsQuantity;
                if (success && isInBoundaryEnd) {
                    (_, success) = storage.winners.uDictGet(64, winnerParticipantIndex + index);
                    if (!success) {
                        winnerParticipantIndex += index;
                    }
                }

                assert (!success || isInBoundaryStart || isInBoundaryEnd) throw ERROR_INTERNAL;
            }

            val raffleParticipantAddress = calculateRaffleParticipantAddress(
                contract.getAddress(), winnerParticipantIndex, storage.participantCode);

            val winnerMessage = createMessage({
                bounce: false,
                dest: address.fromValidBuilder(raffleParticipantAddress.buildAddress()),
                value: 0,
                body: RaffleParticipantWinnerNotification {
                    winnerIndex: storage.winnersQuantity,
                    forwardAmount: inMessageBody.forwardAmount,
                    forwardPayload: inMessageBody.forwardPayload
                },
            });

            storage.winners.uDictSetRef(64, winnerParticipantIndex, createEmptyCell());
            storage.winnersQuantity = storage.winnersQuantity + 1;
            storage.save();

            reserveToncoinsOnBalance(MIN_TONS_FOR_RAFFLE_STORAGE, RESERVE_MODE_EXACT_AMOUNT);
            winnerMessage.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_IGNORE_ERRORS);
        }
        else => {
            assert (inMessage.body.isEmpty()) throw 0xFFFF;

            val excessMessage = createMessage({
                bounce: false,
                dest: storage.ownerAddress,
                value: 0,
                body: createEmptyCell(),
            });

            reserveToncoinsOnBalance(MIN_TONS_FOR_RAFFLE_STORAGE, RESERVE_MODE_EXACT_AMOUNT);
            excessMessage.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
    }
}

get fun raffleData(): (int, int, bits256, int, int, int, int, int, dict?) {
    val storage = lazy RaffleStorage.load();
    return (
        storage.minParticipantQuantity,
        storage.duration,
        storage.conditions,
        storage.minParticipantReachedLt,
        storage.minParticipantReachedUnixTime,
        storage.candidatesQuantity,
        storage.participantsQuantity,
        storage.winnersQuantity,
        storage.winners
    );
}

get fun raffleCandidateAddress(userAddress: address): address {
    val storage = lazy RaffleStorage.load();
    val candidateAddress = calculateRaffleCandidateAddress(contract.getAddress(), userAddress, storage.candidateCode);
    return address.fromValidBuilder(candidateAddress.buildAddress());
}

get fun raffleParticipantAddress(participantIndex: uint64): address {
    val storage = lazy RaffleStorage.load();
    val participantAddress = calculateRaffleParticipantAddress(contract.getAddress(), participantIndex, storage.participantCode);
    return address.fromValidBuilder(participantAddress.buildAddress());
}
