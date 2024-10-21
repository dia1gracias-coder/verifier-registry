import "@stdlib/deploy";

contract Counter with Deployable {
    // Empty init() function is present by default in all Tact contracts
    // since v1.3.0, so the following may be omitted:
    //
    val: Int as uint256;

    init() {
        self.val = 0;
    }
    
    receive("increase"){
        self.val += 1;
    }

    get fun valueAmountGet(): Int{
        return self.val;
    }
}
