import "@stdlib/deploy";
import "@stdlib/ownable";
import "./constants.tact";
import "./messages.tact";
import "./structs.tact";

// PRMD jetton master
@interface("org.ton.jetton.master")
contract PRMDJettonMaster with JettonMaster {
    owner: Address;
    minter: Address;
    content: Cell;
    totalSupply: Int as coins;
    mintable: Bool;
    lastRentRequest: Int as uint32;

    init(owner: Address, content: Cell, minter: Address) {
        self.owner = owner;
        self.content = content;
        self.totalSupply = 0;
        self.mintable = true;
        self.minter = minter;
        self.lastRentRequest = 0;
    }
}

// PRMD jetton wallet
@interface("org.ton.jetton.wallet")
contract PRMDJettonWallet with JettonWallet {
    balance: Int as coins;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }
}

// =====================================
// Traits for implementing the Jetton standard
// =====================================

@interface("org.ton.jetton.master")
trait JettonMaster with Ownable {
    owner: Address;
    // Timestamp of the last rent-refill request sent to the minter
    // (see maybeRequestRentRefill).
    lastRentRequest: Int as uint32;
    // The privileged emission source: the only contract besides the owner
    // allowed to mint, and the destination of burn notifications (leftover
    // burn gas included). Reassignable by the owner/minter via SetMinter, so
    // emission can be handed to a newly deployed game contract without
    // redeploying the token.
    minter: Address;
    content: Cell;
    totalSupply: Int as coins;
    mintable: Bool;

    // === Jetton standard methods (TEP-74) === //
    
    // Change owner of the contract
    receive(msg: ChangeJettonMasterOwner) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.minter, "Not owner");
        self.owner = msg.owner;
    }

    // Hand the emission right (mint + burn-notification destination) to
    // another contract.
    receive(msg: SetMinter) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.minter, "Not owner");
        self.minter = msg.minter;
    }
    
    // Update token content
    receive(msg: UpdateJettonContent) {
        self.requireOwner();
        self.content = msg.content;
    }
    
    // Disable minting
    receive(msg: StopMinting) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.minter, "Not owner");
        self.mintable = false;
    }
    
    // Minting. Deploys/credits the receiver's wallet and carries the remaining
    // attached value forward (SendRemainingValue), so the receiver gets the
    // standard transfer_notification funded by `forwardAmount`.
    receive(msg: MintJetton) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.minter, "Not owner");
        require(self.mintable, "Not mintable");
        require(msg.amount > 0, "Amount should be positive");

        let mintAmount: Int = msg.amount;
        if (self.totalSupply + mintAmount > MAX_SUPPLY) {
            mintAmount = MAX_SUPPLY - self.totalSupply;
            self.mintable = false;
        }
        self.totalSupply += mintAmount;

        require(
            ctx.value >
                minTonsForStorage +
                msg.forwardAmount +
                ctx.readForwardFee() +
                getForwardFee(walletStateInitCells, walletStateInitBits, false) +
                2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        let jettonWallet = self.getJettonWalletInit(msg.receiver);
        send(SendParameters{
            to: contractAddress(jettonWallet),
            value: 0,
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: mintAmount,
                from: myAddress(),
                responseDestination: msg.responseDestination,
                forwardAmount: msg.forwardAmount,
                forwardPayload: emptySlice()
            }.toCell(),
            code: jettonWallet.code,
            data: jettonWallet.data
        });
    }
    
    // Multiple minting (admin airdrop). Each receiver gets its own value paid
    // separately; leftover is returned to the sender.
    receive(msg: MultiMint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.minter, "Not owner");
        require(self.mintable, "Not mintable");
        require(msg.receiverCount > 0, "receiverCount must be positive");

        let tonBalanceBeforeMsg: Int = myBalance() - ctx.value;
        let minPerReceiver: Int = minTonsForStorage + 2 * getComputeFee(gasForTransfer, false);
        let i: Int = 0;

        while (i < msg.receiverCount && self.mintable) {
            let receiver = msg.receivers.get(i);
            i += 1;
            require(receiver != null, "Invalid receiver");
            require(receiver!!.amount > 0, "Amount should be positive");
            require(receiver!!.tonAmount > receiver!!.forwardAmount + minPerReceiver, "Insufficient ton amount");

            let mintAmount = receiver!!.amount;
            if (self.totalSupply + mintAmount > MAX_SUPPLY) {
                mintAmount = MAX_SUPPLY - self.totalSupply;
                self.mintable = false;
            }
            self.totalSupply += mintAmount;

            let jettonWallet = self.getJettonWalletInit(receiver!!.receiver);
            send(SendParameters{
                to: contractAddress(jettonWallet),
                value: receiver!!.tonAmount,
                bounce: true,
                mode: SendPayGasSeparately,
                body: TokenTransferInternal{
                    queryId: msg.queryId,
                    amount: mintAmount,
                    from: myAddress(),
                    responseDestination: receiver!!.responseDestination,
                    forwardAmount: receiver!!.forwardAmount,
                    forwardPayload: emptySlice()
                }.toCell(),
                code: jettonWallet.code,
                data: jettonWallet.data
            });
        }

        // Keep the master solvent, then return any leftover to the sender.
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: Excesses{
                queryId: msg.queryId
            }.toCell()
        });
    }
    
    // Handle Jetton burn notifications. Decrements supply and forwards the
    // remaining value to the current minter (a game credits the leftover gas
    // to its bank/pool — a deliberate product behavior for this rewards
    // token).
    receive(msg: TokenBurnNotification) {
        let ctx: Context = context();
        require(msg.amount > 0, "Amount should be positive");

        let walletInit = self.getJettonWalletInit(msg.sender);
        require(contractAddress(walletInit) == ctx.sender, "Invalid sender");

        self.totalSupply = max(0, self.totalSupply - msg.amount);
        if (self.totalSupply < MAX_SUPPLY) {
            self.mintable = true;
        }

        send(SendParameters{
            to: self.minter,
            value: 0,
            bounce: false,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: JettonsBurned{
                queryId: msg.queryId,
                amount: msg.amount,
                totalSupply: self.totalSupply
            }.toCell()
        });
        self.maybeRequestRentRefill();
    }
    
    // Rent top-up: the value stays on the balance, nothing else to do.
    // Open to anyone — an unsolicited donation cannot hurt.
    receive(msg: RentRefill) {}

    // Rent self-refill: when the master's own funds cover less than the
    // alert horizon of storage rent, ask the minter to top the balance back
    // up to the full target horizon. Fires from the regular traffic
    // receivers below; a day-long cooldown keeps hot traffic from turning
    // into request spam, and a healthy ("hot") master never signals at all.
    // Standard TEP-74/89 flows are untouched: this is one extra outbound
    // service message funded by the master's own balance, skipped silently
    // (SendIgnoreErrors) if even that cannot be afforded. Always call it
    // AFTER the receiver's standard send: actions run in order, so the
    // standard reply keeps its full RemainingValue budget and only the
    // leftover own balance funds the signal.
    fun maybeRequestRentRefill() {
        let owned: Int = myBalance() - context().value;
        let alert: Int = getStorageFee(
            masterStorageCells, masterStorageBits, MASTER_RENT_ALERT_SECONDS, false);
        if (owned >= alert + MASTER_RENT_SIGNAL_VALUE) {
            return;
        }
        if (now() < self.lastRentRequest + MASTER_RENT_SIGNAL_COOLDOWN) {
            return;
        }
        self.lastRentRequest = now();
        let target: Int = getStorageFee(
            masterStorageCells, masterStorageBits, MASTER_RENT_TARGET_SECONDS, false);
        send(SendParameters{
            to: self.minter,
            value: MASTER_RENT_SIGNAL_VALUE,
            bounce: false,
            mode: SendPayGasSeparately | SendIgnoreErrors,
            body: RequestRentRefill{
                queryId: 0,
                deficit: max(0, target - owned) + MASTER_RENT_SIGNAL_VALUE
            }.toCell()
        });
    }

    // Provide wallet address (TEP-89 discovery).
    receive(msg: ProvideWalletAddress) {
        let ctx: Context = context();
        let walletAddress = self.getWalletAddress(msg.ownerAddress);

        send(SendParameters{
            to: ctx.sender,
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: TakeWalletAddress{
                queryId: msg.queryId,
                walletAddress: walletAddress,
                // TEP-89: owner_address is (Maybe ^Address) — the address goes
                // into a reference, not inline after the flag.
                ownerAddress: msg.includeAddress ?
                    beginCell().storeBool(true).storeRef(beginCell().storeAddress(msg.ownerAddress).endCell()).endCell().asSlice() :
                    beginCell().storeBool(false).endCell().asSlice()
            }.toCell()
        });
        self.maybeRequestRentRefill();
    }
    
    // Handle TokenTransferInternal return on failed minting
    bounced(src: bounced<TokenTransferInternal>) {
        self.totalSupply = max(0, self.totalSupply - src.amount);
    }
    
    // === Internal methods === //
    
    // Get initialization of jetton wallet
    virtual fun getJettonWalletInit(owner: Address): StateInit {
        return initOf PRMDJettonWallet(myAddress(), owner);
    }
    
    // Get wallet address
    fun getWalletAddress(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }
    
    // === Get methods === //
    
    // Get jetton data
    get fun get_jetton_data(): JettonMasterData {
        return JettonMasterData{
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            owner: self.owner,
            content: self.content,
            walletCode: self.getJettonWalletInit(myAddress()).code
        };
    }
    
    // Get wallet address
    get fun get_wallet_address(owner: Address): Address {
        return self.getWalletAddress(owner);
    }

    // Current emission source.
    get fun minter(): Address {
        return self.minter;
    }
}

@interface("org.ton.jetton.wallet")
trait JettonWallet {
    balance: Int as coins;
    owner: Address;
    master: Address;

    // === Jetton standard methods (TEP-74) === //
    
    // Outgoing transfer initiated by the wallet owner. Carries the remaining
    // attached value forward (SendRemainingValue) and honors the sender's
    // `forwardAmount` (forward_ton_amount), so DEX routers/pools receive exactly
    // the gas they requested for their transfer_notification.
    receive(msg: TokenTransfer) {
        forceBasechain(msg.destination);
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Incorrect sender");
        require(msg.amount > 0, "Amount should be positive");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        // Require enough TON to deploy the destination wallet, pay the forward
        // notification, the two outgoing message forward fees and compute, and
        // keep a storage reserve. `forwardAmount` is positive -> 2 forwards.
        let fwdCount: Int = 1 + sign(msg.forwardAmount);
        require(
            ctx.value >
                msg.forwardAmount +
                fwdCount * ctx.readForwardFee() +
                getForwardFee(walletStateInitCells, walletStateInitBits, false) +
                (2 * getComputeFee(gasForTransfer, false) + minTonsForStorage),
            "Insufficient amount of TON attached",
        );

        let receiverWalletInit = initOf PRMDJettonWallet(self.master, msg.destination);
        send(SendParameters{
            to: contractAddress(receiverWalletInit),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                responseDestination: msg.responseDestination,
                forwardAmount: msg.forwardAmount,
                forwardPayload: msg.forwardPayload
            }.toCell(),
            code: receiverWalletInit.code,
            data: receiverWalletInit.data
        });
    }
    
    // Incoming internal transfer from the master (mint) or another wallet.
    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();
        self.balance = self.balance + msg.amount;

        // Accept only from the master, or from the sender's own jetton wallet.
        if (ctx.sender != self.master) {
            let senderWalletInit = initOf PRMDJettonWallet(self.master, msg.from);
            require(contractAddress(senderWalletInit) == ctx.sender, "Incorrect sender");
        }

        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;

        // Forward the requested notification value to the owner (e.g. the DEX
        // pool/router), funded by the sender's forward_ton_amount.
        if (msg.forwardAmount > 0) {
            let fwdFee: Int = ctx.readForwardFee();
            msgValue = msgValue - msg.forwardAmount - fwdFee;
            send(SendParameters{
                to: self.owner,
                value: msg.forwardAmount,
                bounce: false,
                mode: SendPayGasSeparately,
                body: TransferNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    sender: msg.from,
                    forwardPayload: msg.forwardPayload
                }.toCell()
            });
        }

        // Keep the wallet solvent, then return any unused TON to the original sender.
        nativeReserve(max(tonBalanceBeforeMsg, minTonsForStorage), ReserveAtMost);
        if (msg.responseDestination != null && msgValue > 0) {
            send(SendParameters{
                to: msg.responseDestination!!,
                value: msgValue,
                bounce: false,
                mode: SendRemainingBalance | SendIgnoreErrors,
                body: Excesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }
    
    // Jetton burning
    receive(msg: Burn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Incorrect sender");
        require(msg.amount > 0, "Amount should be positive");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        let fwdFee: Int = ctx.readForwardFee();
        require(ctx.value > fwdFee + 2 * getComputeFee(gasForBurn, false), "Insufficient amount of TON attached");

        send(SendParameters{
            to: self.master,
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                sender: self.owner,
                responseDestination: msg.responseDestination
            }.toCell()
        });
    }
    
    // Handle returns
    bounced(src: bounced<TokenTransferInternal>) {
        self.balance += src.amount;
    }
    
    bounced(src: bounced<TokenBurnNotification>) {
        self.balance += src.amount;
    }
    
    // === Get methods === //
    
    // Get wallet data
    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: initOf PRMDJettonWallet(self.master, myAddress()).code
        };
    }
}


trait JettonRewards {
    abstract fun getJettonRewardsStats(): JettonRewardsStats;
    abstract fun setJettonRewardsStats(stats: JettonRewardsStats): Bool;
    abstract fun sendJetton(address: Address, amount: Int): Bool;

    // By design: all emission accumulated since the last mint goes entirely to
    // the sender of the current buy (it is not distributed proportionally to the
    // contribution size). This is an intentional activity incentive, not a bug.
    virtual fun mintJetton(): Int {
        let stats = self.getJettonRewardsStats();
        let jettonsToMint: Int = 0;
        if (now() > stats.lastMintTime && stats.totalMinted < MAX_SUPPLY) {
            jettonsToMint = (now() - stats.lastMintTime) * EMISSION_RATE;
            stats.lastMintTime = now();
            if (stats.totalMinted + jettonsToMint > MAX_SUPPLY) {
                jettonsToMint = MAX_SUPPLY - stats.totalMinted;
            }
            stats.totalMinted += jettonsToMint;
        }
        self.setJettonRewardsStats(stats);
        return jettonsToMint;
    }
}
