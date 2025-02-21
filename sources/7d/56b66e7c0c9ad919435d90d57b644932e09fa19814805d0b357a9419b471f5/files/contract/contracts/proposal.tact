import "@stdlib/deploy";
import "./messages";

contract Proposal with Deployable {
    daoParent: Address;
    proposalId: Int as uint32;
    startTimestamp: Int as uint64;
    endTimestamp: Int as uint64;
    title: String;
    description: String;
    action: String;
    target: Address?;
    value: Int as coins;
    executed: Bool;
    votes: map<Address, Bool>;
    votesCount: Int as uint32;
    votesYesCount: Int as uint32;
    votesNoCount: Int as uint32;

    init(daoParent: Address, id: Int){
        self.daoParent = daoParent;
        self.proposalId = id;
        self.startTimestamp = 0;
        self.endTimestamp = 0;
        self.title = "";
        self.description = "";
        self.action = "";
        self.target = null;
        self.value = 0;
        self.executed = false;
        self.votes = emptyMap();
        self.votesCount = 0;
        self.votesYesCount = 0;
        self.votesNoCount = 0;
    }

    receive(msg: ProposalLaunch){
        require(context().sender == self.daoParent, "Only the parent DAO can launch proposals");
        self.startTimestamp = msg.startTimestamp;
        self.endTimestamp = msg.endTimestamp;
        self.title = msg.title;
        self.description = msg.description;
        self.action = msg.action;
        self.target = msg.target;
        self.value = msg.value;
        self.executed = msg.executed;
    }

    receive(msg: RouteProposalVote){
        require(msg.proposalId == self.proposalId, "Invalid proposal ID");
        require(!self.votes.exists(msg.sender), "Voter already voted");
        require(context().sender == self.daoParent, "Only the parent DAO can register votes");
        self.votes.set(msg.sender, msg.choice);
        self.votesCount += 1;
        if (msg.choice) {
            self.votesYesCount += 1;
        } else {
            self.votesNoCount += 1;
        }
    }

    get fun votesCount(): Int {
        return self.votesCount;
    }

    get fun votes(): map<Address, Bool> {
        return self.votes;
    }

    get fun addressVote(address: Address): Bool? {
        return self.votes.get(address);
    }
}