import "@stdlib/ownable";

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
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
    owner: Address;
    response_destination: Address?;
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

message TokenUpdateContent {
    content: Cell;
}

message Mint {
    amount: Int;
    receiver: Address;
}

contract TaxableJetton with Ownable {
    totalSupply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    taxPercentage: Int as uint8;
    taxAddress: Address;
    
    // Provenance: Cryptographic signature to prevent impersonation
    // The contract's address is tied to this signature.
    const platformPublicKey: Int = 0x3f02d39af28baceb9892802ba9c13ebf1fad151bbc31d67590f2c0a193136815;

    init(owner: Address, content: Cell, taxPercentage: Int, taxAddress: Address, signature: Slice) {
        // Verify that this deployment was authorized by Wenmoon
        // We sign a hash of (owner, content, taxPercentage, taxAddress)
        let hash: Int = beginCell()
            .storeAddress(owner)
            .storeRef(content)
            .storeInt(taxPercentage, 257)
            .storeAddress(taxAddress)
            .endCell()
            .hash();
        
        require(checkSignature(hash, signature, self.platformPublicKey), "Invalid Platform Signature");

        self.totalSupply = 0;
        self.owner = owner;
        self.content = content;
        self.mintable = true;
        self.taxPercentage = taxPercentage;
        self.taxAddress = taxAddress;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not Owner");
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.receiver, msg.amount, self.owner);
        self.mintable = false; // Disable further minting
    }

    fun mint(to: Address, amount: Int, response_destination: Address) {
        self.totalSupply = self.totalSupply + amount;
        let winit: StateInit = self.getJettonWalletInit(to);
        send(SendParameters{
            to: contractAddress(winit),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{
                queryId: 0,
                amount: amount,
                from: myAddress(),
                response_destination: response_destination,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    get fun get_jetton_data(): JettonData {
        return JettonData{
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            owner: self.owner,
            content: self.content,
            walletCode: (initOf TaxableJettonWallet(myAddress(), self.owner, self.taxPercentage, self.taxAddress)).code
        };
    }

    get fun get_wallet_address(owner: Address): Address {
        return contractAddress(self.getJettonWalletInit(owner));
    }

    fun getJettonWalletInit(address: Address): StateInit {
        return initOf TaxableJettonWallet(myAddress(), address, self.taxPercentage, self.taxAddress);
    }
}

contract TaxableJettonWallet {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");

    balance: Int as coins;
    owner: Address;
    master: Address;
    taxPercentage: Int as uint8;
    taxAddress: Address;

    init(master: Address, owner: Address, taxPercentage: Int, taxAddress: Address) {
        self.balance = 0;
        self.owner = owner;
        self.master = master;
        self.taxPercentage = taxPercentage;
        self.taxAddress = taxAddress;
    }

    receive(msg: TokenTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        let taxAmount: Int = (msg.amount * self.taxPercentage) / 100;
        let amountToSend: Int = msg.amount - taxAmount;

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        let recipientInit: StateInit = initOf TaxableJettonWallet(self.master, msg.destination, self.taxPercentage, self.taxAddress);
        let treasuryInit: StateInit = initOf TaxableJettonWallet(self.master, self.taxAddress, self.taxPercentage, self.taxAddress);

        // Send to recipient
        send(SendParameters{
            to: contractAddress(recipientInit),
            value: ton("0.05"),
            mode: SendPayGasSeparately,
            bounce: false,
            body: TokenTransferInternal{
                queryId: msg.queryId,
                amount: amountToSend,
                from: self.owner,
                response_destination: msg.response_destination,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
            code: recipientInit.code,
            data: recipientInit.data
        });

        // Send to treasury
        if (taxAmount > 0) {
            send(SendParameters{
                to: contractAddress(treasuryInit),
                value: ton("0.05"),
                mode: SendPayGasSeparately,
                bounce: false,
                body: TokenTransferInternal{
                    queryId: msg.queryId,
                    amount: taxAmount,
                    from: self.owner,
                    response_destination: msg.response_destination,
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: treasuryInit.code,
                data: treasuryInit.data
            });
        }
    }

    receive(msg: TokenTransferInternal) {
        let ctx: Context = context();
        if (ctx.sender != self.master) {
            let sinit: StateInit = initOf TaxableJettonWallet(self.master, msg.from, self.taxPercentage, self.taxAddress);
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!");
        }

        self.balance = self.balance + msg.amount;

        if (msg.forward_ton_amount > 0) {
            send(SendParameters{
                to: self.owner,
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: TokenNotification{
                    queryId: msg.queryId,
                    amount: msg.amount,
                    from: msg.from,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: TokenExcesses{queryId: msg.queryId}.toCell()
            });
        }
    }

    receive(msg: TokenBurn) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        self.balance = self.balance - msg.amount;
        require(self.balance >= 0, "Insufficient balance");

        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenBurnNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    get fun get_wallet_data(): JettonWalletData {
        return JettonWalletData{
            balance: self.balance,
            owner: self.owner,
            master: self.master,
            walletCode: (initOf TaxableJettonWallet(self.master, self.owner, self.taxPercentage, self.taxAddress)).code
        };
    }
}

struct JettonData {
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    walletCode: Cell;
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}
