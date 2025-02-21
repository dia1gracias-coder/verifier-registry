import "@stdlib/deploy";

contract FakeSmart2 with Deployable {
    // Empty init() function is present by default in all Tact contracts
    // since v1.3.0, so the following may be omitted:
    //
    id: Int;

    init(id: Int) {
        self.id = id;
    }

    //Защита кошки
    receive() {
        
    }

    get fun getAddress(): Address {
        return myAddress();
    }
}
