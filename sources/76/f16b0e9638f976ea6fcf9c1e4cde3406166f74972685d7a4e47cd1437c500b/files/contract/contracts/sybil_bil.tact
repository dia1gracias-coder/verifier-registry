
import "@stdlib/deploy";

struct OwnerAddress {
    address: Address;
    percentage: Int;
}

message OwnersAddress {
    addresses: map<Int, OwnerAddress>;
    size: Int;
}

contract SybilBil with Deployable {

    const MinTonForStorage: Int = ton("0.01");
    deployer: Address;
    addresses: map<Int, OwnerAddress>;
    addressesSize: Int;
    id: Int as uint32;

    init(id: Int) {
        self.id = id;
        self.deployer = sender();
        self.addresses = emptyMap();
        self.addressesSize = 0;
    }

    receive(paymentId: String) {
        self.distributeBalance(context().value);
    }

    receive("withdraw all") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value,
            mode: SendIgnoreErrors
        });
    }

    receive("withdraw safe") {
        require(sender() == self.deployer, "Only deployer is allowed to withdraw");
        self.distributeBalance(myBalance() - context().value - self.MinTonForStorage);
    }

    receive(payload: OwnersAddress) {
        require(sender() == self.deployer, "Only deployer is allowed to set addresses");
        self.addresses = payload.addresses;
        self.addressesSize = payload.size;
    }

    get fun addressesSize(): Int {
        return self.addressesSize;
    }
    
    fun distributeBalance(amount: Int) {
        foreach (key, value in self.addresses) {
            send(SendParameters{
                to: value.address,
                bounce: true,
                value: amount / self.addressesSize,
                mode: SendIgnoreErrors
            });
        }
    }

    get fun addresses(): map<Int, OwnerAddress> {
        return self.addresses;
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }

    get fun id(): Int {
        return self.id;
    }
}