import "./fun_messages.tact";
import "./fun_constants.tact";
import "./fun_utils.tact";

contract JettonWalletGovernance {
    status: Int as uint4;
    balance: Int as coins;
    owner: Address;
    master: Address;
    walletMinTransfer: Int as coins;
    
    init(status: Int, balance: Int, owner: Address, master: Address) {
        self.status = status;
        self.balance = balance;
        self.owner = owner;
        self.master = master;
        self.walletMinTransfer = minTransferAmount;
    }

    receive(msg: JettonTransfer) {
        forceBasechainValidation(msg.destination);

        let isFromMaster = sender() == self.master;

        require(self.status <= 15, "Invalid wallet status");
        let outgoingTransfersAllowed = ((self.status & 1) == 0);

        require(outgoingTransfersAllowed || isFromMaster, "Contract is locked");
        require(sender() == self.owner || isFromMaster, "Incorrect sender");

        require(msg.amount > 0, "Transfer amount must be positive");
        require(msg.amount <= maxTransferAmount || isFromMaster, "Transfer amount too large");
        require(self.balance >= msg.amount, "Insufficient balance");
        
        self.balance -= msg.amount;

        checkEitherForwardPayload(msg.forwardPayload);

        let ctx = context();
        
        let fwdCount = 1 + sign(msg.forwardTonAmount);

        let canTransfer = isFromMaster || 
                         ((ctx.value >= minTonForTransfer) && 
                          (self.walletMinTransfer == 0 || msg.amount >= self.walletMinTransfer));
        
        require(canTransfer, "Transfer not allowed: insufficient TON or amount below minimum");

        let requiredTon = msg.forwardTonAmount +
                         fwdCount * ctx.readForwardFee() +
                         2 * getComputeFee(gasForTransfer, false);
        
        require(ctx.value > requiredTon + minTonsForStorage, "Insufficient amount of TON attached");

        let msgValue = ctx.value;
        let toLeaveOnBalance = myBalance() - msgValue + myStorageDue();
        nativeReserve(max(toLeaveOnBalance, minTonsForStorage), ReserveAtMost);
        
        deploy(DeployParameters {
            value: 0,
            mode: SendRemainingValue | SendBounceIfActionFail,
            bounce: true,
            body: JettonTransferInternal {
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: self.master,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }.toCell(),
            init: initOf JettonWalletGovernance(0, 0, msg.destination, self.master),
        });
    }

    receive(msg: JettonTransferInternal) {
        require(self.status <= 15, "Invalid wallet status");
        let incomingTransfersLocked = ((self.status & 2) == 2);
        require(!incomingTransfersLocked, "Incoming transfers are locked");

        require(msg.amount > 0, "Transfer amount must be positive");
        let newBalance = self.balance + msg.amount;
        require(newBalance >= self.balance, "Balance overflow");
        
        self.balance = newBalance;

        let wallet: StateInit = initOf JettonWalletGovernance(0, 0, msg.sender, self.master);
        if (!wallet.hasSameBasechainAddress(sender())) {
            require(self.master == sender(), "Incorrect sender");
        }

        if (msg.forwardTonAmount > 0) {
            message(MessageParameters {
                to: self.owner,
                value: msg.forwardTonAmount,
                mode: SendPayGasSeparately | SendBounceIfActionFail,
                bounce: false,
                body: JettonNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.sender,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }

        if (msg.responseDestination != null) {
            let msgValue = context().value;
            let toLeaveOnBalance = myBalance() - msgValue + myStorageDue();
            nativeReserve(max(toLeaveOnBalance, minTonsForStorage), ReserveAtMost);
            message(MessageParameters {
                to: msg.responseDestination!!,
                value: msgValue,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: false,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
            });
        }
    }

    receive(msg: JettonBurn) {
        require(sender() == self.master, "Not master");
        
        require(msg.amount > 0, "Burn amount must be positive");

        self.balance -= msg.amount;
        require(self.balance >= 0, "Incorrect balance after burn");

        let ctx = context();
        require(ctx.value > (ctx.readForwardFee() + 2 * getComputeFee(gasForBurn, false)), "Insufficient amount of TON attached");

        if (msg.customPayload != null) {
            let payloadSlice = msg.customPayload!!.beginParse();
            
            let payloadInfo = calculateSliceBitsAndRefs(payloadSlice);
            require(payloadInfo.bits >= 267, "Invalid customPayload structure");
            
            require(payloadInfo.bits <= maxCellBits, "CustomPayload too large");
            require(payloadInfo.refs <= 1, "Too many refs in customPayload");
            
            let sellerAddress = payloadSlice.loadAddress();
            
            require(parseStdAddress(sellerAddress.asSlice()).workchain == 0, "Invalid seller workchain");
            
            let tonToPayOut = payloadSlice.loadCoins();
            
            require(tonToPayOut > 0, "Payout amount must be positive");
            require(tonToPayOut <= ton("1000000"), "Payout amount unreasonably large");
            
            let finalDestinationRef = payloadSlice.loadMaybeRef();
            let finalDestination: Address? = null;
            if (finalDestinationRef != null) {
                let destSlice = finalDestinationRef!!.beginParse();
                let refInfo = calculateSliceBitsAndRefs(destSlice);
                require(refInfo.bits >= 267, "Invalid final destination address");
                finalDestination = destSlice.loadAddress();
                require(parseStdAddress(finalDestination!!.asSlice()).workchain == 0, "Invalid final destination workchain");
            }
            
            message(MessageParameters {
                to: self.master,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                bounce: true,
                body: JettonBurnNotificationWithSale {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: self.owner,
                    responseDestination: msg.responseDestination,
                    sellerAddress: sellerAddress,
                    tonToPayOut: tonToPayOut,
                    finalDestination: finalDestination,
                }.toCell(),
            });
        } else {
            message(MessageParameters {
                to: self.master,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                bounce: true,
                body: JettonBurnNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: self.owner,
                    responseDestination: msg.responseDestination,
                }.toCell(),
            });
        }
    }

    receive(msg: SetStatus) {
        require(sender() == self.master, "Incorrect sender");
        self.status = msg.status;
    }

    receive(msg: SetMinTransferAmount) {
        require(sender() == self.master, "Incorrect sender");
        require(msg.newMinAmount >= 0, "Min transfer amount cannot be negative");
        self.walletMinTransfer = msg.newMinAmount;
    }

    receive(msg: TransferAllTon) {
        require(sender() == self.master, "Incorrect sender");
        
        let ctx = context();
        let currentBalance = myBalance();
        let storageFee = myStorageDue();
        
        let reserveAmount = minTonsForStorage + storageFee + ctx.readForwardFee();
        
        let transferAmount = currentBalance - reserveAmount;
        
        require(transferAmount > 0, "No TON balance to transfer");
        
        nativeReserve(reserveAmount, ReserveAtMost);
        
        message(MessageParameters {
            to: self.master,
            value: transferAmount,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: false,
            body: JettonExcesses { queryId: msg.queryId }.toCell(),
        });
        
        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
            });
        }
    }

    receive(_: TopUp) {}

    bounced(msg: bounced<JettonTransferInternal>) {
        require(msg.amount > 0, "Invalid bounced amount");
        let newBalance = self.balance + msg.amount;
        require(newBalance >= self.balance, "Balance overflow on bounce");
        self.balance = newBalance;
    }

    bounced(msg: bounced<JettonBurnNotification>) {
        require(msg.amount > 0, "Invalid bounced amount");
        let newBalance = self.balance + msg.amount;
        require(newBalance >= self.balance, "Balance overflow on bounce");
        self.balance = newBalance;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData {
            balance: self.balance,
            owner: self.owner,
            minter: self.master,
            code: myCode(),
        };
    }

    get fun get_status(): Int {
        return self.status;
    }

    get fun get_transfer_limits(): TransferLimits {
        return TransferLimits {
            minAmount: self.walletMinTransfer,
            maxAmount: maxTransferAmount,
            canTransfer: ((self.status & 1) == 0),
        };
    }

}