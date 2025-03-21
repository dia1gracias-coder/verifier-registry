import "./contract2";

message(0x1) UpdateSelf1 {
    // empty message
}

message(0x3) UpdateContract2 {
    // message to update Contract2's counter
}

contract Contract1 {
    counter: Int as uint32;
    
    init() {
        self.counter = 0;
    }

    // empty receiver for deployment
    receive() {
        cashback(sender());
    }

    receive(_: UpdateSelf1) {
        self.add(1);
        
        // Send UpdateContract2 message to Contract2
        let init: StateInit = initOf Contract2();
        let addr: Address = contractAddress(init);
        send(SendParameters{
            to: addr,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: UpdateContract2{}.toCell()
        });
    }

    receive(_: UpdateContract1) {
        self.add(1);
    }

    fun add(v: Int) {
        self.counter += v;
    }

    get fun counter(): Int {
        return self.counter;
    }
}
