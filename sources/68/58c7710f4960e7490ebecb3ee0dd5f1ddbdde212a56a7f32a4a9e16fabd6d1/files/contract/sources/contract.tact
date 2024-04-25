import "@stdlib/deploy";
import "@stdlib/ownable";

message Withdraw {
    amount: Int as coins;
}

message Order{
    id: Int as uint256;
}

contract Payment with Deployable, OwnableTransferable {

    orders: map<Int, Int>;
    const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    // deployer: Address;
    owner: Address;

    init(owner: Address) {
        self.owner = owner;
        self.orders = emptyMap();
    }

    // accept incoming TON transfers
    receive() {
        dump("funds received");
    }

    receive(order: Order){
        require(self.orders.get(order.id) == null, "order exists");
        let ctx: Context = context();
        self.orders.set(order.id, ctx.value);
    }

    // this will withdraw the entire balance of the contract and leave 0
    receive("withdraw") {
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }


    // this will withdraw a specific amount but leave 0.01 for storage rent costs
    receive(msg: Withdraw) {
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }

}