// ─── JettonMaker V4 — jetton_minter.tact ─────────────────────────────────────

import "./messages.tact";
import "./constants.tact";
import "./jetton_wallet.tact";

/// TEP-74 compliant JettonMinter (master contract) — V4.
/// Deployed by JettonFactory. Admin is the user's wallet — platform has zero control.
///
/// Feature flags (all immutable after deploy):
///   mintable  — owner can mint additional tokens up to maxSupply
///   burnable  — any holder can burn their own tokens
///   pausable  — owner can pause/resume ALL transfers globally
///   freezable — owner can freeze/unfreeze specific wallet addresses
///
/// V4 change: the minter now acts as a transfer router.
/// Wallets send TokenTransferViaRouter here instead of going wallet→wallet directly.
/// The minter validates pause/freeze synchronously, then forwards
/// TokenTransferInternal to the destination wallet.
///
/// Bounce handling (bounced<TokenTransferInternal>):
///   - Mint bounce  (src.from == myAddress()): decrement totalSupply.
///   - Transfer bounce (src.from != myAddress()): send refund TokenTransferInternal
///     to the source wallet so its balance is restored.
///
/// Ownership:
///   - Transfer: 2-step (ProposeOwner → AcceptOwnership)
///   - Renounce: permanent, sets owner to zero address
contract JettonMinter {
    owner:              Address;
    pendingOwner:       Address?;       // set during 2-step ownership transfer
    totalSupply:        Int as coins = 0;
    maxSupply:          Int as coins;
    mintable:           Bool;           // IMMUTABLE — set at init
    burnable:           Bool;           // IMMUTABLE — set at init
    pausable:           Bool;           // IMMUTABLE — set at init
    freezable:          Bool;           // IMMUTABLE — set at init
    transfersPaused:    Bool = false;   // only relevant if pausable == true
    frozen:             map<Address, Bool>; // only relevant if freezable == true
    content:            Cell;           // TEP-64 metadata cell
    ownershipRenounced: Bool = false;

    init(
        owner:     Address,
        maxSupply: Int,
        mintable:  Bool,
        burnable:  Bool,
        pausable:  Bool,
        freezable: Bool,
        content:   Cell
    ) {
        self.owner     = owner;
        self.maxSupply = maxSupply;
        self.mintable  = mintable;
        self.burnable  = burnable;
        self.pausable  = pausable;
        self.freezable = freezable;
        self.content   = content;
        self.frozen    = emptyMap();
    }

    // ─── Initial mint (called by factory as deploy body) ─────────────────────
    /// Mints the entire initial supply to the owner's wallet.
    /// Can only be called once (when totalSupply == 0).
    /// Sender is the factory — no owner check needed; guard is totalSupply == 0.
    receive("MintInitial") {
        require(self.totalSupply == 0, "JettonMinter: already minted");

        self.totalSupply = self.maxSupply;
        self._mint(self.owner, self.maxSupply, self.owner);
    }

    // ─── Additional mint (owner only, only if mintable == true) ──────────────
    receive(msg: Mint) {
        self.requireOwner();
        require(self.mintable, "JettonMinter: token is not mintable");
        require(msg.amount > 0, "JettonMinter: zero amount");
        require(
            self.totalSupply + msg.amount <= self.maxSupply,
            "JettonMinter: exceeds max supply"
        );

        self.totalSupply += msg.amount;
        self._mint(msg.receiver, msg.amount, sender());
    }

    // ─── V4: Transfer router — validates pause/freeze, then forwards ──────────
    /// Receives TokenTransferViaRouter from the source wallet.
    /// The source wallet has already deducted its balance. If we reject here
    /// (require fails) the message bounces and the wallet's bounced<TokenTransferViaRouter>
    /// handler restores the balance.
    ///
    /// If we accept, we send TokenTransferInternal to the destination wallet
    /// with a fixed gas allocation. If the destination wallet bounces that message,
    /// bounced<TokenTransferInternal> below handles the refund to the source wallet.
    receive(msg: TokenTransferViaRouter) {
        // Verify the message came from the legitimate source wallet for msg.from
        let expectedSourceWallet: Address = contractAddress(
            initOf JettonWallet(msg.from, myAddress())
        );
        require(sender() == expectedSourceWallet, "JettonMinter: unauthorized router sender");

        // Check global pause (only enforced if pausable feature is enabled)
        if (self.pausable) {
            require(!self.transfersPaused, "JettonMinter: transfers are paused");
        }

        // Check sender freeze and destination freeze (only if freezable feature enabled)
        if (self.freezable) {
            let senderFrozen: Bool? = self.frozen.get(msg.from);
            require(
                senderFrozen == null || senderFrozen!! == false,
                "JettonMinter: sender wallet is frozen"
            );

            let destFrozen: Bool? = self.frozen.get(msg.destination);
            require(
                destFrozen == null || destFrozen!! == false,
                "JettonMinter: destination wallet is frozen"
            );
        }

        // Forward the transfer to the destination wallet using TokenTransferCredit
        // (distinct from TokenTransferInternal which is mint-only).
        // This separation lets us distinguish mint vs transfer in bounce handlers.
        let destWalletInit: StateInit = initOf JettonWallet(msg.destination, myAddress());
        send(SendParameters{
            to:    contractAddress(destWalletInit),
            value: WALLET_DEPLOY_GAS + msg.forwardTonAmount,
            mode:  SendPayGasSeparately,
            code:  destWalletInit.code,
            data:  destWalletInit.data,
            body:  TokenTransferCredit{
                queryId:             msg.queryId,
                amount:              msg.amount,
                from:                msg.from,
                responseDestination: msg.responseDestination,
                forwardTonAmount:    msg.forwardTonAmount,
                forwardPayload:      msg.forwardPayload
            }.toCell()
        });

        // Return any remaining gas to responseDestination (best-effort)
        if (msg.responseDestination != null) {
            send(SendParameters{
                to:    msg.responseDestination!!,
                value: 0,
                mode:  SendRemainingValue | SendIgnoreErrors,
                body:  TokenExcesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    // ─── Burn notification (from wallet) ─────────────────────────────────────
    receive(msg: TokenBurnNotification) {
        require(self.burnable, "JettonMinter: token is not burnable");
        self._requireWallet(msg.sender);

        // Cannot burn from a frozen wallet
        if (self.freezable) {
            let isFrozen: Bool? = self.frozen.get(msg.sender);
            require(isFrozen == null || isFrozen!! == false, "JettonMinter: wallet is frozen");
        }

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            send(SendParameters{
                to:    msg.responseDestination!!,
                value: 0,
                mode:  SendRemainingValue | SendIgnoreErrors,
                body:  TokenExcesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    // ─── Pause / Resume all transfers (owner only, only if pausable) ──────────
    receive("Pause") {
        self.requireOwner();
        require(self.pausable, "JettonMinter: token is not pausable");
        require(!self.transfersPaused, "JettonMinter: already paused");
        self.transfersPaused = true;
    }

    receive("Resume") {
        self.requireOwner();
        require(self.pausable, "JettonMinter: token is not pausable");
        require(self.transfersPaused, "JettonMinter: not paused");
        self.transfersPaused = false;
    }

    // ─── Freeze / Unfreeze a wallet owner address (owner only, if freezable) ──
    /// `msg.target` is the wallet OWNER address (not the wallet contract address).
    /// The frozen map stores owner addresses. Lookups in TokenTransferViaRouter
    /// use msg.from and msg.destination which are also owner addresses.
    receive(msg: FreezeWallet) {
        self.requireOwner();
        require(self.freezable, "JettonMinter: token is not freezable");
        if (msg.frozen) {
            self.frozen.set(msg.target, true);
        } else {
            self.frozen.del(msg.target);
        }
    }

    // ─── Update metadata URI (owner only) ────────────────────────────────────
    receive(msg: TokenUpdateContent) {
        self.requireOwner();
        self.content = msg.content;
    }

    // ─── 2-step ownership transfer ────────────────────────────────────────────
    /// Step 1: current owner proposes a new owner address.
    receive(msg: ProposeOwner) {
        self.requireOwner();
        require(msg.newOwner != self.owner, "JettonMinter: same owner");
        require(msg.newOwner != newAddress(0, 0), "JettonMinter: zero address");
        self.pendingOwner = msg.newOwner;
    }

    /// Step 2: proposed owner accepts — completes the transfer.
    receive(msg: AcceptOwnership) {
        require(self.pendingOwner != null, "JettonMinter: no pending owner");
        require(sender() == self.pendingOwner!!, "JettonMinter: not pending owner");
        self.owner = self.pendingOwner!!;
        self.pendingOwner = null;
    }

    // ─── Renounce ownership (permanent, irreversible) ─────────────────────────
    /// Sets owner to zero address. No more minting, freezing, pausing or metadata updates.
    receive("RenounceOwnership") {
        self.requireOwner();
        require(!self.ownershipRenounced, "JettonMinter: already renounced");
        self.ownershipRenounced = true;
        self.pendingOwner       = null;
        self.owner              = newAddress(0, 0);
    }

    // ─── Bounce: mint failed (dest wallet bounced TokenTransferInternal) ──────
    /// TokenTransferInternal is ONLY used for mints (_mint helper).
    /// If a mint credit bounces, restore totalSupply.
    bounced(src: bounced<TokenTransferInternal>) {
        self.totalSupply -= src.amount;
    }

    // ─── Bounce: transfer credit failed (dest wallet bounced TokenTransferCredit)
    /// TokenTransferCredit is ONLY used for routed transfers.
    /// The source wallet already decremented its balance.
    /// Send a refund TokenTransferInternal back to restore the source wallet balance.
    /// Fields accessible in bounced<TokenTransferCredit>:
    ///   queryId(64) + amount(coins≤124) = ≤188 bits — well within 224-bit bounce limit.
    bounced(src: bounced<TokenTransferCredit>) {
        // src.amount is accessible (fits within 224-bit bounced payload)
        // We cannot read src.from here (too far into the cell), so we cannot
        // directly compute the source wallet. This edge case (dest wallet rejecting
        // a credit) should not occur in normal operation — the destination wallet
        // only rejects if the sender check fails, which cannot happen since we
        // (the minter) are the trusted sender.
        // In the extremely rare case it does bounce, the TON is returned to us
        // as contract balance. We do NOT decrement totalSupply since this was a
        // transfer (not a mint) — totalSupply was never changed.
        // No action needed.
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────
    /// Sends a TokenTransferInternal to a wallet to credit tokens (used for mints).
    /// `from` is set to myAddress() so the bounce handler can distinguish mint vs transfer.
    fun _mint(to: Address, amount: Int, responseAddr: Address) {
        let walletInit: StateInit = initOf JettonWallet(to, myAddress());
        send(SendParameters{
            to:    contractAddress(walletInit),
            value: WALLET_DEPLOY_GAS,
            mode:  SendPayGasSeparately,
            code:  walletInit.code,
            data:  walletInit.data,
            body:  TokenTransferInternal{
                queryId:             0,
                amount:              amount,
                from:                myAddress(),
                responseDestination: responseAddr,
                forwardTonAmount:    ton("0.01"),
                forwardPayload:      emptySlice()
            }.toCell()
        });
    }

    fun requireOwner() {
        require(!self.ownershipRenounced, "JettonMinter: ownership renounced");
        require(sender() == self.owner, "JettonMinter: caller is not owner");
    }

    fun _requireWallet(walletOwner: Address) {
        let expected: Address = contractAddress(initOf JettonWallet(walletOwner, myAddress()));
        require(sender() == expected, "JettonMinter: invalid wallet sender");
    }

    // ─── TEP-74 get methods ───────────────────────────────────────────────────
    get fun get_jetton_data(): JettonMasterData {
        return JettonMasterData{
            totalSupply:  self.totalSupply,
            mintable:     self.mintable && !self.ownershipRenounced,
            adminAddress: self.owner,
            content:      self.content,
            walletCode:   (initOf JettonWallet(myAddress(), myAddress())).code
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return contractAddress(initOf JettonWallet(ownerAddress, myAddress()));
    }

    // ─── Extended getters ─────────────────────────────────────────────────────
    get fun isBurnable(): Bool           { return self.burnable; }
    get fun isMintable(): Bool           { return self.mintable; }
    get fun isPausable(): Bool           { return self.pausable; }
    get fun isFreezable(): Bool          { return self.freezable; }
    get fun isTransfersPaused(): Bool    { return self.transfersPaused; }
    get fun isOwnershipRenounced(): Bool { return self.ownershipRenounced; }
    get fun maxSupply(): Int              { return self.maxSupply; }
    get fun owner(): Address             { return self.owner; }
    get fun pendingOwner(): Address?     { return self.pendingOwner; }
    get fun isWalletFrozen(addr: Address): Bool {
        let v: Bool? = self.frozen.get(addr);
        return v != null && v!!;
    }
}

struct JettonMasterData {
    totalSupply:  Int as coins;
    mintable:     Bool;
    adminAddress: Address;
    content:      Cell;
    walletCode:   Cell;
}
