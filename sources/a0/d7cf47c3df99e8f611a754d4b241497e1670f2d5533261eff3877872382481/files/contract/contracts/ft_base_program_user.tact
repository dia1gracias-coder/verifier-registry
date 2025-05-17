import "@stdlib/deploy";

import "./info_extends.tact";
import "./messages.tact";

contract FtBaseProgramUser with Deployable {
    const minTonsForStorage: Int = ton("0.1");

    id: Int as uint64;
    owner: Address?;
    program: Address;
    invitedAddress: Address?;
    holdBalance: Int as coins = ton("0.0");

    overtakeInfo: map<Int as uint8, Int as uint16> = emptyMap();
    levelInfo: map<Int as uint8, Info> = emptyMap();
    lastLevel: Int as uint8 = 0;

    init(id: Int, program: Address){
        nativeThrowUnless(132, sender() == program);

        self.id = id;
        self.program = program;
    }

    receive(){}

    receive("gift"){}

    receive("withdraw"){
        self.requireOwner();
        nativeReserve(self.minTonsForStorage + self.holdBalance, 0);

        send(SendParameters{
            to: self.owner!!,
            value: 0,
            mode: SendRemainingBalance,
            body: "Your withdraw".asComment(),
        });
    }

    receive(msg: ActivateLevel){
        self.requireProgram();
        self.checkPossibilityActivateLevel(msg.levelNumber);

        let balance: Int = myBalance() - context().value;
        nativeReserve(max(balance, self.minTonsForStorage), 0);

        self.lastLevel = msg.levelNumber;
        self.levelInfo.set(msg.levelNumber, Info{});

        if (self.owner == null){
            self.owner = msg.owner;
        }
        
        if (self.invitedAddress == null){
            self.invitedAddress = self.programUserAddress(msg.invitedId);
        }

        if(self.id != 1){
            self.sendToUpline(self.id, msg.levelNumber, msg.levelPrice, msg.recipientExcesses);
        } else {
            self.lastLevel = 12;
            self.sendExcesses(self.owner!!);
        }
    }

    receive(msg: UpdateMatrix){
        self.requireUserProgram(msg.fromId);
        let balance: Int = myBalance() - context().value;

        if (self.id == 1){
            self.updateMatrixForId1(msg, balance);
        } else if (self.lastLevel < msg.levelNumber){
            nativeReserve(balance, 0);
            self.makeOvertake(msg.id, msg.levelNumber, msg.levelPrice, msg.recipientExcesses);
        } else {
           self.updateMatrixForNonId1(msg, balance);
        }
    }

    receive(msg: OverflowUp){
        self.requireUserProgram(msg.fromId);
        let balance: Int = myBalance() - context().value;

        let info: Info = self.getInfo(msg.levelNumber);
        let isFrozen = info.isFrozenLevel(msg.levelNumber, self.lastLevel);
        let statusCode: Int = info.findPlaceForOverflowUp(msg.id, msg.fromId, msg.levelPrice, isFrozen);
        
        let splitLevelPrice = msg.levelPrice / 2;

        if (statusCode < 40) {
            emit(ReinvestNumber{reinvestNumber: info.reinvestCount, statusCode: statusCode}.toCell());

            if (statusCode > 30 && self.id != 1) {
                self.holdBalance += splitLevelPrice;
            }

            if (isFrozen && statusCode < 30) {
                nativeReserve(balance, 0);
                self.sendGift(splitLevelPrice);
            } else {
                nativeReserve(balance + splitLevelPrice, 0);
            }

            self.levelInfo.set(msg.levelNumber, info);
            self.sendExcesses(msg.recipientExcesses);
        } else if (statusCode > 40) {
            self.finishCycle(info, msg.levelNumber);

            if (self.id != 1) {
                self.holdBalance -= splitLevelPrice;
                nativeReserve(balance - splitLevelPrice, 0);
                self.sendToUpline(self.id, msg.levelNumber, msg.levelPrice, msg.recipientExcesses);
            } else {
                nativeReserve(balance + splitLevelPrice, 0);
                self.sendExcesses(msg.recipientExcesses);
            }
        }
    }

    receive(msg: OverflowDown){
        self.requireUserProgram(msg.fromId);
        let balance: Int = myBalance() - context().value;

        let info: Info = self.getInfo(msg.levelNumber);
        let isFrozen: Bool = info.isFrozenLevel(msg.levelNumber, self.lastLevel);
        info.findPlaceForOverflowDown(msg.id, msg.levelPrice, isFrozen);
        self.levelInfo.set(msg.levelNumber, info);
        
        emit(ReinvestNumber{reinvestNumber: info.reinvestCount}.toCell());

        let splitLevelPrice = msg.levelPrice / 2;
        if (isFrozen) {
            nativeReserve(balance, 0);
            self.sendGift(splitLevelPrice);
        } else {
            nativeReserve(balance + splitLevelPrice, 0);
        }

        self.sendExcesses(msg.recipientExcesses);
    }

    receive(msg: UpdateUpperAddress){
        self.requireUserProgram(msg.fromId);

        let info: Info = self.getInfo(msg.levelNumber);
        info.updateUpperAddress(msg.upperAddress);
        self.levelInfo.set(msg.levelNumber, info);

        self.sendRemainingValue(msg.recipientExcesses);
    }

    // ------------------ Private Function  ------------------ //

    fun updateMatrixForId1(msg: UpdateMatrix, balance: Int){
        let info: Info = self.getInfo(msg.levelNumber);
        let statusCode: Int = info.findPlaceInMatrix(msg.id, msg.fromId, msg.levelNumber, msg.levelPrice, self.lastLevel);
        self.levelInfo.set(msg.levelNumber, info);

        let splitLevelPrice = msg.levelPrice / 2;
        let reserveValue = (statusCode < 10) ? msg.levelPrice : splitLevelPrice;
        nativeReserve(balance + reserveValue, 0);

        if (statusCode < 40) {
            emit(ReinvestNumber{reinvestNumber: info.reinvestCount, statusCode: statusCode}.toCell());
        }

        if (statusCode < 10){
            self.sendUpdateUpperAddess(msg.id, myAddress(), msg.levelNumber, 0, msg.recipientExcesses);
        } else {
            if (statusCode > 40) {
                self.finishCycle(info, msg.levelNumber);
            }

            let recipient: Int = (statusCode % 10 == 1) ? info.matrix.u1!! : info.matrix.u2!!;
            self.sendOverflowDown(recipient, msg.id, msg.levelNumber, msg.levelPrice, 0, msg.recipientExcesses);
        }
    }

    fun updateMatrixForNonId1(msg: UpdateMatrix, balance: Int){
        let info: Info = self.getInfo(msg.levelNumber);

        if (msg.levelNumber != 1 && info.upperAddress == null){
            nativeReserve(balance, 0);
            self.makeOvertake(msg.id, msg.levelNumber, msg.levelPrice, msg.recipientExcesses);
            return;
        } 

        let statusCode: Int = info.findPlaceInMatrix(msg.id, msg.fromId, msg.levelNumber, msg.levelPrice, self.lastLevel);
        self.levelInfo.set(msg.levelNumber, info);

        if (statusCode < 40) {
            emit(ReinvestNumber{reinvestNumber: info.reinvestCount, statusCode: statusCode}.toCell());
        }

        let isFrozen: Bool = info.isFrozenLevel(msg.levelNumber, self.lastLevel);
        let splitLevelPrice: Int = msg.levelPrice / 2;
        let isFirst: Bool = (statusCode % 10 == 1);

        if (statusCode < 10){
            if (isFrozen) {
                nativeReserve(balance, 0);
                self.sendGift(splitLevelPrice);
            } else {
                nativeReserve(balance + splitLevelPrice, 0);
            }

            self.sendUpdateUpperAddess(msg.id, myAddress(), msg.levelNumber, ton("0.05"), msg.recipientExcesses);
            let recipient = (info.upperAddress == null) ? self.invitedAddress!! : info.upperAddress!!;
            self.sendOverflowUp(recipient, msg.id, msg.levelNumber, msg.levelPrice, msg.recipientExcesses);
        } else if (statusCode < 40) {
            if (statusCode > 30) {
                self.holdBalance += splitLevelPrice;
            }

            if (isFrozen && statusCode < 30) {
                nativeReserve(balance, 0);
                self.sendGift(splitLevelPrice);
            } else {
                nativeReserve(balance + splitLevelPrice, 0);
            }

            let recipient = isFirst ? info.matrix.u1!! : info.matrix.u2!!;
            self.sendOverflowDown(recipient, msg.id, msg.levelNumber, msg.levelPrice, 0, msg.recipientExcesses);
        } else {
            self.holdBalance -= splitLevelPrice;
            nativeReserve(balance - splitLevelPrice, 0);

            let recipient = isFirst ? info.matrix.u1!! : info.matrix.u2!!;
            self.finishCycle(info, msg.levelNumber);
            self.sendOverflowDown(recipient, msg.id, msg.levelNumber, msg.levelPrice, splitLevelPrice, msg.recipientExcesses);
            self.sendToUpline(self.id, msg.levelNumber, msg.levelPrice, msg.recipientExcesses);
        }
    }

    fun makeOvertake(id: Int, levelNumber: Int, levelPrice: Int, recipientExcesses: Address){
        self.updateOvertakingInfo(levelNumber);
        self.sendToUpline(id, levelNumber, levelPrice, recipientExcesses);
    }

    fun sendToUpline(id: Int, levelNumber: Int, levelPrice: Int, recipientExcesses: Address){
        send(SendParameters{
            to: self.invitedAddress!!,
            value: 0,
            mode: SendRemainingBalance,
            body: UpdateMatrix{
                id: id,
                fromId: self.id,
                levelNumber: levelNumber,
                levelPrice: levelPrice,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    fun sendUpdateUpperAddess(toId: Int, upperAddress: Address, levelNumber: Int, value: Int, recipientExcesses: Address){
        let mode: Int = 128;

        if (value != 0) {
            mode = 3;
        }

        send(SendParameters{
            to: self.programUserAddress(toId),
            value: value,
            mode: mode,
            body: UpdateUpperAddress{
                fromId: self.id,
                upperAddress: upperAddress,
                levelNumber: levelNumber,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    fun sendOverflowUp(recipient: Address, id: Int, levelNumber: Int, levelPrice: Int, recipientExcesses: Address){
        send(SendParameters{
            to: recipient,
            value: 0,
            mode: SendRemainingBalance,
            body: OverflowUp{
                id: id,
                fromId: self.id,
                levelNumber: levelNumber,
                levelPrice: levelPrice,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    fun sendOverflowDown(toId: Int, fromId: Int, levelNumber: Int, levelPrice: Int, value: Int, recipientExcesses: Address){
        let recipient: Address = self.programUserAddress(toId);
        self.sendUpdateUpperAddess(fromId, recipient, levelNumber, ton("0.03"), recipientExcesses);
        let mode: Int = 128;

        if (value != 0) {
            value += ton("0.06");
            mode = 3;
        }

        send(SendParameters{
            to: recipient,
            value: value,
            mode: mode,
            body: OverflowDown{
                id: fromId,
                fromId: self.id,
                levelNumber: levelNumber,
                levelPrice: levelPrice,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    fun sendGift(value: Int){
        send(SendParameters{
            to: self.invitedAddress!!,
            value: value,
            mode: SendPayFwdFeesSeparately | SendIgnoreErrors,
            body: "gift".asComment()
        });
    }

    fun sendExcesses(recipient: Address){
         send(SendParameters{
            to: recipient,
            value: 0,
            mode: SendRemainingBalance,
            body: "Excesses".asComment(),
        });
    }

    fun sendRemainingValue(recipient: Address){
         send(SendParameters{
            to: recipient,
            value: 0,
            mode: SendIgnoreErrors | SendRemainingValue,
            body: "Excesses".asComment(),
        });
    }

    fun finishCycle(info: Info, levelNumber: Int){
        emit(FinishCycle{
            matrix: info.matrix,
            levelNumber: levelNumber,
            reinvestNumber: info.reinvestCount
        }.toCell());
        self.updateReinvestCounter(info, levelNumber);
    }

    fun updateReinvestCounter(info: Info, levelNumber: Int){
        info.resetInfoForReinvest();
        self.levelInfo.set(levelNumber, info);
    }

    fun updateOvertakingInfo(levelNumber: Int){
        let count: Int? = self.overtakeInfo.get(levelNumber);

        if (count == null) {
            count = 0;
        }

        count = count!! + 1;
        self.overtakeInfo.set(levelNumber, count!!);
        emit(Overtook{levelNumber: levelNumber, newValue: count!!}.toCell());
    }

    fun getInfo(levelNumber: Int): Info {
        let info: Info? = self.levelInfo.get(levelNumber);

        if(info == null){
            self.levelInfo.set(levelNumber, Info{});
            info = Info{};
        }
        
        return info!!;
    }

    fun checkPossibilityActivateLevel(levelNumber: Int){
        nativeThrowUnless(131, (levelNumber - self.lastLevel) == 1);
    }

    fun requireUserProgram(id: Int){
        nativeThrowUnless(132, sender() == self.programUserAddress(id));
    }

    fun requireProgram(){
        nativeThrowUnless(132, sender() == self.program);
    }

    fun requireOwner(){
        nativeThrowUnless(132, sender() == self.owner!!);
    }

    // ------------------ Get Functions ------------------ //

    get fun id(): Int {
        return self.id;
    }

    get fun owner(): Address {
        return self.owner!!;
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun withdrawBalance(): Int {
        return myBalance() - self.holdBalance - self.minTonsForStorage;
    }

    get fun holdBalance(): Int {
        return self.holdBalance;
    }

    get fun invitedAddress(): Address {
        return self.invitedAddress!!;
    }

    get fun overtakeInfo(): map<Int as uint8, Int as uint16> {
        return self.overtakeInfo;
    }

    get fun levelInfo(): map<Int as uint8, Info> {
        return self.levelInfo;
    }

    get fun lastLevel(): Int {
        return self.lastLevel;
    }

    get fun programAddress(): Address {
        return self.program;
    }

    get fun programUserAddress(id: Int): Address {
        let init: StateInit = initOf FtBaseProgramUser(id, self.program);
        return contractAddress(init);
    }
}
