import "@stdlib/deploy";

message SwapBToA {
    amount: Int as uint64;  // Amount of Jetton B to swap
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

    fun addJettons(amountA: Int, amountB: Int) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        self.amountOfJettonAOnContract += amountA;
        self.amountOfJettonBOnContract += amountB;
    }

    receive(msg: AddJettons) {
        self.addJettons(msg.amountA, msg.amountB);
    }

    receive(msg: SwapBToA) {
        let ctx: Context = context();
        require(ctx.sender != self.owner, "Admin cannot swap");

        let amountOfTokenBToSwap: Int = msg.amount;
        let priceOfJettonA: Int = (self.amountOfJettonAOnContract * self.decimal) / self.amountOfJettonBOnContract;
        let amountOfAJettonToSend: Int = (priceOfJettonA * amountOfTokenBToSwap) / self.decimal;

        if (amountOfAJettonToSend <= self.amountOfJettonAOnContract) {
            // Execute trade
            self.amountOfJettonAOnContract -= amountOfAJettonToSend;
            self.amountOfJettonBOnContract += amountOfTokenBToSwap;

            // Send Jetton A to the sender
            self.sendJetton(ctx.sender, amountOfAJettonToSend, self.jettonA);
        } else {
            // Revert transaction by sending back Jetton B
            self.sendJetton(ctx.sender, amountOfTokenBToSwap, self.jettonB);
        }
    }

    // Sending jettons back to the user
    fun sendJetton(to: Address, amount: Int, jetton: Address) {
        // Assuming sendJetton is a built-in function for transferring jettons
        // The logic to transfer Jettons to a user should be implemented here
    }

    get fun jettonABalances(): Int {
        return (self.amountOfJettonAOnContract);
    }

    get fun jettonBBalances(): Int {
        return (self.amountOfJettonBOnContract);
    }

    get fun jettonPrice(jetton: Address): Int {
        if (jetton == self.jettonA) {
            return (self.amountOfJettonBOnContract * self.decimal) / self.amountOfJettonAOnContract;
        } else if (jetton == self.jettonB) {
            return (self.amountOfJettonAOnContract * self.decimal) / self.amountOfJettonBOnContract;
        } else {
            return 0;  // Undefined behavior for unsupported Jettons
        }
    }
}

