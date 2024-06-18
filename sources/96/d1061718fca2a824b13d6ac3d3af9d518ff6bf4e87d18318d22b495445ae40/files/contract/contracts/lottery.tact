import "@stdlib/ownable";
import "@stdlib/deploy";

message Withdraw{
    amount: Int as uint32;
}

contract Lottery with Ownable, Deployable {
    const sendModeCommentOnly: Int = 1 | 2;

    owner: Address;
    winPercent: Int as uint8 = 45;

    init(owner: Address, winPercent: Int) {
        self.owner = owner;
        if (winPercent>=0) {
            self.winPercent = winPercent;
        }
    }

    receive() {
        let ctx: Context = context();
        let betAmount: Int = ctx.value;

        if (betAmount < 100000000 || betAmount > 1000000000){
            self.reply("Bet amount must be between 0.1 TON and 1 TON".asComment());

           return;
        }

        let potentialWinAmount: Int = betAmount * 2;
        if (myBalance()<=potentialWinAmount){
            self.reply("Insufficient funds in contract to cover potential win".asComment());

            return;
        }

        let randomValue: Int = random(0,100);
        let isWin: Bool = ( randomValue < self.winPercent );

        if (!isWin) {
            send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: self.sendModeCommentOnly,
                body: "You Lose!".asComment()
            });

            return;
        }

        send(SendParameters{
            to: ctx.sender,
            value: potentialWinAmount,
            mode: self.sendModeCommentOnly,
            body: "You Win!".asComment()
        });

    }

    receive(s: String) {}
    receive(s: Slice) {}

    receive("withdraw") {
        self.requireOwner();

        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
            body: "Withdraw successful!".asComment()
        });
    }


    get fun balance(): Int{
        return myBalance();
    }
}


