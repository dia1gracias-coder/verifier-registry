contract Counter {
 
    owner: Address;
    counter: Int as uint32;
 
    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
    }
 
    receive("increment") {
        self.counter = (self.counter + 1);
    }
 
    get fun counter(): Int {
        return self.counter;
    }
 
    get fun owner(): Address {
        return self.owner;
    }
}