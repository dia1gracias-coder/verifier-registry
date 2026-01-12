contract GiftGame {
    owner: Address;
    price: Int;          // nanoTON
    totalPlays: Int;

    lastOutcome: Int;
    lastReward: Int;     // nano-NWR5 (record only)

    init(owner: Address, price: Int) {
        self.owner = owner;
        self.price = price;
        self.totalPlays = 0;
        self.lastOutcome = -1;
        self.lastReward = 0;
    }

    // 🎁 Open gift (player pays TON)
    receive("open") {
        require(context().value >= self.price, "NOT_ENOUGH_TON");

        self.totalPlays += 1;

        let seed = now() + self.totalPlays + context().value;
        let outcome = seed % 5;

        self.lastOutcome = outcome;

        if (outcome == 0) {
            self.lastReward = 168;
        } else if (outcome == 1) {
            self.lastReward = 16800;
        } else if (outcome == 2) {
            self.lastReward = 1680000;
        } else if (outcome == 3) {
            self.lastReward = 168000000;
        } else {
            self.lastReward = 168000000000;
        }
    }

    // 💰 Owner withdraw ALL TON
    receive("withdraw") {
        require(context().sender == self.owner, "NOT_OWNER");

        send(SendParameters{
            to: self.owner,
            value: myBalance(),
            bounce: false
        });
    }

    // 📖 Getters
    get fun getLastOutcome(): Int {
        return self.lastOutcome;
    }

    get fun getLastReward(): Int {
        return self.lastReward;
    }

    get fun getTotalPlays(): Int {
        return self.totalPlays;
    }

    get fun getPrice(): Int {
        return self.price;
    }

    get fun getOwner(): Address {
        return self.owner;
    }
}
