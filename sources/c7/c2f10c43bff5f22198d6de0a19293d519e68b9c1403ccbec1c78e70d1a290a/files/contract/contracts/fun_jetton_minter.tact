import "./fun_jetton_wallet.tact";
import "./fun_messages.tact";
import "./fun_constants.tact";
import "./fun_utils.tact";

const Workchain: Int = 0;

struct JettonMinterState {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

contract GovernanceJettonMinter {
    totalSupply: Int as coins;
    adminAddress: Address;
    nextAdminAddress: Address?;
    jettonContent: Cell;
    locked: Bool;
    paused: Bool;
    fee: Int;
    maxTotalSupplyLimit: Int as coins;
    baseTokenPrice: Int as coins;
    sellEnabled: Bool;
    mintTokenForTonEnabled: Bool;
    minRate: Int as coins;
    maxRate: Int as coins;

    init(
        totalSupply: Int,
        adminAddress: Address,
        nextAdminAddress: Address?,
        jettonContent: Cell,
        locked: Bool,
        paused: Bool,
        fee: Int,
        maxTotalSupplyLimit: Int,
        baseTokenPrice: Int
    ) {
        self.totalSupply = totalSupply;
        self.adminAddress = adminAddress;
        self.nextAdminAddress = nextAdminAddress;
        self.jettonContent = jettonContent;
        self.locked = locked;
        self.paused = paused;
        self.fee = fee;
        self.maxTotalSupplyLimit = maxTotalSupplyLimit;
        self.baseTokenPrice = baseTokenPrice;
        self.sellEnabled = false;
        self.mintTokenForTonEnabled = false;
        self.minRate = ton("0.0001");
        self.maxRate = ton("1000");
    }

    inline fun nonReentrant() {
        require(!self.locked, "Contract is locked");
        self.locked = true;
    }

    inline fun unlockContract() {
        self.locked = false;
    }

    inline fun requireNotPaused() {
        require(!self.paused, "Contract is paused");
    }

    inline fun requirePaused() {
        require(self.paused, "Contract is not paused");
    }

    inline fun getBaseTokenPrice(): Int {
        if (self.totalSupply == 0) {
            return self.baseTokenPrice;
        }
        let balance = myBalance();
        return balance / self.totalSupply;
    }

    inline fun getTokenPriceBuyInternal(): Int {
        return self.getBaseTokenPrice();
    }

    inline fun getTokenPriceSellInternal(): Int {
        let basePrice = self.getBaseTokenPrice();
        if (basePrice == 0) {
            return 0;
        }
        require(self.fee <= 1000, "Fee cannot exceed 100%");
        let feeMultiplier = 1000 - self.fee;
        require(feeMultiplier >= 0, "Invalid fee multiplier");

        require(basePrice < pow(2, 120), "Base price too large for fee calculation");

        return (basePrice * feeMultiplier) / 1000;
    }

    receive(msg: Mint) {
        self.nonReentrant();
        self.requireNotPaused();

        require(sender() == self.adminAddress || sender() == myAddress(), "Incorrect sender");
        require(msg.masterMsg.amount > 0, "Amount must be positive");
        require(msg.masterMsg.amount <= maxMintAmount, "Mint amount too large");

        let newTotalSupply = self.totalSupply + msg.masterMsg.amount;
        require(newTotalSupply >= self.totalSupply, "Total supply overflow");
        require(newTotalSupply <= self.maxTotalSupplyLimit, "Max total supply exceeded");

        require(parseStdAddress(msg.toAddress.asSlice()).workchain == Workchain, "Wrong workchain");

        checkEitherForwardPayload(msg.masterMsg.forwardPayload);

        let fwdCount = 1 + sign(msg.masterMsg.forwardTonAmount);
        let ctx = context();
        if (sender() != myAddress()) {
            require(ctx.value >= minTonForMint, "Insufficient TON for mint");
        }

        require(
        ctx.value >
        msg.masterMsg.forwardTonAmount +
        fwdCount * ctx.readForwardFee() +
        2 * getComputeFee(gasForTransfer, false) + minTonsForStorage,
        "Insufficient amount of TON attached",
        );

        self.totalSupply = newTotalSupply;

        deploy(DeployParameters {
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: msg.masterMsg.toCell(),
            init: getJettonWalletInit(msg.toAddress, myAddress()),
        });

        self.unlockContract();
    }

    receive(msg: JettonBurnNotification) {
        let sender = parseStdAddress(sender().asSlice());
        let wallet = getJettonBasechainWalletByOwner(msg.sender, myAddress());

        require(sender.workchain == Workchain && sender.address == wallet.hash!!, "Unauthorized burn");

        require(msg.amount > 0, "Burn amount must be positive");
        require(msg.amount <= maxBurnAmount, "Burn amount too large");
        require(self.totalSupply >= msg.amount, "Cannot burn more than total supply");

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            message(MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors,
            });
        }
    }

    receive(msg: JettonBurnNotificationWithSale) {
        require(self.sellEnabled, "Token selling is disabled");

        let sender = parseStdAddress(sender().asSlice());
        let wallet = getJettonBasechainWalletByOwner(msg.sender, self.adminAddress);

        require(sender.workchain == Workchain && sender.address == wallet.hash!!, "Unauthorized burn");

        require(msg.amount > 0, "Burn amount must be positive");
        require(msg.amount <= maxBurnAmount, "Burn amount too large");
        require(self.totalSupply >= msg.amount, "Cannot burn more than total supply");

        self.totalSupply -= msg.amount;

        message(MessageParameters {
            to: msg.sellerAddress,
            body: JettonExcesses { queryId: msg.queryId }.toCell(),
            value: msg.tonToPayOut,
            bounce: false,
            mode: SendPayGasSeparately | SendIgnoreErrors,
        });

        if (msg.finalDestination != null) {
            message(MessageParameters {
                to: msg.finalDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors,
            });
        }
    }

    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;

        let targetJettonWallet: BasechainAddress = (ownerWorkchain == Workchain)
        ? contractBasechainAddress(getJettonWalletInit(msg.ownerAddress, myAddress()))
        : emptyBasechainAddress();

        message(MessageParameters {
            bounce: false,
            body: makeTakeWalletAddressMsg(targetJettonWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendBounceIfActionFail,
        });
    }

    receive(msg: ChangeAdmin) {
        require(sender() == self.adminAddress, "Incorrect sender");
        self.nextAdminAddress = msg.newAdminAddress;
    }

    receive(msg: ClaimAdmin) {
        require(sender() == self.nextAdminAddress, "Not next admin");
        self.adminAddress = sender();
        self.nextAdminAddress = null;
    }

    receive(msg: CallTo) {
        self.nonReentrant();

        require(sender() == self.adminAddress, "Incorrect sender");

        let ctx = context();
        require(ctx.value >= minTonForCallTo, "Insufficient TON for CallTo");

        let msgInfo = calculateSliceBitsAndRefs(msg.masterMsg.asSlice());
        require(msgInfo.refs <= maxCellRefs, "Too many refs in masterMsg");
        require(msgInfo.bits <= maxCellBits, "Message too large");

        let masterMsgSlice = msg.masterMsg.beginParse();
        let op = masterMsgSlice.preloadUint(32);

        if (op == UpgradeCodeOpcode) {
            self.requirePaused();
        } else {
            self.requireNotPaused();
        }

        if (op == JettonTransferOpcode) {
            let msgToSend = JettonTransfer.fromSlice(masterMsgSlice);

            require(msgToSend.amount > 0, "Transfer amount must be positive");
            require(msgToSend.amount <= maxTransferAmount, "Transfer amount too large");

            forceBasechainValidation(msgToSend.destination);

            checkEitherForwardPayload(msgToSend.forwardPayload);

            let fwdCount = 1 + sign(msgToSend.forwardTonAmount);

            require(ctx.value >= minTonForTransfer, "Insufficient TON for transfer");
            require(
            ctx.value >
            msgToSend.forwardTonAmount +
            fwdCount * ctx.readForwardFee() +
            (2 * getComputeFee(gasForTransfer, false) + minTonsForStorage),
            "Insufficient amount of TON attached",
            );

            deploy(DeployParameters {
                bounce: false,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, myAddress()),
            });

            self.unlockContract();

        } else if (op == JettonBurnOpcode) {
            let msgToSend = JettonBurn.fromSlice(masterMsgSlice);

            require(msgToSend.amount > 0, "Burn amount must be positive");
            require(msgToSend.amount <= maxBurnAmount, "Burn amount too large");

            require(ctx.value >= minTonForBurn, "Insufficient TON for burn");
            require(
            ctx.value > (ctx.readForwardFee() + 2 * getComputeFee(gasForBurn, false)),
            "Insufficient amount of TON attached",
            );

            deploy(DeployParameters {
                bounce: false,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, myAddress()),
            });

            self.unlockContract();

        } else if (op == SetStatusOpcode) {
            let msgToSend = SetStatus.fromSlice(masterMsgSlice);

            require(msgToSend.status <= 15, "Invalid status value");

            deploy(DeployParameters {
                bounce: false,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, myAddress()),
            });

            self.unlockContract();

        } else if (op == SetMinTransferAmountOpcode) {
            let msgToSend = SetMinTransferAmount.fromSlice(masterMsgSlice);

            require(msgToSend.newMinAmount >= 0, "Min transfer amount cannot be negative");
            require(msgToSend.newMinAmount <= maxTransferAmount, "Min transfer amount too large");

            deploy(DeployParameters {
                bounce: false,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, myAddress()),
            });

            self.unlockContract();

        } else if (op == TransferTonOpcode) {
            let msgToSend = TransferTon.fromSlice(masterMsgSlice);

            require(msgToSend.amount >= 0, "Transfer amount cannot be negative");
            require(ctx.value >= minTonForCallTo, "Insufficient TON for TransferTon");

            deploy(DeployParameters {
                bounce: false,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, myAddress()),
            });

            self.unlockContract();
        } else if (op == SetAutoForwardTonOpcode) {
            let msgToSend = SetAutoForwardTon.fromSlice(masterMsgSlice);

            require(ctx.value >= minTonForCallTo, "Insufficient TON for SetAutoForwardTon");

            deploy(DeployParameters {
                bounce: false,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, myAddress()),
            });

            self.unlockContract();
        } else if (op == UpgradeCodeOpcode) {
            let msgToSend = UpgradeCode.fromSlice(masterMsgSlice);

            let codeSlice = msgToSend.newCode.beginParse();
            require(codeSlice.bits() > 0 || codeSlice.refs() > 0, "New code cannot be empty");

            require(ctx.value >= minTonForCallTo, "Insufficient TON for UpgradeCode");

            deploy(DeployParameters {
                bounce: true,
                value: 0,
                mode: SendRemainingValue | SendBounceIfActionFail,
                body: msg.masterMsg,
                init: getJettonWalletInit(msg.toAddress, myAddress()),
            });

            self.unlockContract();
        } else {
            self.unlockContract();
            require(false, "Unsupported operation in CallTo");
        }
    }

    receive(msg: ChangeMetadataUri) {
        require(sender() == self.adminAddress, "Incorrect sender");

        let metadataInfo = calculateSliceBitsAndRefs(msg.metadata);
        let metadataSize = metadataInfo.bits / 8 + metadataInfo.refs * 32;
        require(metadataSize <= maxMetadataSize, "Metadata too large");

        self.jettonContent = msg.metadata.asCell();
    }

    receive(msg: Upgrade) {
        require(sender() == self.adminAddress, "Incorrect sender");

        let codeSlice = msg.newCode.beginParse();
        require(codeSlice.bits() > 0 || codeSlice.refs() > 0, "New code cannot be empty");

        let dataSlice = msg.newData.beginParse();
        require(dataSlice.bits() > 0 || dataSlice.refs() > 0, "New data cannot be empty");

        setData(msg.newData);
        setCode(msg.newCode);
    }

    receive(msg: UpgradeCode) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(self.paused, "Contract must be paused for upgrade");

        let codeSlice = msg.newCode.beginParse();
        require(codeSlice.bits() > 0 || codeSlice.refs() > 0, "New code cannot be empty");

        setCode(msg.newCode);
    }

    receive(msg: PauseContract) {
        require(sender() == self.adminAddress, "Incorrect sender");
        self.paused = msg.pause;
    }

    receive(msg: SetFee) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newFee >= 0, "Fee cannot be negative");
        require(msg.newFee <= 1000, "Fee cannot exceed 100%");
        self.fee = msg.newFee;
    }

    receive(msg: SetMaxTotalSupply) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newMaxTotalSupply > 0, "Max total supply must be positive");
        require(msg.newMaxTotalSupply >= self.totalSupply, "Max total supply cannot be less than current total supply");
        self.maxTotalSupplyLimit = msg.newMaxTotalSupply;
    }

    receive(msg: SetBasePrice) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newBasePrice > 0, "Base price must be positive");
        self.baseTokenPrice = msg.newBasePrice;
    }

    receive(msg: SetSellEnabled) {
        require(sender() == self.adminAddress, "Incorrect sender");
        self.sellEnabled = msg.enabled;
    }

    receive(msg: SetMintTokenForTonEnabled) {
        require(sender() == self.adminAddress, "Incorrect sender");
        self.mintTokenForTonEnabled = msg.enabled;
    }

    receive(msg: SetMinRate) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newMinRate > 0, "Min rate must be positive");
        require(msg.newMinRate < self.maxRate, "Min rate must be less than max rate");
        self.minRate = msg.newMinRate;
    }

    receive(msg: SetMaxRate) {
        require(sender() == self.adminAddress, "Incorrect sender");
        require(msg.newMaxRate > 0, "Max rate must be positive");
        require(msg.newMaxRate > self.minRate, "Max rate must be greater than min rate");
        self.maxRate = msg.newMaxRate;
    }

    receive(msg: BuyTokens) {
        self.nonReentrant();
        self.requireNotPaused();

        let ctx = context();

        require(ctx.value > 0, "No TON attached");
        require(ctx.value >= minTonForMint, "Insufficient TON for buy");

        require(parseStdAddress(msg.buyerAddress.asSlice()).workchain == Workchain, "Wrong workchain");

        checkEitherForwardPayload(msg.forwardPayload);

        let tokenPrice = self.getTokenPriceBuyInternal();
        require(tokenPrice > 0, "Token price not set");

        let fwdCount = 1 + sign(msg.forwardTonAmount);
        let reservedAmount = msg.forwardTonAmount +
                           fwdCount * ctx.readForwardFee() +
                           (2 * getComputeFee(gasForTransfer, false) + minTonsForStorage);

        require(ctx.value > reservedAmount, "Insufficient TON for operation");

        let tonForTokens = ctx.value - reservedAmount;

        let tokensAmount = tonForTokens / tokenPrice;
        require(tokensAmount > 0, "Calculated tokens amount is zero");
        require(tokensAmount <= maxMintAmount, "Buy amount too large");

        let newTotalSupply = self.totalSupply + tokensAmount;
        require(newTotalSupply >= self.totalSupply, "Total supply overflow");
        require(newTotalSupply <= self.maxTotalSupplyLimit, "Max total supply exceeded");

        self.totalSupply = newTotalSupply;

        deploy(DeployParameters {
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: JettonTransferInternal {
                queryId: msg.queryId,
                amount: tokensAmount,
                sender: myAddress(),
                responseDestination: sender(),
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }.toCell(),
            init: getJettonWalletInit(msg.buyerAddress, myAddress()),
        });

        self.unlockContract();
    }

    receive(msg: MintTokenForTon) {
        self.nonReentrant();
        self.requireNotPaused();

        require(self.mintTokenForTonEnabled, "MintTokenForTon is disabled");

        let ctx = context();
        let buyerAddress = sender();

        require(ctx.value > 0, "No TON attached");
        require(ctx.value >= minTonForMint, "Insufficient TON for mint");
        require(msg.tokenRate > 0, "Token rate must be positive");

        require(parseStdAddress(buyerAddress.asSlice()).workchain == Workchain, "Wrong workchain");

        checkEitherForwardPayload(msg.forwardPayload);

        require(msg.tokenRate >= self.minRate, "Token rate too low");
        require(msg.tokenRate <= self.maxRate, "Token rate too high");

        let eventCost = ton("0.002");
        let minimalReserve = ton("0.01");

        require(ctx.value > minimalReserve, "Insufficient TON for operation");

        let tonForTokens = ctx.value - minimalReserve;

        let tokensAmount = (tonForTokens * 1000000) / msg.tokenRate;

        require(tokensAmount > 0, "Calculated tokens amount is zero");
        require(tokensAmount <= maxMintAmount, "Mint amount too large");

        let newTotalSupply = self.totalSupply + tokensAmount;
        require(newTotalSupply >= self.totalSupply, "Total supply overflow");
        require(newTotalSupply <= self.maxTotalSupplyLimit, "Max total supply exceeded");

        let eventData = MintTokenForTonSuccess {
            queryId: msg.queryId,
            buyer: buyerAddress,
            tonAmount: tonForTokens,
            tokenRate: msg.tokenRate,
            tokensReceived: tokensAmount,
            timestamp: now(),
        };

        message(MessageParameters {
            to: self.adminAddress,
            value: eventCost,
            mode: SendIgnoreErrors,
            bounce: false,
            body: eventData.toCell(),
        });

        let mintMessage = Mint {
            queryId: msg.queryId,
            toAddress: buyerAddress,
            tonAmount: 0,
            masterMsg: JettonTransferInternal {
                queryId: msg.queryId,
                amount: tokensAmount,
                sender: myAddress(),
                responseDestination: myAddress(),
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: msg.forwardPayload,
            }
        };

        message(MessageParameters {
            to: myAddress(),
            value: 0,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: mintMessage.toCell(),
        });

        self.unlockContract();
    }

    receive(msg: SellTokens) {
        self.nonReentrant();
        self.requireNotPaused();

        require(self.sellEnabled, "Token selling is disabled");

        let ctx = context();

        require(ctx.value >= minTonForBurn, "Insufficient TON for sell");
        require(msg.tokensAmount > 0, "Tokens amount must be positive");
        require(msg.tokensAmount <= maxBurnAmount, "Sell amount too large");

        require(parseStdAddress(msg.sellerAddress.asSlice()).workchain == Workchain, "Wrong workchain");

        require(self.totalSupply >= msg.tokensAmount, "Insufficient total supply");

        let tokenPriceSell = self.getTokenPriceSellInternal();
        require(tokenPriceSell > 0, "Token price not set");

        let tonToPayOut = msg.tokensAmount * tokenPriceSell;
        require(tonToPayOut > 0, "Calculated TON amount is zero");

        let currentBalance = myBalance();
        let storageFee = myStorageDue();
        let reserveAmount = minTonsForStorage + storageFee + ctx.readForwardFee() + tonToPayOut;

        require(currentBalance > reserveAmount, "Insufficient contract balance for payout");

        let customPayloadCell = beginCell()
            .storeAddress(msg.sellerAddress)
            .storeCoins(tonToPayOut)
            .storeMaybeRef(msg.responseDestination != null ? beginCell().storeAddress(msg.responseDestination!!).endCell() : null)
            .endCell();

        let payloadInfo = calculateSliceBitsAndRefs(customPayloadCell.asSlice());
        let payloadSize = payloadInfo.bits / 8 + payloadInfo.refs * 32;
        require(payloadSize <= maxForwardPayloadSize, "Custom payload too large for sell operation");

        deploy(DeployParameters {
            value: ctx.value - ctx.readForwardFee(),
            bounce: true,
            mode: SendBounceIfActionFail,
            body: JettonBurn {
                queryId: msg.queryId,
                amount: msg.tokensAmount,
                responseDestination: myAddress(),
                customPayload: customPayloadCell,
            }.toCell(),
            init: getJettonWalletInit(msg.sellerAddress, myAddress()),
        });

        self.unlockContract();
    }

    receive(_: TopUp) {}

    receive(_: JettonExcesses) {
    }

    receive(msg: ForwardTonNotification) {
        let eventCost = ton("0.002");

        let eventData = TonForwardedSuccess {
            queryId: msg.queryId,
            walletOwner: msg.walletOwner,
            forwardedAmount: msg.forwardedAmount,
            timestamp: now(),
        };

        message(MessageParameters {
            to: self.adminAddress,
            value: eventCost,
            mode: SendIgnoreErrors,
            bounce: false,
            body: eventData.toCell(),
        });
    }

    receive(msg: WithdrawAllTon) {
        require(sender() == self.adminAddress, "Incorrect sender");

        let currentBalance = myBalance();
        let storageFee = myStorageDue();

        let reserveAmount = minTonsForStorage + storageFee;

        let withdrawAmount = currentBalance - reserveAmount;

        require(withdrawAmount > 0, "No TON balance to withdraw");

        let recipient = msg.destination;
        if (recipient == null) {
            recipient = self.adminAddress;
        }

        nativeReserve(reserveAmount, ReserveAtMost);

        message(MessageParameters {
            to: recipient!!,
            value: withdrawAmount,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: false,
            body: JettonExcesses { queryId: msg.queryId }.toCell(),
        });
    }

    bounced(msg: bounced<JettonTransferInternal>) {
        self.totalSupply -= msg.amount;
    }

    get fun get_jetton_data(): JettonData {
        return JettonData {
            totalSupply: self.totalSupply,
            mintable: true,
            owner: self.adminAddress,
            content: self.jettonContent,
            jettonWalletCode: codeOf JettonWalletGovernance,
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return getJettonWalletByOwner(ownerAddress, myAddress());
    }

    get fun get_next_admin_address(): Address? {
        return self.nextAdminAddress;
    }

    get fun get_fee(): Int {
        return self.fee;
    }

    get fun get_token_price_buy(): Int {
        return self.getTokenPriceBuyInternal();
    }

    get fun get_token_price_sell(): Int {
        return self.getTokenPriceSellInternal();
    }

    get fun get_base_token_price(): Int {
        return self.getBaseTokenPrice();
    }

    get fun get_contract_balance(): Int {
        return myBalance();
    }

    get fun get_max_total_supply(): Int {
        return self.maxTotalSupplyLimit;
    }

    get fun get_base_price(): Int {
        return self.baseTokenPrice;
    }

    get fun get_sell_enabled(): Bool {
        return self.sellEnabled;
    }

    get fun get_mint_token_for_ton_enabled(): Bool {
        return self.mintTokenForTonEnabled;
    }

    get fun get_min_rate(): Int {
        return self.minRate;
    }

    get fun get_max_rate(): Int {
        return self.maxRate;
    }
}
