import "@stdlib/deploy";
import "@stdlib/ownable";

struct UserStats {
    counter: Int as uint32;
    biggestWin: Int as uint256;
    lastWin: Int as uint256;
} 

contract LootBoxContract with Deployable, Ownable {

    const MIN_VALUE_ON_BALANCE: Int = ton("0.5");
    const WITHDRAW_FEE: Int = ton("0.05");

    owner: Address;

    usersStats: map<Address, UserStats>;
    globalStats: UserStats;

    init(owner: Address) {
        self.owner = owner;
        self.usersStats = emptyMap();
        self.globalStats = UserStats {
            counter: 0,
            biggestWin: 0,
            lastWin: 0
        };
    }

    receive("withdraw") {
        self.requireOwner();
        if(myBalance() > self.MIN_VALUE_ON_BALANCE) {
            send(SendParameters {
                to: self.owner,
                value: myBalance() - self.MIN_VALUE_ON_BALANCE, 
                mode: SendIgnoreErrors
            }); 
        } 
    }

    receive("top_up_balance") {
        self.requireOwner();
    }

    receive("withdraw_all") {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: 0, 
            mode: SendRemainingBalance
        }); 
    }

    receive("play") {
        let ctx: Context = context();
        let sender: Address = ctx.sender;

        let multiplier: Int = randMultiplier();
        let winValue: Int = ctx.value * multiplier / 100;

        let message: StringBuilder = beginComment();
        if(myBalance() - self.WITHDRAW_FEE >= winValue) {
            // send
            message.append("Game over! x");
            message.append(multiplier.toFloatString(2));
            send(SendParameters {
                to: sender,
                value: winValue, 
                mode: SendIgnoreErrors, 
                body: message.toCell()
            });

            // update user stats
            if(self.usersStats.get(sender) != null) {
                let userStats: UserStats = self.usersStats.get(sender)!!;
                let biggestUserWin: Int = userStats.biggestWin;
                if(winValue > biggestUserWin) {
                    biggestUserWin = winValue;
                }
                self.usersStats.set(sender, UserStats{ 
                    counter: userStats.counter + 1,  
                    biggestWin: biggestUserWin,
                    lastWin: winValue
                });
            } else {
                self.usersStats.set(sender, UserStats{ 
                    counter: 1,  
                    biggestWin: winValue,
                    lastWin: winValue
                });
            }
        
            // update global stats
            let biggestGlobalWin: Int = self.globalStats.biggestWin;
            if(winValue > biggestGlobalWin) {
                biggestGlobalWin = winValue;
            }
            self.globalStats = UserStats {
                counter: self.globalStats.counter + 1,
                biggestWin: biggestGlobalWin,
                lastWin: winValue
            };
        } else {
            message.append("Not enought money in contract! (Win was ");
            message.append(winValue.toFloatString(9));
            message.append(" TON)");
            send(SendParameters{
                to: sender,
                value: 0, 
                mode: SendRemainingValue, 
                body: message.toCell()
            }); 
        }
    }

    get fun userStats(address: Address): UserStats? {
       return self.usersStats.get(address);
    }

    get fun globalStats(): UserStats {
       return self.globalStats;
    }
}

fun randMultiplier(): Int { 
    let multiplier: Int = 0;
    let randomNumber: Int = random(0, 100);    
    if(randomNumber >= 80) {
        multiplier = 1000; 
    } else if(randomNumber > 70) {
        multiplier = 500;
    } else if(randomNumber > 50) {
        multiplier = 200;
    } else if(randomNumber > 30) {
        multiplier = 100;
    } else if(randomNumber > 20) {
        multiplier = 50;
    } else if(randomNumber > 10) {
        multiplier = 10;
    } else if(randomNumber > 0) {
        multiplier = 1;
    }

    if(randomNumber >= 90) {
        let secondMultiplier: Int = randMultiplier();
        multiplier = multiplier + secondMultiplier;
    }

    return multiplier;
}