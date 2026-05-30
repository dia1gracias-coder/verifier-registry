import "@stdlib/deploy";

// ── Messages ──
message Register {
    price: Int as coins;
}

message UpgradeSlot {
    slot:  Int;
    price: Int as coins;
}

message ChangeOwner {
    newOwner: Address;
}

// ── User struct ──
struct UserData {
    unlockedSlots: Int;
    registeredAt:  Int;
}

// ── Main Contract ──
contract FutureTon with Deployable {

    owner: Address;
    users: map<Address, UserData>;
    totalUsers: Int = 0;

    init(owner: Address) {
        self.owner = owner;
    }

    // ── Register ──
    receive(msg: Register) {
        let addr: Address = sender();
        require(self.users.get(addr) == null, "Already registered");

        let newUser: UserData = UserData {
            unlockedSlots: 1,
            registeredAt:  now(),
        };
        self.users.set(addr, newUser);
        self.totalUsers = self.totalUsers + 1;

        // Send exact price to owner
        send(SendParameters {
            to:    self.owner,
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

        // Send exact price to owner
        send(SendParameters {
            to:    self.owner,
            value: msg.price,
            mode:  SendIgnoreErrors,
            body:  beginCell().endCell(),
        });
    }

    // ── Change Owner ──
    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "Not owner");
        self.owner = msg.newOwner;
    }

    // ── Withdraw ──
    receive("withdraw") {
        require(sender() == self.owner, "Not owner");
        send(SendParameters {
            to:    self.owner,
            value: 0,
            mode:  SendRemainingBalance + SendIgnoreErrors,
            body:  beginCell().endCell(),
        });
    }

    // ── Getters ──
    get fun getUser(addr: Address): UserData? {
        return self.users.get(addr);
    }

    get fun isRegistered(addr: Address): Bool {
        return self.users.get(addr) != null;
    }

    get fun totalUsers(): Int {
        return self.totalUsers;
    }
}