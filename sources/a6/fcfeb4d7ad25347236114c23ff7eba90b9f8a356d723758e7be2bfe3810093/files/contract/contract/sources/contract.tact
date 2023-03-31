import "@stdlib/deploy";
import "@stdlib/ownable";

// CONST
const POW_10_DECIMALS: Int = 1000000000;

const ROUND_STATUS__OK: Int = 0;
const ROUND_STATUS__ENDED: Int  = 1;

// STRUCT
struct Round {
    id: Int;
    tax_adjustment_multiplier: Int;
    voting_unit: Int;
    status: Int;
    fund: Int;
    project_number: Int;
    total_area: Int;
    projects: map<Int, Project>;
}
struct Project {
    id: Int;
    pid: Int;
    area: Int;
    votes: Int;
    contribution: Int;
    voters: map<Address, Int>;
}
struct Votes {
    project_id: Int;
    votes: Int;
}

// MESSAGE
message StartRound {
    tax_adjustment_multiplier: Int;
    voting_unit: Int;
    fund: Int;
}
message SetFund {
    round_id: Int;
    fund: Int;
}
message BatchUploadProjects {
    round_id: Int;
    count: Int;
    projects: map<Int, Int>;
}
message WeightedBatchVote {
    round_id: Int;
    count: Int;
    amounts: map<Int, Votes>;
}
message EndRound {
    round_id: Int;
}
message WithdrawAll {
    round_id: Int;
}

fun sqrt(x: Int): Int {
    if( x == 0 ) {return 0;}
    if( x < 4 ) {return 1;}
    let r: Int = x;
    let t: Int = x / 2 + 1;
    while( t < r ) {
        r = t;
        t = (x/t + t)/2;
    }
    return r;
}

contract QuadraticGrantTonContract with Deployable, Ownable {
    owner: Address;
    currentRound: Int;
    rounds: map<Int, Round>;

    init(owner: Address) {
        self.owner = owner;
        self.currentRound = 0;
    }

    receive(msg: StartRound) {
        self.requireOwner();
        self.currentRound = self.currentRound + 1;
        let round: Round = Round {
            id: self.currentRound,
            tax_adjustment_multiplier: msg.tax_adjustment_multiplier,
            voting_unit: msg.voting_unit,
            status: ROUND_STATUS__OK,
            fund: msg.fund,
            project_number: 0,
            total_area: 0,
            projects: null
        };
        self.rounds.set(self.currentRound, round);
        send(SendParameters{value: 0, to: sender(), mode: SendRemainingValue });
    }

    receive(msg: SetFund) {
        self.requireOwner();
        let round: Round = self.rounds.get(msg.round_id)!!;
        round.fund = msg.fund;
        self.rounds.set(msg.round_id, round);
        send(SendParameters{value: 0, to: sender(), mode: SendRemainingValue });
    }

    receive(msg: BatchUploadProjects) {
        self.requireOwner();
        let round: Round = self.rounds.get(msg.round_id)!!;
        require(round.status==ROUND_STATUS__OK, "Round status is invalid");
        let project_number: Int = round.project_number;
        let i: Int = 1;
        repeat(msg.count) {
            project_number = project_number + 1;
            let project: Project = Project {
                id: project_number,
                pid: msg.projects.get(i)!!,
                area: 0,
                contribution: 0,
                votes: 0,
                voters: null
            };
            round.projects.set(project_number, project);
            i = i + 1;
        }
        self.rounds.set(msg.round_id, round);
        send(SendParameters{value: 0, to: sender(), mode: SendRemainingValue });
    }

    receive(msg: WeightedBatchVote) {
        let ctx: Context = context();
        let round: Round = self.rounds.get(msg.round_id)!!;
        require(round.status==ROUND_STATUS__OK, "Round status is invalid");

        let i: Int = 1;
        let totalAmount: Int = 0;
        repeat(msg.count) {
            let amounts: Votes = msg.amounts.get(i)!!;
            let project: Project = round.projects.get(amounts.project_id)!!;
            let amount: Int = amounts.votes;
            require(amount >= POW_10_DECIMALS / round.voting_unit, "Amount is too small");
            let votes: Int = amount * round.voting_unit / POW_10_DECIMALS;
            require(votes * POW_10_DECIMALS == amount * round.voting_unit, "Voting amount not integer");

            project.votes = project.votes + votes;
            project.contribution = project.contribution + amount;

            // Compute area difference and update project/round area
            let old_votes: Int = 0;
            let _old_votes: Int? = project.voters.get(sender());
            if(_old_votes != null) {
                old_votes = _old_votes!!;
            }
            let new_votes: Int = old_votes + votes;
            project.voters.set(sender(), new_votes);

            let old_area: Int = sqrt((old_votes * 100));
            let new_area: Int = sqrt((new_votes * 100));

            let area_diff: Int = new_area - old_area;

            project.area = project.area + area_diff;
            round.total_area = round.total_area + area_diff;

            round.projects.set(amounts.project_id, project);
            totalAmount = totalAmount + amount;
            i = i + 1;
        }
        self.rounds.set(msg.round_id, round);
        require(ctx.value - totalAmount >= 0 , "Insufficient funds");
        nativeReserve(totalAmount, 0);
        send(SendParameters{value: 0, to: sender(), mode: SendRemainingBalance });
    }

    receive(msg: EndRound) {
        self.requireOwner();
        let round: Round = self.rounds.get(msg.round_id)!!;
        require(round.status==ROUND_STATUS__OK, "Round status is invalid");
        round.status = ROUND_STATUS__ENDED;
        self.rounds.set(msg.round_id, round);
        send(SendParameters{
            to: sender(), 
            value: 0, 
            mode: SendRemainingBalance + SendIgnoreErrors, 
            bounce: false, 
            body: "Success".asComment()
        });
    }

    get fun round(id: Int): Round? {
        return self.rounds.get(id);
    }

    get fun balance(): Int {
        return myBalance();
    }
}
