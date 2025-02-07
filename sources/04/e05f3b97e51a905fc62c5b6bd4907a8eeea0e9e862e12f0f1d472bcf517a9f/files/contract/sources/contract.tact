import "@stdlib/deploy";

contract SampleTactContract with Deployable {

    owner: Address;
    address: map<Address, Bool>;

    init(owner: Address) {
        self.owner = owner;
        self.address =  emptyMap();
    }

    fun saveSender() {
        
        // Check sender
        let ctx: Context = context();
        // require(ctx.sender == self.owner, "Invalid sender");
        
        self.address.set(ctx.sender, true);
    }

    receive(){
        self.saveSender();
        self.reply("test".asComment());
    }
}

