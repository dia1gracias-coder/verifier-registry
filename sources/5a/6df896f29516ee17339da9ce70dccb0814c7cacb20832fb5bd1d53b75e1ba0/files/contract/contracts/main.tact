import "@stdlib/ownable";
import "@stdlib/deploy";

message Withdraw {
    amount: Int as coins;
}

contract CheckIn with Deployable, OwnableTransferable {
    owner: Address;
    seed: Int as uint32;
    const MinTonForStorage: Int = ton("0.1"); // 0.01 Ton enough for 1 KB of storage for 2.5 years
    init(seed: Int){
        self.owner = sender();
        self.seed = seed;
    }

    receive("deposit") {
        emit("funds received".asComment());
    }

    receive(str: String) {
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors
        });
    }

    // this will withdraw a specific amount but leave 0.01 for storage rent costs
    receive(msg: Withdraw) {
        // Check if the sender is the owner
        self.requireOwner();

        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue | SendIgnoreErrors
        });
    }
    
    get fun seedVal(): Int {
        return self.seed;
    }
}