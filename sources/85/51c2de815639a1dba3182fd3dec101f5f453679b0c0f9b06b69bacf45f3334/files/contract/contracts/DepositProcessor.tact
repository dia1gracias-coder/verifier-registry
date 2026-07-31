import "@stdlib/ownable";

// ─────────────────────────────────────────────────────────────────────────────
// TEP-74 / TEP-89 messages
// ─────────────────────────────────────────────────────────────────────────────

// Sent by this contract's Jetton wallet after receiving Jettons.
message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

// Sent by this contract to its own Jetton wallet when sweeping.
message(0x0f8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

// Sent back by the Jetton wallet with the unused TON after a transfer.
message(0xd53276db) JettonExcesses {
    queryId: Int as uint64;
}

// TEP-89 discovery: ask the Jetton master for a wallet address.
message(0x2c76b973) ProvideWalletAddress {
    queryId: Int as uint64;
    ownerAddress: Address;
    includeAddress: Bool;
}

// TEP-89 discovery: the Jetton master's reply.
message(0xd1735400) TakeWalletAddress {
    queryId: Int as uint64;
    walletAddress: Address;
    ownerAddress: Cell?;
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner messages
// ─────────────────────────────────────────────────────────────────────────────

message DiscoverJettonWallet {
    queryId: Int as uint64;
}

message SetJettonWalletAddress {
    jettonWalletAddress: Address;
}

message UpdateSystemAddress {
    newSystemAddress: Address;
}

message SetPaused {
    paused: Bool;
}

message SweepJettons {
    queryId: Int as uint64;
    amount: Int as coins;

    // TON attached to the Jetton transfer operation.
    // Owner must supply this TON in the incoming transaction.
    transferTonAmount: Int as coins;
}

// Withdraw surplus TON (not Jettons) held by this contract.
// `amount == 0` means "withdraw everything above the storage reserve".
message WithdrawTon {
    amount: Int as coins;
}

// Step 1 of 2. Nominates a new owner; nothing changes until they accept.
message TransferOwnership {
    newOwner: Address;
}

// Step 2 of 2. Must be sent by the nominated owner.
message AcceptOwnership {
}

// Cancels a pending nomination.
message CancelOwnershipTransfer {
}

// Permanently gives up control. See RENOUNCE_CONFIRMATION.
message RenounceOwnership {
    confirmation: Int as uint32;
}

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

message DepositReceivedEvent {
    queryId: Int as uint64;
    from: Address;
    amount: Int as coins;
}

message JettonsSweepRequestedEvent {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
}

message JettonWalletConfiguredEvent {
    jettonWalletAddress: Address;
}

message SystemAddressUpdatedEvent {
    oldAddress: Address;
    newAddress: Address;
}

message PauseStatusUpdatedEvent {
    paused: Bool;
}

message SweepBouncedEvent {
    queryId: Int as uint64;
}

message OwnershipTransferStartedEvent {
    currentOwner: Address;
    pendingOwner: Address;
}

message OwnershipTransferredEvent {
    oldOwner: Address;
    newOwner: Address;
}

message OwnershipRenouncedEvent {
    oldOwner: Address;
}

// ─────────────────────────────────────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────────────────────────────────────

const MIN_TON_RESERVE: Int = ton("0.05");
const SWEEP_GAS_HEADROOM: Int = ton("0.02");
const DISCOVERY_TON: Int = ton("0.05");

// ASCII "RENO". Renouncing is irreversible and bricks every admin function,
// so it cannot be triggered by an accidental empty message.
const RENOUNCE_CONFIRMATION: Int = 0x52454e4f;

contract DepositProcessor with Ownable {
    owner: Address;

    // Nominated next owner. Ownership moves only once they accept.
    pendingOwner: Address?;

    // Once true, every owner-only function is permanently disabled.
    renounced: Bool;

    // Address that ultimately receives the collected Jettons.
    systemAddress: Address;

    // The Jetton this processor accepts (the "token" in ERC-20 terms).
    jettonMaster: Address;

    // This contract's own Jetton wallet.
    //
    // It is configured after deployment because:
    // 1. The Jetton wallet address depends on this contract's address.
    // 2. This contract's address depends on its initial state.
    jettonWalletAddress: Address?;

    // Start paused until the correct Jetton wallet has been configured.
    paused: Bool;

    // Lets the same owner deploy several independent processors.
    nonce: Int as uint64;

    // `owner` and `nonce` are init params so that the contract address is
    // bound to the owner. Otherwise anyone could pre-deploy the same address
    // for a given systemAddress and claim ownership of it.
    init(owner: Address, systemAddress: Address, jettonMaster: Address, nonce: Int) {
        require(
            systemAddress != myAddress(),
            "DepositProcessor: invalid system address"
        );

        self.owner = owner;
        self.pendingOwner = null;
        self.renounced = false;
        self.systemAddress = systemAddress;
        self.jettonMaster = jettonMaster;
        self.jettonWalletAddress = null;
        self.paused = true;
        self.nonce = nonce;
    }

    // Owner check that also respects renouncement.
    fun requireActiveOwner() {
        require(!self.renounced, "DepositProcessor: ownership renounced");
        self.requireOwner();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Deploy / plain TON top-up
    // ─────────────────────────────────────────────────────────────────────────

    // Empty body: used for deployment and for topping the contract up with TON.
    receive() {}

    // Text comments (e.g. a top-up from a wallet UI) are accepted and ignored.
    receive(msg: String) {}

    // ─────────────────────────────────────────────────────────────────────────
    // Deposit notification
    // ─────────────────────────────────────────────────────────────────────────

    receive(msg: JettonTransferNotification) {
        require(!self.paused, "DepositProcessor: paused");

        let configuredWallet: Address? = self.jettonWalletAddress;

        require(
            configuredWallet != null,
            "DepositProcessor: Jetton wallet not configured"
        );

        require(
            sender() == configuredWallet!!,
            "DepositProcessor: unauthorized Jetton wallet"
        );

        require(
            msg.amount > 0,
            "DepositProcessor: invalid amount"
        );

        // Important:
        // This event means Jettons reached this contract's Jetton wallet.
        // It does not mean they have already reached systemAddress.
        emit(
            DepositReceivedEvent {
                queryId: msg.queryId,
                from: msg.sender,
                amount: msg.amount
            }.toCell()
        );
    }

    // Unused TON returned by our Jetton wallet after a sweep. Just keep it.
    receive(msg: JettonExcesses) {}

    // ─────────────────────────────────────────────────────────────────────────
    // Configure Jetton wallet
    // ─────────────────────────────────────────────────────────────────────────

    // Preferred path: ask the Jetton master itself (TEP-89), so a typo in an
    // owner-supplied address cannot brick the contract.
    receive(msg: DiscoverJettonWallet) {
        self.requireActiveOwner();

        require(
            self.jettonWalletAddress == null,
            "DepositProcessor: Jetton wallet already configured"
        );

        require(
            context().value >= DISCOVERY_TON + SWEEP_GAS_HEADROOM,
            "DepositProcessor: insufficient attached TON"
        );

        send(
            SendParameters {
                to: self.jettonMaster,
                value: DISCOVERY_TON,
                bounce: true,
                mode: SendDefaultMode,
                body: ProvideWalletAddress {
                    queryId: msg.queryId,
                    ownerAddress: myAddress(),
                    includeAddress: false
                }.toCell()
            }
        );
    }

    // The Jetton master's reply. Only the configured master is trusted.
    receive(msg: TakeWalletAddress) {
        require(
            sender() == self.jettonMaster,
            "DepositProcessor: unauthorized Jetton master"
        );

        require(
            self.jettonWalletAddress == null,
            "DepositProcessor: Jetton wallet already configured"
        );

        require(
            msg.walletAddress != myAddress(),
            "DepositProcessor: invalid Jetton wallet"
        );

        self.jettonWalletAddress = msg.walletAddress;

        emit(
            JettonWalletConfiguredEvent {
                jettonWalletAddress: msg.walletAddress
            }.toCell()
        );
    }

    // Fallback path, for Jetton masters that do not implement TEP-89.
    receive(msg: SetJettonWalletAddress) {
        self.requireActiveOwner();

        require(
            self.jettonWalletAddress == null,
            "DepositProcessor: Jetton wallet already configured"
        );

        require(
            msg.jettonWalletAddress != myAddress(),
            "DepositProcessor: invalid Jetton wallet"
        );

        require(
            msg.jettonWalletAddress != self.systemAddress,
            "DepositProcessor: invalid Jetton wallet"
        );

        self.jettonWalletAddress = msg.jettonWalletAddress;

        emit(
            JettonWalletConfiguredEvent {
                jettonWalletAddress: msg.jettonWalletAddress
            }.toCell()
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Sweep collected Jettons
    // ─────────────────────────────────────────────────────────────────────────

    receive(msg: SweepJettons) {
        self.requireActiveOwner();

        let configuredWallet: Address? = self.jettonWalletAddress;

        require(
            configuredWallet != null,
            "DepositProcessor: Jetton wallet not configured"
        );

        require(
            msg.amount > 0,
            "DepositProcessor: invalid sweep amount"
        );

        require(
            msg.transferTonAmount > 0,
            "DepositProcessor: invalid transfer TON amount"
        );

        // Require the owner to provide the TON needed for this operation.
        // The extra amount leaves room for this contract's own computation.
        require(
            context().value >= msg.transferTonAmount + SWEEP_GAS_HEADROOM,
            "DepositProcessor: insufficient attached TON"
        );

        send(
            SendParameters {
                to: configuredWallet!!,
                value: msg.transferTonAmount,
                bounce: true,
                mode: SendDefaultMode,
                body: JettonTransfer {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    destination: self.systemAddress,

                    // Return remaining TON to this contract, not to a depositor.
                    responseDestination: myAddress(),

                    customPayload: null,

                    // Collector does not need a transfer notification here.
                    forwardTonAmount: 0,

                    // Do not forward arbitrary depositor-controlled payload.
                    forwardPayload: beginCell().endCell().asSlice()
                }.toCell()
            }
        );

        // This event only records that the sweep was requested.
        // Backend should confirm that systemAddress actually received Jettons.
        emit(
            JettonsSweepRequestedEvent {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: self.systemAddress
            }.toCell()
        );
    }

    // The Jetton wallet rejected the transfer (e.g. insufficient balance).
    // Swallow the bounce so the TON stays here, and surface it as an event.
    bounced(msg: bounced<JettonTransfer>) {
        emit(
            SweepBouncedEvent {
                queryId: msg.queryId
            }.toCell()
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Administrative functions
    // ─────────────────────────────────────────────────────────────────────────

    receive(msg: UpdateSystemAddress) {
        self.requireActiveOwner();

        require(
            msg.newSystemAddress != myAddress(),
            "DepositProcessor: invalid system address"
        );

        let configuredWallet: Address? = self.jettonWalletAddress;

        if (configuredWallet != null) {
            require(
                msg.newSystemAddress != configuredWallet!!,
                "DepositProcessor: invalid system address"
            );
        }

        require(
            msg.newSystemAddress != self.systemAddress,
            "DepositProcessor: system address unchanged"
        );

        let oldAddress: Address = self.systemAddress;
        self.systemAddress = msg.newSystemAddress;

        emit(
            SystemAddressUpdatedEvent {
                oldAddress: oldAddress,
                newAddress: msg.newSystemAddress
            }.toCell()
        );
    }

    receive(msg: SetPaused) {
        self.requireActiveOwner();

        require(
            msg.paused != self.paused,
            "DepositProcessor: pause status unchanged"
        );

        // Cannot unpause before the Jetton wallet is configured.
        if (!msg.paused) {
            require(
                self.jettonWalletAddress != null,
                "DepositProcessor: Jetton wallet not configured"
            );
        }

        self.paused = msg.paused;

        emit(
            PauseStatusUpdatedEvent {
                paused: msg.paused
            }.toCell()
        );
    }

    // Recover TON accidentally sent here, or left over after sweeps.
    // Jettons are never withdrawable this way - they can only go to
    // systemAddress via SweepJettons.
    receive(msg: WithdrawTon) {
        self.requireActiveOwner();

        let balance: Int = myBalance() - context().value;
        let available: Int = balance - MIN_TON_RESERVE;

        require(available > 0, "DepositProcessor: nothing to withdraw");

        let amount: Int = msg.amount;
        if (amount == 0) {
            amount = available;
        }

        require(amount <= available, "DepositProcessor: amount exceeds available");

        send(
            SendParameters {
                to: self.owner,
                value: amount,
                bounce: false,
                mode: SendPayGasSeparately
            }
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Ownership
    // ─────────────────────────────────────────────────────────────────────────

    // Two-step on purpose. A single-step transfer to a mistyped address would
    // hand the contract (and every future sweep) to nobody, permanently.
    receive(msg: TransferOwnership) {
        self.requireActiveOwner();

        require(
            msg.newOwner != self.owner,
            "DepositProcessor: already the owner"
        );

        require(
            msg.newOwner != myAddress(),
            "DepositProcessor: invalid new owner"
        );

        self.pendingOwner = msg.newOwner;

        emit(
            OwnershipTransferStartedEvent {
                currentOwner: self.owner,
                pendingOwner: msg.newOwner
            }.toCell()
        );
    }

    receive(msg: AcceptOwnership) {
        require(!self.renounced, "DepositProcessor: ownership renounced");

        let nominee: Address? = self.pendingOwner;

        require(nominee != null, "DepositProcessor: no pending owner");
        require(sender() == nominee!!, "DepositProcessor: not the pending owner");

        let oldOwner: Address = self.owner;
        self.owner = nominee!!;
        self.pendingOwner = null;

        emit(
            OwnershipTransferredEvent {
                oldOwner: oldOwner,
                newOwner: self.owner
            }.toCell()
        );
    }

    receive(msg: CancelOwnershipTransfer) {
        self.requireActiveOwner();

        require(
            self.pendingOwner != null,
            "DepositProcessor: no pending owner"
        );

        self.pendingOwner = null;
    }

    // Irreversible. After this nobody can sweep, pause, or reconfigure
    // anything, so any Jettons that arrive later are stuck forever.
    //
    // Guarded three ways: the contract must be paused (so no new deposits can
    // land), there must be no pending transfer, and `confirmation` must equal
    // RENOUNCE_CONFIRMATION (0x52454e4f).
    receive(msg: RenounceOwnership) {
        self.requireActiveOwner();

        require(
            msg.confirmation == RENOUNCE_CONFIRMATION,
            "DepositProcessor: wrong renounce confirmation"
        );

        require(
            self.paused,
            "DepositProcessor: pause before renouncing"
        );

        require(
            self.pendingOwner == null,
            "DepositProcessor: pending transfer exists"
        );

        let oldOwner: Address = self.owner;
        self.renounced = true;

        emit(
            OwnershipRenouncedEvent {
                oldOwner: oldOwner
            }.toCell()
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Getters
    // ─────────────────────────────────────────────────────────────────────────

    get fun systemAddress(): Address {
        return self.systemAddress;
    }

    // The Jetton this processor accepts. Named `token` to match the usual
    // ERC-20-style naming.
    get fun token(): Address {
        return self.jettonMaster;
    }

    get fun jettonWalletAddress(): Address? {
        return self.jettonWalletAddress;
    }

    get fun pendingOwner(): Address? {
        return self.pendingOwner;
    }

    get fun renounced(): Bool {
        return self.renounced;
    }

    get fun paused(): Bool {
        return self.paused;
    }

    get fun nonce(): Int {
        return self.nonce;
    }

    get fun balance(): Int {
        return myBalance();
    }
}
