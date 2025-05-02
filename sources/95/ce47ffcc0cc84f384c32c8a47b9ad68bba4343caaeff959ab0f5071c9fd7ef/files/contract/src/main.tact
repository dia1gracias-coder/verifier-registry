import "@stdlib/ownable";

contract SimpleCounter() {
    // empty receiver for deployment
    receive() {
        cashback(sender());
    }
}
