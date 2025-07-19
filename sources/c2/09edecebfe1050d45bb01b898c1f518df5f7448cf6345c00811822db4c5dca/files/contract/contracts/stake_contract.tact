import "@stdlib/deploy";

message AddStake {
    amount: Int as uint32;
}
message Withdraw {
    amount: Int as uint32;
    target: Address;
}

message SetAdmin {
    newAdmin: Address;
}

message Drain {
    target: Address;
}

contract StakeContract with Deployable {
    totalStaked: Int; // as uint128
    admin: Address;
    balance: Int;
    
    const minTonForStorage: Int = ton("0.001");

    mapStakes: map<Address, Int>; 

    init(){
        self.totalStaked = 0;
        self.balance = 0;
        self.mapStakes = emptyMap();
        self.admin = sender();
        //self.admin = 'EQBGhqLAZseEqRXz4ByFPTGV7SVMlI4hrbs-Sps_Xzx01x8G'; //example
    }



    receive(msg: AddStake) {
        let user: Address = sender();
        let stakeAmount: Int = msg.amount;
        
        require(stakeAmount > 0, "Nothing to stake");
        require(msg.amount * 1000000000 < context().value, "Mismatch stake");

        // Get current stake
        //let current: Int = self.mapStakes.get(sender) 0; //?? 0
        // Получаем опциональный предыдущий стейк
        let prevOpt = self.mapStakes.get(user);
        // Распаковываем nullable Int
        let current: Int = 0;
        if (prevOpt == null) {
            current = 0;
        } else {
            current = prevOpt!!;
        }


        // Update mapping and total
        self.mapStakes.set(user, current + stakeAmount); 
        self.totalStaked += stakeAmount;
        self.balance += stakeAmount;
        //cashback(sender());
    }

    receive(msg: Withdraw) {
        require(sender() == self.admin, "Only admin");
        require(self.balance >= msg.amount, "We're bunkrupt");
        self.balance -= msg.amount;
        send(SendParameters{
            to: msg.target,
            value: msg.amount,
            mode: SendRemainingValue + SendIgnoreErrors,
            //body: //Deposit{amount: msg.amount}.toCell()
        });
    }
    //bounced(){}
receive("drain"){
    require(sender() == self.admin, "Only admin");
    send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            //body: Deposit{amount: msg.amount}.toCell()
        });
self.balance = 0;
}

    // Эмердженси-дрейн: сливаем всё на admin
    receive(msg: Drain) {
        //require(sender() == self.admin, "Only admin");
        //let amount = self.balance  * 1000000000- context().value - self.minTonForStorage; //much less than 0
        let amount = self.balance - 1;
        send(SendParameters{
            to:    sender(),
            value: amount,//amount,
            bounce: true,
            mode:  SendRemainingBalance + SendIgnoreErrors //SendRemainingValue
        });
        self.balance -= amount;
        self.reply("drained".asComment())
    }

// Изменить администратора может только текущий admin
    receive(msg: SetAdmin) {
        require(sender() == self.admin, "Only admin");
        self.admin = msg.newAdmin;
    }


    get fun userStake(key: Address):  Int? {
        return self.mapStakes.get(key);
    }
    get fun allStakes(): map<Address, Int>{
        return self.mapStakes;
    }
    get fun totalStaked(): Int{
        return self.totalStaked;
    }
    get fun balance(): Int{
        return self.balance;
    }
}

/*
Основная логика:
stake() — принимает входящий TON и фиксирует его стейк за юзером.
// accept funds from user and increase stake
receive("stake") {
    let value = msg.value;
    let sender = sender();

    // Get current stake
    let current = self.stakes.get(sender) ?? 0;

    // Update mapping and total
    self.stakes.set(sender, current + value);
    self.totalStaked += value;
}

withdraw() — позволяет юзеру снять ранее застейканные токены. (Withdraw-Admin)
// user initiates withdraw
receive("withdraw") {
    let sender = sender();
    let stake = self.stakes.get(sender) ?? 0;

    require(stake > 0, "Nothing to withdraw");

    // Clear storage and decrease TVL
    self.stakes.set(sender, 0);
    self.totalStaked -= stake;

    // Send back the funds
    send(sender, stake);
}

getUserStake(address) — view-функция, чтобы узнать баланс стейка. (?)
getTotalStake() — view-функция, чтобы показать TVL. (?)

VALID CODE:
message StakeAI {
    amount: Int as uint32;
}

    // Приём любых входящих транзакций без тела — это stake()
    receive(msg: StakeAI) {
        let amount = msg.amount; //value
        require(amount > 0, "Empty stake");

        let user = sender();
        // Получаем опциональный предыдущий стейк
        let prevOpt = self.mapStakes.get(user);
        // Распаковываем nullable Int
        let current: Int = 0;
        if (prevOpt == null) {
            current = 0;
        } else {
            current = prevOpt!!;
        }
        // Калькулируем новый стейк
        let updated = current + amount;
        self.mapStakes.set(user, updated);
        self.totalStaked += amount;
        self.balance += amount;
    }
*/