import "@stdlib/deploy";
import "@stdlib/ownable";
message Add {
    amount: Int as uint32;
}

contract SampleTactContract with Deployable, Ownable {
    owner: Address;
    counter: Int as uint32;
    init(){
        self.owner = sender();
        self.counter = 0;
    }

    fun add(v: Int) {
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        // Update counter
        self.counter += v;
    }

    receive(msg: Add){
        self.add(msg.amount);
    }

    receive(){
        self.add(2);
    }

    receive("increment"){
        self.add(1);
        self.reply("incremented".asComment());
    }

    get fun greeting(): String {
        return "hello world";
    }

    get fun counter(): Int {
        return self.counter;
    }
}