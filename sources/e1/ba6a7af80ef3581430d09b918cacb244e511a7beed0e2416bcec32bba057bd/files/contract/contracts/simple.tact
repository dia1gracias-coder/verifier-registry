message Add {
    queryId: Int as uint64;
    amount: Int as uint32;
}

contract Simple {

    init(id: Int) {
    }

    receive(msg: Add) {

    }

    get fun counter(): Int {
        return 0;
    }

    get fun id(): Int {
        return 1;
    }
}
