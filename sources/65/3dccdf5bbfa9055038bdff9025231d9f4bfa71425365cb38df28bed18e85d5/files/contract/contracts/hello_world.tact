import "@stdlib/ownable";

// message with opcode
message(0x7e8764ef) Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

// Contract defenition. `Ownable` is a trait to share functionality.
contract HelloWorld with Ownable {

// storage variables
    id: Int as uint32;
    counter: Int as uint32;
    owner: Address;

// init function.
    init(id: Int, owner: Address) {
        self.id = id;
        self.counter = 0;
        self.owner = owner;
    }

// default(null) recieve for deploy
    receive() {
        cashback(sender())
        }

// function to recive messages from other contracts
    receive(msg: Add) {
        // function from `Ownable` trait to assert, that only owner may call this
        self.requireOwner();
        self.counter += msg.amount;

        // Notify the caller that the receiver was executed and forward remaining value back
        self.notify("Cashback".asComment());
    }

// getter function to be called offchain
    get fun counter(): Int {
        return self.counter;
    }

    get fun id(): Int {
        return self.id;
    }
}