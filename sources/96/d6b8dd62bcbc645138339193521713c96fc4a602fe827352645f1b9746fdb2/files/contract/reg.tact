import "@stdlib/deploy";

contract Register with Deployable {

    // Persistent state: maps an address to its 64‑bit user ID.
    users: map<Address, Int>;

    // Off‑chain getter for the registration fee (1 TON in nanoTON).
    get fun REGISTER_FEE(): Int {
        return 1_000_000_000;
    }

    /// Internal message receiver for the “register” command.
    /// The message body must contain a 64‑bit unsigned user ID
    /// after the 32‑bit zero prefix.
    receive("register") {
        let s: Address = sender();         // caller’s address
        let v: Int = context().value;      // amount of TON sent

        // Parse message body: skip 32 zero bits, then read 64‑bit user ID
        let cs: Slice = inMsg();
        cs.loadUint(32);                   // skip prefix
        let id: Int = cs.loadUint(64);

        require(!self.users.exists(s), "Already registered");
        require(v >= self.REGISTER_FEE(), "Insufficient fee");

        self.users.set(s, id);

        // Send confirmation and return remaining TON
        send(SendParameters{
            to: s,
            value: 0,
            mode: SendRemainingValue,
            body: "Successfully registered!".asComment()
        });
    }

    // Off‑chain getter: returns the registered user ID or null if none.
    get fun user_id_of(addr: Address): Int? {
        return self.users.get(addr);
    }
}
