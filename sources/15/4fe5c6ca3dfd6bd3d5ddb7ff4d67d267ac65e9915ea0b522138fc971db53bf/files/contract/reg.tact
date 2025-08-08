import "@stdlib/deploy";

contract Register with Deployable {

    // Persistent state
    owner: Address;
    users: map<Address, Int>;    // user ID by address
    counter: Int;                // total registered users
    register_fee: Int;           // mutable registration fee in nanoTON

    // Getter for current fee
    get fun REGISTER_FEE(): Int {
        return self.register_fee;
    }

    // On deploy: set owner and default fee (0.1 TON)
    init() {
        self.owner = sender();        // deployer's address = owner
        self.counter = 0;
        self.register_fee = 100_000_000; // 0.1 TON in nanoTON
    }

    /// Internal message to register
    receive("register") {
        let s: Address = sender();
        let v: Int = context().value;

        let cs: Slice = inMsg();
        cs.loadUint(32);                // skip prefix
        let id: Int = cs.loadUint(64);  // 64-bit user ID

        require(!self.users.exists(s), "Already registered");
        require(v >= self.REGISTER_FEE(), "Insufficient fee");

        self.users.set(s, id);
        self.counter += 1;

        // Emit (address, id)
        emit(beginCell().storeAddress(s).storeUint(id, 64).endCell());
    }

    /// Owner: change registration fee (body: [32 zero bits][uint64 newFee])
    receive("set_fee") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");

        let cs: Slice = inMsg();
        cs.loadUint(32);                  // skip prefix
        let newFee: Int = cs.loadUint(64); // nanoTON (uint64 is plenty)
        require(newFee > 0, "Fee must be > 0");

        self.register_fee = newFee;

        // Emit (newFee)
        emit(beginCell().storeUint(newFee, 64).endCell());
    }

    /// Owner: change registration fee by sending the new fee as TON Value
    receive("set_fee_value") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");

        let newFee: Int = context().value;    // nanoTON from the message value
        require(newFee > 0, "Fee must be > 0");

        self.register_fee = newFee;

        // event: store new fee (uint64)
        emit(beginCell().storeUint(newFee, 64).endCell());
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

    // Getter: total users
    get fun total_users(): Int {
        return self.counter;
    }
}
