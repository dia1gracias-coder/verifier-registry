import "@stdlib/deploy";

message Withdraw {
    amount: Int as coins;
}

message Deposit {
}

contract SpinWheel with Deployable {
    owner: Address;
    userBettingAmount : map<Address, Int>;
    userWinNumber : map<Address, Int>;
    const MinSpinAmount:Int =ton("0.5");
    const MinTonForStorage: Int = ton("0.01"); // enough for 1 KB of storage for 2.5 years
    
    init(owner: Address) {
        self.owner = owner;
        self.userBettingAmount=emptyMap();
        self.userWinNumber=emptyMap();
    }

    
    receive("Deposit") {
        let amount: Int = 0;
        if (self.userBettingAmount.get(sender()) != null) {
            amount = self.userBettingAmount.get(sender())!! + context().value;
        }
        self.userBettingAmount.set(sender(),amount);
    }

    receive("Spin") {
        if (self.userBettingAmount.get(sender()) != null) {
            let userAmount: Int = self.userBettingAmount.get(sender())!!;
            if (userAmount >= self.MinSpinAmount) {
                let winNum: Int = self.winning();
                if (winNum <= 10 && winNum % 2 == 1) {
                    self.userBettingAmount.set(sender(),userAmount*2);
                } else if (winNum % 2 == 0) {
                    self.userBettingAmount.set(sender(),0);
                }
                self.userWinNumber.set(sender(), winNum);
                self.reply(winNum.toString().asComment());
                return;
            }
        }
        self.userWinNumber.set(sender(), -1);
    }

    // this will withdraw the entire balance of the contract and leave 0
    receive("withdraw all") {
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    // this will withdraw a specific amount but leave 0.01 for storage rent costs
    receive(msg: Withdraw) {
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    get fun userBalance(address: Address): Int {
        if (self.userBettingAmount.get(address) != null) {
            return self.userBettingAmount.get(address)!!;
        }
        return 0;
    }

    get fun getLastSpin(address: Address): Int {
        if (self.userWinNumber.get(address) != null) {
            return self.userWinNumber.get(address)!!;
        }
        return -2;
    }
 
    fun winning(): Int {
        let rndNum: Int = random(0,1000);
        if (rndNum>=306) {
            let tempwinindex: Int = random(0,12);
            if (tempwinindex > 10) {
                return 8;
            } else if (tempwinindex > 8) {
                return 6;
            } else if (tempwinindex > 6) {
                return 4;
            } else if (tempwinindex > 4) {
                return 2;
            }else if (tempwinindex > 1) {
                return 0;
            } else {
                return 10;
            }
        } else {
            let tempwinindex: Int = random(0,12);
            if (tempwinindex > 10) {
                return 11;
            } else if (tempwinindex > 8) {
                return 9;
            } else if (tempwinindex > 6) {
                return 7;
            } else if (tempwinindex > 4) {
                return 5;
            } else if (tempwinindex > 2) {
                return 3;
            } else {
                return 1;
            }
        }
    }


}