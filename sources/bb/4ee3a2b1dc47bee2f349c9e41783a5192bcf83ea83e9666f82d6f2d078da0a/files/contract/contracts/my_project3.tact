import "@stdlib/deploy";

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract MyProject3 with Deployable {
    id: Int as uint32;
    counter: Int as uint32;
    counter2: Int as uint32;

    init(id: Int) {
        self.id = id;
        self.counter = 0;
        self.counter2 = 0;
    }

    receive(msg: Add) {
        self.counter += msg.amount;
        self.counter2 = msg.amount * 2;

        // Notify the caller that the receiver was executed and forward remaining value back
        self.notify("Cashback".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun counter2(): Int {
        return self.counter2;
    }

    get fun id(): Int {
        return self.id;
    }
}
