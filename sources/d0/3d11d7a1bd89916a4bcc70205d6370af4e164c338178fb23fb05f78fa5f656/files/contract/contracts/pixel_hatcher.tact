import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

/* INTERNAL MESSAGES */
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
message Settings {
    sellPerc: Int?;
    msg: Int?;
    inscribe: Int?;
    maxOrderLength: Int?;
}

/* MAIN CONTRACT PIXELHATCHER */
contract PixelHatcher with Deployable, OwnableTransferable, Resumable {
    seqno: Int; // CONTRACT SEQUENCE NUMBER (FOR DEPLOYABLE)
    owner: Address; // CONTRACT OWNER
    stopped: Bool; // CONTRACT STOPPED FLAG
    orderClosed: map<Int, Int>; // RECORDS OF RECENT CLOSED ORDERS
    orderHashList: map<Int, Int>; // RECORDS OF RECENT ORDERS IN ACSENDING ORDER
    orderHashListIndex: Int = 0; // LAST INDEX OF ORDERHASHLIST

    sellFeePerc: Int = 500; // 500 / 10000 = 5%
    msgFee: Int = 100000000; // 0.1 TON
    inscribeFee: Int = 10000000; // 0.01 TON
    maxOrderLength: Int = 5000; // MAXIMUM NUMBER OF ORDERS

    /* constructor */

    init(initSeqno: Int){
        self.seqno = initSeqno;
        self.owner = sender();
        self.stopped = false;
    }

    /* WITHDRAW FUNCTIONS FOR OWNER */

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

    /* inscription related handling */

    receive(msg: String){
        require(context().value >= self.inscribeFee, "Inscription fee is not enough");
    }

    receive(){
        require(context().value >= self.inscribeFee, "No dust allowed");
    }

    /* CONTRACT MESSAGE */

    receive(msg: Buy){
        self.requireNotStopped();

        // step 1: CHECK IF SENT VALUE IS TOO LOW
        require(context().value >= (msg.price + self.msgFee), "Message fee is not enough");

        // step 2: CHECK IF ORDER IS EXPIRED OR CANCELED
        let recordKey: Int = self.getKey(msg.seller, msg.amount, msg.price, msg.nonce);
        require(self.orderClosed.get(recordKey) == null, "Order is expired or canceled");

        // step 3: CHECK IF SEND VALUE IS VALID
        let sendValue: Int = msg.price * (10000 - self.sellFeePerc) / 10000;
        
        // step 4: SET RECORD AND SEND MONEY
        self.updateOrderRecords(recordKey, 1);
        send(SendParameters{to: msg.seller, bounce: true, value: sendValue, mode: SendPayGasSeparately});
    }

    receive(msg: Cancel){
        self.requireNotStopped();

        // STEP 1: CHECK IF SENT VALUE IS TOO LOW
        require(context().value >= self.msgFee, "Message fee is not enough");

        // STEP 2: CHECK IF ORDER IS EXPIRED OR CANCELED
        let recordKey: Int = self.getKey(sender(), msg.amount, msg.price, msg.nonce);
        self.updateOrderRecords(recordKey, 0);
    }

    receive(msg: Settings){
        self.requireOwner();
        if (msg.sellPerc != null) {
            self.sellFeePerc = msg.sellPerc!!;
        }
        if (msg.msg != null) {
            self.msgFee = msg.msg!!;
        }
        if (msg.inscribe != null) {
            self.inscribeFee = msg.inscribe!!;
        }
        if (msg.maxOrderLength != null) {
            self.maxOrderLength = msg.maxOrderLength!!;
        }
    }

     fun getKey(address: Address, amount: Int, price: Int, nonce: Int): Int {
        return beginCell().storeAddress(address).storeUint(amount, 256).storeUint(price, 256).storeUint(nonce,32).endCell().hash();
    }

     fun updateOrderRecords(recordKey: Int, type: Int) {
        // CIRCULAR BUFFER STYLE UPDATE
        self.orderHashListIndex = (self.orderHashListIndex + 1) % self.maxOrderLength;
        if (self.orderHashList.get(self.orderHashListIndex) != null) {
            let oldestOrderHash: Int = self.orderHashList.get(self.orderHashListIndex)!!;
            self.orderClosed.set(oldestOrderHash, null);
        }
        self.orderHashList.set(self.orderHashListIndex, recordKey);
        self.orderClosed.set(recordKey, type);
    }

    /* GETTER FUNCTIONS */

    get fun sellFeePerc(): Int {
        return self.sellFeePerc;
    }

    get fun msgFee(): Int {
        return self.msgFee;
    }

    get fun inscribeFee(): Int {
        return self.inscribeFee;
    }

    get fun maxOrderLength(): Int {
        return self.maxOrderLength;
    }

    get fun orderClosed(): map<Int, Int> {
        return self.orderClosed;
    }

    get fun orderHashList(): map<Int, Int> {
        return self.orderHashList;
    }

    get fun orderHashListIndex(): Int {
        return self.orderHashListIndex;
    }

    get fun contractSeqno(): Int {
        return self.seqno;
    }

    get fun balance(): Int {
        return myBalance();
    }
}