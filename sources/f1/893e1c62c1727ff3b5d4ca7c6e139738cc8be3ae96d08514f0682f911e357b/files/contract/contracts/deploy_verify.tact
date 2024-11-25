import "@stdlib/deploy";

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

message Subtract {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract DeployVerify with Deployable {
    id: Int as uint32;
    counterOld: Int as uint32;

    init(id: Int) {
        self.id = id;
        self.counterOld = 0;
    }

    receive(msg: Add) {
        self.counterOld += msg.amount;

        // Notify the caller that the receiver was executed and forward remaining value back
        self.notify("CashbackData".asComment());
    }

    receive(msg: Subtract) {
        require(msg.amount <= self.counterOld, "Underflow");
        self.counterOld -= msg.amount;

        // Notify the caller that the receiver was executed and forward remaining value back
        self.notify("CashbackData".asComment());
    }

    get fun counter(): Int {
        return self.counterOld;
    }

    get fun id(): Int {
        return self.id;
    }
}
