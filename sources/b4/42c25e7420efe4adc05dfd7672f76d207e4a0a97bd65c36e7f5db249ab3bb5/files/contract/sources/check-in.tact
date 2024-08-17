message CheckIn {
}

contract BountyBayCheckIn {
    total_check_ins: Int as uint256;

    init(){
        self.total_check_ins = 0;
    }

    receive(msg: CheckIn){
        self.total_check_ins += 1;
        send(SendParameters{
                bounce: false,
                to: sender(),
                value: 0,
                mode: SendRemainingValue
            }
        );
    }

    get fun get_total_check_ins(): Int {
        return self.total_check_ins;
    }
}