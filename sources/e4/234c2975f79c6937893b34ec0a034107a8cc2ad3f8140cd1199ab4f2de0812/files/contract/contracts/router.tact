import "@stdlib/deploy";

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Cell; // Cell to store everything
}

struct SwapPayload {
    op: Int as uint64;
    jettonAddress: Address;
    routerAddress: Address;
}

contract Router with Deployable {
    amount: Int as coins;
    from: Address;
    payload: SwapPayload?;
    target: Address;
    owner: Address;

    init() {
        self.amount = 0;
        // why newAddress(0, 0) is not working?
        self.from = myAddress();
        self.target = myAddress();
        self.owner = sender();
    }

    receive(msg: TokenNotification) {
        self.from = msg.from;
        self.amount += msg.amount;
//        self.payload = SwapPayload.fromCell(msg.forward_payload);
    }

    get fun amount(): Int {
        return self.amount;
    }

    get fun from(): Address {
        return self.from;
    }

    get fun payload(): SwapPayload? {
        return self.payload;
    }
}
