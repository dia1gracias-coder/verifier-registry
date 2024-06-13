import "@stdlib/deploy";

message Deposit {
    address: Address;
}



contract VertusManager with Deployable {
    const MinTonForStorage: Int=  ton("0.01");
    owner: Address;
    x: Int as uint32;


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


    receive(msg: Deposit){
        let ctx: Context = context();
        require(ctx.value > 0, "Deposit amount must be positive");

        send(SendParameters{
            to: msg.address,
            bounce: false,
            value: 0,
            mode: SendRemainingValue
        });
    }

    receive(msg: String){

    }
}
