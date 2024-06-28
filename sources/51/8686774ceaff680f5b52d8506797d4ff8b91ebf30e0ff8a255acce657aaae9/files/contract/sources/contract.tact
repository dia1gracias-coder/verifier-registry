import "@stdlib/deploy";
import "@stdlib/ownable";
message SignedMessage {
    data: Cell;
    signature: Cell;
}
message SweepMessage {
}
message ChangeJettonMaster {
    jettonMaster: Address;
}
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

contract MessageVerifier with Deployable, Ownable {
    owner: Address;
    publicKey: Int as uint256;
    jettonMaster: Address;
    jettonBalance: Int as coins;
    processedSignatures: map<Int, Bool>; // Store processed signature hashes

    init(publicKey: Int, jettonMaster: Address){
        self.owner = sender();
        self.publicKey = publicKey;
        self.jettonBalance = 0;
        self.jettonMaster = jettonMaster;
    }

    receive(msg: TokenNotification){
        let jettonAddress: Address = sender();
        require(jettonAddress == self.jettonMaster, "Invalid jetton address");
        self.jettonBalance = self.jettonBalance + msg.amount;
    }

    receive(msg: SweepMessage){
        self.requireOwner();
        self.sweep();
    }

    receive(msg: ChangeJettonMaster){
        self.requireOwner();
        self.jettonMaster = msg.jettonMaster;
    }

    receive(msg: SignedMessage){
        let ctx: Context = context();
        let dataSlice: Slice = msg.data.beginParse();
        let signatureSlice: Slice = msg.signature.beginParse();
        require(checkDataSignature(dataSlice, signatureSlice, self.publicKey), "Invalid signature");
        // require(sender() == dataSlice.loadAddress(), "Invalid sender");
        let amount: Int = dataSlice.loadCoins();
        require(amount > 0, "Invalid amount");
        require(amount <= self.jettonBalance, "Insufficient jetton balance");
        let signatureHash: Int = sha256(signatureSlice);
        let exists: Bool? = self.processedSignatures.get(signatureHash);
        require(exists == null, "Signature already processed");
        self.processedSignatures.set(signatureHash, true);
        self.sendJetton(amount, sender());
    }

    fun sendJetton(amount: Int, destination: Address) {
        self.jettonBalance = (self.jettonBalance - amount);
        send(SendParameters{
                to: self.jettonMaster,
                value: 0,
                mode: SendRemainingValue,
                body: TokenTransfer{
                    queryId: 0,
                    amount: amount,
                    destination: destination,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardTonAmount: ton("0.01"),
                    forwardPayload: emptySlice()
                }.toCell()
            }
        );
    }

    fun sweep() {
        self.requireOwner();
        require(self.jettonBalance > 0, "No jettons to sweep");
        send(SendParameters{
                to: self.jettonMaster,
                value: 0,
                mode: 64, // Sending all remaining value
                body: TokenTransfer{
                    queryId: 0,
                    amount: self.jettonBalance,
                    destination: self.owner,
                    responseDestination: myAddress(),
                    customPayload: null,
                    forwardTonAmount: 0,
                    forwardPayload: emptySlice()
                }.toCell()
            }
        );
        self.jettonBalance = 0;
    }

    get fun getIsSignatureProcessed(signatureHash: Int): Bool {
        let exists: Bool? = self.processedSignatures.get(signatureHash);
        return exists == true;
    }

    get fun getPublicKey(): Int {
        return self.publicKey;
    }

    get fun getJettonBalance(): Int {
        return self.jettonBalance;
    }

    get fun getJettonMaster(): Address {
        return self.jettonMaster;
    }
}