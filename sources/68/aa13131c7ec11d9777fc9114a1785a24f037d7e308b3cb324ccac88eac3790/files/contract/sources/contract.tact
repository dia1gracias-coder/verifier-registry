import "@stdlib/deploy";
import "@stdlib/ownable";

contract LootBoxContract with Deployable, Ownable {

    owner: Address;
    counter: Int as uint32 = 0;

    lastWinner: Address?;
    lastMultiplier: Int = 0;
    lastGameAmount: Int = 0;

    init(owner: Address) {
        self.owner = owner;
    }

    receive("withdraw") {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: myBalance(), 
            mode: SendIgnoreErrors, 
            body: "Withdraw was made!".asComment()
        }); 
    }

    receive("play") {
        let ctx: Context = context();
        let to: Address = ctx.sender;

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

        let value: Int = ctx.value * multiplier / 100;

        if(myBalance() >= value) {
            send(SendParameters{
                to: to,
                value: value, 
                mode: SendIgnoreErrors, 
                body: "Game over!".asComment()
            });
        } else {
            send(SendParameters{
                to: to,
                value: 0, 
                mode: SendRemainingValue, 
                body: "Not enought money in contract!".asComment()
            }); 
        }
    }
}