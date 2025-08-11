import "@stdlib/deploy";

contract Register with Deployable {

    // Persistent state
    owner: Address;
    receiver: Address;           // where register funds are forwarded
    users: map<Address, Int>;    // user ID by address
    counter: Int;                // total registered users
    register_fee: Int;           // mutable registration fee in nanoTON

    // Rent/reserve to keep contract alive
    const RENT_RESERVE: Int = 10_000_000; // 0.01 TON

    // Getter for current fee
    get fun REGISTER_FEE(): Int {
        return self.register_fee;
    }

    // Getter for owner address
    get fun get_owner(): Address {
        return self.owner;
    }

    // Getter for receiver address
    get fun get_receiver(): Address {
        return self.receiver;
    }

    // On deploy: set owner, receiver=owner, and default fee (0.32 TON)
    init() {
        self.owner = sender();
        self.receiver = self.owner;
        self.counter = 0;
        self.register_fee = 320_000_000; // 0.32 TON in nanoTON
    }

    /// Internal message to register
    /// body: [32 zero bits][uint64 id]
    receive("register") {
        let s: Address = sender();
        let v: Int = context().value;

        let cs: Slice = inMsg();
        cs.loadUint(32);                 // skip prefix
        let id: Int = cs.loadUint(64);   // 64-bit user ID

        require(!self.users.exists(s), "Already registered!");
        require(v >= self.REGISTER_FEE(), "Insufficient fee");

        // Register user
        self.users.set(s, id);
        self.counter += 1;

        // Keep a small rent reserve in contract; forward the rest to receiver.
        // Top up to RENT_RESERVE if current balance is below it, using part of v.
        let bal_before: Int = myBalance();
        let need_topup: Int = max(0, self.RENT_RESERVE - bal_before);
        let forward_amt: Int = v - need_topup;
        require(forward_amt > 0, "Not enough to cover rent reserve");

        // Forward funds to receiver
        send(SendParameters{
            to: self.receiver,
            value: forward_amt,
            mode: 1,                              // pay fees from contract's balance
            body: "Register fee".asComment()
        });

        // Emit (address, id)
        emit(beginCell().storeAddress(s).storeUint(id, 64).endCell());
    }

    /// Owner: change registration fee (body: [32 zero bits][uint64 newFee])
    receive("set_fee") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");

        let cs: Slice = inMsg();
        cs.loadUint(32);                   // skip prefix
        let newFee: Int = cs.loadUint(64); // nanoTON
        require(newFee > 0, "Fee must be > 0");

        self.register_fee = newFee;

        // Emit (newFee)
        emit(beginCell().storeUint(newFee, 64).endCell());
    }

    /// Owner: change registration fee by sending the new fee as TON Value
    receive("set_fee_value") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");

        let newFee: Int = context().value;    // nanoTON from message value
        require(newFee > 0, "Fee must be > 0");

        self.register_fee = newFee;

        // event: store new fee (uint64)
        emit(beginCell().storeUint(newFee, 64).endCell());
    }

    /// Owner: set/replace receiver (body: [32 zero bits][Address newReceiver])
    receive("set_receiver") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");

        let cs: Slice = inMsg();
        cs.loadUint(32); // skip prefix
        let newReceiver: Address = cs.loadAddress();
        self.receiver = newReceiver;

        // Emit new receiver address
        emit(beginCell().storeAddress(newReceiver).endCell());
    }

    /// Only owner can withdraw extra balance (keeps RENT_RESERVE in contract)
    receive("withdraw") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");

        let bal: Int = myBalance();
        require(bal > self.RENT_RESERVE, "Not enough balance to withdraw");

        send(SendParameters{
            to: s,
            value: bal - self.RENT_RESERVE,
            mode: 1,
            body: "Owner withdrawal".asComment()
        });
    }

    /// ✅ Change owner (restricted to current owner)
    /// body: [32 zero bits][new_address]
    receive("change_owner") {
        let s: Address = sender();
        require(s == self.owner, "Only owner");

        let cs: Slice = inMsg();
        cs.loadUint(32); // skip prefix
        let newOwner: Address = cs.loadAddress();

        self.owner = newOwner;

        // (optional) You may want to auto-update receiver to new owner
        // self.receiver = newOwner; 0QDZKjtvOuBGSYOsqR_teKZaPtrCtuSn25JocRc1Hvty_BVP

        emit(beginCell().storeAddress(newOwner).endCell());
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
