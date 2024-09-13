import "@stdlib/deploy";
import "./imports/math.fc";

@name(set_code)
native setCode(code: Cell);

@name(set_data)
native setData(d: Cell);

@name(sqrt)
native sqrt(x: Int): Int;

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

message Exp {
    queryId: Int as uint64;
}

message Sqrt {
    queryId: Int as uint64;
}

struct InC {
    id: Int;
    counter: Int;
}

message Subtract {
    queryId: Int as uint64;
    amount: Int as uint32;
}

message Upgrade {
    newCode: Cell;
    newData: Cell;
}

message UpgradeCode {
    newCode: Cell;
}

message UpgradeData {
    newData: Cell;
}

contract Counter with Deployable {
    id: Int as uint32;
    counter: Int as uint32;

    init(id: Int) {
        self.id = id;
        self.counter = 0;
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

    receive(msg: Upgrade) {
        setCode(msg.newCode);
        setData(msg.newData);
    }

    receive(msg: Exp) {
        self.counter = pow(self.counter, 2);
    }

    receive(msg: Sqrt) {
        self.counter = sqrt(self.counter);
    }

    receive(msg: UpgradeCode) {
        setCode(msg.newCode);
    }

    receive(msg: UpgradeData) {
        setData(msg.newData);
    }

    //UPGRADE v2
    get fun data(): InC {
        return InC {
            id: self.id,
            counter: self.counter
        };
    }

    receive(msg: Subtract) {
        self.counter -= msg.amount;
    }
}
