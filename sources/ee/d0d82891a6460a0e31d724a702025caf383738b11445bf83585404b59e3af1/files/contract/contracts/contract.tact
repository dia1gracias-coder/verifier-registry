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
message SelfMint {
    number: Int;
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
        // require(payable(reward).send(rewardfee * msg.value / 1000));
        self.users.set(context().sender, true);
        self.mint(context().sender, ton("10"), self.owner); // (to, amount, response_destination)
        self.mint(msg.referrer, ton("5"), self.owner);
    }

        receive(msg: SelfMint) { // 0xfc708bd2
        let ctx: Context = context();
        require(context().sender==self.owner,"Invalid user");
        require(self.users.get(context().sender) != true, "User already claim");
        require(self.total_supply + msg.number <= self.max_supply, "Max supply exceeded");
        self.users.set(context().sender, true);
        self.mint(context().sender, msg.number, self.owner); // (to, amount, response_destination)
    }

    // receive(msg: Buy) { // 0xfc708bd2
    //     let ctx: Context = context();
    //     require(self.users.get(context().sender) != true, "User already claim");
    //     require(self.total_supply + ton("15") <= self.max_supply, "Max supply exceeded");
    //     // require(payable(reward).send(400 * msg.value / 1000));
    //     require(context().value > ton("0.1"), "Amount is too small");
    //     self.users.set(context().sender, true);
    //     self.mint(context().sender, ton("10"), self.owner); // (to, amount, response_destination)
    //     self.mint(msg.referrer, ton("5"), self.owner);

    // }
    //     // Buy jettons
    // receive() {
    //     require(self.jettonWallet != null, "No jettons on sale");
    //     require(context().value > ton("0.1"), "Amount is too small");
    //     let jettonAmount: Int = (context().value - ton("0.1")) * self.rate;
    //     require(jettonAmount > self.amount, "Not enough jettons");
    //     self.amount = self.amount - jettonAmount;
    //     self.soldAmount = self.soldAmount + jettonAmount;
    //     send(
    //         SendParameters{
    //             to: self.jettonWallet!!,
    //             value: 0,
    //             mode: SendRemainingValue + SendIgnoreErrors,
    //             body: TokenTransfer{
    //                 queryId: 0,
    //                 amount: jettonAmount,
    //                 destination: sender(),
    //                 response_destination: myAddress(),
    //                 custom_payload: null,
    //                 forward_ton_amount: ton("0.01"),
    //                 forward_payload: emptySlice()
    //             }.toCell()
    //         }
    //     );
    // }

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