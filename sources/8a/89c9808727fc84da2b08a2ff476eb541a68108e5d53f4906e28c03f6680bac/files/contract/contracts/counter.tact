import "@stdlib/deploy";
message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}
message Response {
    queryId: Int as uint64;
    counter: Int as uint32;
}

contract Counter with Deployable {
    id: Int as uint64;
    counter: Int as uint32;
    init(id: Int, counter: Int){
        self.id = id;
        self.counter = counter;
    }

    receive(msg: Add){
        self.counter += msg.amount;
        send(SendParameters{
                to: sender(),
                value: ton("0.01"),
                mode: SendIgnoreErrors | SendPayGasSeparately,
                body: Response{queryId: msg.queryId, counter: self.counter}.toCell()
            }
        );
    }

    receive("inc"){
        self.counter += 1;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun counter(): Int {
        return self.counter;
    }
}