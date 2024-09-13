import "@stdlib/deploy";

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract TestContract with Deployable {
    id: Int as uint32;
    counter: Int as uint32;
    counter_one: Int as uint32;
    counter_two: Int as uint32;
    t_id: Int as uint32;
    te_id2: Int as uint32;
    te_id3: Int as uint32;
    te_id4: Int as uint32;
    te_id115: Int as uint32;
    counter_test: Int as uint32;

    init(id: Int) {
        self.id = id;
        self.t_id = id;
        self.te_id2 = id;
        self.te_id3 = id;
        self.te_id4 = id;
        self.te_id115 = id;
        self.counter = 0;
        self.counter_one = 1;
        self.counter_two = 2;
        self.counter_test = 1000;
    }

    receive(msg: Add) {
        self.counter += msg.amount;

        // Notify the caller that the receiver was executed and forward remaining value back
        self.notify("Cashback".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun counter2(): Int {
        return self.counter_one;
    }


    get fun counter3(): Int {
        return self.counter_two;
    }



    get fun id(): Int {
        return self.id;
    }

    get fun tid(): Int {
        return self.t_id;
    }

    get fun teid2(): Int {
        return self.te_id2;
    }

    get fun teidtest2(): Int {
        return self.te_id115;
    }
}
