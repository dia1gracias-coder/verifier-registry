import "@stdlib/deploy";
import "@stdlib/ownable";

// internal messages
message Buy {
    seller: Address;
    amount: Int as uint32;
    price: Int as uint256;
    nonce: Int as uint32;
}
message Cancel {
    amount: Int as uint32;
    price: Int as uint256;
    nonce: Int as uint32;
}
message Fee {
    sellPerc: Int;
    msg: Int;
    inscribe: Int;
}

// contract
contract Inshrimption with Deployable, OwnableTransferable {
    currSeqno: Int;
    owner: Address;
    used: map<Int, Int>;
    sellFeePerc: Int = 500;
    msgFee: Int = 100000000;
    inscribeFee: Int = 10000000;

    init(initSeqno: Int){
        self.currSeqno = initSeqno;
        self.owner = sender();
    }

    receive("Withdraw"){
        self.requireOwner();
        send(SendParameters{to: self.owner, value: myBalance(), mode: (SendRemainingBalance + SendIgnoreErrors)});
    }

    receive("Withdraw10"){
        self.requireOwner();
        send(SendParameters{to: self.owner, value: ton("10"), mode: (SendPayGasSeparately + SendIgnoreErrors)});
    }

    receive("Withdraw100"){
        self.requireOwner();
        send(SendParameters{to: self.owner, value: ton("100"), mode: (SendPayGasSeparately + SendIgnoreErrors)});
    }

    receive("Withdraw1000"){
        self.requireOwner();
        send(SendParameters{to: self.owner, value: ton("1000"), mode: (SendPayGasSeparately + SendIgnoreErrors)});
    }

    receive(msg: String){
        require(context().value >= self.inscribeFee, "Inscription fee is not enough");
    }

    receive(){
        require(context().value >= self.inscribeFee, "no dust allowed");
    }

    receive(msg: Buy){
        // step 1: check if sent value is too low
        require(context().value >= (msg.price + self.msgFee), "Message fee is not enough");
        // step 2: check if order is expired or canceled
        let recordKey: Int = self.getKey(msg.seller, msg.amount, msg.price, msg.nonce);
        require(self.used.get(recordKey) == null, "Order is expired or canceled");
        // step 3: check if send value is valid
        let sendValue: Int = msg.price * (10000 - self.sellFeePerc) / 10000;
        require(sendValue > 0, "Price after fee deduction is too low");
        // step 4: set record and send money
        self.used.set(recordKey, 0);
        send(SendParameters{to: msg.seller, bounce: true, value: sendValue, mode: SendPayGasSeparately});
    }

    receive(msg: Cancel){
        let recordKey: Int = self.getKey(sender(), msg.amount, msg.price, msg.nonce);
        self.used.set(recordKey, 0);
    }

    receive(msg: Fee){
        self.requireOwner();
        self.sellFeePerc = msg.sellPerc;
        self.msgFee = msg.msg;
        self.inscribeFee = msg.inscribe;
    }

     fun getKey(address: Address, amount: Int, price: Int, nonce: Int): Int {
        let addrHash: Int = beginCell().storeAddress(address).endCell().hash();
        let stringBuilder: StringBuilder = beginString();
        stringBuilder.append(addrHash.toString());
        stringBuilder.append(amount.toString());
        stringBuilder.append(price.toString());
        stringBuilder.append(nonce.toString());
        return sha256(stringBuilder.toString());
    }

    get fun sellFeePerc(): Int {
        return self.sellFeePerc;
    }

    get fun msgFee(): Int {
        return self.msgFee;
    }

    get fun inscribeFee(): Int {
        return self.inscribeFee;
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun contractSeqno(): Int {
        return self.currSeqno;
    }
}