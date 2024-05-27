import "@stdlib/deploy";

contract Counter with Deployable{

    // persistent state variable of type Int to hold the counter value
    val: Int as uint32;

    // initialize the state variable when contract is deployed
    init() {
        self.val = 0;
    }

    // handler for incoming increment messages that change the state
    receive("increment") {
        self.val = self.val + 1;
    }

    // read-only getter for querying the counter value
    get fun counter(): Int {
        return self.val;
    }
}
