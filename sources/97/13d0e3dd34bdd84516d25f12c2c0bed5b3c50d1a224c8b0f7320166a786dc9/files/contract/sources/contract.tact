import "@stdlib/deploy";

contract Lottery with Deployable {

    const MinTonForStorage: Int = ton("0.05");
    owner: Address;
    address: map<Address, Bool>;
    lenght: Int;
    participants: Int;

    init(owner: Address) {
        self.owner = owner;
        self.address = emptyMap();
        self.lenght = 0;
        self.participants = 4;
    }

    fun saveSender() {
        let ctx: Context = context();
        self.address.set(ctx.sender, true);
        self.lenght += 1;
    }

    fun checkingTheStartOfTheLottery(): Bool {
        if (self.lenght >= 3) {
            return true;
        }
        return false;
    }

    fun getWinner(): Address {
        let randomKey = random(1, self.lenght);
        let inc = 1;

        foreach (key, value in self.address) {
            if (inc == randomKey) {
                return key;
            }
            inc += 1;
        }
        return self.owner;
    }

    fun reset() {
        self.address = emptyMap();
        self.lenght = 0;
    }

    receive() {
        // // let ctx: Context = context();
        // if (ctx.sender == self.owner && loadMessage().toString() != "") {
        //     self.participants = loadMessage().toInt();
        //     return;
        // }
        self.saveSender();
        if (self.checkingTheStartOfTheLottery()) {
            let winner = self.getWinner();
            // Отправка выигрыша
            let totalValue = myBalance() - self.MinTonForStorage;
            let ownerShare = totalValue / 10; // 10% от выигрыша
            let winnerShare = totalValue - ownerShare;

            // Отправка 10% владельцу
            send(SendParameters{
                to: self.owner,
                value: ownerShare,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "Owner share".asComment(),
            });

            // Отправка оставшейся части победителю
            send(SendParameters{
                to: winner,
                value: winnerShare,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "You winner".asComment(),
            });

            self.reset();
        }
    }

    // Добавляем метод для получения текущего значения participants
    fun getParticipants(): Int {
        return self.participants;
    }
}