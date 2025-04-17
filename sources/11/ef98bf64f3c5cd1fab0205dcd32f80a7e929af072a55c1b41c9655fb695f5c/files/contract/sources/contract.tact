import "@stdlib/ownable";
// import "@stdlib/deployble";

message(0x1) Increment {
    // empty message
}

message(0x2) Add {
    amount: Int as uint32;
}

contract NFTMinerList(owner: Address, counter: Int) with Ownable {

    // owner: Address;
    // counter: Int as uint32;

    // init(owner: Address, counter: Int) {
    //     self.owner = owner;
    //     self.counter = counter;
    // }

    // empty receiver for deployment
    receive() {
        cashback(sender());
    }

    receive(_: Increment) {
        self.add(1);
    }

    receive(msg: Add) {
        self.add(msg.amount);
    }

    fun add(v: Int) {
        self.requireOwner();
        self.counter += v;
    }

    get fun counter(): Int {
        return self.counter;
    }
}
