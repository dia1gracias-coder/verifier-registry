import "@stdlib/deploy";
import "@stdlib/ownable";
import "./reentrancyGuard";
import "./superOperator";

struct Operation {
    date: Int;
    amount: Int as coins;
    transId: String;
}
message Claim {
    operation: Operation;
    signature: Slice as bytes64;
    signdata: String;
    query_id: Int as uint64;
}
message Reward {
    amount: Int;
    receiver: Address;
    transId: String?;
    date: Int?;
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

contract ClaimUXUYContract with Deployable, Ownable, ReentrancyGuard, SuperOperator {
    owner: Address;
    reentrancyGuardStatus: Int;
    const MinTonForStorage: Int = ton("0.1");
    status: Bool;
    userCheckInEntries: map<Int, Bool>;
    transIds: map<Int, Bool>;
    superOperators: map<Address, Bool>;
    jettonMasterAddress: Address;
    publicKey: Int as uint256; // public key as an 256-bit unsigned Int

    init(owner: Address, publicKey: Int, jettonMasterAddress: Address) {
        self.owner = owner;
        self.reentrancyGuardStatus = self._NOT_ENTERED;
        self.status = true;
        self.superOperators.set(owner, true);
        self.publicKey = publicKey; // storing the public key upon contract initialization
        self.jettonMasterAddress = jettonMasterAddress;
    }

    // accept incoming TON transfers
    receive() {}

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

    receive("withdrawAllTON"){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{to: self.owner, bounce: true, value: 0, mode: (SendRemainingBalance + SendIgnoreErrors)});
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
        require(self.status, "check-in status is false");
        let isClaim: Bool = self._haveClaim(sender, op.date);
        require(isClaim == false, "Already Checked In!");
        let isTrans: Bool = self._existsTransId(op.transId);
        require(isTrans == false, "Exists transId");
        // let op_hash: Int = beginCell().storeRef(msg.operation.toCell()).endCell().hash(); //msg.operation.toCell().hash();
        let op_hash: Int = sha256(msg.signdata);
        // let op_hash: Int = beginCell().storeRef(msg.signdata.asSlice().asCell()).endCell().hash();
        let isOk: Bool = checkSignature(op_hash, msg.signature, self.publicKey);
        require(isOk, "Signature is invalid");
        self._setTransId(op.transId);
        self._setCheckIn(sender, op.date);
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

    fun _haveClaim(user: Address, date: Int): Bool {
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

    fun _setCheckIn(user: Address, date: Int) {
        let sb: StringBuilder = beginString();
        sb.append(user.toString());
        sb.append(date.toString());
        let shaInt: Int = sha256(sb.toString());
        self.userCheckInEntries.set(shaInt, true);
    }

    fun _removeCheckIn(user: Address, date: Int) {
        let sb: StringBuilder = beginString();
        sb.append(user.toString());
        sb.append(date.toString());
        let shaInt: Int = sha256(sb.toString());
        self.userCheckInEntries.set(shaInt, null);
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

    fun _removeTransId(transId: String) {
        let shaInt: Int = sha256(transId);
        self.transIds.set(shaInt, null);
    }

    get fun haveClaim (user: Address, date: Int): Bool {
        return self._haveClaim(user, date);
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
}