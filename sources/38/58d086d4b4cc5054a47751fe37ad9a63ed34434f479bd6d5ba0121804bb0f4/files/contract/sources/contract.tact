import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}

contract SampleTactContract with Deployable {

    owner: Address;
    counter: Int as uint32;
    // add msg to store a input message
    inputMsg: String;

    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
        self.inputMsg = "";
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

    // Add a receive function to accept message function then save it to input msg
    receive(str: String) {
        self.inputMsg = str;
        self.reply("saved".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }

    // Add a getter function to get the input msg
    get fun inputMsg(): String {
        return self.inputMsg;
    }
}