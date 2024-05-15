import "@stdlib/deploy";
import "@stdlib/ownable";

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract Ownertry with Deployable {
    id: Int as uint32;
    counter: Int as uint32;
    owner: Address;

    init(id: Int) {
        self.id = id;
        self.counter = 0;
        self.owner = sender();
    }

    fun add(v: Int) {
        require(self.owner == sender(), "not owner");
        
        // Update counter
        self.counter = (self.counter + v);
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
}
