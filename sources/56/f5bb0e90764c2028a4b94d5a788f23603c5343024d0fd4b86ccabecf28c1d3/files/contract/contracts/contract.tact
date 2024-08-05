import "@stdlib/deploy";
import "@stdlib/ownable";
import "./jetton";

message Mint {
    amount: Int;
    receiver: Address;
    referrer: Address;
}

message AmountDetails {
    amount: Int;
}

contract TestJetton with Deployable, OwnableTransferable, Jetton {
    id: Int as uint32;
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    users: map<Address, Bool>;

    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.

    init(id: Int, owner: Address, content: Cell, max_supply: Int) {
        self.id = id;
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
    }

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(self.users.get(context().sender) != true, "User already claim");
        require(self.total_supply + ton("15") <= self.max_supply, "Max supply exceeded");
        self.users.set(context().sender, true);
        self.mint(context().sender, ton("10"), self.owner); // (to, amount, response_destination)
        self.mint(msg.referrer, ton("5"), self.owner);
        
    }

    receive(amountDetails:AmountDetails)
    {
        require(context().sender==self.owner,"Invalid user");
        send(SendParameters{
            to: context().sender,
            value: amountDetails.amount,
            bounce: false,
            mode: SendIgnoreErrors,
            body: "Remaining balance returned".asComment()
        });
    }
} 