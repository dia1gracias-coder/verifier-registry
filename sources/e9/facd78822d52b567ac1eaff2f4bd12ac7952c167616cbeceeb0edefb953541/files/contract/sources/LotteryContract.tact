import "@stdlib/deploy";
import "@stdlib/ownable";

message JoinInfo {
    address: Address;
    seqno: Int as uint128;
}
message DrawInfo {
    seqno: Int as uint128;
}
message PlayerInfo {
    address: Address;
    amount: Int as uint128;
}
message WinnerInfo {
    address: Address;
    seqno: Int as uint128;
}
message ClearInfo {
    seqno: Int as uint128;
}
message Withdraw {
    amount: Int as coins;
}

contract LotteryStartTactContract with Deployable {
    // enough for 1 KB of storage for 2.5 years
    const minTonForStorage: Int = ton("0.01");
    const remainingTonValue: Int = ton("0.5");
    owner: Address;
    transno: Int as uint128;
    winnerList: map<Int, WinnerInfo>;
    winnerQuantity: Int as uint8 = 0;
    init(owner: Address, transno: Int){
        self.owner = owner;
        self.transno = transno;
    }

    receive(message: JoinInfo) {
        let ctx: Context = context();
        require(ctx.value > self.minTonForStorage, "value is not enough");
        require(message.seqno != null, "seqno can not empty");
        dump(ctx.value);
        dump(message.seqno);
        message.address = sender();
        let init: StateInit = initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno);
        send(SendParameters{
            to: contractAddress(init),
            body: message.toCell(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            code: init.code,
            data: init.data
        });
    }

    receive(message: DrawInfo) {
        require(sender() == self.owner, "Only owner is allowed to drawLottery");
        require(message.seqno != null, "seqno can not empty");
        let init: StateInit = initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno);
        send(SendParameters{
            to: contractAddress(init),
            body: message.toCell(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            code: init.code,
            data: init.data
        });
    }

    receive(message: WinnerInfo) {
        let child: Address = contractAddress(initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno));
        require(sender() == child, "not child");
        self.pushWinner(message);
    }

    receive(message: ClearInfo) {
        self.clearWinner(message);
        self.reply("clear success".asComment());
    }

    receive("recharge"){
        dump(context().value);
    }

    receive("withdraw") {
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.remainingTonValue,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    receive(message: Withdraw) {
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        let amount: Int = min(message.amount, myBalance() - context().value - self.remainingTonValue);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    fun pushWinner(winner: WinnerInfo) {
        self.winnerList.set(self.winnerQuantity, winner);
        self.winnerQuantity = (self.winnerQuantity + 1);
    }

    fun clearWinner(winner: ClearInfo) {
        self.winnerList.set(winner.seqno, null);
        self.winnerQuantity = (self.winnerQuantity - 1);
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun address(): Address {
        return myAddress();
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun transno(): Int {
        return self.transno;
    }

    get fun winnerQuantity(): Int {
        return self.winnerQuantity;
    }

    get fun winnerList(): map<Int, WinnerInfo> {
        return self.winnerList;
    }

}

contract LotteryPlayTactContract with Deployable {
    // enough for 1 KB of storage for 2.5 years
    const minTonForStorage: Int = ton("0.01");
    owner: Address;
    father: Address;
    seqno: Int as uint128;
    playerList: map<Int, PlayerInfo>;
    playerQuantity: Int as uint8 = 0;
    conditionQuantity: Int as uint8 = 3;
    init(owner: Address, father: Address, seqno: Int){
        self.owner = owner;
        self.father = father;
        self.seqno = seqno;
    }

    receive(message: JoinInfo){
        let ctx: Context = context();
        require(self.father == sender(), "not father");
        require(ctx.value > self.minTonForStorage, "value is not enough");
        require(message.seqno != null, "seqno can not empty");
        require(message.address != null, "address can not empty");
        dump(ctx.value);
        dump(message.seqno);
        // let index: Int = 0;
        // let exist: Bool = false;
        // while (!exist && index < self.playerQuantity) {
        //     let player: PlayerInfo = self.playerList.get(index)!!;
        //     if (player.address == message.address) {
        //         exist = true;
        //     }
        //     index = (index + 1);
        // } 
        // require(!exist, "have joined");
        self.playerList.set(self.playerQuantity, PlayerInfo{
            address: message.address,
            amount: ctx.value
        });
        self.playerQuantity = self.playerQuantity + 1;
        // if (self.playerQuantity >= self.conditionQuantity) {
        //     let winner: Address = self.drawWinner();
        //     let serviceCharge: Int = (myBalance() * 1) / 100;
        //     let amount: Int = myBalance() - context().value - self.minTonForStorage - serviceCharge;
        //     require(amount > 0, "Insufficient balance");
        //     send(SendParameters{
        //         to: winner,
        //         value: amount,
        //         mode: SendRemainingValue,
        //         bounce: true
        //     });
        //     send(SendParameters{
        //         to: self.father,
        //         value: 0,
        //         body: WinnerInfo{address: winner, seqno: self.seqno}.toCell(),
        //         mode: SendRemainingBalance,
        //         bounce: true
        //     });
        // }
    }

    receive(message: DrawInfo){
        let ctx: Context = context();
        require(self.father == sender(), "not father");
        let winner: Address = self.drawWinner();
        let serviceCharge: Int = (myBalance() * 1) / 100;
        let amount: Int = myBalance() - context().value * 2 - self.minTonForStorage - serviceCharge;
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: winner,
            value: amount,
            mode: SendRemainingValue,
            bounce: true
        });
        send(SendParameters{
            to: self.father,
            value: 0,
            body: WinnerInfo{address: winner, seqno: self.seqno}.toCell(),
            mode: SendRemainingBalance,
            bounce: true
        });
    }

    fun drawWinner(): Address {
        let randomPercent: Int = random(1, 100);
        let randomAmount: Int = randomPercent / 100 * myBalance();
        let calculateAmount: Int = 0;
        let winner: Address = newAddress(0, 0);
        let index: Int = 0;
        while (calculateAmount < randomAmount && index < self.playerQuantity) {
            let player: PlayerInfo = self.playerList.get(index)!!;
            calculateAmount = calculateAmount + player.amount;
            index = index + 1;
            winner = player.address;
        }
        return winner;
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun address(): Address {
        return myAddress();
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun father(): Address {
        return self.father;
    }

    get fun seqno(): Int {
        return self.seqno;
    }

    get fun playerList(): map<Int, PlayerInfo> {
        return self.playerList;
    }

    get fun playerQuantity(): Int {
        return self.playerQuantity;
    }

    get fun conditionQuantity(): Int {
        return self.conditionQuantity;
    }

}