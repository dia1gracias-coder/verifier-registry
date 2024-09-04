import "@stdlib/deploy";
import "@stdlib/stoppable";
import "@stdlib/ownable";
import "./userChoice.tact";

// -------------------------------------------------------------

message Bet {
    choice: Bool; // 0-False, 1-True
}

contract MrBit with Deployable, Ownable, Resumable {
    owner: Address;
    stopped: Bool;
    fees: Int as uint32;
    players: map<Address, Address>;
    init(ow: Address){
        self.owner = ow;
        self.stopped = false;
        self.fees = 0;
        self.players = emptyMap();
    }

    receive(){
        dump("empty message received");
    }

    receive(str: String){
        dump("String message received");
    }

    receive(msg: Bet){
        let ctx: Context = context();
        let betAmount: Int = ctx.value;
        
        require(myBalance() > betAmount, "Insufficient reward pool balance");

        commit();
        
        let initUserChoiceContract: StateInit = initOf UserChoice(ctx.sender);
        let userChoiceContractAddress: Address = contractAddress(initUserChoiceContract);
        
        nativeRandomizeLt();
        let randomNumber: Int = randomInt();
        let randomNumberFlipped: Int = randomNumber % 2;
        
        if (randomNumberFlipped == 1 && msg.choice == true || randomNumberFlipped == 0 && msg.choice == false) {
            let to: Address = ctx.sender;
            let value: Int = betAmount + ((betAmount * 99) / 100);
            self.fees += betAmount / 100;
            send(SendParameters{to: to, value: value, mode: SendIgnoreErrors});
        } else {
            self.fees += betAmount / 100;
            dump(self.fees);
        }

        if (self.players.get(ctx.sender)==null) {
            send(SendParameters{
                    to: userChoiceContractAddress,
                    value: ton("0.1"),
                    mode: SendIgnoreErrors,
                    bounce: true,
                    body: BetResult{
                        choice: msg.choice,
                        win: randomNumberFlipped == 1 &&
                            msg.choice == true ||
                            randomNumberFlipped == 0 &&
                            msg.choice == false,
                        timestamp: now()
                    }.toCell(),
                    code: initUserChoiceContract.code, // attaching the state init will cause the message to deploy
                    data: initUserChoiceContract.data
                }
            );
            self.players.set(ctx.sender, userChoiceContractAddress);
        } else {
            send(SendParameters{
                    to: userChoiceContractAddress,
                    value: ton("0.1"),
                    mode: SendIgnoreErrors,
                    bounce: true,
                    body: BetResult{
                        choice: msg.choice,
                        win: randomNumberFlipped == 1 &&
                            msg.choice == true ||
                            randomNumberFlipped == 0 &&
                            msg.choice == false,
                        timestamp: now()
                    }.toCell()
                }
            );
        }
    }

    receive("wfees"){
        self.requireOwner();
        let value: Int = self.fees;
        send(SendParameters{
                to: self.owner,
                value: value,
                mode: SendIgnoreErrors,
                bounce: true,
                body: "Sent the Fees!".asComment()
            }
        );
        self.fees = 0;
    }

    receive("wa"){
        self.requireOwner();
        send(SendParameters{
                to: self.owner,
                value: 0,
                mode: SendIgnoreErrors | SendRemainingBalance,
                bounce: true,
                body: "Sent the all balance!".asComment()
            }
        );
        self.fees = 0;
    }

    get fun fees(): String {
        return self.fees.toCoinsString();
    }

    get fun userHistory(player: Address): Address? {
        return self.players.get(player);
    }
}