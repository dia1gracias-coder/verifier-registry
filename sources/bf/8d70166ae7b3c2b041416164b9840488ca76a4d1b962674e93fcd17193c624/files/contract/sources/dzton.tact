import "@stdlib/deploy";
import "@stdlib/ownable";

contract Dzton with Deployable, Ownable{

    owner: Address;

    init(owner: Address) {
        self.owner = owner;
    }

    receive() {}

    get fun getOwner() : Address {
        return self.owner;
    }

}

