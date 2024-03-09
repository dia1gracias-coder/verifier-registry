import "@stdlib/deploy";
import "@stdlib/ownable";

message JoinInfo {
    seqno: Int as uint128;
    quantity: Int as uint8;
}
message JoinChildInfo {
    seqno: Int as uint128;
    address: Address;
}
message PlayInfo {
    seqno: Int as uint128;
    quantity: Int as uint8;
}
message PlayChildInfo {
    seqno: Int as uint128;
    address: Address;
}
message DrawInfo {
    seqno: Int as uint128;
    quantity: Int as uint8;
}
message DrawChildInfo {
    seqno: Int as uint128;
    address: Address;
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
        require(message.quantity != null, "quantity can not empty");
        
        emit(message.toCell());
        
        let joinChildInfo: JoinChildInfo = JoinChildInfo{
            address: sender(),
            seqno: message.seqno
        };
        let init: StateInit = initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno, message.quantity);
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

    receive(message: PlayInfo) {
        
        let ctx: Context = context();
        
        require(ctx.value >= minAmount, "the value must be greater than 0.1");
        require(message.seqno != null, "seqno can not empty");
        require(message.quantity != null, "quantity can not empty");
        
        emit(message.toCell());
        
        let playChildInfo: PlayChildInfo = PlayChildInfo{
            address: sender(),
            seqno: message.seqno
        };
        let init: StateInit = initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno, message.quantity);
        send(SendParameters{
            to: contractAddress(init),
            body: playChildInfo.toCell(),
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
        require(message.quantity != null, "quantity can not empty");
        
        emit(message.toCell());
        
        let drawChildInfo: DrawChildInfo = DrawChildInfo{
            address: sender(),
            seqno: message.seqno
        };
        let init: StateInit = initOf LotteryPlayTactContract(self.owner, myAddress(), message.seqno, message.quantity);
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

    get fun balance(): String {
        return myBalance().toCoinsString();
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun transno(): Int {
        return self.transno;
    }

    get fun playAddress(seqno: Int, quantity: Int): Address {
        return contractAddress(initOf LotteryPlayTactContract(self.owner, myAddress(), seqno, quantity));
    }

}

contract LotteryPlayTactContract with Deployable {
    
    owner: Address;
    father: Address;
    seqno: Int as uint128;
    playerList: map<Int, PlayerInfo>;
    playerQuantity: Int as uint8;
    conditionQuantity: Int as uint8;
    winnerIndex: Int = 0;
    finished: Bool = false;
    
    init(owner: Address, father: Address, seqno: Int, quantity: Int){
        self.owner = owner;
        self.father = father;
        self.seqno = seqno;
        self.conditionQuantity = quantity;
        self.playerQuantity = 0;
    }

    receive(message: JoinChildInfo){
        
        let ctx: Context = context();
        
        require(self.father == sender(), "Access denied");
        require(ctx.value >= minAmount, "the value must be greater than 0.1");
        require(message.seqno != null, "seqno can not empty");
        require(message.address != null, "address can not empty");
        
        emit(message.toCell());
        
        if (self.isJoined(message.address) || self.finished) {
            emit("have joined".asComment());
            send(SendParameters{
                to: message.address,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true
            });
        } else {
            emit("joining".asComment());
            self.playerList.set(self.playerQuantity, PlayerInfo{
                address: message.address,
                amount: ctx.value
            });
            self.playerQuantity = self.playerQuantity + 1;
        }
    }

    receive(message: PlayChildInfo){
        
        let ctx: Context = context();
        
        require(self.father == sender(), "Access denied");
        require(ctx.value >= minAmount, "the value must be greater than 0.1");
        require(message.seqno != null, "seqno can not empty");
        require(message.address != null, "address can not empty");
        
        emit(message.toCell());
        
        if (self.isJoined(message.address) || self.finished) {
            emit("have joined".asComment());
            send(SendParameters{
                to: message.address,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: true
            });
        } else {
            emit("joining".asComment());
            self.playerList.set(self.playerQuantity, PlayerInfo{
                address: message.address,
                amount: ctx.value
            });
            self.playerQuantity = self.playerQuantity + 1;
            if (self.playerQuantity >= self.conditionQuantity) {
                let winner: Address = self.calculateWinner();
                let serviceCharge: Int = (myBalance() * 1) / 100;
                let amount: Int = myBalance() - context().value - minAmount - serviceCharge;
                if (amount <= 0) {
                    amount = 0;
                }
                send(SendParameters{
                    to: winner,
                    value: amount,
                    mode: SendRemainingValue + SendIgnoreErrors,
                    bounce: true
                });
                send(SendParameters{
                    to: self.owner,
                    value: 0,
                    mode: SendRemainingBalance + SendIgnoreErrors,
                    bounce: true
                });
            }
        }

    }

    receive(message: DrawChildInfo){
        
        let ctx: Context = context();
        require(self.father == sender(), "Access denied");
        emit(message.toCell());
        
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
            bounce: true
        });
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: true
        });
    }

    fun isJoined(address: Address): Bool {
        let index: Int = 0;
        let exist: Bool = false;
        while (!exist && index < self.playerQuantity) {
            let player: PlayerInfo = self.playerList.get(index)!!;
            if (player.address == address) {
                exist = true;
            }
            index = (index + 1);
        } 
        return exist;
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
        return myBalance().toCoinsString();
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

    get fun finished(): Bool {
        return self.finished;
    }

    get fun winner(): Address {
        let player: PlayerInfo = self.playerList.get(self.winnerIndex)!!;
        return player.address;
    }

}