import "@stdlib/deploy";

contract HelloBlueprint with Deployable {
    owner: Address;
    version: Int as uint32;

    counter: Int as uint32;

    init(owner: Address, version: Int) {
        self.owner = owner;
        self.version = version;
        self.counter = 0;
    }

    fun checkOwner() {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid Sender");
    }

    receive("nofund") {
        self.checkOwner();

        self.counter += 1;
        self.reply("RefundGas".asComment());
    }

    receive("fund") {
        self.counter += 1;
        // dump value
    }
}
