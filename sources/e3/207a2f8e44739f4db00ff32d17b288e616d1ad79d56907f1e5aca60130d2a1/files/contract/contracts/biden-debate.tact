import "@stdlib/deploy";
import "@stdlib/ownable";

message SetSnapshot {
    holder: Address;
}

message SetResult {
    result: Bool;
}

message Transfer {
    recipient: Address;
    amount: Int;
}

const LockAmount: Int = 40000000000; // 40K TFB

contract BidenDebate with Deployable, Ownable  {
    result: Bool; // IS BIDEN LOSE
    isFinished: Bool; // DEBATE IS OVER

    token: Address; // TFB JETTON ADDRESS

    holders: map<Int, Address>; // HOLDERS LIST SNAPSHOT
    holdersLength: Int;

    owner: Address; // OWNER ADDRESS
    lockAddress: Address; // LOCK ADDRESS
    zeroAddress: Address; // BURN ADDRESS

    init(token: Address, lockAddress: Address) {
        self.token = token;
        self.lockAddress = lockAddress;
        self.owner = sender();
        self.result = false;
        self.isFinished = false;
        self.zeroAddress = newAddress(0, 0);
        self.holders = emptyMap();
        self.holdersLength = 0;
    }

    receive(msg: SetResult) {
        self.requireOwner();
        self.result = msg.result; // SET RESULT
    }

    receive(msg: SetSnapshot) {
        self.requireOwner();
        self.holders.set(self.holdersLength, msg.holder); // SET HOLDER ADDRESS
        self.holdersLength = self.holdersLength + 1;
    }

    fun allocate() {
        self.requireOwner();

        if (self.isFinished == false) {
            // IF RESULT EQUAL 'true', THEN TRANSFER ALL TOKENS TO HOLDERS
            if (self.result == true) {
                send(SendParameters{
                to: self.token,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: Transfer{recipient: self.lockAddress, amount: LockAmount}.toCell()
                });
            } else { // IF RESULT EQUAL 'false', THEN BURN ALL TOKENS
                send(SendParameters{
                to: self.token,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: Transfer{recipient: self.zeroAddress, amount: LockAmount}.toCell()
                });
            }

            self.isFinished = true;
        }
    }

    get fun token(): Address {
        return self.token; // GET TOKEN ADDRESS
    }

    get fun lockAddress(): Address {
        return self.lockAddress; // GET LOCK ADDRESS
    }

    get fun result(): Bool {
        return self.result; // GET RESULT
    }

    get fun isFinished(): Bool {
        return self.isFinished; // GET STATUS
    }
}
