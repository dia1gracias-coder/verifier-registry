import "@stdlib/deploy";

contract A with Deployable {
    init() { }
    get fun test1(): Int {
        return 1 / self.test2();
    }
    get fun test2(): Int {
        return 0;
    }
    get fun testManualError(): Int {
        require(now() < -1, "Time is an illusion. Lunchtime doubly so 12.");
        return 3;
    }
}