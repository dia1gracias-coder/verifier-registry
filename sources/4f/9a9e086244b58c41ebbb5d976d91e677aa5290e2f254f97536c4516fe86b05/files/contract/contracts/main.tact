import "@stdlib/ownable";
import "@stdlib/stoppable";

message Deploy {
    queryId: Int as uint64;
}

message DeployOk {
    queryId: Int as uint64;
}

message FinishRound {
    queryId: Int as uint64;
    winner: Address;
}

message UpdateParams {
    queryId: Int as uint64;
    entryFee: Int;
    prizePercentage: Int;
    commissionPercentage: Int;
}

message UpdateParamsOk {
    queryId: Int as uint64;
    entryFee: Int;
    prizePercentage: Int;
    commissionPercentage: Int;
}

message FinishRoundOk {
    queryId: Int as uint64;
    round: Int;
}


contract Main with OwnableTransferable, Stoppable {
    id: Int as uint64;
    owner: Address;
    round: Int as uint32;
    stopped: Bool;

    entryFee: Int as coins;
    prizePercentage: Int as uint32;
    commissionPercentage: Int as uint32;

    init(id: Int, owner: Address, entryFee: Int, commissionPercentage: Int, prizePercentage: Int) {
        self.id = id;
        self.round = 0;
        self.stopped = false;

        self.owner = owner;

        self.entryFee = entryFee;
        self.commissionPercentage = commissionPercentage;
        self.prizePercentage = prizePercentage;
    }

    receive(deploy: Deploy) {
        self.notify(DeployOk{queryId: deploy.queryId}.toCell());
    }

    receive("join") {
        self.requireNotStopped();

        let commission = self.entryFee * self.commissionPercentage / 100000;

        let transactionFee = gasConsumed() + getForwardFee(1, 64, false) + getForwardFee(1, 0, false);

        require(context().value >= self.entryFee + transactionFee, "Insufficient entry fee.");

        send(SendParameters{
            to: self.owner,
            bounce: true,
            value: commission,
            mode: SendPayGasSeparately
        });

        let overpayment = context().value - (self.entryFee);
        if (overpayment > 0) {
            send(SendParameters{
            to: context().sender,
            bounce: false,
            value: overpayment
            });
        }
    }

    receive(msg: FinishRound){
        self.requireOwner();

        let transactionFee = gasConsumed() + getForwardFee(1, 363, false) + getForwardFee(1, 0, false);
        let prize = (myBalance() - context().value) * self.prizePercentage / 100000;
        require(myBalance() - prize - transactionFee > ton("0.01"), "Not enough contact balance");

        send(SendParameters{
        to: msg.winner,
        bounce: true,
        value: prize,
        mode: SendPayGasSeparately
        });

        self.round += 1;

        self.reply(
            FinishRoundOk{
                queryId: msg.queryId,
                round:self.round
            }.toCell()
        );
    }

    receive(msg: UpdateParams) {
        self.requireNotStopped();
        self.requireOwner();

        require(msg.entryFee > 0, "Entry fee must be positive.");
        require(msg.commissionPercentage >= 0 && msg.commissionPercentage <= 100000, "Invalid commission percentage.");
        require(msg.prizePercentage >= 0 && msg.prizePercentage <= 100000, "Invalid prize percentage.");

        self.entryFee = msg.entryFee;
        self.commissionPercentage = msg.commissionPercentage;
        self.prizePercentage = msg.prizePercentage;

        self.reply(UpdateParamsOk{
            queryId: msg.queryId,
            entryFee: msg.entryFee,
            prizePercentage: msg.prizePercentage,
            commissionPercentage: msg.commissionPercentage
        }.toCell())
    }

    get fun round(): Int {
        return self.round;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun entryFee(): Int {
        return self.entryFee;
    }

    get fun commissionPercentage(): Int {
        return self.commissionPercentage;
    }

    get fun prizePercentage(): Int {
        return self.prizePercentage;
    }
}
