message(0x1) Ping {
    remaining: Int as uint32;
}

message(0x2) Pong {
    remaining: Int as uint32;
}

contract PongContract(
    pingAddress: Address,
) {
    // empty receiver for deployment
    receive() {
        // return the amount to the sender
        cashback(sender());
    }

    receive(msg: Ping) {
        // Received ping, send pong back if remaining > 0
        if (msg.remaining > 0) {
            self.sendPong(msg.remaining);
        }
    }

    fun sendPong(remaining: Int) {
        send(SendParameters{
            to: self.pingAddress,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: Pong{remaining: remaining}.toCell(),
        });
    }

    get fun pingAddress(): Address {
        return self.pingAddress;
    }
}

