message Test {
    id: Int;
    amount: Int as coins;
}

contract Gas {
    MAX_INT: Int;
    IS_MASTERCHAIN: Bool;
    LAST_TX: Int;

    init(isMasterchain: Bool) {
        self.MAX_INT = (1 << 255) - 1;
        self.LAST_TX = now();
        self.IS_MASTERCHAIN = isMasterchain;
    }

    receive() {
        nativeReserve(myBalance() - context().value + self.calc(),ReserveExact | ReserveBounceIfActionFail);
        commit();
        // message(MessageParameters {
        //     to: sender(),
        //     value: 0,
        //     bounce: false,
        //     mode: SendRemainingBalance,
        // });
        cashback(sender());
    }

    receive(msg: String) {
               nativeReserve(myBalance() - context().value + self.calc(),ReserveExact | ReserveBounceIfActionFail);
               commit();

        // message(MessageParameters {
        //     to: sender(),
        //     value: 0,
        //     bounce: false,
        //     mode: SendRemainingBalance,
        // });
        cashback(sender());
    }

    receive(msg: Slice) {
                nativeReserve(myBalance() - context().value + self.calc(),ReserveExact | ReserveBounceIfActionFail);
                commit();

        // message(MessageParameters {
        //     to: sender(),
        //     value: 0,
        //     bounce: false,
        //     mode: SendRemainingBalance,
        // });
        cashback(sender());
    }

    receive(msg: Test) {
                nativeReserve(myBalance() - context().value + self.calc() + msg.amount,0);
                commit();

        throwUnless(10000,msg.id > 10);
        cashback(sender());
    }


    get fun calcStorageFees(): Int{
        let data: DataSize = myCode().computeDataSize(self.MAX_INT);
        return getStorageFee(data.cells,data.bits,now() - self.LAST_TX,self.IS_MASTERCHAIN);
    }

    fun calc(): Int{
        let data: DataSize = myCode().computeDataSize(self.MAX_INT);
        let currentLastTx = self.LAST_TX;
        self.LAST_TX = now();
        return getStorageFee(data.cells,data.bits,now() - currentLastTx,self.IS_MASTERCHAIN);
    }

    get fun calcStorageFees2(): Int {
        return myStorageDue();
    }
}