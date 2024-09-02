import "@stdlib/deploy";
import "@stdlib/ownable";

struct Operation {
    date: Int;
    amount: Int as coins;
    transId: String;
}
message RewardUXUY {
    operation: Operation;
    signature: Slice as bytes64;
    query_id: Int as uint64;
}
message UpdatePublicKey {
    publicKey: Int;
}
message UpdateUXUYContractAddress {
    address: Address;
}
message Reward {
    amount: Int;
    receiver: Address;
    transId: String?;
    date: Int?;
}
message UpdateOwnerAddress {
    address: Address;
}
message UpdateSalt {
    newSalt: String;
}
contract RewardUXUYContract with Deployable {
    owner: Address;
    const MinTonForStorage: Int = ton("0.1");
    transIds: map<Int, Bool>;
    jettonMasterAddress: Address;
    publicKey: Int as uint256; // public key as an 256-bit unsigned Int
    salt: String;
    init(owner: Address, publicKey: Int, jettonMasterAddress: Address, salt: String) {
        self.owner = owner;
        self.publicKey = publicKey; // storing the public key upon contract initialization
        self.jettonMasterAddress = jettonMasterAddress;
        self.salt = salt;
    }
    receive() {}
    receive(msg: UpdateOwnerAddress) {
        require(sender() == self.owner, "Not owner");
        self.owner = msg.address;
        self.reply("Owner updated".asComment());
    }
    receive(msg: UpdateUXUYContractAddress) {
        require(sender() == self.owner, "Only deployer can update public key");
        self.jettonMasterAddress = msg.address;
        self.reply("UXUY address has update".asComment());
    }
    receive(msg: UpdatePublicKey) {
        require(sender() == self.owner, "Only deployer can update public key");
        self.publicKey = msg.publicKey;
        self.reply("Public key has update".asComment());
    }
    receive(msg: UpdateSalt) {
        require(sender() == self.owner, "Not owner");
        self.salt = msg.newSalt;
        self.reply("Salt updated".asComment());
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
    receive(msg: RewardUXUY){
        let sender: Address = sender();
        let op: Operation = msg.operation;
        let isTrans: Bool = self._existsTransId(op.transId);
        require(isTrans == false, "Exists transId");
        let fizz: StringBuilder = beginString();
        fizz.append("uxuymint:");
        fizz.append(op.date.toCoinsString());
        fizz.append(":");
        fizz.append(op.amount.toCoinsString());
        fizz.append(":");
        fizz.append(op.transId);
        fizz.append(":");
        fizz.append(self.salt);
        let fizzStr: String = fizz.toString();
        let op_hash: Int = sha256(fizzStr);
        let isOk: Bool = checkSignature(op_hash, msg.signature, self.publicKey);
        require(isOk, "Signature is invalid");
        self._setTransId(op.transId);
        send(SendParameters{
            to: self.jettonMasterAddress,
            value: 0,
            mode: SendRemainingValue, 
            bounce: true,
            body: Reward{
                receiver: sender,
                amount: op.amount,
                transId: null,
                date: null,
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
    get fun getUXUYContractAddress (): Address {
        return self.jettonMasterAddress;
    }
    get fun getOwnerAddress (): Address {
        return self.owner;
    }
}