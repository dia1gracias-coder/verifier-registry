import "./contract1";

message(0x2) UpdateContract1 {
    // message to update Contract1's counter
}

message(0x4) UpdateSelf2 {
    // empty message
}

contract Contract2 {
    counter: Int as uint32;
    
    init() {
        self.counter = 0;
    }

    // empty receiver for deployment
    receive() {
        cashback(sender());
    }

    receive(_: UpdateSelf2) {
        self.add(1);
        
        // Send UpdateContract1 message to Contract1
        let init: StateInit = initOf Contract1();
        let addr: Address = contractAddress(init);
        send(SendParameters{
            to: addr,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: UpdateContract1{}.toCell()
        });
    }

    receive(_: UpdateContract2) {
        self.add(1);
    }

    fun add(v: Int) {
        self.counter += v;
    }

    get fun counter(): Int {
        return self.counter;
    }
}
