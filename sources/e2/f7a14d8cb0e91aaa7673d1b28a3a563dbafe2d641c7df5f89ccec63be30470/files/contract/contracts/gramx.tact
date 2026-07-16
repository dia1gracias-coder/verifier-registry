import "@stdlib/ownable";

// One-time fixed-supply initialization.
// This is not a reusable mint function: it can succeed only once.
message InitializeFixedSupply {
    queryId: Int as uint64;
}

message ProposeOwner {
    newOwner: Address;
}

message AcceptOwner {}

contract GramxToken with Jetton {
    totalSupply: Int as coins;
    owner: Address;
    pendingOwner: Address?;
    content: Cell;
    mintable: Bool;

    fixedSupply: Int as coins;
    initialReceiver: Address;
    initialized: Bool;

    init(
        owner: Address,
        content: Cell,
        fixedSupply: Int,
        initialReceiver: Address
    ) {
        require(fixedSupply > 0, "Fixed supply must be positive");

        self.totalSupply = 0;
        self.owner = owner;
        self.pendingOwner = null;
        self.content = content;
        self.mintable = false;

        self.fixedSupply = fixedSupply;
        self.initialReceiver = initialReceiver;
        self.initialized = false;
    }

    // Creates the complete fixed supply exactly once.
    // No receiver or amount can be changed by the caller.
    receive(msg: InitializeFixedSupply) {
        let ctx: Context = context();

        require(ctx.sender == self.owner, "Not Owner");
        require(!self.initialized, "Supply already initialized");
        require(self.totalSupply == 0, "Invalid total supply");

        self.initialized = true;
        self.totalSupply = self.fixedSupply;

        let walletInit: StateInit =
            self.getJettonWalletInit(self.initialReceiver);

        send(SendParameters {
            to: contractAddress(walletInit),
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransferInternal {
                queryId: msg.queryId,
                amount: self.fixedSupply,
                from: myAddress(),
                response_destination: self.owner,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: walletInit.code,
            data: walletInit.data
        });
    }

    // Two-step ownership transfer prevents accidental transfer
    // to a wrong or inaccessible address.
    receive(msg: ProposeOwner) {
        let ctx: Context = context();

        require(ctx.sender == self.owner, "Not Owner");
        require(msg.newOwner != self.owner, "Already owner");

        self.pendingOwner = msg.newOwner;
    }

    receive(msg: AcceptOwner) {
        let ctx: Context = context();

        require(self.pendingOwner != null, "No pending owner");
        require(ctx.sender == self.pendingOwner!!, "Not pending owner");

        self.owner = ctx.sender;
        self.pendingOwner = null;
    }

    // If the one-time supply delivery fails, restore the
    // uninitialized state so the owner can retry safely.
    bounced(src: bounced<TokenTransferInternal>) {
        require(self.initialized, "Unexpected bounce");
        require(src.amount == self.fixedSupply, "Invalid bounced supply");

        self.totalSupply = 0;
        self.initialized = false;
    }
}

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

struct FixedSupplyData {
    fixedSupply: Int;
    initialReceiver: Address;
    initialized: Bool;
    pendingOwner: Address?;
}

@interface("org.ton.jetton.master")
trait Jetton with Ownable {
    totalSupply: Int;
    owner: Address;
    pendingOwner: Address?;
    content: Cell;
    mintable: Bool;

    fixedSupply: Int;
    initialReceiver: Address;
    initialized: Bool;

    // Metadata is intentionally immutable.
    // There is no TokenUpdateContent receiver.

    receive(msg: TokenBurnNotification) {
        require(msg.amount > 0, "Amount must be positive");
        self.requireWallet(msg.owner);
        require(self.totalSupply >= msg.amount, "Invalid burn amount");

        self.totalSupply -= msg.amount;

        if (msg.response_destination != null) {
            send(SendParameters {
                to: msg.response_destination!!,
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses {
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    fun requireWallet(walletOwner: Address) {
        let ctx: Context = context();
        let walletInit: StateInit =
            self.getJettonWalletInit(walletOwner);

        require(
            contractAddress(walletInit) == ctx.sender,
            "Invalid wallet"
        );
    }

    virtual fun getJettonWalletInit(
        walletOwner: Address
    ): StateInit {
        return initOf JettonDefaultWallet(
            myAddress(),
            walletOwner
        );
    }

    get fun get_jetton_data(): JettonData {
        let walletCode: Cell =
            self.getJettonWalletInit(myAddress()).code;

        return JettonData {
            totalSupply: self.totalSupply,
            mintable: false,
            owner: self.owner,
            content: self.content,
            walletCode: walletCode
        };
    }

    get fun get_wallet_address(
        walletOwner: Address
    ): Address {
        let walletInit: StateInit =
            self.getJettonWalletInit(walletOwner);

        return contractAddress(walletInit);
    }

    get fun get_fixed_supply_data(): FixedSupplyData {
        return FixedSupplyData {
            fixedSupply: self.fixedSupply,
            initialReceiver: self.initialReceiver,
            initialized: self.initialized,
            pendingOwner: self.pendingOwner
        };
    }
}

@interface("org.ton.jetton.wallet")
contract JettonDefaultWallet {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int as coins;
    owner: Address;
    master: Address;

    init(master: Address, owner: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
    }

    receive(msg: TokenTransfer) {
        let ctx: Context = context();

        require(ctx.sender == self.owner, "Invalid sender");
        require(msg.amount > 0, "Amount must be positive");
        require(
            self.balance >= msg.amount,
            "Insufficient jetton balance"
        );

        let forwardFee: Int = ctx.readForwardFee();

        // Covers storage, wallet execution, recipient execution,
        // requested TON forwarding, and estimated forwarding fees.
        let requiredValue: Int =
            self.storageTopUp(ctx.value) +
            (2 * self.gasConsumption) +
            msg.forward_ton_amount +
            (2 * forwardFee);

        require(
            ctx.value >= requiredValue,
            "Insufficient TON for transfer"
        );

        self.balance -= msg.amount;

        let walletInit: StateInit =
            initOf JettonDefaultWallet(
                self.master,
                msg.destination
            );

        send(SendParameters {
            to: contractAddress(walletInit),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenTransferInternal {
                queryId: msg.queryId,
                amount: msg.amount,
                from: self.owner,
                response_destination:
                    msg.response_destination,
                forward_ton_amount:
                    msg.forward_ton_amount,
                forward_payload:
                    msg.forward_payload
            }.toCell(),
            code: walletInit.code,
            data: walletInit.data
        });
    }

    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();

        require(msg.amount > 0, "Amount must be positive");

        if (ctx.sender != self.master) {
            let senderWalletInit: StateInit =
                initOf JettonDefaultWallet(
                    self.master,
                    msg.from
                );

            require(
                contractAddress(senderWalletInit) ==
                    ctx.sender,
                "Invalid sender"
            );
        }

        self.balance += msg.amount;

        let availableValue: Int =
            self.availableValue(ctx.value);
        let forwardFee: Int = ctx.readForwardFee();

        require(
            availableValue >=
                msg.forward_ton_amount + forwardFee,
            "Insufficient forwarded value"
        );

        let excessValue: Int =
            availableValue -
            msg.forward_ton_amount -
            forwardFee;

        // TEP-74 notification delivery is best-effort.
        // IgnoreErrors is intentional so a recipient contract
        // cannot block or revert receipt of Jettons.
        if (msg.forward_ton_amount > 0) {
            send(SendParameters {
                to: self.owner,
                value: msg.forward_ton_amount,
                mode:
                    SendPayGasSeparately +
                    SendIgnoreErrors,
                bounce: false,
                body: TokenNotification {
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload:
                        msg.forward_payload
                }.toCell()
            });
        }

        if (excessValue > 0) {
            send(SendParameters {
                to: msg.response_destination,
                value: excessValue,
                bounce: false,
                mode: SendIgnoreErrors,
                body: TokenExcesses {
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();

        require(ctx.sender == self.owner, "Invalid sender");
        require(msg.amount > 0, "Amount must be positive");
        require(
            self.balance >= msg.amount,
            "Insufficient jetton balance"
        );

        let forwardFee: Int = ctx.readForwardFee();
        let requiredValue: Int =
            self.storageTopUp(ctx.value) +
            (2 * self.gasConsumption) +
            forwardFee;

        require(
            ctx.value >= requiredValue,
            "Insufficient TON for burn"
        );

        self.balance -= msg.amount;

        send(SendParameters {
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification {
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination:
                    msg.response_destination
            }.toCell()
        });
    }

    fun storageTopUp(messageValue: Int): Int {
        let balanceBeforeMessage: Int =
            myBalance() - messageValue;

        return
            self.minTonsForStorage -
            min(
                balanceBeforeMessage,
                self.minTonsForStorage
            );
    }

    fun availableValue(messageValue: Int): Int {
        return
            messageValue -
            self.storageTopUp(messageValue) -
            self.gasConsumption;
    }

    bounced(src: bounced<TokenTransferInternal>) {
        require(src.amount > 0, "Invalid bounced amount");
        self.balance += src.amount;
    }

    bounced(src: bounced<TokenBurnNotification>) {
        require(src.amount > 0, "Invalid bounced amount");
        self.balance += src.amount;
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData {
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode:
                (initOf JettonDefaultWallet(
                    self.master,
                    self.owner
                )).code
        };
    }
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;

    // Retained for TEP-74 wire compatibility.
    // It is not interpreted by the Jetton wallet.
    custom_payload: Cell?;

    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    response_destination: Address;

    // Retained for TEP-74 wire compatibility.
    custom_payload: Cell?;
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address?;
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;
}
