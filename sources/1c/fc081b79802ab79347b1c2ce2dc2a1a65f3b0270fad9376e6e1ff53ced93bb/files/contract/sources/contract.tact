import "@stdlib/ownable";

message JoinEvent {
    user: Address;
    times: Int;
    time_stamp: Int;
}

message(0xffcc3d14) JoinMsg {
    query_id: Int as uint64;
}

contract Join with Ownable {
    const gasConsumption: Int = ton("0.01");
    const MinTonForStorage: Int = ton("0.01");
    join_times: map<Address, Int>;
    owner: Address;

    init() {
        self.owner = sender();
    }

    receive(msg: JoinMsg) {
        let temp_times:Int = 0;
        if (self.join_times.get(sender()) == null) {
            self.join_times.set(sender(), 1);
            temp_times = 1;
        }
        else{
            let times:Int = self.join_times.get(sender())!!;
            require(times <= 100, "Over 100 times");
            self.join_times.set(sender(), times + 1);
            temp_times = times;
        }
        emit(JoinEvent{
            user: sender(), 
            times: temp_times,
            time_stamp: now()
        }.toCell());
    }

    // receive() {
    //     let ctx: Context = context();
    //     require(ctx.value >= ton("0.001"), "Value Too Low");
    //     let temp_times:Int = 0;
    //     if (self.join_times.get(ctx.sender) == null) {
    //         self.join_times.set(ctx.sender, 1);
    //         temp_times = 1;
    //     }
    //     else{
    //         let times:Int = self.join_times.get(ctx.sender)!!;
    //         require(times <= 100, "Over 100 times");
    //         self.join_times.set(ctx.sender, times + 1);
    //         temp_times = times;
    //     }
    //     emit(JoinEvent{
    //         user: ctx.sender, 
    //         times: temp_times,
    //         time_stamp: now()
    //     }.toCell());
    // }

    get fun get_join_times(target: Address): Int {     
        if (self.join_times.get(target) == null) {
            return 0;
        } else {
            return self.join_times.get(target)!!;
        }
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

    receive("withdraw all") {
        self.requireOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }
    
} 