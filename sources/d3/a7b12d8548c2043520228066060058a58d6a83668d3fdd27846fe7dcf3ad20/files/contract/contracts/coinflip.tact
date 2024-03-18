/*import "@stdlib/deploy";
message MakeBet {
    side: Int;
    amount: Int as coins;
}
message GamePlayedEvent {
    player: Address;
    amount: Int as coins;
    isWin: Bool;
}

contract Coinflip with Deployable {
    const MIN_TON_FOR_STORAGE: Int = ton("0.01"); // 1kb for 2.5year
    owner: Address;
    testvar: Int = 0;
    init(){
        self.owner = sender();
       // self.testvar += 1;
    }

     fun onlyOwner() {
        require(sender() == self.owner, "only owner");
    }

    receive(){}

    receive(msg: MakeBet){
        let ctx: Context = context();
        let amount: Int = ctx.value;
        require(msg.amount < ton("1"), "Max bet 1 TON");
        let winAmount: Int = (msg.amount * 8000 / 10000 + msg.amount);
        require((myBalance() - self.MIN_TON_FOR_STORAGE) >= winAmount, "Not enought funds");
        let randomNumber: Int = randomInt();
        //dump(randomNumber);
        let side: Int = randomNumber % 2;
        if (msg.side == side) {
            send(SendParameters{
                    to: sender(),
                    value: winAmount, //сколько тонов отправляем
                    mode: (SendRemainingValue + SendIgnoreErrors),
                    body: "You Win!".asComment()
                }
            );
            emit(GamePlayedEvent{player: sender(), amount: ton("1.25"), isWin: true}.toCell());
        } else {
            //не угадал
            send(SendParameters{
                    to: sender(),
                    value: (amount - msg.amount), //сколько тонов отправляем
                    mode: (SendRemainingValue + SendIgnoreErrors),
                    body: "You loose!".asComment()
                }
            );
            emit(GamePlayedEvent{player: sender(), amount: ton("1.25"), isWin: false}.toCell());
        }
    }

    receive("Withdraw all safe"){
        self.onlyOwner();
        send(SendParameters{
                to: sender(),
                value: ((myBalance() - context().value) - self.MIN_TON_FOR_STORAGE), //сколько тонов отправляем
                mode: (SendIgnoreErrors + SendRemainingValue) // SendRemainingValue означает что отправленные для этой транзакции тоны (fee) будет отправлен сендеру
            }
        );
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }



    get fun rand(): Int {
        let randomNumber: Int = randomInt();
        return randomNumber;
    }
}*/

import "@stdlib/deploy";

contract Coinflip with Deployable {
    const MIN_TON_FOR_STORAGE: Int = ton("0.01"); // 1kb for 2.5year
    owner: Address;
    test: Int;
    init(){
        self.owner = sender();
        self.test = 10;
    }

     fun onlyOwner() {
        require(sender() == self.owner, "only owner");
    }

    receive("click"){
        let ctx: Context = context();
        let amount: Int = ctx.value;
        let randomNumber: Int = randomInt();
        //dump(randomNumber);
        let sb: StringBuilder = beginString();
        sb.append("Number is: ");
        sb.append(randomNumber.toString());
        send(SendParameters{
                to: sender(),
                value: 0, //сколько тонов отправляем
                mode: (SendRemainingValue + SendIgnoreErrors),
                body: sb.toString().asComment()
            }
        );
    }

    get fun rand(): Int {
        let randomNumber: Int = randomInt();
        return randomNumber;
    }
}