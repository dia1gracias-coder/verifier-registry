

message Add {
    amount: Int as uint32;
}

// Since v1.6.0, Tact has a contract parameters syntax that can supersede
// lazy initialization by init() for all contracts that do not require specific on-chain
// deployment logic that must be run only once in the `init()` function.
//
// Note that the empty parameter list above is still a parameter list,
// meaning that the contract won't have an implicit or explicit `init(){:tact}` function
// and will enjoy storage write optimizations and use less gas overall.
//
// See: https://docs.tact-lang.org/book/contracts/#parameters
contract CounterContract {

    Id: Int as uint32 = 17564;  
    
    //поле контракта
    counter: Int as uint32 = 0;

    //это вместо конструктора
    //init() { // для образца. Можно было сразу присвоить
    //    self.counter = 0; 
    //}

    receive(msg: String) {
        if(msg == "increment") {
            self.counter += 1;
        }        
    }

    receive(msg: Add) {
        self.counter += msg.amount;        
    }

    //геттер
    get fun getCounter(): Int {
        return self.counter;
    }

    get fun getId() : Int {
        return self.Id;
    }
    
    // Empty receiver for the deployment,
    // which expects the `null` message body
    receive() {
        // Forward the remaining value in the
        // incoming message back to the sender
        cashback(sender());
    }
}