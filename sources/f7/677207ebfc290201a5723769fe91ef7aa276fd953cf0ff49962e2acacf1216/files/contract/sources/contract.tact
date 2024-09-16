import "@stdlib/deploy";

message MintJettons {
    amount: Int as uint32;
    recipient: Address;
}

contract JettonMasterContract with Deployable {

    owner: Address;
    totalSupply: Int as uint32;
    isMintable: Bool;

    init(owner: Address, initialSupply: Int) {
        self.owner = owner;
        self.totalSupply = initialSupply;
        self.isMintable = true; // Allow minting
    }

    fun mint(amount: Int, recipient: Address) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Unauthorized minting attempt");
        require(self.isMintable, "Minting is disabled");

        // Mint new Jettons by increasing the total supply
        self.totalSupply += amount;

        // Here, add logic to credit the recipient with the minted Jettons
        // This typically involves calling a transfer function or updating a recipient's balance
        // transferJettons(recipient, amount);
    }

    receive(msg: MintJettons) {
        self.mint(msg.amount, msg.recipient);
    }

    // Additional optional function to disable further minting
    fun disableMinting() {
        self.isMintable = false;
    }

    get fun currentSupply(): Int {
        return self.totalSupply;
    }
}
