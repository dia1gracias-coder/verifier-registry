import "@stdlib/deploy";
import "@stdlib/ownable";

contract LootBoxContract with Deployable, Ownable {

    const MIN_VALUE_ON_BALANCE: Int = ton("0.5");

    owner: Address;

    counter: Int as uint32 = 0;
    biggestWinner: Address? = null;
    biggestWin: Int as uint32 = 0;

    init(owner: Address) {
        self.owner = owner;
    }

    receive("withdraw") {
        if(self.owner == context().sender) {
            if(myBalance() > self.MIN_VALUE_ON_BALANCE) {
                send(SendParameters{
                    to: self.owner,
                    value: myBalance() - self.MIN_VALUE_ON_BALANCE, 
                    mode: SendRemainingValue, 
                    body: "Withdraw was made!".asComment()
                }); 
            }
        } else {
            send(SendParameters{
                to: context().sender,
                value: 0, 
                mode: SendRemainingValue, 
                body: "Owner only comand!".asComment()
            }); 
        }  
    }

    receive("play") {
        let ctx: Context = context();
        let to: Address = ctx.sender;
        let initValue: Int = ctx.value;

        let multiplier: Int = randMultiplier();
        let winValue: Int = initValue * multiplier / 100;

        let message: StringBuilder = beginString();
        if(myBalance() >= winValue) {

            self.counter = self.counter + 1;

            message.append("Game over! x");
            message.append(multiplierToString(multiplier));

            send(SendParameters{
                to: to,
                value: winValue, 
                mode: SendIgnoreErrors, 
                body: message.toString().asComment()
            });

            // update stats
            if(winValue > self.biggestWin) {
                self.biggestWin = winValue;
                self.biggestWinner = to;
            }
        } else {

            message.append("Not enought money in contract! (Win was ");
            message.append(nanoTonsToString(winValue));
            message.append(" TON)");

            send(SendParameters{
                to: to,
                value: 0, 
                mode: SendRemainingValue, 
                body: message.toString().asComment()
            }); 
        }
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun biggestWin(): Int {
        return self.biggestWin;
    }
}

    // returns value multiplied by 100
    fun randMultiplier(): Int { 
        let multiplier: Int = 0;
        let randomNumber: Int = random(0, 100);
        if(randomNumber >= 99) {
            multiplier = 1000;
        } else if(randomNumber > 90) {
            multiplier = 500;
        } else if(randomNumber > 75) {
            multiplier = 200;
        } else if(randomNumber > 50) {
            multiplier = 100;
        } else if(randomNumber > 25) {
            multiplier = 50;
        } else if(randomNumber > 10) {
            multiplier = 10;
        } else if(randomNumber > 0) {
            multiplier = 1;
        }
        return multiplier;
    }

    // returns multiplier string as a float number 
    fun multiplierToString(multiplier: Int): String  {
        let multiplierString: StringBuilder = beginString();

        multiplierString.append((multiplier / 100).toString());

        if((multiplier % 100) > 0) {
            multiplierString.append(".");
            multiplierString.append((multiplier % 100).toString());
        }

        return multiplierString.toString();
    }

    // returns multiplier string as a float number 
    fun nanoTonsToString(nanoTons: Int): String  {
        let nanoTonsString: StringBuilder = beginString();

        let fullTons: Int = nanoTons / ton("1");
        nanoTonsString.append(fullTons.toString());
        
        let partTons: Int = (nanoTons % ton("1")) / 1000000;
    
        if(partTons > 0) {
            nanoTonsString.append(".");
            nanoTonsString.append(partTons.toString());
        }

        return nanoTonsString.toString();
    }