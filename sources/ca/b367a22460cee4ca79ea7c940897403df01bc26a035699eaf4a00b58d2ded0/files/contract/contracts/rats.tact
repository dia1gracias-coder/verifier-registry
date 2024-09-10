import "@stdlib/deploy";

message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract Rats with Deployable {
    const MinTonForStorage: Int=  ton("0.0113");
    owner: Address;
    x: Int as uint64;


    init(x: Int) {
        let ctx: Context = context();
        self.owner = ctx.sender;
        self.x = x;
    }


    receive("Withdraw all"){
        let ctx: Context = context();

        require(ctx.sender == self.owner,  "Only owner can withdraw all funds");
        let amount: Int = myBalance() - ctx.value - self.MinTonForStorage;
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: ctx.sender,
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    receive(msg: String){

    }
}
