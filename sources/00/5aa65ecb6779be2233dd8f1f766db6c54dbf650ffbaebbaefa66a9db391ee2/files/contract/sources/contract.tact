import "@stdlib/stoppable";
import "@stdlib/ownable";
import "@stdlib/deploy";

message Withdraw {
    amount: Int as coins;
}


contract LotteryContract with Deployable, OwnableTransferable {

    owner: Address;

    init(owner: Address) {
        self.owner = owner;
    }

    fun calculateMaxBid() : Int { 
        return (myBalance() - ton("0.01")) / 2;
    }

    receive() {
        let ctx: Context = context();
        require(ctx.value < self.calculateMaxBid(), "Check maxBid getter");
        let randomValue: Int = random(0, 99);
        if (randomValue < 40) {
            send(SendParameters{
                to: ctx.sender,
                bounce: true,
                value: ctx.value,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "You won!".asComment()
            });
        } else {
            send(SendParameters{
                to: ctx.sender,
                bounce: true,
                value: 0,
                mode: SendIgnoreErrors,
                body: "You lose :c".asComment()
            });
        }
    }

    receive(msg: Withdraw) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        let amount: Int = min(msg.amount, myBalance() - ctx.value - ton("0.01"));
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: ctx.sender,
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    receive("fill") {
        send(SendParameters{
                to: context().sender,
                bounce: true,
                value: 0,
                mode: SendIgnoreErrors,
                body: "Filled".asComment()
            });
    }

    get fun maxBid(): Int {
        return self.calculateMaxBid();
    }
}