message BidEvent {
    id: String;
    sender: Address;
}

contract BidTest {
 
    // initialize the state variable when contract is deployed
    init() {}
 
    // handler for incoming increment messages that change the state
    receive(id: String) {
        emit(BidEvent{id: id, sender: sender()}.toCell());
    }

}