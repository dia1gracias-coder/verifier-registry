// this trait has to be imported
import "@stdlib/deploy";
import "@stdlib/ownable";

// the Deployable trait adds a default receiver for the "Deploy" message
contract Counter with Deployable, Ownable {
 
    val: Int as uint32;
    owner: Address;

    init(owner: Address) {
        self.val = 0;
        self.owner = owner;
    }
 
    receive("increment") {
        self.requireOwner();
        self.val = self.val + 1;
    }
 
    get fun value(): Int {
        return self.val;
    }

    get fun getOwner(): Address {
        return self.owner;
    }
}