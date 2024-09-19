import "@stdlib/deploy";

@name(set_code)
native setCode(code: Cell);

@name(set_data)
native setData(d: Cell);

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

struct InC {
    id: Int;
    counter: Int;
}

message Subtract {
    queryId: Int as uint64;
    amount: Int as uint32;
}

message UpgradeCode {
    newCode: Cell;
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
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun id(): Int {
        return self.id;
    }

    receive(msg: UpgradeCode) {
        setCode(msg.newCode);
    }

    // v2
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
