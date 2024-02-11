import "@stdlib/deploy";
message Add {
    amount: Int as uint32;
}

// contract address will be === source code + initial state (storage)
contract FirstContract with Deployable {
    id: Int as uint32;
    counter: Int as uint32;
    init(id: Int){
        self.id = id;
        self.counter = 0;
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun id(): Int {
        return self.id;
    }

    receive("increment"){
        self.counter = (self.counter + 1);
    }

    receive(msg: Add){
        self.counter = (self.counter + msg.amount);
    }
}