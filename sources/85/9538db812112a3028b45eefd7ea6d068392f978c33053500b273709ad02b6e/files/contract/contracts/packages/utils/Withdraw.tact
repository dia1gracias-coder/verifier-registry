import "./Estimable.tact";

message(0x79f8d455) WithdrawSafe {
    query_id: Int as uint64;
}

message(0x43620644) WithdrawAll {
    query_id: Int as uint64;
}

trait Withdraw with Estimable {

    
    //*********************************//
    //             Messages            //
    //*********************************//

    receive(msg: WithdrawSafe) {
        self._withdrawSafe();
    }

    receive(msg: WithdrawAll) {
        self._withdrawAll();
    }


    //*********************************//
    //       Internal functions        //
    //*********************************//

    virtual inline fun _withdrawSafe() {
        self._canWithdraw();
        let amount: Int = myBalance() - context().value - self.minTonsForStorage;
        send(SendParameters{
            to: sender(),
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: true,
        });
    }

    virtual inline fun _withdrawAll() {
        self._canWithdraw();
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingBalance,
            bounce: true,
        });
    }

    virtual inline fun _canWithdraw() {}
}