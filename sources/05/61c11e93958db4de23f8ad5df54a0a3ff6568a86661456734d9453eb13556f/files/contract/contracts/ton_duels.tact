// TON Duels project. Written with love by ButterDevelop

message(0x123456) Init {

}

message Deposit {
    userId:      Int as uint32;
    paymentType: Int as uint8;
}

message WithdrawUser {
    to:        Address;
    amount:    Int as coins;
    nonce:     Int as uint64;
    signature: Slice;
}

message WithdrawAdmin {
    to:        Address;
    amount:    Int as coins;
    nonce:     Int as uint64;
    signature: Slice;
}

message SetServerKey {
    newKey:    Int as uint256;
    nonce:     Int as uint64;
    signature: Slice;
}

message SetAdminKey {
    newKey:    Int as uint256;
    nonce:     Int as uint64;
    signature: Slice;
}

message TransferEvent {
    recipient: Address;
    amount:    Int as coins;
}


fun doTransfer(to: Address, amount: Int) {
    require(myBalance() >= amount, "Insufficient balance");

    let gas = gasConsumed() * 3; // so as not to go into the red

    send(SendParameters {
        to:     to,
        bounce: true,
        value:  amount - gas,
        mode:   SendDefaultMode
    });

    // Emit event for off-chain things and debugging
    emit(TransferEvent { recipient: to, amount: amount - gas }.toCell());
 }

contract TonDuels {
    // public key of the server signing user requests (ED25519)
    serverKey:  Int as uint256;
    // public key of the administrator signing admin payments
    adminKey:   Int as uint256;
    // user nonces stores the last used nonce for each recipient address
    userNonces: map<Address, Int as uint64>;
    // different nonce for admin operations
    adminNonce: Int as uint64;
    // nonce for vanity address generation
    vanityAddressNonce: Int as uint64;

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
    init(serverPub: Int as uint256, adminPub: Int as uint256, vanityAddressNonce: Int as uint64) {
        self.serverKey          = serverPub;
        self.adminKey           = adminPub;
        self.vanityAddressNonce = vanityAddressNonce;
        self.userNonces         = emptyMap();
        self.adminNonce         = 0;
    }

    receive(msg: Init) {
        
    }

    // Deposit function: accepts TON, simply stores them in the contract
    receive(msg: Deposit) {
        send(SendParameters {
            to:     sender(),
            bounce: true,
            value:  0,
            mode:   SendPayFwdFeesSeparately,
            body:   "Successful deposit $$$".asComment()
        });

        // Emit event for off-chain things and debugging
        emit(msg.toCell());
    }

    // Withdrawal of funds to the user based on a server-signed request
    external(msg: WithdrawUser) {
        // Assembling a cell with fields {to, amount, nonce}
        let data = beginCell()
            .storeAddress(msg.to)
            .storeUint(msg.amount, 128)
            .storeUint(msg.nonce,   64)
            .endCell();

        self.signatureAuthCheck(data, msg.signature, self.serverKey, msg.nonce, msg.to, false);

        // We accept commission for gas and send funds
        acceptMessage();

        doTransfer(msg.to, msg.amount);
    }

    // Admin's conclusion of the commission on the request signed by the admin
    external(msg: WithdrawAdmin) {
        // We collect a cell with fields {to, amount}
        let data = beginCell()
            .storeAddress(msg.to)
            .storeUint(msg.amount, 128)
            .storeUint(msg.nonce,  64)
            .endCell();

        self.signatureAuthCheck(data, msg.signature, self.adminKey, msg.nonce, null, true);

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
}