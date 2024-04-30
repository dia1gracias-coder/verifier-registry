import "@stdlib/ownable";

message SignEvent {
    user: Address;
    time_stamp: Int;
}


contract Sign with Ownable {
    const MinTonForStorage: Int = ton("0.01");

    owner: Address;

    init() {
        self.owner = sender();
    }

    receive() {
        let ctx: Context = context();
        require(ctx.value >= ton("0.2"), "Value Too Low");
        emit(SignEvent{
            user: sender(), 
            time_stamp: now()
        }.toCell());
    }

    receive("withdraw") {
        self.requireOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }


    
} 