import "@stdlib/deploy";
import "@stdlib/ownable";

message JoinInfo {
    seqno: Int as uint128;
}
message JoinChildInfo {
    seqno: Int as uint128;
    address: Address;
}
message DrawInfo {
    seqno: Int as uint128;
}
message DrawChildInfo {
    seqno: Int as uint128;
    address: Address;
}
message TakeInfo {
    receiver: Address;
}
struct PlayerInfo {
    address: Address;
    amount: Int as uint128;
}

const minAmount: Int = ton("0.1");

contract LotteryStartTactContract with Deployable {
    
    owner: Address;
    transno: Int as uint128;

    init(owner: Address, transno: Int) {
        self.owner = owner;
        self.transno = transno;
    }

    receive(message: JoinInfo) {
        
        let ctx: Context = context();
        
        require(ctx.value >= minAmount, "the value must be greater than 0.1");
        require(message.seqno != null, "seqno can not empty");
        
        emit(message.toCell());
        
        let joinChildInfo: JoinChildInfo = JoinChildInfo{
            address: sender(),
            seqno: message.seqno
        };
        let init: StateInit = initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno);
        send(SendParameters{
            to: contractAddress(init),
            body: joinChildInfo.toCell(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            code: init.code,
            data: init.data
        });
    }

    receive(message: DrawInfo) {
        
        require(sender() == self.owner, "Access denied");
        require(message.seqno != null, "seqno can not empty");
        
        emit(message.toCell());
        
        let drawChildInfo: DrawChildInfo = DrawChildInfo{
            address: sender(),
            seqno: message.seqno
        };
        let init: StateInit = initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno);
        send(SendParameters{
            to: contractAddress(init),
            body: drawChildInfo.toCell(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            code: init.code,
            data: init.data
        });
    }

    receive("recharge"){
        dump(context().value.toCoinsString());
        emit("recharge".asComment());
    }

    receive("recycle") {
        require(sender() == self.owner, "Access denied");
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: true,
            body: "recycle".asComment()
        });
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }

}

contract LotteryPlayTactContract with Deployable {
    
    owner: Address;
    father: Address;
    seqno: Int as uint128;
    playerList: map<Int, PlayerInfo>;
    playerQuantity: Int as uint8;
    winnerIndex: Int = 0;
    finished: Bool = false;
    tonQuantity: Int as uint128 = 0;
    
    init(owner: Address, father: Address, seqno: Int){
        self.owner = owner;
        self.father = father;
        self.seqno = seqno;
        self.playerQuantity = 0;
    }

    receive(message: JoinChildInfo){
        
        let ctx: Context = context();
        
        require(self.father == sender(), "Access denied");
        require(ctx.value >= minAmount, "the value must be greater than 0.1");
        require(message.seqno != null, "seqno can not empty");
        require(message.address != null, "address can not empty");
        
        emit(message.toCell());

        if (self.finished) {
            emit("It's already over".asComment());
            send(SendParameters{
                to: message.address,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true,
                body: "It's already over".asComment()
            });
            return;
        }
        
        emit("joining".asComment());
        self.playerList.set(self.playerQuantity, PlayerInfo{
            address: message.address,
            amount: ctx.value
        });
        self.playerQuantity = self.playerQuantity + 1;
        self.tonQuantity = myBalance();
    }

    receive(message: DrawChildInfo){
        
        let ctx: Context = context();
        require(self.father == sender(), "Access denied");
        emit(message.toCell());

        if (self.finished) {
            emit("It's already over".asComment());
            send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: true,
                body: "It's already over".asComment()
            });
            return;
        }

        if (self.playerQuantity == 0) {
            emit("nobody joined yet".asComment());
            self.finished = true;
            self.playerList = emptyMap();
            self.playerQuantity = 0;
            send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: true,
                body: "service charge, nobody joined".asComment()
            });
        } else {
            self.tonQuantity = myBalance();
            let winner: Address = self.calculateWinner();
            let serviceCharge: Int = (myBalance() * 1) / 100;
            let amount: Int = myBalance() - context().value - minAmount - serviceCharge;
            if (amount <= 0) {
                amount = 0;
            }
            send(SendParameters{
                to: winner,
                value: amount,
                mode: SendIgnoreErrors,
                bounce: true,
                body: "win bonus".asComment()
            });
            send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: true,
                body: "service charge".asComment()
            });
        }
    }

    receive(message: TakeInfo) {
        require(sender() == self.owner, "Access denied");
        send(SendParameters{
            to: message.receiver,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: true,
            body: "take success".asComment()
        });
    }

    fun calculateWinner(): Address {
        let precent: Int = random(1, 100);
        let randomAmount: Int = myBalance() * precent / 100;
        let calculateAmount: Int = 0;
        let winner: Address = newAddress(0, 0);
        let index: Int = 0;
        while (calculateAmount < randomAmount && index < self.playerQuantity) {
            let player: PlayerInfo = self.playerList.get(index)!!;
            calculateAmount = calculateAmount + player.amount;
            index = index + 1;
            winner = player.address;
        }
        self.finished = true;
        self.winnerIndex = index - 1;
        return winner;
    }

    get fun balance(): String {
        let current: Int = myBalance();
        if (current <= 0) {
            return self.tonQuantity.toCoinsString();
        } else {
            return myBalance().toCoinsString();
        }
    }

    get fun father(): Address {
        return self.father;
    }

    get fun playerList(): map<Int, PlayerInfo> {
        return self.playerList;
    }

    get fun playerQuantity(): Int {
        return self.playerQuantity;
    }

    get fun finished(): Bool {
        return self.finished;
    }

    get fun winner(): Address {
        if (self.playerQuantity == 0) {
            return newAddress(0, 0);
        }
        let player: PlayerInfo = self.playerList.get(self.winnerIndex)!!;
        return player.address;
    }

    get fun tonQuantity(): String {
        return self.tonQuantity.toCoinsString();
    }

}