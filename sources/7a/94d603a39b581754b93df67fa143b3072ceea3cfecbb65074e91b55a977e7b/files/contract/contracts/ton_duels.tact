// TON Duels project. Written with love by TON Duels Team

const OP_INIT:             Int = 0x01234567;
const OP_DEPOSIT:          Int = 0xD3205170;
const OP_WITHDRAW_USER:    Int = 0xA11ECAFE;
const OP_WITHDRAW_ADMIN:   Int = 0xB22EAD00;
const OP_SET_SERVER_KEY:   Int = 0x51343543;
const OP_SET_ADMIN_KEY:    Int = 0xADADFACE;
const OP_SET_ABLE_DEPOSIT: Int = 0xAB13D320;
const OP_TRANSFER_EVENT:   Int = 0xAA39BD10;

// We describe a set of opcodes as a single structure
struct MsgOpcodes {
    init:             Int;
    deposit:          Int;
    withdrawUser:     Int;
    withdrawAdmin:    Int;
    setServerKey:     Int;
    setAdminKey:      Int;
    setAbleToDeposit: Int;
    transferEvent:    Int;
}

message(OP_INIT) Init {

}

message(OP_DEPOSIT) Deposit {
    userId:      Int as uint32;
    paymentType: Int as uint8;
}

message(OP_WITHDRAW_USER) WithdrawUser {
    withdrawalId: Int as uint32;
    to:           Address;
    amount:       Int as coins;
    nonce:        Int as uint64;
    signature:    Slice;
}

message(OP_WITHDRAW_ADMIN) WithdrawAdmin {
    withdrawalId: Int as uint32;
    to:           Address;
    amount:       Int as coins;
    nonce:        Int as uint64;
    signature:    Slice;
}

message(OP_SET_SERVER_KEY) SetServerKey {
    newKey:    Int as uint256;
    nonce:     Int as uint64;
    signature: Slice;
}

message(OP_SET_ADMIN_KEY) SetAdminKey {
    newKey:    Int as uint256;
    nonce:     Int as uint64;
    signature: Slice;
}

message(OP_SET_ABLE_DEPOSIT) SetAbleToDeposit {
    ableToDeposit: Bool;
    nonce:         Int as uint64;
    signature:     Slice;
}

message(OP_TRANSFER_EVENT) TransferEvent {
    recipient: Address;
    amount:    Int as coins;
}


const MIN_COMMISSION_AMOUNT: Int = ton("0.01");

fun doTransfer(to: Address, amount: Int) {
    let gas = MIN_COMMISSION_AMOUNT + (gasConsumed() * 2); // so as not to go into the red

    send(SendParameters {
        to:     to,
        bounce: true,
        value:  amount - gas,
        mode:   SendDefaultMode,
        body:   "TON Duels withdrawal! $$$".asComment()
    });

    // Emit event for off-chain things and debugging
    emit(TransferEvent { recipient: to, amount: amount - gas }.toCell());
}

contract TonDuels {
    // public key of the server signing user requests (ED25519)
    serverKey:     Int as uint256;
    // public key of the administrator signing admin payments
    adminKey:      Int as uint256;
    // user nonces stores the last used nonce for each recipient address
    userNonces:    map<Address, Int as uint64>;
    // different nonce for admin operations
    adminNonce:    Int as uint64;
    // ability to switch off or on deposits
    ableToDeposit: Bool;

    // Unified signature & nonce check
    fun signatureAuthCheck(
        data:      Cell,
        signature: Slice,
        key:       Int,
        nonce:     Int,
        addr:      Address?, // for user: recipient address; for admin: null
        isAdmin:   Bool
    ) {
        // Signature validation
        let hash = data.hash();
        require(checkSignature(hash, signature, key), "Invalid signature");

        if (isAdmin) {
            // Admin replay protection
            require(nonce == self.adminNonce + 1, "Invalid nonce");
            self.adminNonce = nonce;
        } else {
            // User replay protection
            let toAddr   = addr!!;
            let prevTemp = self.userNonces.get(toAddr);
            let prev     = prevTemp == null ? 0 : prevTemp!!;
            require(nonce == prev + 1, "Invalid nonce");
            self.userNonces.set(toAddr, nonce);
        }
    }

    // Constructor: set keys and initialize mapping
    init(serverPub: Int as uint256, adminPub: Int as uint256) {
        self.serverKey     = serverPub;
        self.adminKey      = adminPub;
        self.userNonces    = emptyMap();
        self.adminNonce    = 0;
        self.ableToDeposit = true;
    }

    receive(msg: Init) {
        
    }

    // Deposit function: accepts TON, simply stores them in the contract
    receive(msg: Deposit) {
        require(self.ableToDeposit, "Sorry, deposits are temporarily unavailable");

        send(SendParameters {
            to:     sender(),
            bounce: true,
            value:  0,
            mode:   SendPayFwdFeesSeparately,
            body:   "Successful TON Duels deposit! $$$".asComment()
        });

        // Emit event for off-chain things and debugging
        emit(msg.toCell());
    }

    // Withdrawal of funds to the user based on a server-signed request
    external(msg: WithdrawUser) {
        // Assembling a cell with fields {to, amount, nonce}
        let data = beginCell()
            .storeUint(msg.withdrawalId, 32)
            .storeAddress(msg.to)
            .storeCoins(msg.amount)
            .storeUint(msg.nonce, 64)
            .endCell();

        self.signatureAuthCheck(data, msg.signature, self.serverKey, msg.nonce, msg.to, false);

        require(myBalance() >= msg.amount, "Insufficient balance");

        // We accept commission for gas and send funds
        acceptMessage();

        doTransfer(msg.to, msg.amount);
    }

    // Admin's conclusion of the commission on the request signed by the admin
    external(msg: WithdrawAdmin) {
        // We collect a cell with fields {to, amount}
        let data = beginCell()
            .storeUint(msg.withdrawalId, 32)
            .storeAddress(msg.to)
            .storeCoins(msg.amount)
            .storeUint(msg.nonce, 64)
            .endCell();

        self.signatureAuthCheck(data, msg.signature, self.adminKey, msg.nonce, null, true);

        require(myBalance() >= msg.amount, "Insufficient balance");

        // We accept commission for gas and send funds
        acceptMessage();

        doTransfer(msg.to, msg.amount);
    }

    // Rotate serverKey; only admin can authorize via admin signature
    external(msg: SetServerKey) {
        let data = beginCell()
            .storeUint(msg.newKey, 256)
            .storeUint(msg.nonce,  64)
            .endCell();
        self.signatureAuthCheck(data, msg.signature, self.adminKey, msg.nonce, null, true);
        // We accept commission for gas and send funds
        acceptMessage();
        self.serverKey = msg.newKey;
    }

    // Rotate adminKey; only current admin can authorize via admin signature
    external(msg: SetAdminKey) {
        let data = beginCell()
            .storeUint(msg.newKey, 256)
            .storeUint(msg.nonce,  64)
            .endCell();
        self.signatureAuthCheck(data, msg.signature, self.adminKey, msg.nonce, null, true);
        // We accept commission for gas and send funds
        acceptMessage();
        self.adminKey = msg.newKey;
    }

    // Change ableToDeposit; only current admin can authorize via admin signature
    external(msg: SetAbleToDeposit) {
        let data = beginCell()
            .storeBool(msg.ableToDeposit)
            .storeUint(msg.nonce, 64)
            .endCell();
        self.signatureAuthCheck(data, msg.signature, self.adminKey, msg.nonce, null, true);
        // We accept commission for gas and send funds
        acceptMessage();
        self.ableToDeposit = msg.ableToDeposit;
    }


    /* GETTERS */

    // Public getter for serverKey
    get fun serverKey(): Int {
        return self.serverKey;
    }

    // Public getter for adminKey
    get fun adminKey(): Int {
        return self.adminKey;
    }

    // Public getter for a specific user's nonce
    get fun userNonce(addr: Address): Int {
        let nonceTemp = self.userNonces.get(addr);
        let nonce     = nonceTemp == null ? 0 : nonceTemp!!;
        return nonce;
    }

    // Public getter for adminNonce
    get fun adminNonce(): Int {
        return self.adminNonce;
    }

    // Public getter for contract's balance
    get fun balance(): Int {
        return myBalance();
    }

    // Public getter for ableToDeposit
    get fun ableToDeposit(): Bool {
        return self.ableToDeposit;
    }

    // Public getter for opcodes
    get fun opcodes(): MsgOpcodes {
        return MsgOpcodes {
            init:             Init.opcode(),
            deposit:          Deposit.opcode(),
            withdrawUser:     WithdrawUser.opcode(),
            withdrawAdmin:    WithdrawAdmin.opcode(),
            setServerKey:     SetServerKey.opcode(),
            setAdminKey:      SetAdminKey.opcode(),
            setAbleToDeposit: SetAbleToDeposit.opcode(),
            transferEvent:    TransferEvent.opcode(),
        };
    }
}