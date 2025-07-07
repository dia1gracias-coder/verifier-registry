// Defining a contract
contract HelloWorld {
    // Listens to incoming Ping messages
    receive(msg: Ping) {
        // Sends a Pong reply message
        reply(Pong {}.toCell());
    }

    // Listens to incoming Hello messages
    receive(msg: Hello) {
        // Replies with the received Hello message
        reply(msg.toCell());
    }

    // Listens to incoming empty messages,
    // which are very handy and cheap for the deployments.
    receive() {
        // Forward the remaining value in the
        // incoming message back to the sender.
        cashback(sender());
    }
}

// A helper inlined function to send binary messages.
// See the "Primitive types" section below for more info about cells.
inline fun reply(msgBody: Cell) {
    message(MessageParameters {
        to: sender(),
        value: 0,
        mode: SendRemainingValue | SendIgnoreErrors,
        body: msgBody,
    });
}

// Empty message structs with specified 32-bit integer prefix.
// See the "Structs and message structs" section below for more info.
message(1) Ping {}
message(2) Pong {}
message(3) Hello {}