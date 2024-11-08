import "@stdlib/deploy";
message Add {
    amount: Int as uint32;
}

contract ForstIncr with Deployable {
    id: Int as uint32;
    counter: Int as uint32;
    
    init(id: Int){
        self.id = id;
        self.counter = 0;
    }

     receive(msg: String) {
        if msg == "increment" {
            self.counter = self.counter + 1;
        }
    }


    receive(msg: Add){
        self.counter = self.counter + msg.amount;
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun id(): Int {
        return self.id;
    }
}