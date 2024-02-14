import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}

contract SampleTactContract2 with Deployable {



    counter: Int as uint32 = 0;

    init() {}

    fun add(v: Int) {
        self.counter = (self.counter + v);
    }

    receive(msg: Add) {
        self.add(msg.amount);
    }

    receive("increment") {
        self.add(1);
        self.reply("incremented".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }
}