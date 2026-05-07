import "./ft_trinity_program_user";
import "./ft_user_main";

import "./messages_trinity";
import "./messages";
import "./structs_trinity";

contract FtTrinityProgramMain {
    const PASSIVE_PERCENT: Int = 20; // %

    editable: Bool = true;
    relaunch: Bool = true;

    wallet: Address;
    startTrinity: Int as uint256 = 0;

    totalFrtInProgram: Int as coins = 0;
    passiveVault: Int as coins = 0;
    protocolFees: Int as coins = 0;

    owner: Address;
    master: Address;

    levelPrices: map<Int as uint8, Int as coins> = emptyMap();
    levelFees: map<Int as uint8, Int as coins> = emptyMap();
    levelPricesAutoFee: map<Int as uint8, Int as coins> = emptyMap();
    autoWithdrawMinFee: Int as coins = 0;
    autoWithdrawPercent: Int as uint8 = 1; // %

    minValueForActivate: Int as coins = ton("0.2");

    init(owner: Address, master: Address){
        nativeThrowUnless(132, sender() == owner);

        self.owner = owner;
        self.master = master;
        self.wallet = owner;
    }

    receive() {}

    receive("Excesses") {}

    receive(msg: JettonExcesses) {}

    receive(msg: SetupTrinityPrice){
        nativeThrowUnless(132, sender() == self.owner);
        self.levelPrices = msg.newLevelPrice;
        self.levelPricesAutoFee = msg.newLevelPriceAutoFee;
        sendRemainingValue(sender());
    }

    receive(msg: SetupTrinityFee) {
        nativeThrowUnless(132, sender() == self.owner);
        self.levelFees = msg.newLevelFee;
        sendRemainingValue(sender());
    }

    receive(msg: SetupTrinityStart) {
        nativeThrowUnless(132, sender() == self.owner);
        self.startTrinity = msg.startTrinity;
        sendRemainingValue(sender());
    }

    receive(msg: SetupJettonWallet) {
        nativeThrowUnless(132, sender() == self.owner);
        self.wallet = msg.wallet;
        sendRemainingValue(sender());
    }

    receive(msg: SetupAutoWithdrawMinFee) {
        nativeThrowUnless(132, sender() == self.owner);
        self.autoWithdrawMinFee = msg.value;
        sendRemainingValue(sender());
    }

    receive(msg: SetupAutoWithdrawPercent) {
        nativeThrowUnless(132, sender() == self.owner);
        self.autoWithdrawPercent = msg.value;
        sendRemainingValue(sender());
    }

    receive(msg: SetupMinValueForActivate) {
        nativeThrowUnless(132, sender() == self.owner);
        self.minValueForActivate = msg.newMinValue;
        sendRemainingValue(sender());
    }

    receive(msg: SetupStartParam) {
        nativeThrowUnless(132, sender() == self.owner);
        nativeThrowUnless(133, self.relaunch);
        self.totalFrtInProgram = msg.totalFrtInProgram;
        self.passiveVault = msg.passiveVault;
    }

    receive(msg: SetupProgramUser) {
        nativeThrowUnless(133, self.relaunch);

        let body: Cell = SetupProgramUserInternal {
            id: msg.id,
            owner: msg.owner,
            invitedId: msg.invitedId,
            invitedAddress: msg.invitedAddress,
            canClaim: msg.canClaim,
            lastLevel: msg.lastLevel,
            overtakeInfo: msg.overtakeInfo,
            levelInfo: msg.levelInfo,
            spentForActivate: msg.spentForActivate,
            recipientExcesses: sender()
        }.toCell();

        sendDeployWithRemainingValue(msg.id, body);
    }

    receive(msg: ChangeUOwner) {
        nativeThrowUnless(132, sender() == self.owner);

        let userAddress: Address = self.trinityProgramUserAddress(msg.id);
        let body = ChangeUOwner {
            id: msg.id,
            newOwner: msg.newOwner,
            recipientExcesses: sender()
        }.toCell();

        sendMessageWithRemainingValue(userAddress, body);
    }

    receive(msg: ChangeInfo) {
        nativeThrowUnless(132, sender() == self.owner);
        nativeThrowUnless(133, self.editable);

        let userAddress: Address = self.trinityProgramUserAddress(msg.id);
        let body: Cell = ChangeInfo {
            id: msg.id,
            levelNumber: msg.levelNumber,
            newInfo: msg.newInfo,
            recipientExcesses: msg.recipientExcesses
        }.toCell();
        
        sendMessageWithRemainingValue(userAddress, body);
    }

    receive(msg: ChangeActivation) {
        nativeThrowUnless(132, sender() == self.owner);
        nativeThrowUnless(133, self.editable);

        let userAddress: Address = self.trinityProgramUserAddress(msg.id);
        let body: Cell = ChangeActivation {
            id: msg.id,
            activating: msg.activating,
            lastLevel: msg.lastLevel,
            recipientExcesses: msg.recipientExcesses
        }.toCell();

        sendMessageWithRemainingValue(userAddress, body);
    }

    receive(_: ChangeRelaunch) {
        nativeThrowUnless(132, sender() == self.owner);
        self.relaunch = false;
        sendRemainingValue(sender());
    }

    receive(_: ChangeEditable) {
        nativeThrowUnless(132, sender() == self.owner);
        self.editable = false;
        sendRemainingValue(sender());
    }

    receive(msg: ManualRecycle) {
        let nextLevelPrice = msg.nextLevelPrice;

        if (msg.levelNumber < 12) {
            let nextLevel = msg.levelNumber + 1;
            nextLevelPrice = self.levelPrices.get(nextLevel)!! + self.levelPricesAutoFee.get(nextLevel)!!;
        } else {
            nextLevelPrice = 0;
        }

        let userAddress: Address = self.trinityProgramUserAddress(msg.id);
        let body: Cell = ManualRecycle {
            id: msg.id,
            levelNumber: msg.levelNumber,
            nextLevelPrice: nextLevelPrice,
            autoWithdrawMinFee: self.autoWithdrawMinFee,
            recipientExcesses: msg.recipientExcesses
        }.toCell();

        sendMessageWithRemainingValue(userAddress, body);
    }

    receive(msg: BuyLevel) {
        self.requireUserMain(msg.userId);

        if (msg.levelNumber != 0 || context().value < self.minValueForActivate) {
            sendRemainingValue(msg.recipientExcesses);

        } else {
            let body: Cell = ActivateContract {
                owner: msg.owner,
                invitedId: msg.invitedId,
                recipientExcesses: msg.recipientExcesses
            }.toCell();
    
            sendDeployWithRemainingValue(msg.userId, body);
        }
    }

    receive(msg: AutoActivation) {
        requireTrinityProgramUser(msg.userId);
        
        let levelPrice = self.levelPrices.get(msg.levelNumber)!!;
        let levelAutoFee = self.levelPricesAutoFee.get(msg.levelNumber)!!;

        let totalPrice = levelPrice + levelAutoFee;

        if (msg.value < totalPrice) {
            let body: Cell = FailAutoActivate {
                levelNumber: msg.levelNumber,
                value: msg.value,
                recipientExcesses: msg.recipientExcesses
            }.toCell();

            sendMessageWithRemainingValue(sender(), body);
        } else {
            let levelFee = self.levelFees.get(msg.levelNumber)!!;
            self.protocolFees += levelAutoFee;
            self.passiveVault += (levelPrice * 20)/100;
            sendTon(msg.recipientExcesses, ton("0.05"));
            self.sendActivateLevelMessage(sender(), msg.levelNumber, levelPrice, levelAutoFee, myAddress(), levelFee);
        }
    }

    receive(msg: JettonNotification) {
        nativeThrowUnless(132, sender() == self.wallet);
        self.processJettonNotification(msg);
    }

    receive(msg: ReturnJetton) {
        requireTrinityProgramUser(msg.userId);
        let passivePart: Int = (msg.amount * self.PASSIVE_PERCENT) / 100;

        self.passiveVault -= passivePart;
        self.protocolFees -= msg.autoFee;
        self.totalFrtInProgram -= (msg.amount + msg.autoFee);

        if(msg.recipient != myAddress()) {
            self.sendTransferToWallet(msg.recipient, msg.recipient, msg.amount, 0);
        }
    }

    receive(msg: ClaimJetton) {
        requireTrinityProgramUser(msg.userId);
        
        if (msg.isAuto) {
            let autoFee = max(self.autoWithdrawMinFee, (msg.amount * self.autoWithdrawPercent) / 100);
            let amountAfterFee: Int = msg.amount - autoFee;

            self.protocolFees += autoFee;

            sendTon(msg.recipientExcesses, ton("0.05"));
            self.sendTransferToWallet(msg.recipient, myAddress(), amountAfterFee, ton("0.1"));
        } else {
            self.sendTransferToWallet(msg.recipient, msg.recipient, msg.amount, 0);
        }
    }

    receive(_: GetPassiveBankFull) {
        nativeThrowUnless(132, sender() == self.owner);
        let transferValue = self.passiveVault;
        self.passiveVault = 0;
        self.sendTransferToWallet(self.owner, self.owner, transferValue, 0);
    }

    receive(_: GetPassiveBank) {
        nativeThrowUnless(132, sender() == self.owner);
        let transferValue = (self.passiveVault * 33)/100;
        self.passiveVault -= transferValue;
        self.sendTransferToWallet(self.owner, self.owner, transferValue, 0);
    }

    receive(_: GetProtocolFees) {
        nativeThrowUnless(132, sender() == self.owner);
        let transferValue = self.protocolFees;
        self.protocolFees = 0;
        self.sendTransferToWallet(self.owner, self.owner, transferValue, 0);
    }

    receive(msg: GetJetton) {
        nativeThrowUnless(132, sender() == self.owner);
        nativeThrowUnless(133, self.editable);
        self.sendTransferToWallet(msg.recipient, msg.recipientExcesses, msg.value, 0);
    }

    receive(msg: ClaimTon) {
        nativeThrowUnless(132, sender() == self.owner);
        message(MessageParameters {
            to: self.owner,
            value: msg.amount,
            mode: 2
        });
    }

    inline fun processJettonNotification(msg: JettonNotification) {
        if(self.startTrinity == 0) {
            self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
            return;
        }

        let opCode =  msg.forwardPayload.loadUint(32);

        if (opCode == 1393241968) { // TryActivateOneLevel
            let data = STryActivateOneLevel.fromSlice(msg.forwardPayload);

            if (!data.isEarly && self.checkCanActivation(data.userId)) {
                self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
                return;
            }

            let levelNumber = data.levelNumber;
            let levelPriceOpt = self.levelPrices.get(levelNumber);

            if (levelPriceOpt == null) {
                self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
                return;
            }

            let levelPrice = levelPriceOpt!!;
            let fee = self.levelFees.get(levelNumber)!!;

            if (msg.amount < levelPrice || context().value < fee) {
                self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
                return;
            }

            let userAddress: Address = self.trinityProgramUserAddress(data.userId);
            let passivePart: Int = (levelPrice * self.PASSIVE_PERCENT) / 100;

            self.passiveVault += passivePart;
            self.totalFrtInProgram += levelPrice;
            
            self.sendActivateLevelMessage(userAddress, levelNumber, levelPrice, 0, msg.sender, 0);
            return;
        }

        if (opCode == 1393241969) { // TryActivateManyLevels
            let data = STryActivateManyLevels.fromSlice(msg.forwardPayload);

            if (!data.isEarly && self.checkCanActivation(data.userId)) {
                self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
                return;
            }

            let allLevelPrice: Int = 0;
            let allFee: Int = ton("0.5");
            let startLevelNumber = data.startLevelNumber;
            let finishLevelNumber = data.finishLevelNumber;

            let levels: map<Int as uint8, Int as coins> = emptyMap();
            let fees: map<Int as uint8, Int as coins> = emptyMap();
            let nextLevelPrice: map<Int as uint8, Int as coins> = emptyMap();

            if(finishLevelNumber - startLevelNumber < 1) {
                self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
                return;
            }

            while(startLevelNumber <= finishLevelNumber) {
                let levelPriceOpt: Int? = self.levelPrices.get(startLevelNumber);
                let feeOpt: Int? = self.levelFees.get(startLevelNumber);

                if (levelPriceOpt == null || feeOpt == null) {
                    self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
                    return;
                }

                let levelPrice: Int = levelPriceOpt!!;
                let fee: Int = feeOpt!!;

                allLevelPrice += levelPrice;
                allFee += fee;

                levels.set(startLevelNumber, levelPrice);
                fees.set(startLevelNumber, fee);

                let nextLevel = startLevelNumber + 1;
                let levelAutoFeeOpt: Int? = self.levelPricesAutoFee.get(nextLevel);

                if (levelAutoFeeOpt != null) {
                    let levelAutoFee: Int = levelAutoFeeOpt!!;
                    nextLevelPrice.set(nextLevel, levelPrice + levelAutoFee);
                } 

                startLevelNumber += 1;
            }

            if (msg.amount < allLevelPrice || context().value < allFee) {
                self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
                return;
            }

            let userAddress: Address = self.trinityProgramUserAddress(data.userId);
            let passivePart: Int = (allLevelPrice * self.PASSIVE_PERCENT) / 100;

            self.passiveVault += passivePart;
            self.totalFrtInProgram += allLevelPrice;

            self.sendActivateManyLevelMessage(userAddress, data.startLevelNumber, data.finishLevelNumber, levels, fees, nextLevelPrice, msg.sender, 0);
            return;
        }

        self.sendTransferToWallet(msg.sender, msg.sender, msg.amount, 0);
    }

    inline fun checkCanActivation(id: Int): Bool {
        return ((id / 20) + self.startTrinity) > now();
    }

    inline fun sendActivateLevelMessage(userAddress: Address, levelNumber: Int, levelPrice: Int, autoFee: Int, recipientExcesses: Address, value: Int) {
        let mode: Int = value != 0 ? 3 : 64 + 2;

        let nextLevelPrice = 0;

        if (levelNumber < 12) {
            nextLevelPrice += self.levelPrices.get(levelNumber + 1)!!;
            nextLevelPrice += self.levelPricesAutoFee.get(levelNumber + 1)!!;
        }
        
        message(MessageParameters {
            to: userAddress,
            value: value,
            mode: mode,
            body: ActivateOneLevel {
                levelNumber: levelNumber,
                levelPrice: levelPrice,
                nextLevelPrice: nextLevelPrice,
                autoFee: autoFee,
                autoWithdrawMinFee: self.autoWithdrawMinFee,
                recipientExcesses: recipientExcesses
            }.toCell(),
        });
    }

    inline fun sendActivateManyLevelMessage(userAddress: Address, start: Int, finish: Int, levels:  map<Int as uint8, Int as coins>, fees:  map<Int as uint8, Int as coins>, nextLevelPrice:  map<Int as uint8, Int as coins>, recipientExcesses: Address, value: Int) {
        let mode: Int = value != 0 ? 3 : 64 + 2;

        message(MessageParameters {
            to: userAddress,
            value: value,
            mode: mode,
            body: ActivateManyLevels {
                startLevelNumber: start,
                finishLevelNumber: finish,
                levels: levels,
                fees: fees,
                nextLevelPrice: nextLevelPrice,
                autoWithdrawMinFee: self.autoWithdrawMinFee,
                recipientExcesses: recipientExcesses
            }.toCell(),
        });
    }

    inline fun sendTransferToWallet(recipient: Address, responseDestination: Address, amount: Int, value: Int) {
        let mode: Int = value != 0 ? 3 : 64 + 2;

        message(MessageParameters {
            to: self.wallet,
            value: value,
            mode: mode,
            bounce: false,
            body: JettonTransfer {
                queryId: 0,
                amount: amount,
                destination: recipient,
                responseDestination: responseDestination,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload:beginCell().storeUint(0, 1).asSlice()
            }.toCell(),
        });
    }

    inline fun requireUserMain(id: Int){
        let userMainInit: StateInit = initOf FtUserMain(id, self.master);
        nativeThrowUnless(132, userMainInit.hasSameBasechainAddress(sender()));
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun master(): Address {
        return self.master;
    }

    get fun jettonWallet(): Address {
        return self.wallet;
    }

    get fun startTrinity(): Int {
        return self.startTrinity;
    }

    get fun totalFrtInProgram(): Int {
        return self.totalFrtInProgram;
    }

    get fun passiveBankAmount(): Int {
        return self.passiveVault;
    }

    get fun commissionFees(): Int {
        return self.protocolFees;
    }

    get fun levelPrices(): map<Int as uint8, Int as coins> {
        return self.levelPrices;
    }

    get fun levelFees(): map<Int as uint8, Int as coins> {
        return self.levelFees;
    }

    get fun levelPricesAutoFee(): map<Int as uint8, Int as coins> {
        return self.levelPricesAutoFee;
    }

    get fun autoWithdrawMinFee(): Int {
        return self.autoWithdrawMinFee;
    }

    get fun autoWithdrawPercent(): Int {
        return self.autoWithdrawPercent;
    }

    get fun trinityProgramUserAddress(id: Int): Address {
        let init = initTrinityProgramUser(id);
        return contractAddress(init);
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun editable(): Bool {
        return self.editable;
    }

    get fun relaunch(): Bool {
        return self.relaunch;
    }
}

inline fun sendDeployWithRemainingValue(id: Int, body: Cell) {
    let initTrinityProgramUser: StateInit = initTrinityProgramUser(id);

     deploy(DeployParameters {
        init: initTrinityProgramUser,
        value: 0,
        mode: SendRemainingValue | SendIgnoreErrors,
        body: body
    });
}

inline fun sendMessageWithRemainingValue(recipient: Address, body: Cell) {
    message(MessageParameters {
        to: recipient,
        value: 0,
        mode: SendRemainingValue | SendIgnoreErrors,
        body: body
    });
}

inline fun sendTon(recepient: Address, value: Int) {
    message(MessageParameters {to: recepient, value: value, mode: 2});
}

inline fun requireTrinityProgramUser(id: Int) {
    let initTrinityProgramUser: StateInit = initTrinityProgramUser(id);
    nativeThrowUnless(132, initTrinityProgramUser.hasSameBasechainAddress(sender()));
}

inline fun initTrinityProgramUser(id: Int): StateInit {
    return initOf FtTrinityProgramUser(id, myAddress());
}
