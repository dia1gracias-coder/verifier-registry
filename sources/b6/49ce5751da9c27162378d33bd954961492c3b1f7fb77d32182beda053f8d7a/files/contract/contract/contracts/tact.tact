import "@stdlib/deploy";

// ── Messages ──
message Register {
    price: Int as coins;
}

message UpgradeSlot {
    slot:  Int;
    price: Int as coins;
}

message ChangeReceiver {
    newReceiver: Address;
}

message Withdraw {
    to: Address;
}

message ChangeAdmin {
    newAdmin: Address;
}

// ── User struct ──
struct UserData {
    unlockedSlots: Int;
    registeredAt:  Int;
}

// ── Main Contract ──
contract FutureTon with Deployable {

    admin:      Address;
    receiver:   Address;
    users:      map<Address, UserData>;
    totalUsers: Int = 0;

    init(admin: Address, receiver: Address) {
        self.admin    = admin;
        self.receiver = receiver;
    }

    // ── Register ──
    receive(msg: Register) {
        let addr: Address = sender();

        let newUser: UserData = UserData {
            unlockedSlots: 1,
            registeredAt:  now(),
        };
        self.users.set(addr, newUser);
        self.totalUsers = self.totalUsers + 1;

        send(SendParameters {
            to:    self.receiver,
            value: msg.price,
            mode:  SendIgnoreErrors,
            body:  beginCell().endCell(),
        });
    }

    // ── Upgrade Slot ──
    receive(msg: UpgradeSlot) {
        let addr: Address = sender();
        require(self.users.get(addr) != null, "Not registered");

        let user: UserData = self.users.get(addr)!!;
        let slot: Int = msg.slot;
        require(slot >= 2 && slot <= 12, "Invalid slot");

        let slotBit: Int = (1 << (slot - 1));
        require((user.unlockedSlots & slotBit) == 0, "Slot already unlocked");

        let updatedUser: UserData = UserData {
            unlockedSlots: user.unlockedSlots | slotBit,
            registeredAt:  user.registeredAt,
        };
        self.users.set(addr, updatedUser);

        send(SendParameters {
            to:    self.receiver,
            value: msg.price,
            mode:  SendIgnoreErrors,
            body:  beginCell().endCell(),
        });
    }

    // ── Change Receiver (only admin) ──
    receive(msg: ChangeReceiver) {
        require(sender() == self.admin, "Not admin");
        self.receiver = msg.newReceiver;
    }

    // ── Withdraw to any address (only admin) ──
    receive(msg: Withdraw) {
        require(sender() == self.admin, "Not admin");
        send(SendParameters {
            to:    msg.to,
            value: 0,
            mode:  SendRemainingBalance + SendIgnoreErrors,
            body:  beginCell().endCell(),
        });
    }

    // ── Plain TON transfer → forward to receiver ──
    receive() {
        send(SendParameters {
            to:    self.receiver,
            value: 0,
            mode:  SendRemainingValue + SendIgnoreErrors,
            body:  beginCell().endCell(),
        });
    }

    // ── Destroy → send all funds to admin ──
    receive("destroy") {
        require(sender() == self.admin, "Not admin");
        send(SendParameters {
            to:    self.admin,
            value: 0,
            mode:  SendRemainingBalance + SendIgnoreErrors,
            body:  beginCell().endCell(),
        });
    }

    // ── Change Admin (only current admin) ──
receive(msg: ChangeAdmin) {
    require(sender() == self.admin, "Not admin");
    self.admin = msg.newAdmin;
}

    // ── Getters ──
    get fun getUser(addr: Address): UserData? {
        return self.users.get(addr);
    }

    get fun admin(): Address {
        return self.admin;
    }

    get fun receiver(): Address {
        return self.receiver;
    }

}