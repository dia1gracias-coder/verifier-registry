import "@stdlib/deploy";

struct PollInit {
    master: Address;
    creator:Address;
    pollId: Int as uint32;
    optionsCount: Int as int8;
}

message DeployNewPollContract {
    optionsCount: Int as int8;
}

contract PollFactory {
    nextPollId: Int as uint32 = 0;

    receive() {
        cashback(sender());
    }

    receive(msg: DeployNewPollContract) {
        let pollInit = initOf Poll(PollInit {
            master: myAddress(),
            creator:sender(),
            pollId: self.nextPollId,
            optionsCount: msg.optionsCount,
        });

        deploy(DeployParameters {
            init: pollInit,
            mode: SendRemainingValue,
            value: 0,
        });

        self.nextPollId += 1;
    }

    get fun nextPollId(): Int { return self.nextPollId; }

}

message Vote {
    optionIndex: Int as int8;
}
message EndPoll {
    winnerIndex: Int as int8;
}

struct PollState {
    pots: map<Int, Int as uint128>;
    totalBets: Int as uint128;
    userBets: map<Address, UserBets>;
}

struct UserBets {
    bets: map<Int, Int as uint128>;
}

contract Poll {
    const MinTonForStorage: Int = 1;
    const TonToNanoTonMultiplier: Int = ton("1");
    optionsCount: Int as int8;
    pots: map<Int, Int as uint128>;
    userBets: map<Address, UserBets>;
    totalBets: Int as uint128 = 0;


    master:Address;
    creator:Address;
    pollId: Int as uint32;

    pollEnded: Bool = false;
    winnerIndex: Int as int8 = -1;

    init(data: PollInit) {
        self.master = data.master;
        self.creator = data.creator;
        self.pollId = data.pollId;
        self.optionsCount = data.optionsCount;

        // initialize pots array
        let x = 0;
        repeat(self.optionsCount) {
            self.pots.set(x,0);
            x += 1;
        }
    }

    receive() {
        cashback(sender());
    }

    receive(msg: Vote){
        let sender = sender();

        //initialize user bets if not exists
        if (!self.userBets.exists(sender)) {
            let ub = UserBets {
                bets:emptyMap()
            };
            let x = 0;
            repeat(self.optionsCount) {
                ub.bets.set(x,0);
                x += 1;
            }
            self.userBets.set(sender,ub);  // new inner map
        }


        let bets = self.userBets.get(sender)!!.bets;
        require(bets != null, "User bets should be initialized");
        let newBet = bets.get(msg.optionIndex)!! + context().value;
        bets.set(msg.optionIndex,newBet);
        self.userBets.set(sender,UserBets {bets:bets});

        let newPot = self.pots.get(msg.optionIndex)!! + context().value;
        self.pots.set(msg.optionIndex,newPot);
        self.totalBets += context().value;
    }

    receive(msg: EndPoll) {
        require(sender() == self.master, "Only master can end poll");
        require(!self.pollEnded, "Poll already ended");

        // self.pollEnded = true;
        self.winnerIndex = msg.winnerIndex;

        self.distributeRewards();
    }

    inline fun distributeRewards() {

        message(MessageParameters {
                to: self.master,
                value: ton("0.5"),
            });

        message(MessageParameters {
                to: self.creator,
                value: ton("0.5"),
            });
        self.totalBets = max(self.totalBets - ton("1.01") , 0);

        let totalWinnerBets = max(self.pots.get(self.winnerIndex)!! , 0);

        foreach (user,bets in self.userBets){
            
            //check if user bet on winning option
            let userBetOnWinner = bets.bets.get(self.winnerIndex);
            if (userBetOnWinner == 0) {
                return;
            }

            let payout = (userBetOnWinner!! * self.totalBets) / totalWinnerBets;

            //send money to user
            message(MessageParameters {
                to: user,
                value: payout,
            });
        }
        
    }

    get fun pollState():PollState {
        return PollState {
            pots: self.pots,
            totalBets: self.totalBets,
            userBets: self.userBets,
        };
    }
}
