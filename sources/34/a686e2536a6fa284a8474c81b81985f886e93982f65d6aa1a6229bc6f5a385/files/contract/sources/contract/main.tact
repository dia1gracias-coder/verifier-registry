import "@stdlib/deploy";
import "@stdlib/ownable";

struct Operation {
    date: Int;
    amount: Int as coins;
    transId: String;
    query_id: Int as uint64;
    forward_ton_amount: Int as coins;
}
message Claim {
    operation: Operation;
    signature: Slice as bytes64;
    tokenIndex: Int as int8;
    forward_payload: Slice as remaining;
}
message UpdatePublicKey {
    publicKey: Int;
}
message UpdateJettonWalletAddress {
    tokenIndex: Int as int8;
    address: Address;
}
message UpdateOwnerAddress {
    address: Address;
}
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}
contract ClaimJetton with Deployable {
    owner: Address;
    const MinTonForStorage: Int = ton("0.1");
    transIds: map<Int, Bool>;
    publicKey: Int as uint256;
    tokenIndexToJettonWalletAddress: map<Int as int8, Address>;

    init(owner: Address, publicKey: Int) {
        self.owner = owner;
        self.publicKey = publicKey;
    }

    receive() {}

    receive(msg: UpdateOwnerAddress) {
        require(sender() == self.owner, "Not owner");
        self.owner = msg.address;
        self.reply("Owner updated".asComment());
    }

    receive(msg: UpdateJettonWalletAddress) {
        require(sender() == self.owner, "Only deployer can update JettonWallet address");
        self.tokenIndexToJettonWalletAddress.set(msg.tokenIndex, msg.address);
        self.reply("Jetton_Wallet address has update".asComment());
    }

    receive(msg: UpdatePublicKey) {
        require(sender() == self.owner, "Only deployer can update public key");
        self.publicKey = msg.publicKey;
        self.reply("Public key has update".asComment());
    }

    receive("withdrawTONSafe"){
        let withdrawValue: Int = ((myBalance() - context().value) - self.MinTonForStorage);
        require(sender() == self.owner && withdrawValue > 0, "Only deployer is allowed to withdraw");
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: withdrawValue,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }

    receive(msg: Claim){
        let sender: Address = sender();
        let op: Operation = msg.operation;

        let isTrans: Bool = self._existsTransId(op.transId);
        require(isTrans == false, "Exists transId");

        let fizz: StringBuilder = beginString();
        fizz.append("claim:");
        fizz.append(op.date.toCoinsString());
        fizz.append(":");
        fizz.append(op.amount.toCoinsString());
        fizz.append(":");
        fizz.append(op.transId);
        let fizzStr: String = fizz.toString();
        let op_hash: Int = sha256(fizzStr);
        let isOk: Bool = checkSignature(op_hash, msg.signature, self.publicKey);
        require(isOk, "Signature is invalid");

        let jettonWalletAddress: Address? = self.tokenIndexToJettonWalletAddress.get(msg.tokenIndex);
        require(jettonWalletAddress != null, "No this token");

        self._setTransId(op.transId);
        send(SendParameters{
            to: jettonWalletAddress!!,
            value: 0,
            mode: SendRemainingValue, 
            bounce: true,
            body: TokenTransfer{
                query_id: op.query_id,
                amount: op.amount,
                destination: sender,
                response_destination: sender,
                custom_payload: null,
                forward_ton_amount: op.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
        });
    }

    fun _existsTransId(transId: String): Bool {
        let shaInt: Int = sha256(transId);
        let isIn: Bool? = self.transIds.get(shaInt);
        if (isIn == true) {
            return true;
        } else {
            return false;
        }
    }

    fun _setTransId(transId: String) {
        let shaInt: Int = sha256(transId);
        self.transIds.set(shaInt, true);
    }

    get fun existsTransId (transId: String): Bool {
        return self._existsTransId(transId);
    }

    get fun getPublicKey (): Int {
        return self.publicKey;
    }

    get fun getJettonWalletAddress (tokenIndex: Int): Bool {
        let jettonWalletAddress: Address? = self.tokenIndexToJettonWalletAddress.get(tokenIndex);
        if (jettonWalletAddress != null) {
            return true;
        } else {
            return false;
        }
    }

    get fun getOwnerAddress (): Address {
        return self.owner;
    }
}
