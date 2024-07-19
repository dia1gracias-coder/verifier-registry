import "./standards/jetton-master-standard-trait";

contract DittoCoinMaster with JettonMasterStandard {
    
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;

    init(totalSupply: Int, mintable: Bool, owner: Address, content: Cell?) {
        self.totalSupply = totalSupply;
        self.mintable = mintable;
        self.owner = owner;
        self.content = content;
    }

    /**
    * Mints jettons to recipient. Will only be invoked if message is sent by a whitelisted contract
    * or contract owner.
    * Excess TON will subsequently be sent back to the message sender.
    *
    * @param msg The Mint message containing the following parameters:
    *      recipient: The address of the recipient
    *      amount: The amount of jettons to be minted
    */
    receive(msg: Mint) {
        let ctx: Context = context();
        self.requireOwner();
        require(self.mintable, "Can't Mint Anymore");
        self.mint(msg.recipient, msg.amount, ctx.sender);
    }

}

/***************************************** NabiPointMaster messages *****************************************/

message(0x98b1748d) Mint {
    recipient: Address;
    amount: Int as coins;
}