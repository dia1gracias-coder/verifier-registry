import "@stdlib/ownable";

// Message for updating the stored string.
// Define the message carrying a hex string
message SetHex {
    hex: String;
}

contract Oracle {
    // Persistent state variable to hold the hex string
    data: String;

    // Initialize `data` to an empty string on deployment
    init() {
        self.data = "";
    }

    // Handle external messages of type SetHex to store or update the hex value
    external(msg: SetHex) {
        acceptMessage();
        self.data = msg.hex;
    }

    // Read-only getter to return the stored hex string
    get fun getHex(): String {
        return self.data;
    }

    receive() {
        cashback(sender());
    }
}
