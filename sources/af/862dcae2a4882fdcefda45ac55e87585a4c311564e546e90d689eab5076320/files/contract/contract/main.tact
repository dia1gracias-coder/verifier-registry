contract Example {
    receive() {
        send(SendParameters {
            bounce: true, // default
            to: sender(), // or another destination address
            value: ton("0.01"), // attached amount of TON to send
            body: "Hello from Tact!".asComment(), // comment (optional)
        });
    }
}