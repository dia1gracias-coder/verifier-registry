import "@stdlib/ownable";

message(0x1) Enter {}

message(0x2) Draw {}

contract LotteryFortuneSun with Ownable {
    owner: Address;
    entryAmount: Int as int64;
    players: map<Int as int8, Address>;
    playersLength: Int as int8;
    maxPlayers: Int as int8;
    deadline: Int as int32;
    duration: Int as int32;
    lastWinner: Address?;

    // jackpot address pool
    jackpot: Address?;

    // jackpot pool percent
    jackpotPercent: Int as int32;

    // owner percent
    ownerPercent: Int as int32;

    init(_owner: Address, _jackpot: Address?) {
        self.owner = _owner;
        self.entryAmount = ton("0.1");
        self.maxPlayers = 10;
        self.duration = 120;
        self.jackpot = _jackpot;
        self.jackpotPercent = 5;
        self.ownerPercent = 5;
        self.playersLength = 0;
        self.deadline = now() + self.duration;
    }

    fun draw() {
        self.requireOwner();
        require(self.playersLength > 0, "Players empty");

        let totalPrize: Int = self.entryAmount * self.playersLength;

        let jackpotPart: Int = self.jackpot != null ? (totalPrize * self.jackpotPercent / 100) : 0;
        let ownerFee: Int = totalPrize * self.ownerPercent / 100;
        let winnerPrize: Int = totalPrize - jackpotPart - ownerFee;

        let winnerIndex = random(1, self.playersLength);
        let winnerAddress: Address? = self.players.get(winnerIndex);


        if(winnerAddress != null) {
            send(SendParameters { to: winnerAddress!!, value: winnerPrize });
        }

        send(SendParameters { to: self.owner(), value: ownerFee });
        if(jackpotPart > 0 && self.jackpot != null) {
            send(SendParameters { to: self.jackpot!!, value: jackpotPart });
        }

        // reset pool
        self.resetPool();
    }

    fun resetPool() {
        self.playersLength = 0;
        self.players = emptyMap();
        self.deadline = now() + self.duration;
    }

    // Enter into the pool
    receive(msg: Enter) {
        require(context().value == self.entryAmount, "Invalid entry amount");
        require(self.playersLength < self.maxPlayers, "Pool is full");

        self.playersLength += 1;
        self.players.set(self.playersLength, sender());
    }

    // Draw
    receive(msg: Draw) {
        self.requireOwner();
        self.draw();
    }

    get fun playersLength(): Int {
        return self.playersLength;
    }

    get fun lastWinner(): Address? {
        return self.lastWinner;
    }

    get fun deadline(): Int {
        return self.deadline;
    }

    // empty receiver for deployment
    receive() {
        cashback(sender());
    }
}
