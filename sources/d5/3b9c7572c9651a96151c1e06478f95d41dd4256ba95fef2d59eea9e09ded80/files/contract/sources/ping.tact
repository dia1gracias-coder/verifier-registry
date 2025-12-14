message(0x1) Ping {
    remaining: Int as uint32;
}

message(0x2) Pong {
    remaining: Int as uint32;
}

message(0x3) Start {
    // empty message to start ping-pong
}

contract PingContract(
    pongAddress: Address,
    n: Int as uint32,
) {
    // empty receiver for deployment
    receive() {
        // return the amount to the sender
        cashback(sender());
    }

    receive(msg: Start) {
        // Start the ping-pong by sending first ping
        if (self.n > 0) {
            self.sendPing(self.n);
        }
    }

    receive(msg: Pong) {
        // Received pong, continue ping-pong if remaining > 0
        if (msg.remaining > 0) {
            self.sendPing(msg.remaining - 1);
        }
    }

    fun sendPing(remaining: Int) {
        send(SendParameters{
            to: self.pongAddress,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: Ping{remaining: remaining}.toCell(),
        });
    }

    get fun pongAddress(): Address {
        return self.pongAddress;
    }

    get fun n(): Int {
        return self.n;
    }
}

