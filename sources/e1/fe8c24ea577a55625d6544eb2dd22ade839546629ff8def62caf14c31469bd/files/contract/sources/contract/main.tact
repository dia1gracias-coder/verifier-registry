import "@stdlib/deploy";
import "@stdlib/ownable";
struct Operation {
    date: Int;
    transId: String;
    amount: Int as coins;
    query_id: Int as uint64;
}
message CheckIn {
    operation: Operation;
    signature: Slice as bytes64;
}
message UpdatePublicKey {
    publicKey: Int;
}
message UpdateSalt {
    newSalt: String;
}
message UpdateOwnerAddress {
    address: Address;
}
contract CheckInContract with Deployable {
    owner: Address;
    const MinTonForStorage: Int = ton("0.1");
    transIds: map<Int, Bool>;
    userCheckInEntries: map<Int, Bool>;
    publicKey: Int as uint256;
    salt: String;
    init(owner: Address, publicKey: Int, salt: String) {
        self.owner = owner;
        self.publicKey = publicKey;
        self.salt = salt;
    }
    receive() {}
    receive(msg: UpdateOwnerAddress) {
        require(sender() == self.owner, "Not owner");
        self.owner = msg.address;
        self.reply("Owner updated".asComment());
    }
    receive(msg: UpdatePublicKey) {
        require(sender() == self.owner, "Not owner");
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
        require(sender() == self.owner && withdrawValue > 0, "Not owner");
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: withdrawValue,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }
    receive(msg: CheckIn){
        let sender: Address = sender();
        let op: Operation = msg.operation;
        let isTrans: Bool = self._existsTransId(op.transId);
        require(isTrans == false, "Exists transId");
        let isCheckIn: Bool = self._haveCheckIn(sender, op.date);
        require(isCheckIn == false, "Already Checked In!");
        let fizz: StringBuilder = beginString();
        fizz.append("ton:checkin:");
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
        self._setCheckIn(sender, op.date);
        self.reply("Check-in successful".asComment());
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
    fun _setCheckIn(user: Address, date: Int) {
        let sb: StringBuilder = beginString();
        sb.append(user.toString());
        sb.append(date.toString());
        let shaInt: Int = sha256(sb.toString());
        self.userCheckInEntries.set(shaInt, true);
    }
    fun _haveCheckIn(user: Address, date: Int): Bool {
        let sb: StringBuilder = beginString();
        sb.append(user.toString());
        sb.append(date.toString());
        let shaInt: Int = sha256(sb.toString());
        let IsIn: Bool? = self.userCheckInEntries.get(shaInt);
        if (IsIn == true) {
            return true;
        } else {
            return false;
        }
    }
    get fun existsTransId (transId: String): Bool {
        return self._existsTransId(transId);
    }
    get fun userIsCheckIn (user: Address, date: Int): Bool {
        return self._haveCheckIn(user, date);
    }
    get fun getPublicKey (): Int {
        return self.publicKey;
    }
    get fun getOwnerAddress (): Address {
        return self.owner;
    }
}
