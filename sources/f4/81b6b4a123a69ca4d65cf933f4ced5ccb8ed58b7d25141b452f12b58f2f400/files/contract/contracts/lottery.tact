import "@stdlib/deploy";
struct Ticket {
    number: Int as uint32;
    owner: Address;
}
message CreateLottery {
    creator: Address;
    operator: Address?;
    price: Int;
    endTime: Int;
    discountDivisor: Int;
}
message BuyTicket {
    recipient: Address;
    amount: Int as uint32;
    ticketNumbers: map<Int as uint32, Int as uint32>;
    refWallet: Address?;
}
message ClaimTickets {
    ticketIds: map<Int as uint32, Int as uint32>;
    ticketLength: Int as uint32;
}
struct LotteryInfo {
    seqno: Int;
    creator: Address;
    ticketCnt: Int;
    endTime: Int;
    price: Int;
    status: Int;
    amountCollected: Int;
}

message Withdraw {
    target: Address;
}

contract Lottery {
    factory: Address;
    creator: Address = newAddress(0, 0);
    operator: Address = newAddress(0, 0);
    seqno: Int;
    ticketCnt: Int = 0;
    endTime: Int as uint256 = 0;
    price: Int as uint256 = 0;
    discountDivisor: Int = 0;
    status: Int as uint16 = 0;
    claimed: map<Address, Int as uint8>;
    ///////////////////////
    const bracketCalculator1: Int = 1;
    const bracketCalculator2: Int = 11;
    const bracketCalculator3: Int = 111;
    const bracketCalculator4: Int = 1111;
    const bracketCalculator5: Int = 11111;
    const bracketCalculator6: Int = 111111;
    //////////////////////
    const rewardBreakDown1: Int = 200;
    const rewardBreakDown2: Int = 300;
    const rewardBreakDown3: Int = 500;
    const rewardBreakDown4: Int = 1000;
    const rewardBreakDown5: Int = 2000;
    const rewardBreakDown6: Int = 4000;
    /////////////////////
    feePercent: Int = 200;
    refPercent: Int = 1800;
    rewardPerBracket: map<Int, Int as uint256>;
    tickets: map<Int, Ticket>;
    winnerCntPerBracket: map<Int, Int as uint256>;
    amountCollected: Int as uint256 = 0;
    feeAmount: Int as uint256 = 0;
    ///////////////////////
    finalNumber: Int as uint32 = 0;
    const MaxNumberTicketsPerBuyOrClaim: Int = 30;
    const MinTonForStorage: Int = ton("0.01");
    /////////////////////////
    init(factory: Address, seqno: Int){
        self.factory = factory;
        self.seqno = seqno;
        let i = 0;
        while (i < 6) {
            self.winnerCntPerBracket.set(i, 0);
            // self.rewardPerBracket.set(i, 0);
            i = i + 1;
        }
    }

    receive(msg: CreateLottery){
        require(self.factory == sender(), "You are not factory");
        self.creator = msg.creator;
        self.operator = msg.operator!!;
        self.price = msg.price;
        self.endTime = msg.endTime;
        self.discountDivisor = msg.discountDivisor;
        self.finalNumber = random(1000000, 2000000);
        // self.finalNumber = 1700788;
    }

    receive(msg: BuyTicket){
        require(msg.amount > 0, "No ticket specified");
        require(msg.amount <= self.MaxNumberTicketsPerBuyOrClaim, "Too many tickets");
        require(now() < self.endTime, "Lottery is over");
        require(self.status == 0, "Lottery is not active");
        /////////////
        let tonAmount = self.calculateTotalPriceForBulkTickets(msg.amount);
        require(context().value >= tonAmount, "Not enough Ton");
        self.amountCollected = self.amountCollected + tonAmount;
        let i = 0;
        let ticketIds: map<Int, Int> = emptyMap();
        while (i < msg.amount) {
            let thisTicketNumber = msg.ticketNumbers.get(i)!!;
            // require(thisTicketNumber >= 1000000 && thisTicketNumber <= 1999999, "Outside range");
            self.registerWinner(thisTicketNumber);
            self.tickets.set(self.ticketCnt, Ticket{owner: msg.recipient, number: thisTicketNumber});
            self.ticketCnt = self.ticketCnt + 1;
            i = i + 1;
        }
        if (msg.refWallet != null) {
            send(SendParameters{
                    to: msg.refWallet!!,
                    bounce: true,
                    value: (tonAmount * self.refPercent) / 10000,
                    mode: SendIgnoreErrors,
                    body: "accept".asComment()
                }
            );
        }
    }

    receive("close"){
        require(sender() == self.creator || sender() == self.operator, "Access is denied");
        require(self.status == 0, "Lottery is not active");
        // require(now() > self.endTime, "Lottery is not over");
        self.status = 1;
    }

    fun registerWinner(ticketNumber: Int) {
        let i = 0;
        let finalNumber = self.finalNumber;
        while (i < 6) {
            let j = 5 - i;
            let thisBracketCalculator = self.getBracketCalculator(j);
            let transformedWinningNumber = thisBracketCalculator + (finalNumber % pow(10, j + 1));
            let thisTicketNumber = thisBracketCalculator + (ticketNumber % pow(10, j + 1));
            if (transformedWinningNumber == thisTicketNumber) {
                self.winnerCntPerBracket.set(j, self.winnerCntPerBracket.get(j)!! + 1);
                return;
            }
            i = i + 1;
        }
    }

    receive("draw"){
        require(sender() == self.factory, "Access is denied");
        require(self.status == 1, "Lottery not close");
        // distribute reward
        let amountToShareWinners: Int = (myBalance() * (10000 - self.feePercent)) / 10000;
        let i = 0;
        while (i < 6) {
            if (self.winnerCntPerBracket.get(i)!! != 0) {
                if (self.getBreakDown(i) != 0) {
                    let rewardShare =
                        ((self.getBreakDown(i) * amountToShareWinners) / self.winnerCntPerBracket.get(i)!!) / 10000;
                    self.rewardPerBracket.set(i, rewardShare);
                }
            } else {
                self.rewardPerBracket.set(i, 0);
            }
            i = i + 1;
        }
        self.status = 2;
        self.feeAmount = (self.amountCollected * self.feePercent) / 10000;
    }

    receive(msg: ClaimTickets){
        require(self.status == 2, "Lottery not claimable");
        require(self.claimed.get(sender()) == null, "Already claimed");
        let rewardToTransfer = 0;
        let i = 0;
        while (i < msg.ticketLength) {
            let thisTicketId = msg.ticketIds.get(i)!!;
            require(sender() == self.tickets.get(i)!!.owner, "You are not owner");
            let thisTicketNumber = self.tickets.get(i)!!.number;
            let rewardForTicketId = self.calculateRewardsForTicketId(thisTicketId);
            rewardToTransfer = rewardToTransfer + rewardForTicketId;
            i = i + 1;
        }
        // transfe ton
        send(SendParameters{to: sender(), bounce: true, value: rewardToTransfer, mode: SendIgnoreErrors});
        self.claimed.set(sender(), 1);
    }

    receive("widrawCommission"){
        require(sender() == self.creator || sender() == self.operator, "Access is denied");
        require(self.feeAmount > 0, "Sufficient balance");
        // transfe ton
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: (self.feeAmount - context().value) - self.MinTonForStorage,
                mode: SendRemainingValue + SendIgnoreErrors
            }
        );
        self.feeAmount = 0;
    }

    receive("moveFunds"){
        require(sender() == self.creator || sender() == self.operator, "Access is denied");
        let init: StateInit = initOf Lottery(self.factory, self.seqno + 1);
        send(SendParameters{
                to: contractAddress(init),
                bounce: true,
                value: myBalance() - self.MinTonForStorage,
                mode: SendIgnoreErrors,
                body: "addFunds".asComment()
            }
        );
    }

    receive("addFunds"){
        self.amountCollected = self.amountCollected + context().value;
    }

    receive(msg: Withdraw){
        require(sender() == self.factory, "Access is denied");
        send(SendParameters{
                to: msg.target,
                bounce: true,
                value: myBalance() - self.MinTonForStorage,
                mode: SendIgnoreErrors,
                body: "addFunds".asComment()
            }
        );
    }

    fun getBracketCalculator(i: Int): Int {
        let bracketCalculator = self.bracketCalculator1;
        if (i == 1) {
            bracketCalculator = self.bracketCalculator2;
        }
        if (i == 2) {
            bracketCalculator = self.bracketCalculator3;
        }
        if (i == 3) {
            bracketCalculator = self.bracketCalculator4;
        }
        if (i == 4) {
            bracketCalculator = self.bracketCalculator5;
        }
        if (i == 5) {
            bracketCalculator = self.bracketCalculator6;
        }
        return bracketCalculator;
    }

    fun getBreakDown(i: Int): Int {
        let breakDown = self.rewardBreakDown1;
        if (i == 1) {
            breakDown = self.rewardBreakDown2;
        }
        if (i == 2) {
            breakDown = self.rewardBreakDown3;
        }
        if (i == 3) {
            breakDown = self.rewardBreakDown4;
        }
        if (i == 4) {
            breakDown = self.rewardBreakDown5;
        }
        if (i == 5) {
            breakDown = self.rewardBreakDown6;
        }
        return breakDown;
    }

    get fun allTickets(): map<Int, Ticket> {
        return self.tickets;
    }

    get fun isClaimable (user: Address): Bool {
        if (self.claimed.get(user) == null) {
            return true;
        }
        return false;
    }

    get fun calculateTotalPriceForBulkTickets(amount: Int): Int {
        return ((self.price * amount) * ((self.discountDivisor + 1) - amount)) / self.discountDivisor;
    }

    get fun winningNumber(): Int {
        if (self.status != 2) {
            return 0;
        }
        return self.finalNumber;
    }

    get fun info(): LotteryInfo {
        return
            LotteryInfo{
                seqno: self.seqno,
                creator: self.creator,
                ticketCnt: self.ticketCnt,
                endTime: self.endTime,
                price: self.price,
                status: self.status,
                amountCollected: self.amountCollected
            };
    }

    get fun calculateRewardsForTicketId(ticketId: Int): Int {
        let winningTicketNumber = self.finalNumber;
        let userNumber = self.tickets.get(ticketId)!!.number;
        let bracket = 5;
        while (bracket >= 0) {
            let transformedWinningNumber =
                self.getBracketCalculator(bracket) + (winningTicketNumber % pow(10, bracket + 1));
            let transformedUserNumber = self.getBracketCalculator(bracket) + (userNumber % pow(10, bracket + 1));
            if (transformedWinningNumber == transformedUserNumber && self.winnerCntPerBracket.get(bracket)!! != 0) {
                return self.rewardPerBracket.get(bracket)!!;
            }
            bracket = bracket - 1;
        }
        return 0;
    }
}