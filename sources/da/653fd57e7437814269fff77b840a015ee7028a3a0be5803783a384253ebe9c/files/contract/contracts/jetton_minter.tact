import "./messages.tact";
import "./constants.tact";
import "./jetton_wallet.tact";

/// TEP-74 compliant JettonMinter (master contract) — V2.
/// Deployed by JettonFactory. Admin is the user's wallet — platform has zero control.
///
/// Feature flags (all immutable after deploy):
///   mintable  — owner can mint additional tokens up to maxSupply
///   burnable  — any holder can burn their own tokens
///   pausable  — owner can pause/resume ALL transfers globally
///   freezable — owner can freeze/unfreeze specific wallet addresses
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

    // ─── Freeze / Unfreeze a wallet (owner only, only if freezable) ───────────
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

    // ─── Bounce handler ───────────────────────────────────────────────────────
    bounced(src: bounced<TokenTransferInternal>) {
        self.totalSupply -= src.amount;
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────
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
