import "./jetton_airdrop";
import "./messages";
import "./constants";
import "./utils";

struct JettonFullInfo {
    balance: Int as coins;
    airdropAmount: Int as coins;
    transferableBalance: Int as coins;
    startUnlockTime: Int as uint32;
    perSecond: Int as coins;
    unlockByTime: Int as coins;
    unlockByActivity: Int as coins;
}

contract JettonWallet {
    owner: Address;
    minter: Address;
    airdrop: Address;

    balance: Int as coins;
    airdropAmount: Int as coins = 0;
    transferableBalance: Int as coins = 0;

    startUnlockTime: Int as uint32 = 0;
    lastUnlockTime: Int as uint32 = 0;

    unlockByTime: Int as coins = 0;
    unlockByActivity: Int as coins = 0;

    init(owner: Address, minter: Address, balance: Int) {
        self.owner = owner;
        self.minter = minter;
        self.balance = balance;

        self.airdrop = contractAddress(initOf JettonAirdrop(self.minter));
    }

    // ------------ Unlock functions ------------ //

    receive(msg: UpdateUnlockByActivity) {
        require(sender() == self.minter, "Incorrect sender");

        self.reserveStorage();
        self.recalculateUnlockableByTime();

        let maxPossibleUnlockActivity: Int = self.airdropAmount - self.unlockByTime;
        if (maxPossibleUnlockActivity < 0) {
            maxPossibleUnlockActivity = 0;
        }

        let diffUnlockValue: Int = min(msg.unlockValue, maxPossibleUnlockActivity) - self.unlockByActivity;
        if (diffUnlockValue < 0) {
            diffUnlockValue = 0;
        }

        self.transferableBalance += diffUnlockValue;
        self.unlockByActivity += diffUnlockValue;

        message(MessageParameters {
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
            body: JettonExcesses { queryId: 0 }.toCell(),
        });
    }

    // ------------ Airdrop functions ------------ //

    receive(msg: ClaimAirdrop) {
        require(self.owner == sender(), "Incorrect sender");
        require(self.owner == msg.destination, "Incorrect destination");
        require(self.startUnlockTime == 0, "Airdrop already claimed");

        self.reserveStorage();

        message(MessageParameters {
            to: contractAddress(initOf JettonAirdrop(self.minter)),
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: msg.toCell(),
        });
    }

    // ------------ Standart functions ------------ //

    receive(msg: JettonTransfer) {
        forceBasechain(msg.destination);
        require(sender() == self.owner, "Incorrect sender");

        self.recalculateUnlockableByTime();

        self.balance -= msg.amount;
        self.transferableBalance -= msg.amount;

        require(self.balance >= 0, "Incorrect balance after send");
        require(self.transferableBalance >= 0, "Incorrect transferableBalance after send");
        checkEitherForwardPayload(msg.forwardPayload);

        let ctx = context();
        let fwdCount = 1 + sign(msg.forwardTonAmount); // msg.forwardTonAmount is coins, so it's positive
        require(
            ctx.value >
            msg.forwardTonAmount +
            fwdCount * ctx.readForwardFee() +
            getForwardFee(walletStateInitCells, walletStateInitBits, false) +
            (2 * getComputeFee(gasForTransfer, false) + minTonsForStorage),
            "Insufficient amount of TON attached",
        );

        deploy(DeployParameters {
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonTransferInternal {
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }.toCell(),
            init: initOf JettonWallet(msg.destination, self.minter, 0),
        });
    }

    receive(msg: JettonTransferInternal) {
        self.balance += msg.amount;

        let wallet: StateInit = initOf JettonWallet(msg.sender, self.minter, 0);
        if (!wallet.hasSameBasechainAddress(sender())) {
            require(self.minter == sender(), "Incorrect sender");
        }

        if (self.airdrop == msg.sender) {
            require(self.startUnlockTime == 0, "Airdrop already claimed");

            self.startUnlockTime = now();
            self.lastUnlockTime = now();
            self.airdropAmount = msg.amount;
        } else {
            self.transferableBalance += msg.amount;
        }

        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg = myBalance() - msgValue;

        if (msg.forwardTonAmount > 0) {
            let fwdFee: Int = ctx.readForwardFee();
            msgValue -= msg.forwardTonAmount + fwdFee;
            message(MessageParameters {
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: JettonNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.sender,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        // 0xd53276db -- Cashback to the original Sender
        if (msg.responseDestination != null && msgValue > 0) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                value: msgValue,
                mode: SendRemainingBalance | SendIgnoreErrors,
                bounce: false,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
            });
        }
    }

    receive(msg: ProvideWalletBalance) {
        let info: VerifyInfo? = null;
        if (msg.includeVerifyInfo) {
            info = VerifyInfo {
                minter: self.minter,
                owner: self.owner,
                code: myCode(),
            };
        }

        message(MessageParameters {
            body: TakeWalletBalance {
                balance: self.balance,
                verifyInfo: info,
            }.toCell(),
            to: msg.receiver,
            value: 0,
            mode: SendRemainingValue,
        });
    }

    receive(msg: JettonBurn) {
        require(sender() == self.owner, "Incorrect sender");

        self.balance -= msg.amount;
        require(self.balance >= 0, "Incorrect balance after send");

        let ctx = context();
        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > (fwdFee + 2 * getComputeFee(gasForBurn, false)), "Insufficient amount of TON attached");

        message(MessageParameters {
            to: self.minter,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: JettonBurnNotification {
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination,
            }.toCell(),
        });
    }

    receive(msg: ClaimTON) {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        message(MessageParameters {
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    // ------------ Private functions ------------ //

    fun reserveStorage() {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg = myBalance() - msgValue;
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
    }

    fun recalculateUnlockableByTime() {
        if (self.startUnlockTime == 0) {
            return;
        }

        let remainingAirdrop: Int = self.airdropAmount - (self.unlockByActivity + self.unlockByTime);
        if remainingAirdrop <= 0 {
            return;
        }

        let deltaTime: Int = now() - self.lastUnlockTime;

        let airdropDuration: Int = yearUnix * 5;
        let elapsedSinceStart: Int = self.lastUnlockTime - self.startUnlockTime;
        let remainingDuration: Int = airdropDuration - elapsedSinceStart;
        let unlockAmount: Int = (remainingAirdrop * deltaTime) / remainingDuration;

        if unlockAmount > remainingAirdrop {
            unlockAmount = remainingAirdrop;
        }

        self.lastUnlockTime = now();
        self.transferableBalance += unlockAmount;
        self.unlockByTime += unlockAmount;
    }

    // ----------- Bounced handlers ------------ //

    bounced(msg: bounced<JettonTransferInternal>) {
        self.balance += msg.amount;
        self.transferableBalance += msg.amount;
    }

    bounced(msg: bounced<JettonBurnNotification>) {
        self.balance += msg.amount;
    }

    // ------------ Getters ------------ //

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData {
            balance: self.balance,
            owner: self.owner,
            minter: self.minter,
            code: myCode(),
        };
    }

    get fun fullData(): JettonFullInfo {
        if self.startUnlockTime == 0 || self.airdropAmount == 0 {
            return JettonFullInfo {
                balance: self.balance,
                airdropAmount: self.airdropAmount,
                transferableBalance: self.transferableBalance,
                startUnlockTime: self.startUnlockTime,
                perSecond: 0,
                unlockByTime: self.unlockByTime,
                unlockByActivity: self.unlockByActivity,
            };
        }

        let remainingAirdrop: Int = self.airdropAmount - (self.unlockByActivity + self.unlockByTime);

        if remainingAirdrop < 0 {
            remainingAirdrop = 0;
        }

        let deltaTime: Int = now() - self.lastUnlockTime;

        let airdropDuration: Int = yearUnix * 5;
        let elapsedSinceStart: Int = self.lastUnlockTime - self.startUnlockTime;
        let remainingDuration: Int = airdropDuration - elapsedSinceStart;
        let unlockAmount: Int = (remainingAirdrop * deltaTime) / remainingDuration;

        if unlockAmount > remainingAirdrop {
            unlockAmount = remainingAirdrop;
        }

        return JettonFullInfo {
            balance: self.balance,
            airdropAmount: self.airdropAmount,
            transferableBalance: self.transferableBalance + unlockAmount,
            startUnlockTime: self.startUnlockTime,
            perSecond: (remainingAirdrop / remainingDuration),
            unlockByTime: self.unlockByTime + unlockAmount,
            unlockByActivity: self.unlockByActivity,
        };
    }
}
