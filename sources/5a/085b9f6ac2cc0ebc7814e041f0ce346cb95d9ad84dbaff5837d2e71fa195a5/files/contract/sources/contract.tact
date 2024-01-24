import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}
message Send {
    to: map<Int, Address>;
    len: Int;
    amount: Int as coins;
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

    receive(msg: Add) {
        self.add(msg.amount);
    }

    receive("increment") {
        self.add(1);
        self.reply("incremented".asComment());
    }
     receive(msg:Send) {
        dump(msg.amount*msg.len);

        // let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(msg.amount*msg.len <= context().value, "Insufficient balance");
        let i: Int = 0;
         while (i<msg.len) {   
             send(SendParameters{
                to: msg.to.get(i)!!,
                bounce: true,
                value: msg.amount,
                mode: SendRemainingValue + SendIgnoreErrors
            });         // loop while a condition is true
            i = i + 1;
        
        }
     
    }

    get fun counter(): Int {
        return self.counter;
    }
}