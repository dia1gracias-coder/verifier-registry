struct Array {
    m: map<Int as uint10, Address>;
    length: Int = 0;
}
struct PoolInfo {
    balance: Int as coins;
    timer: Int as uint32;
    lastSender: Address;
    winner: Address;
    currentVipNumber: Int as uint8;
    winnerPrize: Int as coins;
    isCounterReset: Bool;
}
contract ForeverTonContract {
    counter: Int as uint35 = 0;
    owner: Address;
    vipAddress: Array = Array {
            m: emptyMap()
        };
    vipNumber: Int as uint8 = 250;
    lastSender: Address;
    winner: Address;
    startTime: Int = 0;
    winnerPrize: Int as coins = 0;
    init(){
        self.owner = sender();
        self.lastSender = self.owner;
        self.winner = self.owner;
    }
    receive() {
        if(sender() == self.owner){
            cashback((self.owner));
            return;
        }
        require(context().value >= ton("1"), "At least 1 TON is required");
        if (self.counter < self.vipNumber) {
            self.vipAddress.m.set(self.vipAddress.length, sender());
            self.vipAddress.length += 1;
        } else {
            if(self.counter == self.vipNumber){
                self.winnerPrize = 0;
                self.startTime = now();
            }
            if(self.startTime + 3600 * 24 + (self.counter - self.vipNumber) * 60 - now() <= 0){
                let finalPriceWinner = myBalance() * 9 / 10;
                let finalPriceVip = myBalance() * 5 / 100 / (self.vipNumber + 1);
                message(MessageParameters{
                    to: self.lastSender,
                    value: finalPriceWinner,
                });
                foreach (key, value in self.vipAddress.m) { 
                    message(MessageParameters{
                        to: value,
                        value: finalPriceVip,
                    });
                }
                message(MessageParameters{
                    to: sender(),
                    value: finalPriceVip,
                });
                self.winner = self.lastSender;
                self.lastSender = sender();
                self.counter = self.vipNumber;
                self.winnerPrize = finalPriceWinner;
                return;
            }else{
                let fee = context().value * 3 / 10;
                message(MessageParameters{
                    to: self.owner,
                    value: fee
                });
                self.lastSender = sender();
            }
        }
        self.counter += 1;
    }

    get fun timer(): Int{
        if (self.counter <= self.vipNumber){
            return 0;
        }else{
            return self.startTime + 3600 * 24 + (self.counter - self.vipNumber) * 60;
        }
    }
    get fun vipAddress(): map<Int as uint10, Address> {
        return self.vipAddress.m;
    }
    get fun poolInfo() : PoolInfo{
        return PoolInfo {
            balance: myBalance(), 
            timer: self.timer(),
            lastSender: self.lastSender,
            winner: self.winner,
            currentVipNumber: self.vipAddress.length,
            winnerPrize: self.winnerPrize,
            isCounterReset: self.counter <= self.vipNumber
            }
    }
}
