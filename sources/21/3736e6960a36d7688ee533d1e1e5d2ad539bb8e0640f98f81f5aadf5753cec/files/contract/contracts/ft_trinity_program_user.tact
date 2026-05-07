import "./ft_user_main.tact";
import "./messages_trinity.tact";
import "./info_extends_trinity.tact";
import "./structs_trinity";
import "./messages";
import "./ft_trinity_user_getters";

contract FtTrinityProgramUser with FtTrinityUserGetters {
    const minTonsForStorage: Int = ton("0.1");
    const minTonsForNotActive: Int = ton("0.005");
    const linePercent: Int = 3333; // 3.333%
    const firstLinePercent: Int = 14;
    const secondLinePercent: Int = 21;
    const thirdLinePercent: Int = 35;

    id: Int as uint64;
    owner: Address?;
    program: Address;
    master: Address = address("EQAvJuEln0lP8c2YMZ4sKGwQRt_kmxmC494v8Y4TTHgOasKJ");

    autoUpgrade: Bool = true;
    autoWithdraw: Bool = false;

    invitedId: Int as uint64 = 0;
    invitedAddress: Address?;

    canClaim: Int as coins = 0;
    lastLevel: Int as uint8 = 0;
    overtakeInfo: map<Int as uint8, Int as uint16> = emptyMap();
    levelInfo: map<Int as uint8, TrinityInfo> = emptyMap();
    spentForActivate: Int as coins = 0;

    autoActivatingFee: Int as coins = 0;

    activating: Bool = false;
    activatingLevelPrice: map<Int as uint8, Int as coins> = emptyMap();
    autoActivatingLevelPrice: map<Int as uint8, Int as coins> = emptyMap();
    activatingLevelFees: map<Int as uint8, Int as coins> = emptyMap();
    finishActivatingLevel: Int as uint8 = 0;

    init(id: Int, program: Address){
        self.id = id;
        self.program = program;
    }

    receive() {}

    receive(msg: SetupProgramUserInternal) {
        self.requireProgram();
        self.reserveBalanceOrMinStorage();
        
        self.owner = msg.owner;
        self.invitedId = msg.invitedId;
        self.invitedAddress = msg.invitedAddress;
        self.canClaim = msg.canClaim;
        self.lastLevel = msg.lastLevel;
        self.overtakeInfo = msg.overtakeInfo;
        self.levelInfo = msg.levelInfo;
        self.spentForActivate = msg.spentForActivate;

        if (self.lastLevel == 12) {
            self.autoUpgrade = false;
        }

        sendExcesses(msg.recipientExcesses);
    }

    receive(msg: ActivateContract) {
        self.requireProgram();
        self.reserveBalanceOrMinStorage();

        self.owner = msg.owner;
        self.invitedId = msg.invitedId;
        self.invitedAddress = self.programUserAddress(msg.invitedId);
        sendExcesses(msg.recipientExcesses);
    }

    receive(msg: ActivateOneLevel) {
        self.requireProgram();
        self.processActivateOneLevel(msg);
    }

    receive(msg: ActivateManyLevels) { 
        self.requireProgram();
        self.processActivateManyLevels(msg);
    }

    receive(msg: FinishActivation) {
        self.requireUser(msg.fromId);
        self.processFinishActivation(msg);
    }

    receive(msg: CancelActivation) {
        self.requireUser(msg.fromId);
        self.processCancelActivation(msg);
    }

    receive(msg: FailAutoActivate) {
        self.requireProgram();
        let prevLevelNumber = msg.levelNumber - 1;

        let info: TrinityInfo = self.getInfo(prevLevelNumber);
        info.nextLevelValue += msg.value;
        self.levelInfo.set(prevLevelNumber, info);

        sendRemainingValue(msg.recipientExcesses);
    }

    receive(msg: ManualRecycle) {
        self.requireProgram();
        self.reserveBalanceOrMinStorage();

        let info: TrinityInfo = self.getInfo(msg.levelNumber);

        if (info.reinvestCount > 1 && info.holdValue > 0 && (info.upperAddress == null || info.matrix.places.get(1) == null)) {
            let levelPrice: Int = info.holdValue;
            info.holdValue = 0;
            self.levelInfo.set(msg.levelNumber, info);

            self.sendToUpline(self.id, msg.levelNumber, levelPrice, msg.nextLevelPrice, true, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);
        } else {
            sendExcesses(msg.recipientExcesses);
        }
    }

    receive(msg: SwitchAutoUpgrade) {
        self.requireOwner();

        if (self.autoUpgrade || self.lastLevel != 12) {
            if (self.autoUpgrade) {
                self.autoUpgrade = false;

                let info = self.getInfo(self.lastLevel);
                self.canClaim += info.nextLevelValue;
                info.nextLevelValue = 0;

                self.levelInfo.set(self.lastLevel, info);
            } else {
                self.autoUpgrade = true;
            }
        }
        sendRemainingValue(sender());
    }

    receive(msg: SwitchAutoWithdraw) {
        self.requireOwner();
        self.autoWithdraw = !self.autoWithdraw;
        sendRemainingValue(sender());
    }

    receive(msg: ClaimMatrixProfit) {
        self.requireOwner();

        let valueToWithdraw: Int = self.canClaim;
        require(valueToWithdraw > 0, "Nothing to withdraw");

        self.canClaim = 0;
        self.sendClaim(valueToWithdraw, 0, false, self.owner!!);
    }

    receive(msg: ClaimLineBonus) {
        self.requireOwner();
        require((msg.levelNumber > 0 && msg.levelNumber <= self.lastLevel), "Too big level number");
        require((msg.levelNumber > 0 && msg.lineNumber < 4), "Level number should be less than 4 and more than 0");

        let info: TrinityInfo = self.getInfo(msg.levelNumber);

        let bonusAmount: Int = 0;

        if (msg.lineNumber == 1) {
            bonusAmount = info.canClaimFirstLineBonus;
            info.canClaimFirstLineBonus = 0;
        } else if (msg.lineNumber == 2) {
            bonusAmount = info.canClaimSecondLineBonus;
            info.canClaimSecondLineBonus = 0;
        } else {
            bonusAmount = info.canClaimThirdLineBonus;
            info.canClaimThirdLineBonus = 0;
        }

        require(bonusAmount > 0, "Nothing to withdraw");
        self.levelInfo.set(msg.levelNumber, info);

        self.sendClaim(bonusAmount, 0, false, msg.recipientExcesses);
    }

    receive(msg: ReturnTon) {
        self.requireOwner();
        nativeReserve(self.minTonsForStorage, 0);
        sendExcesses(self.owner!!);
    }

    receive(msg: UpdateTrinityMatrix) {
        self.requireUser(msg.fromId);
        let valueInMessage = context().value;
        let balance: Int = myBalance() - valueInMessage;

        if (self.id == 1) {
            self.processUpdateMatrixForId1(msg);
        } else if (self.invitedId == 0) {
            self.sendRequestInvitedId(msg);
        } else if (valueInMessage < ton("0.5")) {
            nativeReserve(balance, 0);
            self.sendCancelActivation(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses);
        } else if (self.lastLevel < msg.levelNumber){
            self.makeOvertake(msg.levelNumber);
            nativeReserve(balance, 0);

            self.sendToUpline(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, false, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);
        } else {
            self.processUpdateMatrix(msg);
        }
    }

    receive(msg: OverflowFromBottom) { // OverflowToUp
        self.requireUser(msg.fromId);
        self.reserveBalanceOrMinStorage();

        if (msg.userLine == 1) {
            self.processOverflowFromBottomForFirstLine(msg);
        } else if (msg.userLine == 2) {
            self.processOverflowFromBottomForSecondLine(msg);
        }
    }

    receive(msg: OverflowFromTop) { // OverflowToDown
        self.requireUser(msg.fromId);
        self.reserveBalanceOrMinStorage();
        self.processOverflowFromTop(msg);
    }

    receive(msg: UpdateInvitedId) {
        self.requireUserMain();

        let userInit: StateInit = self.programUserInit(msg.invitedId);
        self.invitedAddress = contractAddress(userInit);
        self.invitedId = msg.invitedId;

        deploy(DeployParameters{
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: msg.forwardPayload,
            init: userInit
        });
    }

    receive(msg: UpdateUpperAddress) {
        self.requireUser(msg.fromId);

        let info: TrinityInfo = self.getInfo(msg.levelNumber);
        info.updateUpperAddress(msg.upperAddress);
        self.levelInfo.set(msg.levelNumber, info);

        sendRemainingValue(msg.recipientExcesses);
    }

    receive(msg: GiftTrinity){
        self.requireUser(msg.fromId);
        self.canClaim += msg.value;
        sendRemainingValue(msg.recipientExcesses);
    }

    receive(msg: ChangeUOwner) {
        self.requireProgram();
        self.owner = msg.newOwner;
        sendRemainingValue(msg.recipientExcesses);
    }

    receive(msg: ChangeInfo) {
        self.requireProgram();
        self.levelInfo.set(msg.levelNumber, msg.newInfo);
        sendRemainingValue(msg.recipientExcesses);
    }

    receive(msg: ChangeActivation) {
        self.requireProgram();
        self.activating = msg.activating;
        self.lastLevel = msg.lastLevel;
        sendRemainingValue(msg.recipientExcesses);
    }

    inline fun activateLevel(number: Int, price: Int, nextLevelPrice: Int, autoWithdrawMinFee: Int, recipientExcesses: Address, value: Int){
        self.activating = true;
        self.lastLevel = number;
        self.levelInfo.set(number, TrinityInfo{});
        self.sendToUpline(self.id, number, price, nextLevelPrice, false, autoWithdrawMinFee, recipientExcesses, value);
    }

    inline fun processActivateOneLevel(msg: ActivateOneLevel) {
        if (self.owner == null || self.activating || !self.checkPossibilityActivateLevel(msg.levelNumber)) {
            self.returnJetton(msg.recipientExcesses, msg.levelPrice, msg.autoFee, msg.levelNumber);
            return;
        }

        self.reserveBalanceOrMinStorage();

        if(msg.levelNumber == 12) {
            self.autoUpgrade = false;
        }

        if (msg.levelNumber > 1) {
            let prevLevelNumber = msg.levelNumber - 1;
            let prevLevelInfo: TrinityInfo = self.getInfo(prevLevelNumber);

            let nextLevelValue: Int = prevLevelInfo.nextLevelValue;
            prevLevelInfo.nextLevelValue = 0;

            self.levelInfo.set(prevLevelNumber, prevLevelInfo);

            self.canClaim += nextLevelValue;
        }

        if (self.id != 1){
            self.autoActivatingFee = msg.autoFee;
            self.spentForActivate += msg.levelPrice;
            self.activateLevel(msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);

        } else {
            while(self.lastLevel < 12){
                self.lastLevel += 1;
                self.levelInfo.set(self.lastLevel, TrinityInfo{});
            }

            sendExcesses(self.owner!!);
        }     
    }

    inline fun processActivateManyLevels(msg: ActivateManyLevels) {
        let allLevelPrice: Int = 0;

        foreach (_, levelPrice in msg.levels) {
            allLevelPrice += levelPrice;
        }

        if (self.owner == null || self.activating || !self.checkPossibilityActivateLevel(msg.startLevelNumber)) {
            self.returnJetton(msg.recipientExcesses, allLevelPrice, 0, 0);
            return;
        }

        if (msg.startLevelNumber > 1) {
            let prevLevelNumber = msg.startLevelNumber - 1;
            let prevLevelInfo: TrinityInfo = self.getInfo(prevLevelNumber);

            let nextLevelValue: Int = prevLevelInfo.nextLevelValue;
            prevLevelInfo.nextLevelValue = 0;

            self.levelInfo.set(prevLevelNumber, prevLevelInfo);

            self.canClaim += nextLevelValue;
        }

        let levelPriceOpt: Int? = msg.levels.get(msg.startLevelNumber);
        let feeOpt: Int? =  msg.fees.get(msg.startLevelNumber);

        if (levelPriceOpt == null || feeOpt == null) {
            self.returnJetton(msg.recipientExcesses, allLevelPrice, 0, 0);
            return;
        }

        let levelPrice: Int = levelPriceOpt!!;
        let fee: Int = feeOpt!!;

        self.activatingLevelPrice = msg.levels;
        self.activatingLevelFees = msg.fees;
        self.autoActivatingLevelPrice = msg.nextLevelPrice;
        self.finishActivatingLevel = msg.finishLevelNumber;

        self.lastLevel = msg.startLevelNumber;
        self.spentForActivate += allLevelPrice;

        let nextLevelPriceOpt: Int? = self.autoActivatingLevelPrice.get(msg.startLevelNumber + 1);
        let nextLevelPrice: Int = nextLevelPriceOpt == null ? 0 : nextLevelPriceOpt!!;

        self.activateLevel(msg.startLevelNumber, levelPrice, nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses, fee);
    }

    inline fun processFinishActivation(msg: FinishActivation) {
        if (self.finishActivatingLevel == 0) {
            self.activating = false;
            self.autoActivatingFee = 0;
            sendRemainingValue(msg.recipientExcesses);
            return;
        }
        
        let nextLevel: Int = msg.wasActivatedLevel + 1;
        let levelPrice: Int = self.activatingLevelPrice.get(nextLevel)!!;
        let nextLevelPrice: Int = 0;

        if(nextLevel < 12) {
            let nextLevelPriceOpt = self.autoActivatingLevelPrice.get(nextLevel + 1);
            nextLevelPrice = nextLevelPriceOpt == null ? 0 : nextLevelPriceOpt!!;
        }

        if (nextLevel == 12) {
            self.autoUpgrade = false;
        }
        
        self.lastLevel = nextLevel;

        if(nextLevel == self.finishActivatingLevel) {
            self.finishActivatingLevel = 0;
            self.activatingLevelPrice = emptyMap();
            self.autoActivatingLevelPrice = emptyMap();
            self.activatingLevelFees = emptyMap();

            nativeReserve(self.minTonsForStorage, 0);

            self.activateLevel(nextLevel, levelPrice, nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);
        } else {
            let fee: Int = self.activatingLevelFees.get(nextLevel)!!;
            self.activateLevel(nextLevel, levelPrice, nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses, fee);
        }
    }

    inline fun processCancelActivation(msg: CancelActivation) {
        let info: TrinityInfo = self.getInfo(msg.levelNumber);

        if(info.reinvestCount > 1) {
            info.upperAddress = null;
            info.holdValue = msg.levelPrice;
            self.levelInfo.set(msg.levelNumber, info);

            sendRemainingValue(msg.recipientExcesses);
            return;
        }

        self.lastLevel -= 1;

        self.activating = false;
        let excessAmount: Int = 0;

        if (self.finishActivatingLevel != 0) {
           let level = msg.levelNumber;

            while(level <= self.finishActivatingLevel) {
                let levelPrice: Int = self.activatingLevelPrice.get(level)!!;
                excessAmount += levelPrice;
                level += 1;
            }

            self.activatingLevelFees = emptyMap();
            self.activatingLevelPrice = emptyMap();
            self.autoActivatingLevelPrice = emptyMap();
            self.finishActivatingLevel = 0;
        } else {
            excessAmount = msg.levelPrice;
        }

        let autoFee: Int = self.autoActivatingFee;
        self.autoActivatingFee = 0;
        self.spentForActivate -= excessAmount;
        self.returnJetton(msg.recipientExcesses, excessAmount, autoFee, msg.levelNumber);
    }

    inline fun processUpdateMatrixForId1(msg: UpdateTrinityMatrix) {
        self.reserveBalanceOrMinStorage();
        if (msg.levelNumber > self.lastLevel) {
            self.lastLevel = msg.levelNumber;
        }
            
        let info: TrinityInfo = self.getInfo(msg.levelNumber);
        let placeInfo: ResFindPlace = info.placeUserInMatrix(msg.id, 1);

        let line: Int = placeInfo.line;
        let place: Int = placeInfo.place;
        let branch: Int = placeInfo.branch;

        if (line == 1) {
            info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, 70, 10000, place, msg.autoWithdrawMinFee, false, msg.recipientExcesses);
            self.levelInfo.set(msg.levelNumber, info);

            reinvestNumber(1, info.reinvestCount);
            self.sendFinishActivating(msg.id, msg.levelNumber, msg.autoWithdrawMinFee, msg.recipientExcesses);
            self.sendUpdateUpperAddress(msg.id, myAddress(), msg.levelNumber, ton("0.05"), msg.recipientExcesses);
            sendExcesses(msg.recipientExcesses);
            return;
        }

        let upperId: Int = placeInfo.upperId!!;
        let upperAddress: Address = self.programUserAddress(upperId);

        if (line == 2) {
            let linePercent: Int = self.linePercent * 2;
            info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, 56, linePercent, place, msg.autoWithdrawMinFee, false, msg.recipientExcesses);
            self.levelInfo.set(msg.levelNumber, info);
            reinvestNumber(2, info.reinvestCount);
            self.sendOverflowToDown(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, upperId, line, branch, 1, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses, 0);

        } else {
            let isRecycle: Bool = info.matrix.isFullThirdLine();
            info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, self.thirdLinePercent, self.linePercent, place, msg.autoWithdrawMinFee, isRecycle, msg.recipientExcesses);
            reinvestNumber(3, info.reinvestCount);

            if (isRecycle) {
                finishCycle(info, msg.levelNumber);
                info.resetInfoForReinvest();
            }
            
            self.levelInfo.set(msg.levelNumber, info);
            self.sendFinishActivating(msg.id, msg.levelNumber, msg.autoWithdrawMinFee, msg.recipientExcesses);
            self.sendOverflowToDown(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, upperId, line, branch, 1, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses, 0);
        }
    }

    inline fun processUpdateMatrix(msg: UpdateTrinityMatrix) {
        let info: TrinityInfo = self.getInfo(msg.levelNumber);
        self.reserveBalanceOrMinStorage();

        if (info.upperAddress == null) {
            self.makeOvertake(msg.levelNumber);
            self.sendToUpline(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, false, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);
            return;
        } 

        let placeInfo: ResFindPlace = info.placeUserInMatrix(msg.id, 1);

        let line = placeInfo.line;
        let place = placeInfo.place;
        let branch: Int = placeInfo.branch;

        if (line == 1) {
            let upperAddress: Address = info.upperAddress!!;
            info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, self.firstLinePercent, self.linePercent, place, msg.autoWithdrawMinFee, false, msg.recipientExcesses);
            self.levelInfo.set(msg.levelNumber, info);

            reinvestNumber(1, info.reinvestCount);
            self.sendUpdateUpperAddress(msg.id, myAddress(), msg.levelNumber, ton("0.05"), msg.recipientExcesses);
            self.sendOverflowToUp(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, self.id, line, branch, 1, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses); 
            return;
        }

        let upperId: Int = placeInfo.upperId!!;

        if (line == 2) {
            let upperAddress: Address = info.upperAddress!!;
            info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, self.secondLinePercent, self.linePercent, place, msg.autoWithdrawMinFee, false, msg.recipientExcesses);
            self.levelInfo.set(msg.levelNumber, info);

            reinvestNumber(2, info.reinvestCount);
            self.sendOverflowToUp(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, upperId, 2, branch, 1, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses);
            return;
        } 

        // line == 3
        let upperAddress: Address = self.programUserAddress(upperId);
        let isRecycle: Bool = info.matrix.isFullThirdLine();

        info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, self.thirdLinePercent, self.linePercent, place, msg.autoWithdrawMinFee, isRecycle, msg.recipientExcesses);

        reinvestNumber(3, info.reinvestCount);
        self.sendFinishActivating(msg.id, msg.levelNumber, msg.autoWithdrawMinFee, msg.recipientExcesses);

        let holdValue: Int = 0;

        if (isRecycle) {
            holdValue = info.holdValue;
            finishCycle(info, msg.levelNumber);
            info.resetInfoForReinvest();
        }

        self.levelInfo.set(msg.levelNumber, info);

        if (isRecycle) {
            let valueForDown: Int = (context().value * 40) / 100;
            self.sendOverflowToDown(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, upperId, line, branch, 1, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses, valueForDown);
            self.sendToUpline(self.id, msg.levelNumber, holdValue, msg.nextLevelPrice, isRecycle, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);
        } else {
            self.sendOverflowToDown(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, upperId, line, branch, 1, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses, 0);
        }
    }

    inline fun processOverflowFromBottomForFirstLine(msg: OverflowFromBottom) {
        let isRoot: Bool = self.id == 1;
        let info: TrinityInfo = self.getInfo(msg.levelNumber);
        let place: Int = info.findPlaceInSecondLine(msg.userBranch, msg.upperId);
        let wasOccupied = info.matrix.places.get(place) != null; // True - было занято / False - не было занято
    
        if ((wasOccupied && msg.countOverflow == 1) || place == 0) {
            self.sendCancelActivation(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses);
            return;
        }

        reinvestNumber(2, info.reinvestCount);
        info.matrix.recordPlace(place, msg.id, msg.countOverflow + 1);

        if(!wasOccupied) {
            let linePercent: Int = isRoot ? self.linePercent * 2 : self.linePercent;
            let matrixPercent: Int = isRoot ? 56 : self.secondLinePercent;
            info = self.calculateProfit(info, msg.levelNumber,msg.levelPrice, msg.nextLevelPrice, matrixPercent, linePercent, place, msg.autoWithdrawMinFee, false, msg.recipientExcesses);
        }

        self.levelInfo.set(msg.levelNumber, info);

        if (!isRoot && msg.countOverflow == 1) {
            let upperAddress: Address = info.upperAddress!!;
            self.sendOverflowToUp(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.upperId, 2, msg.userBranch, 2, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses);
        } else {
            if(isRoot) {
                self.sendFinishActivating(msg.id, msg.levelNumber, msg.autoWithdrawMinFee, msg.recipientExcesses);
            }

            sendExcesses(msg.recipientExcesses);
        }
    }

    inline fun processOverflowFromBottomForSecondLine(msg: OverflowFromBottom) {
        let isRoot: Bool = self.id == 1;
        let info: TrinityInfo = self.getInfo(msg.levelNumber);
        let place: Int = info.findPlaceInThirdLine(msg.userBranch, msg.upperId);
        let wasOccupied = info.matrix.places.get(place) != null;
    
        if (wasOccupied || place == 0) {
            self.sendCancelActivation(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses);
            return;
        }

        reinvestNumber(3, info.reinvestCount);
        info.matrix.recordPlace(place, msg.id, 2);
        let isRecycle: Bool = info.matrix.isFullThirdLine();

        info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, self.thirdLinePercent, self.linePercent, place, msg.autoWithdrawMinFee, isRecycle, msg.recipientExcesses);
        self.sendFinishActivating(msg.id, msg.levelNumber, msg.autoWithdrawMinFee, msg.recipientExcesses);

        let holdValue: Int = 0;

        if (isRecycle) {
            holdValue = info.holdValue;
            finishCycle(info, msg.levelNumber);
            info.resetInfoForReinvest();
        }
        
        self.levelInfo.set(msg.levelNumber, info);
        let notRootRecycle: Bool = isRecycle && !isRoot;

        if (msg.countOverflow == 1) {
            let valueForDown: Int = notRootRecycle ? ((context().value * 20) / 100) : 0;
            let upperAddress: Address = self.programUserAddress(msg.upperId);
            self.sendOverflowToDown(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.upperId, 3, msg.userBranch, 2, msg.autoWithdrawMinFee, upperAddress, msg.recipientExcesses, valueForDown);

            if (notRootRecycle) {
                self.sendToUpline(self.id, msg.levelNumber, holdValue, msg.nextLevelPrice, isRecycle, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);
            }
            return;
        }

        if (notRootRecycle) {
            self.sendToUpline(self.id, msg.levelNumber, holdValue, msg.nextLevelPrice, isRecycle, msg.autoWithdrawMinFee, msg.recipientExcesses, 0);
        } else {
            sendExcesses(msg.recipientExcesses);
        }
    }

    inline fun processOverflowFromTop(msg: OverflowFromTop) {
        let info: TrinityInfo = self.getInfo(msg.levelNumber);
        let place: Int = msg.userBranch;
        let wasOccupied: Bool = info.matrix.places.get(place) != null; // True - было занято / False - не было занято
        
        info.matrix.recordPlace(msg.userBranch, msg.id, 3);

        if (!wasOccupied) {
            info = self.calculateProfit(info, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, self.firstLinePercent, self.linePercent, place, msg.autoWithdrawMinFee, false, msg.recipientExcesses);
        }

        self.levelInfo.set(msg.levelNumber, info);

        reinvestNumber(1, info.reinvestCount);

        if (msg.userLine == 2) {
            self.sendFinishActivating(msg.id, msg.levelNumber, msg.autoWithdrawMinFee, msg.recipientExcesses);
            self.sendUpdateUpperAddress(msg.id, myAddress(), msg.levelNumber, 0, msg.recipientExcesses);
            return;
        }

        if (msg.countOverflow == 1) {
            self.sendUpdateUpperAddress(msg.id, myAddress(), msg.levelNumber, ton("0.05"), msg.recipientExcesses);
            self.sendOverflowToUp(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.upperId, 1, msg.userBranch, 2, msg.autoWithdrawMinFee,info.upperAddress!!, msg.recipientExcesses);
            return;
        }

        self.sendUpdateUpperAddress(msg.id, myAddress(), msg.levelNumber, 0, msg.recipientExcesses);
    }

    inline fun makeOvertake(levelNumber: Int){
        let count: Int? = self.overtakeInfo.get(levelNumber);
        let newCount: Int = count == null ? 1 : count!! + 1;
        self.overtakeInfo.set(levelNumber, newCount);
        emit(Overtook{levelNumber: levelNumber, newValue: newCount}.toCell());
    }

    inline fun checkPossibilityActivateLevel(levelNumber: Int): Bool {
        return !(levelNumber - self.lastLevel != 1);
    }

    inline fun calculateProfit(info: TrinityInfo, levelNumber: Int, levelPrice: Int, nextLevelPrice: Int, matrixPercent: Int, linePercent: Int, place: Int, autoWithdrawMinFee: Int, isRecycle: Bool, recipientExcesses: Address): TrinityInfo {
        let isRoot: Bool = self.id == 1;
        let matrixProfit: Int = (levelPrice * matrixPercent) / 100;
        let lineProfit: Int = (levelPrice * linePercent) / 100000;

        // ROOT
        if (isRoot) {
            info.matrixProfit += matrixProfit;
            info.incrementLineBonusForId1(place, lineProfit, isRecycle);
            self.canClaim += matrixProfit;
            return info;
        }

        // RECYCLE PLACE
        if (place == 13 || place == 39) {
            info.holdValue += matrixProfit;
            info.incrementLineBonus(place, lineProfit, isRecycle);
            return info;
        }

        // FROZEN LEVEL
        if (info.isFrozenLevel(levelNumber, self.lastLevel)) {
            let giftValue: Int = matrixProfit + lineProfit;

            info.lostProfit += giftValue;
            self.sendGift(giftValue, autoWithdrawMinFee, recipientExcesses);
            return info;
        }

        // NORMAL PROFIT
        info.matrixProfit += matrixProfit;
        info.incrementLineBonus(place, lineProfit, isRecycle);

        // AUTO UPGRADE
        if (self.autoUpgrade && levelNumber == self.lastLevel && nextLevelPrice > 0) {
            let totalForUpgrade: Int = levelPrice + nextLevelPrice;

            if(info.nextLevelValue >= totalForUpgrade) {   
                self.sendAutoActivation(totalForUpgrade, recipientExcesses);
                self.canClaim += matrixProfit + (info.nextLevelValue - totalForUpgrade);
                info.nextLevelValue = 0;
            } else {
                info.nextLevelValue += matrixProfit;
            }

            return info;
        }

        // AUTO WITHDRAW
        if (self.autoWithdraw) {
            if (self.canClaim > 0 && self.canClaim >= autoWithdrawMinFee * 2) {
                let claimValueForWithdraw: Int = self.canClaim;
                self.sendClaim(claimValueForWithdraw, ton("0.05"), true, recipientExcesses);
                self.canClaim = matrixProfit;
            } else {
                self.canClaim += matrixProfit;
            }
            return info;
        }

        // DEFAULT
        self.canClaim += matrixProfit;
        return info;
    }

    inline fun reserveBalanceOrMinStorage(){
        let balance: Int = myBalance() - context().value;
        nativeReserve(max(balance, self.minTonsForStorage), 0);
    }

    inline fun sendToUpline(id: Int, number: Int, price: Int, nextPrice: Int, isRecycle: Bool, autoWithdrawMinFee: Int, recipientExcesses: Address, value: Int){
        let mode: Int = value != 0 ? 3 : 128;
        let body: Cell = UpdateTrinityMatrix { 
            id: id, fromId: self.id, levelNumber: number, levelPrice: price,
            nextLevelPrice: nextPrice, autoWithdrawMinFee: autoWithdrawMinFee, recipientExcesses: recipientExcesses
        }.toCell();

        if (number == 1 && !isRecycle) {
            let userInit: StateInit = self.programUserInit(self.invitedId);
            self.invitedAddress = contractAddress(userInit);

            deploy(DeployParameters{
                value: value,
                mode: mode,
                body: body,
                init: userInit
            });
            return;
        }

        message(MessageParameters{
            to: self.invitedAddress!!,
            value: value,
            mode: mode,
            body: body
        });
    }

    inline fun sendOverflowToUp(id: Int, levelNumber: Int, levelPrice: Int, nextLevelPrice: Int, upperId: Int, userLine: Int, userBranch: Int, countOverflow: Int, autoWithdrawMinFee: Int, upperAddress: Address, recipientExcesses: Address){
        message(MessageParameters{
            to: upperAddress,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: OverflowFromBottom {
                id: id, fromId: self.id, levelNumber: levelNumber, levelPrice: levelPrice,
                nextLevelPrice: nextLevelPrice, upperId: upperId, userLine: userLine,
                userBranch: userBranch, countOverflow: countOverflow, autoWithdrawMinFee: autoWithdrawMinFee, recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    inline fun sendOverflowToDown(id: Int, levelNumber: Int, levelPrice: Int, nextLevelPrice: Int, upperId: Int, userLine: Int, userBranch: Int, countOverflow: Int, autoWithdrawMinFee: Int, upperAddress: Address, recipientExcesses: Address, value: Int){  
        message(MessageParameters{
            to: upperAddress,
            value: value,
            mode: value != 0 ? 3 : 128,
            body: OverflowFromTop {
                id: id, fromId: self.id, levelNumber: levelNumber, levelPrice: levelPrice,
                nextLevelPrice: nextLevelPrice, upperId: upperId, userLine: userLine, 
                userBranch: userBranch, countOverflow: countOverflow, autoWithdrawMinFee: autoWithdrawMinFee, recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    inline fun sendFinishActivating(id: Int, levelNumber: Int, autoWithdrawMinFee: Int, recipientExcesses: Address){
        message(MessageParameters{
            to: self.programUserAddress(id),
            value: ton("0.05"),
            mode: SendPayGasSeparately | SendIgnoreErrors,
            body: FinishActivation {
                fromId: self.id,
                wasActivatedLevel: levelNumber,
                autoWithdrawMinFee: autoWithdrawMinFee,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    inline fun sendCancelActivation(toId: Int, levelNumber: Int, levelPrice: Int, nextLevelPrice: Int, autoWithdrawMinFee: Int, recipientExcesses: Address){
        message(MessageParameters {
            to: self.programUserAddress(toId),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: CancelActivation {
                fromId: self.id,
                levelNumber: levelNumber,
                levelPrice: levelPrice,
                nextLevelPrice: nextLevelPrice,
                autoWithdrawMinFee: autoWithdrawMinFee,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    inline fun sendAutoActivation(amount: Int, recipientExcesses: Address){ 
        message(MessageParameters{
            to: self.program,
            value: ton("0.05"),
            mode: SendPayGasSeparately | SendIgnoreErrors,
            body: AutoActivation {
                userId: self.id,
                levelNumber: self.lastLevel + 1,
                value: amount,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    inline fun sendUpdateUpperAddress(toId: Int, upperAddress: Address, levelNumber: Int, value: Int, recipientExcesses: Address){        
        message(MessageParameters{
            to: self.programUserAddress(toId),
            value: value,
            mode: value != 0 ? 3 : 128,
            body: UpdateUpperAddress{
                fromId: self.id,
                upperAddress: upperAddress,
                levelNumber: levelNumber,
                recipientExcesses: recipientExcesses
            }.toCell()
        });
    }

    inline fun sendGift(value: Int, autoWithdrawMinFee: Int, recipientExcesses: Address){
        let userInit: StateInit = self.programUserInit(self.invitedId);
        deploy(DeployParameters {
            value: ton("0.1"),
            mode: 0,
            body: GiftTrinity {
                fromId: self.id,
                value: value,
                autoWithdrawMinFee: autoWithdrawMinFee,
                recipientExcesses: recipientExcesses
            }.toCell(),
            init: userInit
        });
    }

    inline fun sendClaim(amount: Int, value: Int, isAuto: Bool, recipientExcesses: Address){
        message(MessageParameters{
            to: self.program,
            value: value,
            mode: value != 0 ? 3 : 64,
            body: ClaimJetton {
                userId: self.id,
                recipient: self.owner!!,
                amount: amount,
                isAuto: isAuto,
                recipientExcesses: recipientExcesses,
            }.toCell()
        });
    }

    inline fun returnJetton(recipient: Address, amount: Int, autoFee: Int, levelNumber: Int) {
        if (autoFee > 0) {
            let info: TrinityInfo = self.levelInfo.get(levelNumber - 1)!!;
            info.nextLevelValue += (autoFee + amount);
            self.levelInfo.set(levelNumber - 1, info);
        }

        message(MessageParameters{
            to: self.program,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: ReturnJetton {
                userId: self.id,
                recipient: recipient,
                autoFee: autoFee,
                amount: amount
            }.toCell()
        });
    }

    inline fun sendRequestInvitedId(msg: UpdateTrinityMatrix){
        self.makeOvertake(msg.levelNumber);
        nativeReserve(self.minTonsForNotActive, 0);

        if (context().value < ton("0.75")) {
            self.sendCancelActivation(msg.id, msg.levelNumber, msg.levelPrice, msg.nextLevelPrice, msg.autoWithdrawMinFee, msg.recipientExcesses);
            return;
        }

        let forwardPayload: Cell = UpdateTrinityMatrix{
            id: msg.id,
            fromId: self.id,
            levelNumber: msg.levelNumber,
            levelPrice: msg.levelPrice,
            nextLevelPrice: msg.nextLevelPrice,
            autoWithdrawMinFee: msg.autoWithdrawMinFee, 
            recipientExcesses: msg.recipientExcesses
        }.toCell();

        message(MessageParameters{
            to: self.userMainAddress(self.id),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: GetInvitedId {
                forwardPayload: forwardPayload,
            }.toCell()
        });
    }
        
    fun getInfo(levelNumber: Int): TrinityInfo {
        let info: TrinityInfo? = self.levelInfo.get(levelNumber);

        if(info == null){
            self.levelInfo.set(levelNumber, TrinityInfo{});
            return TrinityInfo{};
        }
        
        return info!!;
    }

    fun requireUser(id: Int){
        let userInit: StateInit = self.programUserInit(id);
        nativeThrowUnless(132, userInit.hasSameBasechainAddress(sender()));
    }

    inline fun requireOwner(){
        if (self.owner == null) {
            throw(132);
        }

        nativeThrowUnless(132, sender() == self.owner!!);
    }

    inline fun requireProgram(){
        nativeThrowUnless(132, sender() == self.program);
    }

    inline fun requireUserMain(){
        let userMainInit: StateInit = initOf FtUserMain(self.id, self.master);
        nativeThrowUnless(132, userMainInit.hasSameBasechainAddress(sender()));
    }
}

inline fun sendExcesses(recipient: Address){
    message(MessageParameters {
        to: recipient,
        value: 0,
        mode: SendRemainingBalance | SendIgnoreErrors,
        body: "Excesses".asComment(),
    });
}

inline fun finishCycle(info: TrinityInfo, levelNumber: Int) {
    emit(FinishTrinityCycle {
        matrix: info.matrix.places,
        levelNumber: levelNumber,
        reinvestNumber: info.reinvestCount
    }.toCell());
}

inline fun reinvestNumber(status: Int, recycle: Int) {
    emit(ReinvestNumber {
        reinvestNumber: recycle,
        statusCode: status
    }.toCell());
}

inline fun sendRemainingValue(recipient: Address){
    message(MessageParameters{
        to: recipient,
        value: 0,
        mode: SendRemainingValue | SendIgnoreErrors,
        body: "Excesses".asComment(),
    });
}
