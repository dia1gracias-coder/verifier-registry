import "@stdlib/deploy";

struct ContractData {
    publicKey: Int as uint256;
    owner: Address;
    jettonMasterAddress: Address;
}
struct Operation {
    date: Int;
    amount: Int as coins;
    transId: String;
}
message Claim {
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
message SafeTransfer {
    query_id: Int as uint64;
    amount: Int;
    receiver: Address;
}
message UpdateOwnerAddress {
    address: Address;
}

contract ClaimUXUYContract with Deployable {
    owner: Address;
    transIds: map<Int, Bool>;
    jettonMasterAddress: Address;
    publicKey: Int as uint256;
    init(owner: Address, publicKey: Int, jettonMasterAddress: Address) {
        self.owner = owner;
        self.publicKey = publicKey;
        self.jettonMasterAddress = jettonMasterAddress;
    }
    receive() {}
    receive(msg: UpdateOwnerAddress) {
        require(sender() == self.owner, "Not the owner");
        self.owner = msg.address;
        self.reply("Owner updated".asComment());
    }
    receive(msg: UpdateUXUYContractAddress) {
        require(sender() == self.owner, "Not the owner");
        self.jettonMasterAddress = msg.address;
        self.reply("UXUY address has update".asComment());
    }
    receive(msg: UpdatePublicKey) {
        require(sender() == self.owner, "Not the owner");
        self.publicKey = msg.publicKey;
        self.reply("Public key has update".asComment());
    }
    receive("clearTransIds"){
        require(sender() == self.owner, "Not the owner");
        self.transIds = emptyMap();
    }
    receive("withdrawAllTON"){
        require(sender() == self.owner, "Not the owner");
        send(SendParameters{to: self.owner, bounce: true, value: 0, mode: (SendRemainingBalance + SendIgnoreErrors)});
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
        let shaInt: Int = sha256(op.transId);
        self.transIds.set(shaInt, true);
        send(SendParameters{
            to: self.jettonMasterAddress,
            value: 0,
            mode: SendRemainingValue, 
            bounce: true,
            body: SafeTransfer{
                query_id: msg.query_id,
                amount: op.amount,
                receiver: sender,
            }.toCell(),
        });
        emit("SafeTransfer".asComment());
    }
    bounced(msg: bounced<SafeTransfer>){
        self.reply("SafeTransfer fail".asComment());
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
    get fun existsTransId (transId: String): Bool {
        return self._existsTransId(transId);
    }
    get fun getContractData (): ContractData {
        return ContractData{
            publicKey: self.publicKey,
            owner: self.owner,
            jettonMasterAddress: self.jettonMasterAddress,
        };
    }
}