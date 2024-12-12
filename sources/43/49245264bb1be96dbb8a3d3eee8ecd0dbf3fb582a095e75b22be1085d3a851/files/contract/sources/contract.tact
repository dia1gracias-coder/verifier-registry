import "@stdlib/deploy";
import "@stdlib/ownable";

//TODO: undefined behaviour when participantsNum is less than NumberOfWinners
contract Lottery with Deployable {

    const NumberOfWinners: Int = 3;

    maxParticipants: Int;
    depositDeadline: Int as uint32;

    participants: map<Int, Address>; 
    participantsNum: Int as uint8 = 0;

    init(depositDeadline: Int, maxParticipants: Int) {
        self.depositDeadline = depositDeadline;
        // shouldn't be too big, due to gas consumption
        self.maxParticipants = maxParticipants;
    }

    fun sendRewards() {
        let winnersNum: Int = 0;
        let totalPrize = myBalance() - context().value;

        while (winnersNum != self.NumberOfWinners) {
            let random: Int = random(0, self.participantsNum);
            let winner = self.participants.get(random);

            if (winner != null) {

                let percent: Int = 50;
                if (winnersNum == 1) {
                    percent = 30;
                } else if (winnersNum == 2) {
                    percent = 20;
                }
                let amountToSend: Int = totalPrize * percent / 100;

                winnersNum = winnersNum + 1;

                send(SendParameters{
                    to: winner!!,
                    bounce: false,
                    value: amountToSend,
                    mode: 0 + SendIgnoreErrors
                });

                self.participants.del(random);
            }
        }
        
        self.notify("refund".asComment());

    }

    receive() {
        if(now() <= self.depositDeadline && self.participantsNum < self.maxParticipants) {
            self.participants.set(self.participantsNum, sender());
            self.participantsNum = self.participantsNum + 1;
        } else {
            self.sendRewards();
        } 
    }

    get fun balance(): Int {
        return myBalance();
    }

}