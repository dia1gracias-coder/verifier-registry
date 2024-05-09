import "@stdlib/deploy";
import "@stdlib/ownable";

message SetStatus {
    statusId: Int;
}

message SetLockAddress {
    lockAddress: Address;
}

message SetHoldersSnapshot {
    holder: Address;
}

message Transfer {
    recipient: Address;
    amount: Int;
}

const LockAmount: Int = 200000000000; // 200K TFB
const HolderPercent: Int = 20; // 20%

contract Main with Deployable, Ownable  {
    owner: Address; // OWNER ADDRESS
    lockAddress: Address; // LOCK ADDRESS
    token: Address; // TFB JETTON ADDRESS
    zeroAddress: Address; // BURN ADDRESS
    statusId: Int; // ACTIVITY STATUS ID
    holders: map<Int, Address>; // HOLDERS LIST SNAPSHOT
    holdersLength: Int;

    init(token: Address, lockAddress: Address) {
        self.token = token;
        self.lockAddress = lockAddress;
        self.owner = sender();
        self.holders =  emptyMap();
        self.statusId =  0;
        self.zeroAddress = newAddress(0, 0);
        self.holdersLength = 0;
    }

    receive(msg: SetStatus) {
        self.requireOwner();
        self.statusId = msg.statusId; // SET ACTIVITY STATUS
    }

    receive(msg: SetLockAddress) {
        self.requireOwner();
        self.lockAddress = msg.lockAddress; // SET LOCK ADDRESS
    }

    receive(msg: SetHoldersSnapshot) {
        self.requireOwner();
        self.holders.set(self.holdersLength, msg.holder); // SET HOLDER ADDRESS
        self.holdersLength = self.holdersLength + 1;
    }

    fun onStatusChange() {
        self.requireOwner();
        
        // IF STATUS EQUAL '1', THEN TRANSFER ALL TOKENS TO HOLDERS
        if (self.statusId == 1) {
            send(SendParameters{
                to: self.token,
                value: 0, 
                mode: SendRemainingValue + SendIgnoreErrors, 
                body: Transfer{recipient: self.lockAddress, amount: LockAmount}.toCell()
            });
        }

        // IF STATUS EQUAL '2', THEN BURN ALL TOKENS
        if (self.statusId == 2) {
            send(SendParameters{
                to: self.token,
                value: 0, 
                mode: SendRemainingValue + SendIgnoreErrors, 
                body: Transfer{recipient: self.zeroAddress, amount: LockAmount}.toCell()
            });
        }
    }

    get fun status(): Int {
        return self.statusId; // GET ACTIVITY STATUS
    }

    get fun lockAddress(): Address {
        return self.lockAddress; // GET LOCK ADDRESS
    }

    get fun token(): Address {
        return self.token; // GET TOKEN ADDRESS
    }
}
