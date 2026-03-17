import "@stdlib/deploy";

message(1) CreateProposal {
    description: String;
    duration: Int as uint32;
}

message(2) Vote {
    proposalId: Int as uint32;
    support: Bool;
}

message(3) ExecuteProposal {
    proposalId: Int as uint32;
}

struct Proposal {
    id: Int as uint32;
    description: String;
    votesFor: Int as uint32;
    votesAgainst: Int as uint32;
    deadline: Int as uint32;
    executed: Bool;
    proposer: Address;
}

contract FpDao with Deployable {

    jettonMaster: Address;
    proposals: map<Int as uint32, Proposal>;
    proposalCount: Int as uint32;
    voted: map<Int, Bool>;
    version: Int as uint32;

    init(jettonMaster: Address, version: Int) {
        self.jettonMaster = jettonMaster;
        self.proposalCount = 0;
        self.proposals = emptyMap();
        self.voted = emptyMap();
        self.version = version;
    }

    receive() {}

    receive(msg: CreateProposal) {
        require(msg.duration >= 60, "Duration must be >= 60 seconds");
        require(msg.description != "", "Description cannot be empty");

        let id: Int = self.proposalCount;
        let deadline: Int = now() + msg.duration;

        self.proposals.set(id, Proposal{
            id: id,
            description: msg.description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: deadline,
            executed: false,
            proposer: sender()
        });

        self.proposalCount = self.proposalCount + 1;
        self.reply("Proposal created".asComment());
    }

    receive(msg: Vote) {
        require(msg.proposalId < self.proposalCount, "Proposal not found");

        let p: Proposal = self.proposals.get(msg.proposalId)!!;
        require(now() < p.deadline, "Voting period has ended");

        let addrInt: Int = sender().asSlice().loadUint(256);
        let voteKey: Int = msg.proposalId * 1000000000 + addrInt % 1000000000;
        let alreadyVoted: Bool? = self.voted.get(voteKey);
        require(alreadyVoted == null || alreadyVoted!! == false, "Already voted");

        self.voted.set(voteKey, true);

        if (msg.support) {
            p.votesFor = p.votesFor + 1;
        } else {
            p.votesAgainst = p.votesAgainst + 1;
        }

        self.proposals.set(msg.proposalId, p);
        self.reply("Vote counted".asComment());
    }

    receive(msg: ExecuteProposal) {
        require(msg.proposalId < self.proposalCount, "Proposal not found");

        let p: Proposal = self.proposals.get(msg.proposalId)!!;
        require(now() >= p.deadline, "Voting still active");
        require(!p.executed, "Already executed");

        p.executed = true;
        self.proposals.set(msg.proposalId, p);
        self.reply("Proposal executed".asComment());
    }

    get fun getProposal(id: Int): Proposal? {
        return self.proposals.get(id);
    }

    get fun getProposalCount(): Int {
        return self.proposalCount;
    }

    get fun getJettonMaster(): Address {
        return self.jettonMaster;
    }
}
