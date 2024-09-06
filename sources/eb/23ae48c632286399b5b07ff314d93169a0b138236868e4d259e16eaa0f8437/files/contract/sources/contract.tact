import "@stdlib/deploy";

message Swap {
    amount: Int as uint64;  // Amount of Jetton to swap
    jetton: Address;        // Jetton address of the swap
}

message AddJettons {
    amountA: Int as uint64;  // Amount of Jetton A to add
    amountB: Int as uint64;  // Amount of Jetton B to add
}

contract JDexContract with Deployable {

    owner: Address;
    amountOfJettonAOnContract: Int as uint64;
    amountOfJettonBOnContract: Int as uint64;
    jettonA: Address;
    jettonB: Address;
    decimal: Int = 100000000;

    init(owner: Address, jettonA: Address, jettonB: Address) {
        self.owner = owner;
        self.jettonA = jettonA;
        self.jettonB = jettonB;
        self.amountOfJettonAOnContract = 0;
        self.amountOfJettonBOnContract = 0;
    }

    fun addJettons(amountA: Int, amountB: Int) { // Corrected to match the message format
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        self.amountOfJettonAOnContract += amountA;
        self.amountOfJettonBOnContract += amountB;
    }

    receive(msg: AddJettons) {
        self.addJettons(msg.amountA, msg.amountB);
    }

    receive(msg: Swap) {
        let ctx: Context = context();
        require(ctx.sender != self.owner, "Admin cannot swap");

        let amountToSwap: Int = msg.amount;
        let jettonToSwap: Address = msg.jetton;
        require(amountToSwap > 0, "Swap amount must be greater than zero");

        if (jettonToSwap == self.jettonB) {
            require(amountToSwap <= self.amountOfJettonBOnContract, "Insufficient Jetton B in contract");

            let priceOfJettonA: Int = (self.amountOfJettonAOnContract * self.decimal) / self.amountOfJettonBOnContract;
            let amountOfAJettonToSend: Int = (priceOfJettonA * amountToSwap) / self.decimal;

            if (amountOfAJettonToSend <= self.amountOfJettonAOnContract) {
                // Execute trade
                self.amountOfJettonAOnContract -= amountOfAJettonToSend;
                self.amountOfJettonBOnContract += amountToSwap;

                // Send Jetton A to the sender
                self.sendJetton(ctx.sender, amountOfAJettonToSend, self.jettonA);
            } else {
                // Revert transaction by sending back Jetton B
                self.sendJetton(ctx.sender, amountToSwap, self.jettonB);
            }
        } else if (jettonToSwap == self.jettonA) {
            require(amountToSwap <= self.amountOfJettonAOnContract, "Insufficient Jetton A in contract");

            let priceOfJettonB: Int = (self.amountOfJettonBOnContract * self.decimal) / self.amountOfJettonAOnContract;
            let amountOfBJettonToSend: Int = (priceOfJettonB * amountToSwap) / self.decimal;

            if (amountOfBJettonToSend <= self.amountOfJettonBOnContract) {
                // Execute trade
                self.amountOfJettonBOnContract -= amountOfBJettonToSend;
                self.amountOfJettonAOnContract += amountToSwap;

                // Send Jetton B to the sender
                self.sendJetton(ctx.sender, amountOfBJettonToSend, self.jettonB);
            } else {
                // Revert transaction by sending back Jetton A
                self.sendJetton(ctx.sender, amountToSwap, self.jettonA);
            }
        } else {
            // throw("Unsupported jetton for swap");
        }
    }

    // Sending jettons back to the user
    fun sendJetton(to: Address, amount: Int , jetton: Address) {
        // Implementation needed for transferring Jettons on TON blockchain.
        // This could include calling the transfer function of the Jetton smart contract.
    }

    get fun jettonABalances(): Int {
        return self.amountOfJettonAOnContract;
    }

    get fun jettonBBalances(): Int {
        return self.amountOfJettonBOnContract;
    }

    get fun jettonPrice(jetton: Address): Int {
        if (jetton == self.jettonA) {
            require(self.amountOfJettonAOnContract != 0, "Division by zero error");
            return (self.amountOfJettonBOnContract * self.decimal) / self.amountOfJettonAOnContract;
        } else if (jetton == self.jettonB) {
            require(self.amountOfJettonBOnContract != 0, "Division by zero error");
            return (self.amountOfJettonAOnContract * self.decimal) / self.amountOfJettonBOnContract;
        } else {
            return 0;  // Undefined behavior for unsupported Jettons
        }
    }
}
