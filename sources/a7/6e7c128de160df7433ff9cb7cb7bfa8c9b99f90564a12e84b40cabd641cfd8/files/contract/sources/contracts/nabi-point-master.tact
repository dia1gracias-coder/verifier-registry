import "./standards/jetton-master-standard-trait";

contract NabiPointMaster with JettonMasterStandard {
    
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;

    whitelistedDistributors: map<Address, Bool>;

    init(totalSupply: Int, mintable: Bool, owner: Address, content: Cell?) {
        self.totalSupply = totalSupply;
        self.mintable = mintable;
        self.owner = owner;
        self.content = content;
    }

    /**
    * Mints jettons to recipient. Will only be invoked if message is sent by a whitelisted contract.
    *
    * @param msg The Mint message containing the following parameters:
    *      recipient: The address of the recipient
    *      amount: The amount of jettons to be minted
    */
    receive(msg: Mint) {
        let ctx: Context = context();
        self.requireWhitelistSender(ctx.sender);
        self.mint(msg.recipient, msg.amount, msg.recipient);
    }

    /**
    * Adds or removes an address from the whitelist.
    *
    * @param msg The EditWhitelist message containing the following parameters:
    *      address: The contract address
    *      isWhitelisted: Whether the address is to be added to or removed from the whitelist
    */
    receive(msg: EditWhitelist) {
        let ctx: Context = context();
        self.requireOwner();
        if (msg.isWhitelisted) {
            self.whitelistedDistributors.set(msg.address, true);
        } else {
            self.whitelistedDistributors.set(msg.address, null);
        }
    }

    /**
    * Ensures that the input address is a whitelisted contract.
    *
    * @param sender Address of sender
    */
    fun requireWhitelistSender(sender: Address) {
        require(self.whitelistedDistributors.get(sender) != null, "Sender is not whitelisted");
    }
}

/***************************************** NabiPointMaster messages *****************************************/

message(0x98b1748d) Mint {
    recipient: Address;
    amount: Int as coins;
}

message EditWhitelist {
    address: Address;
    isWhitelisted: Bool;
}