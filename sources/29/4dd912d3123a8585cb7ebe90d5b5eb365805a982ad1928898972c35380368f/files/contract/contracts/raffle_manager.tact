import "@stdlib/deploy";
import "@stdlib/ownable";
message CreateTpot {
    tpotId: Int;
    entryFee: Int;
    startAt: Int;
    endAt: Int;
    ownerPercentage: Int;
    referralPercentage: Int;
}
message JoinTpot {
    tpotId: Int;
    referralAddress: Address;
}
message CloseTpot {
    tpotId: Int;
}
message SetWinner {
    tpotId: Int;
    index: Int;
    isExistsReferral: Bool;
    referralAddress: Address;
}
message UpdateWinner {
    tpotId: Int;
    index: Int;
    isExistsReferral: Bool;
    referralAddress: Address;
}
message OwnerShareToTreasury {
    tpotId: Int;
}
message WithdrawRemainingPrizeToTreasury {
    tpotId: Int;
}
message ClaimWinner {
    tpotId: Int;
}
message ClaimWinnersReferralReward {
    tpotId: Int;
}
message ClaimJoinReferralReward {
}
message SetTreasury {
    treasuryAddr: Address;
}
message SetStartEndTime {
    tpotId: Int;
    startAt: Int;
    endAt: Int;
}
message WithdrawAll {
}
message WithdrawAllWithoutDestruction {
}
message WithdrawAllExcludingPrize {
}
message SetJoinReferralPercentage {
    percentage: Int;
}
message SetGasFeePercentage {
    percentage: Int;
}
message DeleteTpot {
    tpotId: Int;
}
message TPotEvent {
    event: String;
    tpotId: Int as uint32;
    senderAddress: Address;
    referralAddress: Address;
    amount: Int as uint128;
    referralAmount: Int as uint128;
}
struct Winner {
    address: Address;
    prizeAmount: Int as uint128;
    isClaimed: Bool;
    claimedAt: Int as uint32;
    claimAbleAt: Int as uint32;
}
struct TPotOwnerInfo {
    amount: Int as uint128;
    isClaimed: Bool;
    isRemainingPrizeClaimed: Bool;
    claimedAt: Int as uint32;
}
struct TpotInfo {
    tpotId: Int as uint32;
    totalAmount: Int as uint128;
    entryFee: Int as uint128;
    participants: map<Int as uint32, Address>; // Cyclic array implementation
    participantsLength: Int as uint32;
    winner: Winner;
    referral: Winner;
    closed: Bool;
    createdAt: Int as uint32;
    startAt: Int as uint32;
    endAt: Int as uint32;
    ownerPercentage: Int as uint8;
    referralPercentage: Int as uint8;
    owner: TPotOwnerInfo;
}
struct ParticipantInfo {
    // totalEntryAmount: Int as uint128;
    totalJoinReferralAmount: Int as uint128;
    currentReferralAmount: Int as uint128;
    lastEntryAt: Int as uint32;
    entryCount: Int as uint32;
    lastClaimedAt: Int as uint32;
    claimableAt: Int as uint32;
}

contract RaffleManager with Deployable, Ownable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.1"); // enough for 1 KB of storage for 2.5 years
    const SEC_1_MONTH: Int = ((60 * 60) * 24) * 30;
    // const SEC_1_MONTH: Int = (60 * 60) * 1;
    owner: Address;
    treasuryAddress: Address;
    tpots: map<Int as uint32, TpotInfo>;
    participantInfo: map<Address, ParticipantInfo>;
    joinReferralPercentage: Int as uint8;
    gasFeePercentage: Int as uint8;
    init(initialOwner: Address, treasuryAddr: Address){
        self.owner = initialOwner;
        self.treasuryAddress = treasuryAddr;
        self.joinReferralPercentage = 20;
        self.gasFeePercentage = 10;
    }

    receive(msg: CreateTpot){
        self.requireOwner();
        require(!self.tpots.exists(msg.tpotId), "T-Pot ID already exists");
        let newAddr = newAddress(0, 0);
        self.tpots.set(msg.tpotId,
            TpotInfo{
                tpotId: msg.tpotId,
                totalAmount: 0,
                entryFee: msg.entryFee,
                participants: emptyMap(),
                participantsLength: 0,
                winner: Winner{address: newAddr, prizeAmount: 0, isClaimed: false, claimedAt: 0, claimAbleAt: 0},
                referral: Winner{address: newAddr, prizeAmount: 0, isClaimed: false, claimedAt: 0, claimAbleAt: 0},
                closed: false,
                createdAt: now(),
                startAt: msg.startAt,
                endAt: msg.endAt,
                ownerPercentage: msg.ownerPercentage,
                referralPercentage: msg.referralPercentage,
                owner: TPotOwnerInfo{amount: 0, isClaimed: false, isRemainingPrizeClaimed: false, claimedAt: 0}
            }
        );
        self.notify("TPOT CREATE".asComment());
        emit(TPotEvent{
                event: "TPOT_CREATE",
                tpotId: msg.tpotId,
                senderAddress: sender(),
                referralAddress: newAddress(0, 0),
                amount: msg.entryFee,
                referralAmount: msg.entryFee
            }.toCell()
        );
    }

    receive(msg: JoinTpot){
        let ctx: Context = context();
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(!tpot.closed, "T-Pot is closed");
        let curTime = now();
        require(tpot.startAt < curTime && tpot.endAt > curTime, "This T-Pot is no longer available");
        let entryfee = tpot.entryFee;
        require(ctx.value >= entryfee, "Insufficient entry fee for T-Pot");
        let participantIndex = tpot.participantsLength;
        let participantStdAddr = ctx.sender;
        tpot.participants.set(participantIndex, participantStdAddr);
        tpot.participantsLength = participantIndex + 1;
        tpot.totalAmount += entryfee;
        let gasFeeAmount = (entryfee * self.gasFeePercentage) / 100;
        let usableRemainingAmount = entryfee - gasFeeAmount;
        let joinReferralAmount = (usableRemainingAmount * self.joinReferralPercentage) / 100;
        let winnerReferralAmount = (usableRemainingAmount * tpot.referralPercentage) / 100;
        let ownerAmount = ((usableRemainingAmount * tpot.ownerPercentage) / 100) - winnerReferralAmount;
        tpot.winner.prizeAmount += ((usableRemainingAmount - ownerAmount) - joinReferralAmount) - winnerReferralAmount;
        tpot.referral.prizeAmount += winnerReferralAmount;
        tpot.owner.amount += ownerAmount;
        if (self.participantInfo.exists(participantStdAddr)) {
            let entryInfo = self.participantInfo.get(participantStdAddr)!!;
            // entryInfo.totalEntryAmount += entryfee;
            entryInfo.entryCount += 1;
            entryInfo.lastEntryAt = curTime;
            entryInfo.claimableAt = curTime + self.SEC_1_MONTH;
            self.participantInfo.set(participantStdAddr, entryInfo);
        } else {
            let entryInfo = ParticipantInfo{
                // totalEntryAmount: entryfee,
                totalJoinReferralAmount: 0,
                currentReferralAmount: 0,
                lastEntryAt: curTime,
                entryCount: 1,
                lastClaimedAt: 0,
                claimableAt: curTime + self.SEC_1_MONTH
            };
            self.participantInfo.set(participantStdAddr, entryInfo);
        }
        if (msg.referralAddress != newAddress(0, 0)) {
            if (self.participantInfo.exists(msg.referralAddress)) {
                let referralInfo = self.participantInfo.get(msg.referralAddress)!!;
                referralInfo.totalJoinReferralAmount += joinReferralAmount;
                referralInfo.currentReferralAmount += joinReferralAmount;
                referralInfo.claimableAt = curTime + self.SEC_1_MONTH;
                self.participantInfo.set(msg.referralAddress, referralInfo);
            } else {
                let referralInfo = ParticipantInfo{
                    // totalEntryAmount: 0,
                    totalJoinReferralAmount: joinReferralAmount,
                    currentReferralAmount: joinReferralAmount,
                    lastEntryAt: 0,
                    entryCount: 0,
                    lastClaimedAt: 0,
                    claimableAt: curTime + self.SEC_1_MONTH
                };
                self.participantInfo.set(msg.referralAddress, referralInfo);
            }
        } else {
            tpot.owner.amount += joinReferralAmount;
        }
        self.tpots.set(msg.tpotId, tpot);

        emit(TPotEvent{
                event: "TPOT_JOIN",
                tpotId: msg.tpotId,
                senderAddress: sender(),
                referralAddress: msg.referralAddress,
                amount: entryfee,
                referralAmount: msg.referralAddress != newAddress(0, 0) ? joinReferralAmount : 0
            }.toCell()
        );
    }

    receive(msg: CloseTpot){
        self.requireOwner();
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(!tpot.closed, "T-Pot is already closed");
        tpot.closed = true;
        self.tpots.set(msg.tpotId, tpot);
        self.notify("TPOT_CLOSE".asComment());
        emit(TPotEvent{
                event: "TPOT_CLOSE",
                tpotId: msg.tpotId,
                senderAddress: sender(),
                referralAddress: newAddress(0, 0),
                amount: 0,
                referralAmount: 0
            }.toCell()
        );
    }

    receive(msg: DeleteTpot){
        self.requireOwner();
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(tpot.closed, "T-Pot is still open.");
        let curTime = now();
        require(tpot.winner.prizeAmount == 0 || tpot.winner.claimAbleAt < curTime || tpot.winner.isClaimed,
            "Winner claim pending"
        );
        require(tpot.referral.prizeAmount == 0 || tpot.referral.claimAbleAt < curTime || tpot.referral.isClaimed,
            "Winner's referral claim pending"
        );
        require(tpot.owner.amount == 0 || tpot.owner.isClaimed, "Owner claim pending");
        self.tpots.del(msg.tpotId);
        self.notify("TPOT_DELETE".asComment());
        emit(TPotEvent{
                event: "TPOT_DELETE",
                tpotId: msg.tpotId,
                senderAddress: sender(),
                referralAddress: newAddress(0, 0),
                amount: 0,
                referralAmount: 0
            }.toCell()
        );
    }

    receive(msg: SetWinner){
        self.requireOwner();
        let claimableat = now() + self.SEC_1_MONTH;
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(tpot.closed, "T-Pot is still open");
        require(msg.index >= 0 && msg.index < tpot.participantsLength, "Winner index not valid!");
        require(tpot.participants.exists(msg.index), "Participant does not exist");
        let winnerAddr = tpot.participants.get(msg.index);
        require(winnerAddr != null, "Participant does not exist");
        require(tpot.winner.claimAbleAt == 0, "The winner has already been selected");
        tpot.winner.address = winnerAddr!!;
        tpot.winner.claimAbleAt = claimableat;
        if (msg.isExistsReferral) {
            tpot.referral.address = msg.referralAddress;
            tpot.referral.claimAbleAt = claimableat;
        } else {
            tpot.owner.amount += tpot.referral.prizeAmount;
            tpot.referral.prizeAmount = 0;
        }
        self.tpots.set(msg.tpotId, tpot);
        self.notify("TPOT_SET_WINNER".asComment());
        emit(TPotEvent{
                event: "TPOT_SET_WINNER",
                tpotId: msg.tpotId,
                senderAddress: tpot.winner.address,
                referralAddress: tpot.referral.address,
                amount: tpot.winner.prizeAmount,
                referralAmount: tpot.referral.prizeAmount
            }.toCell()
        );
    }

    receive(msg: UpdateWinner){
        self.requireOwner();
        let claimableat = now() + self.SEC_1_MONTH;
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(tpot.closed, "T-Pot is still open");
        require(!tpot.winner.isClaimed, "Winner has already been claimed");
        require(!tpot.referral.isClaimed, "Referral has already been claimed");
        require(msg.index >= 0 && msg.index < tpot.participantsLength, "Winner index not valid!");
        require(tpot.participants.exists(msg.index), "Participant does not exist");
        let winnerAddr = tpot.participants.get(msg.index);
        require(winnerAddr != null, "Participant does not exist");
        tpot.winner.address = winnerAddr!!;
        tpot.winner.claimAbleAt = claimableat;
        if (msg.isExistsReferral) {
            tpot.referral.address = msg.referralAddress;
            tpot.referral.claimAbleAt = claimableat;
        } else {
            tpot.referral.prizeAmount = 0;
            if (!tpot.owner.isClaimed) {
                tpot.owner.amount += tpot.referral.prizeAmount;
            }
        }
        self.tpots.set(msg.tpotId, tpot);
        self.notify("TPOT_UPDATE_WINNER".asComment());
        emit(TPotEvent{
                event: "TPOT_UPDATE_WINNER",
                tpotId: msg.tpotId,
                senderAddress: tpot.winner.address,
                referralAddress: tpot.referral.address,
                amount: tpot.winner.prizeAmount,
                referralAmount: tpot.referral.prizeAmount
            }.toCell()
        );
    }

    receive(msg: OwnerShareToTreasury){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(tpot.closed, "T-Pot is still open");
        require(tpot.winner.prizeAmount > 0, "Winner is not registed yet");
        require(!tpot.owner.isClaimed, "Already taken!!");
        require(tpot.owner.amount > 0, "Owner’s share zeor");
        require((tpot.owner.amount + self.MinTonForStorage) <= myBalance(), "Contract balance is insufficient!!!");
        send(SendParameters{
                to: self.treasuryAddress,
                bounce: true,
                value: tpot.owner.amount,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "TPOT_SEND_TO_TREASURY Owner share.".asComment()
            }
        );
        tpot.owner.isClaimed = true;
        tpot.owner.claimedAt = now();
        self.tpots.set(msg.tpotId, tpot);
        self.notify("TPOT_SEND_TO_TREASURY".asComment());

        emit(TPotEvent{
                event: "TPOT_SEND_TO_TREASURY",
                tpotId: msg.tpotId,
                senderAddress: self.owner,
                referralAddress: self.treasuryAddress,
                amount: tpot.owner.amount,
                referralAmount: 0
            }.toCell()
        );
    }


    receive(msg: ClaimWinner){
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let ctx: Context = context();
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(tpot.closed, "T-Pot is still open.");
        require(!tpot.winner.isClaimed, "Already taken.");
        let curTime = now();
        require(tpot.winner.claimAbleAt > curTime, "Claiming time is over");
        // let winnerAddr = newAddress(0, tpot.winner.address);
        require(ctx.sender == tpot.winner.address, "Only the winner is allowed to claim");
        require(tpot.winner.prizeAmount > 0, "Winner prize amount is 0!!");
        require(tpot.winner.prizeAmount <= myBalance(), "Contract balance is insufficient!!!");
        send(SendParameters{
                to: ctx.sender,
                bounce: true,
                value: tpot.winner.prizeAmount,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "TPOT_CLAIM_WINNER".asComment()
            }
        );
        tpot.winner.isClaimed = true;
        tpot.winner.claimedAt = curTime;
        self.tpots.set(msg.tpotId, tpot);
        self.notify("TPOT_CLAIM_WINNER".asComment());

        emit(TPotEvent{
                event: "TPOT_CLAIM_WINNER",
                tpotId: msg.tpotId,
                senderAddress: ctx.sender,
                referralAddress: ctx.sender,
                amount: tpot.winner.prizeAmount,
                referralAmount: 0
            }.toCell()
        );
    }

    receive(msg: ClaimWinnersReferralReward){
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let ctx: Context = context();
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(tpot.closed, "T-Pot is still open.");
        require(!tpot.referral.isClaimed, "Already taken.");
        let curTime = now();
        require(tpot.winner.claimAbleAt > curTime, "Claiming time is over");
        // let referralAddr = newAddress(0, tpot.referral.address);
        require(ctx.sender == tpot.referral.address, "Only the winner is allowed to claim");
        require(tpot.referral.prizeAmount > 0, "Winner prize amount is 0!!");
        require(tpot.referral.prizeAmount <= myBalance(), "Contract balance is insufficient!!!");
        send(SendParameters{
                to: ctx.sender,
                bounce: true,
                value: tpot.referral.prizeAmount,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "TPOT_CLAIM_WINNER_REFERRAL".asComment()
            }
        );
        tpot.referral.isClaimed = true;
        tpot.referral.claimedAt = curTime;
        self.tpots.set(msg.tpotId, tpot);
        self.notify("TPOT_CLAIM_WINNER_REFERRAL".asComment());

        emit(TPotEvent{
                event: "TPOT_CLAIM_WINNER_REFERRAL",
                tpotId: msg.tpotId,
                senderAddress: ctx.sender,
                referralAddress: ctx.sender,
                amount: tpot.referral.prizeAmount,
                referralAmount: tpot.referral.prizeAmount
            }.toCell()
        );
    }

    receive(msg: ClaimJoinReferralReward){
        let ctx: Context = context();
        // let joinReferralAddr = parseStdAddress(ctx.sender.asSlice());
        require(self.participantInfo.exists(ctx.sender), "Address does not exist");
        let referralInfo = self.participantInfo.get(ctx.sender)!!;
        // require(referralInfo != null, "No Referral Earnings Linked to This Wallet Address");
        require(referralInfo.currentReferralAmount > 0, "No amount available for claim");
        require(referralInfo.claimableAt > now(), "Claiming time is over");
        require(referralInfo.currentReferralAmount < myBalance(), "Contract balance is insufficient!!!");
        let claimaAmount = referralInfo.currentReferralAmount;
        send(SendParameters{
                to: ctx.sender,
                bounce: true,
                value: claimaAmount,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "TPOT_CLAIM_JOIN_REFERRAL".asComment()
            }
        );
        referralInfo.currentReferralAmount = 0;
        referralInfo.lastClaimedAt = now();
        referralInfo.claimableAt = 0;
        self.participantInfo.set(ctx.sender, referralInfo);
        self.notify("TPOT_CLAIM_JOIN_REFERRAL".asComment());

        emit(TPotEvent{
                event: "TPOT_CLAIM_JOIN_REFERRAL",
                tpotId: 0,
                senderAddress: ctx.sender,
                referralAddress: ctx.sender,
                amount: claimaAmount,
                referralAmount: claimaAmount
            }.toCell()
        );
    }

    receive(msg: SetTreasury){
        self.requireOwner();
        self.treasuryAddress = msg.treasuryAddr;
        self.notify("TPOT_SET_TREASURY".asComment());
        emit(TPotEvent{
                event: "TPOT_SET_TREASURY",
                tpotId: 0,
                senderAddress: sender(),
                referralAddress: self.treasuryAddress,
                amount: 0,
                referralAmount: 0
            }.toCell()
        );
    }

    get fun balance(tpotId: Int): String {
        require(self.tpots.exists(tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(tpotId)!!;
        return tpot.totalAmount.toCoinsString();
    }

    receive(msg: SetStartEndTime){
        self.requireOwner();
        require(self.tpots.exists(msg.tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(msg.tpotId)!!;
        require(!tpot.closed, "T-Pot is already closed");
        tpot.startAt = msg.startAt;
        tpot.endAt = msg.endAt;
        self.tpots.set(msg.tpotId, tpot);
        self.notify("TPOT_UPDATE_TIME".asComment());

        emit(TPotEvent{
                event: "TPOT_UPDATE_TIME",
                tpotId: msg.tpotId,
                senderAddress: sender(),
                referralAddress: sender(),
                amount: 0,
                referralAmount: 0
            }.toCell()
        );
    }

    get fun tpotInfo(tpotId: Int): TpotInfo {
        if (self.tpots.exists(tpotId)) {
            return self.tpots.get(tpotId)!!;
        } else {
            // let newAddr = parseStdAddress(newAddress(0, 0).asSlice());
            return
                TpotInfo{
                    tpotId: -1,
                    entryFee: -1,
                    totalAmount: 0,
                    participants: emptyMap(),
                    participantsLength: 0,
                    winner: Winner{
                        address: newAddress(0, 0),
                        prizeAmount: 0,
                        isClaimed: false,
                        claimedAt: 0,
                        claimAbleAt: 0
                    },
                    referral: Winner{
                        address: newAddress(0, 0),
                        prizeAmount: 0,
                        isClaimed: false,
                        claimedAt: 0,
                        claimAbleAt: 0
                    },
                    closed: false,
                    createdAt: 0,
                    startAt: 0,
                    endAt: 0,
                    ownerPercentage: 0,
                    referralPercentage: 0,
                    owner: TPotOwnerInfo{amount: 0, isClaimed: false, isRemainingPrizeClaimed: false, claimedAt: 0}
                };
        }
    }

    get fun participant(tpotId: Int, index: Int): Address {
        require(self.tpots.exists(tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(tpotId)!!;
        require(index >= 0 && index < tpot.participantsLength, "Index out of bounds");
        require(tpot.participants.exists(index), "T-Pot participant does not exist");
        // let partStdAddr = tpot.participants.get(index)!!;
        // let partAddr = newAddress(0, partStdAddr);
        return tpot.participants.get(index)!!;
    }

    // get fun myParticipantInfo(tpotId: Int, address: Address): TpotInfo {
    //     require(self.tpots.exists(tpotId), "T-Pot does not exist");
    //     let myTpotInfo = self.tpots.get(tpotId)!!;
    //     let participants: map<Int, StdAddress> = emptyMap();
    //     let count = 0;
    //     let userStdAddr = parseStdAddress(address.asSlice());
    //     foreach (key, value in myTpotInfo.participants) {
    //         if (value == userStdAddr) {
    //             participants.set(key, value);
    //             count += 1;
    //         }
    //     }
    //     myTpotInfo.participants = participants;
    //     myTpotInfo.participantsLength = count;
    //     return myTpotInfo;
    // }

    get fun joinReferralRewardAmount(address: Address): Int {
        // let referralStdAddr = parseStdAddress(address.asSlice());
        if (!self.participantInfo.exists(address)) {
            return -1;
        }
        let referralInfo = self.participantInfo.get(address)!!;
        let curTime = now();
        return referralInfo.claimableAt > curTime ? referralInfo.currentReferralAmount : 0;
    }

    get fun participantInfo(address: Address): ParticipantInfo {
        // let participantStdAddr = parseStdAddress(address.asSlice());
        require(self.participantInfo.exists(address), "Address does not exist");
        let referralInfo = self.participantInfo.get(address)!!;
        return referralInfo;
    }

    get fun allParticipantInfos(): map<Address, ParticipantInfo> {
        return self.participantInfo;
    }

    get fun treasuryAddress(): Address {
        return self.treasuryAddress;
    }

    get fun currentPotEntryFee(tpotId: Int): Int {
        require(self.tpots.exists(tpotId), "T-Pot does not exist");
        let tpot = self.tpots.get(tpotId)!!;
        require(!tpot.closed, "T-Pot is already closed");
        // let entryfee = tpot.entryFee;
        // let curTime = now();
        // if (curTime < tpot.earlyDiscountEndAt && tpot.earlyDiscountPercentage > 0) {
        //     let discountAmount = (entryfee * tpot.earlyDiscountPercentage) / 100;
        //     entryfee -= discountAmount;
        // }
        return tpot.entryFee;
    }

    get fun allTpots(): map<Int as uint32, TpotInfo> {
        return self.tpots;
    }

    // get fun tpots(tpotIds: Slice): map<Int, TpotInfo> {
    // while (tpotIds.has_next()) {
    //     sum = sum + input.load_uint(32); // 32비트 정수 값 로드
    // }
    // return self.tpots;
    // }

    get fun pureTransactionSumExcludingPrize(): Int {
        let needAmounts = 0;
        foreach (key, tpot in self.tpots) {
            if (tpot.closed) {
                if (!tpot.winner.isClaimed) {
                    needAmounts += tpot.winner.prizeAmount;
                }
                if (!tpot.referral.isClaimed) {
                    needAmounts += tpot.referral.prizeAmount;
                }
                if (!tpot.owner.isClaimed) {
                    needAmounts += tpot.owner.amount;
                }
            } else {
                needAmounts += tpot.winner.prizeAmount;
                needAmounts += tpot.referral.prizeAmount;
                needAmounts += tpot.owner.amount;
            }
        }
        return myBalance() - needAmounts;
    }

    receive(msg: WithdrawAllWithoutDestruction){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        let amount = (myBalance() - context().value) - self.MinTonForStorage;
        send(SendParameters{
                to: self.treasuryAddress,
                bounce: true,
                value: amount,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "TPOT_SEND_ALL_TO_TREASURY".asComment()
            }
        );
        self.notify("TPOT_SEND_ALL_TO_TREASURY".asComment());

        emit(TPotEvent{
                event: "TPOT_SEND_ALL_TO_TREASURY_SAFE",
                tpotId: 0,
                senderAddress: sender(),
                referralAddress: self.treasuryAddress,
                amount: amount,
                referralAmount: 0
            }.toCell()
        );
    }

    receive(msg: WithdrawAll){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        let balance = myBalance();
        send(SendParameters{
                to: self.treasuryAddress,
                bounce: true,
                value: balance,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "TPOT_SEND_ALL_TO_TREASURY".asComment()
            }
        );
        self.notify("TPOT_SEND_ALL_TO_TREASURY".asComment());
        emit(TPotEvent{
                event: "TPOT_SEND_ALL_TO_TREASURY",
                tpotId: 0,
                senderAddress: sender(),
                referralAddress: self.treasuryAddress,
                amount: balance,
                referralAmount: 0
            }.toCell()
        );
    }

    receive(msg: WithdrawAllExcludingPrize){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        let reamainingAmounts = self.pureTransactionSumExcludingPrize() - self.MinTonForStorage;
        // let amount = (myBalance() - reamainingAmounts) - self.MinTonForStorage;
        send(SendParameters{
                to: self.treasuryAddress,
                bounce: true,
                value: reamainingAmounts,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "Withdraw(ExcludingPrize) all successfully".asComment()
            }
        );
        self.notify("Withdraw(ExcludingPrize) all successfully".asComment());

        emit(TPotEvent{
                event: "TPOT_SEND_ALL_TO_TREASURY_EXCEPT_PRIZE",
                tpotId: 0,
                senderAddress: sender(),
                referralAddress: self.treasuryAddress,
                amount: reamainingAmounts,
                referralAmount: 0
            }.toCell()
        );
    }

    receive(msg: SetJoinReferralPercentage){
        self.requireOwner();
        self.joinReferralPercentage = msg.percentage;
        self.notify("TPOT_UPDATE_JOIN_REFERRAL".asComment());

        emit(TPotEvent{
                event: "TPOT_UPDATE_JOIN_REFERRAL",
                tpotId: 0,
                senderAddress: sender(),
                referralAddress: self.treasuryAddress,
                amount: self.joinReferralPercentage,
                referralAmount: 0
            }.toCell()
        );
    }

    receive(msg: SetGasFeePercentage){
        self.requireOwner();
        self.gasFeePercentage = msg.percentage;
        self.notify("TPOT_UPDATE_GAS_RATE".asComment());

        emit(TPotEvent{
                event: "TPOT_UPDATE_GAS_RATE",
                tpotId: 0,
                senderAddress: sender(),
                referralAddress: self.treasuryAddress,
                amount: self.gasFeePercentage,
                referralAmount: 0
            }.toCell()
        );
    }
}