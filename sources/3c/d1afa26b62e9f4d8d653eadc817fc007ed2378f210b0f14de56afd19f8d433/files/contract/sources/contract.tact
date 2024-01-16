import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}

message Minus {
    amount: Int as uint32;
}

message Multiply {
    amount: Int as uint32;
}

message Devide {
    amount: Int as uint32;
}

contract SampleTactContract with Deployable {

    owner: Address;
    counter: Int as uint32;

    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
    }

    fun add(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter + v);
    }

    fun minus(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter - v);
    }

    fun multiply(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter * v);
    }

    fun devide(v: Int) {
        
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter / v);
    }

    receive(msg: Add) {
        self.add(msg.amount);
    }

    receive(msg: Minus) {
        self.minus(msg.amount);
    }

    receive(msg: Multiply) {
        self.multiply(msg.amount);
    }

    receive(msg: Devide) {
        self.devide(msg.amount);
    }

    receive("increment") {
        self.add(1);
        self.reply("incremented".asComment());
    }

    receive("decrease") {
        self.minus(1);
        self.reply("decreased".asComment());
    }

    receive("multiply2") {
        self.multiply(2);
        self.reply("multiplied".asComment());
    }

    receive("devide2") {
        self.devide(2);
        self.reply("devided".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun owner(): Address {
        return self.owner;
    }
}