import "@stdlib/deploy";
import "@stdlib/stoppable";
import "@stdlib/ownable";

message Withdraw {
    amount: Int as coins;
}

message Income {
    goal: String;
    id: Int as uint32;
    for: Int? as uint32; // мета данные userFor
}

struct Payment {
    sender: Address;
    goal: String;
    value: Int as coins;
    date: Int as uint32;
    id: Int as uint32; // мета user_id
    for: Int? as uint32; // мета данные userFor
}

message Clear {
    itemNumb: Int;
}

contract MeetTon with Deployable, OwnableTransferable, Resumable {
    const MinTonForStorage: Int = ton("0.01");

    owner: Address;
    stopped: Bool;
    payments: map<Int, Payment>;
    arrLength: Int = 0;

    init() {
        self.owner = sender();
        self.stopped = false;
    }

    receive(inc: Income){
        self.requireNotStopped();

        let item: Payment = Payment{for: inc.for, id: inc.id, goal: inc.goal, value: context().value, sender: sender(), date: now()};

        self.payments.set(self.arrLength, item);
        self.arrLength = self.arrLength + 1;
    }

    receive("withdraw safe"){
        self.requireOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.MinTonForStorage, // баланс - деньги указаные в сообщении - минус минимальные бабки на ресурсы
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: Withdraw){
        // вывод конкретной суммы
        self.requireOwner();
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(amount>0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: Clear) {
        self.requireOwner();
        require(self.arrLength == msg.itemNumb, "You have more unresolved transactions");
        // хак, чтобы никогда не потерять последние транзакции
        // нужно проверить, что перед удалением ты знал все платежи которые были
        // если изменится, то есть необработанные транзакции

        self.payments = emptyMap();
        self.arrLength = 0;
    }

    receive("clear") {
        self.requireOwner();

        self.payments = emptyMap();
        self.arrLength = 0;
    }

    get fun balance(): Int{
        return myBalance();
    }

    get fun myAddress(): Address {
        return myAddress();
    }

    get fun payment(key: Int): Payment?{
        return self.payments.get(key);
    }

    get fun payments(): map<Int, Payment> {
        return self.payments;
    }

    get fun length(): Int {
        return self.arrLength;
    }
}
