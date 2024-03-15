contract CounterSample1 {
 
    // owner: Address;
    counter: Int as uint32;
 
    init() {
        self.counter = 0;
    }
 
    receive("increment") {
        self.counter = (self.counter + 101);
    }
 
    get fun counter(): Int {
        return self.counter;
    }
 
    // get fun owner(): Address {
    //     return self.owner;
    // }
}