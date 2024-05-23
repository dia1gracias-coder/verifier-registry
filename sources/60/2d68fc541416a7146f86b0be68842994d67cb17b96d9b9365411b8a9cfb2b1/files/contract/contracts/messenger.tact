import "@stdlib/deploy";

    struct HTLCNotification {
            htlcID: Int;
            sender: Address;
            receiver: Address;
            amount: Int;
            timelock: Int;
            hashlock: Int;
            dstAddress: String;
            phtlcID: Int;
    }

    message HTLCNotify {
        data: HTLCNotification;
    }



contract Messenger with Deployable {
    init() {
        
    }

    receive(msg: HTLCNotify) {
        emit(HTLCNotify {data: HTLCNotification {   htlcID: msg.data.htlcID,
                                                    sender: msg.data.sender,
                                                    receiver: msg.data.receiver,
                                                    amount: msg.data.amount,
                                                    timelock: msg.data.timelock,
                                                    hashlock: msg.data.hashlock,
                                                    dstAddress: msg.data.dstAddress,
                                                    phtlcID: msg.data.phtlcID
                                                }}.toCell());
    }

}




