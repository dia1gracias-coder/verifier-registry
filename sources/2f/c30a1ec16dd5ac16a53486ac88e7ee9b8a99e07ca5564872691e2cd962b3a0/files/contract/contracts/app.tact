import "@stdlib/deploy";
import "./user.tact";

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract App with Deployable {
    id: Int as uint32;
    counter: Int as uint32;

    init(id: Int) {
        self.id = id;
        self.counter = 0;
    }

    receive() {
        self.counter += 42;
    }

    receive(msg: Add) {
        self.counter += msg.amount;

        // Notify the caller that the receiver was executed and forward remaining value back
        self.notify("Cashback".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun userAddress(): Address {
        return contractAddress(initOf Userr());
    }
}
