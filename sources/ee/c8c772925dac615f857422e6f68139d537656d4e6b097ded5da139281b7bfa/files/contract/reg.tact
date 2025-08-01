import "@stdlib/deploy";

contract Register with Deployable {

    // Persistent state
    owner: Address;
    users: map<Address, Int>;    // user ID by address
    counter: Int;                // total registered users

    // Constants
    get fun REGISTER_FEE(): Int {
        return 1_000_000_00;    // 1 TON in nanoTON
    }

    // On deploy: set contract owner
    // On deploy: set contract owner
    init() {
        self.owner = myAddress();  // FIXED: set to current contract address
        self.counter = 0;
    }


    /// Internal message to register
    receive("register") {
        let s: Address = sender();
        let v: Int = context().value;

        let cs: Slice = inMsg();
        cs.loadUint(32);          // skip prefix
        let id: Int = cs.loadUint(64); // 64-bit user ID

        require(!self.users.exists(s), "Already registered");
        require(v >= self.REGISTER_FEE(), "Insufficient fee");

        self.users.set(s, id);
        self.counter += 1;

       emit(beginCell()
            .storeAddress(s)
            .storeUint(id, 64)
        .endCell());

    }

    /// Only owner can withdraw balance

    receive("withdraw") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");
        send(SendParameters{
            to: s,
            value: 0,
            mode: SendRemainingValue,
            body: "Owner withdrawal".asComment()
        });
    }

    // Getter: get user ID
    get fun user_id_of(addr: Address): Int? {
        return self.users.get(addr);
    }

    // Getter: get total number of registered users
    get fun total_users(): Int {
        return self.counter;
    }
}
