import "@stdlib/deploy";

contract MyRow with Deployable {
    owner: Address;
    id: Int as uint32;
    
    init(id: Int) {
        self.id = id;
        self.owner = address("UQAUqpc4MqbnJ0fr7hgG9N8b8lQM_0MnrnBAtHQllZyoOvU6")
    }
    receive() {
    send(SendParameters{
        // bounce is set to true by default
        to: self.owner, // sending message back to the sender
        value: 0, // don't add Toncoins to the message...
        mode: SendRemainingValue | SendIgnoreErrors, // ...except for ones received from the sender due to SendRemainingValue
        body: "Hello, World".asComment(), // asComment converts a String to a Cell with a comment
    });
}
}
