import "@stdlib/deploy";

// --- New Message for setting the wallet ---
message SetWallet {
    address: Address;
}

message(0x0f8a7ea5) Transfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

contract VestingContract with Deployable {
    owner: Address;
    beneficiary: Address;
    totalAmount: Int as coins;
    releasedAmount: Int as coins = 0;
    startTime: Int as uint32;
    duration: Int as uint32 = 94608000; 
    cliff: Int as uint32 = 15768000;    
    jettonWallet: Address?; 

    init(owner: Address, beneficiary: Address, totalAmount: Int, startTime: Int) {
        self.owner = owner;
        self.beneficiary = beneficiary;
        self.totalAmount = totalAmount;
        self.startTime = startTime;
    }

    // FIX: Changed from receive(msg: Address) to receive(msg: SetWallet)
    receive(msg: SetWallet) {
        require(sender() == self.owner, "Only owner can set wallet");
        self.jettonWallet = msg.address;
    }

    receive("release") {
        let currentTime: Int = now();
        require(currentTime >= self.startTime + self.cliff, "Cliff period not reached");

        let unlocked: Int = self.calculateUnlocked(currentTime);
        let claimable: Int = unlocked - self.releasedAmount;
        
        require(claimable > 0, "No tokens to release");
        require(self.jettonWallet != null, "Jetton wallet not configured");
        
        self.releasedAmount = self.releasedAmount + claimable;
        
        send(SendParameters{
            to: self.jettonWallet!!,
            value: ton("0.1"),
            mode: SendPayGasSeparately,
            body: Transfer{
                query_id: 0,
                amount: claimable,
                destination: self.beneficiary,
                response_destination: self.beneficiary,
                custom_payload: null,
                forward_ton_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });
    }

    get fun calculateUnlocked(time: Int): Int {
        if (time < self.startTime + self.cliff) { return 0; }
        if (time >= self.startTime + self.duration) { return self.totalAmount; }
        return (self.totalAmount * (time - self.startTime)) / self.duration;
    }
}