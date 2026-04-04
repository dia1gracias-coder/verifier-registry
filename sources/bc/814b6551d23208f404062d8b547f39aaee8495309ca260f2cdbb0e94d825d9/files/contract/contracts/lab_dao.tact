import "@stdlib/deploy";

message(1) CreateProposal {
    description: String;
    duration: Int as uint32;
}

message(2) Vote {
    proposalId: Int as uint32;
    support: Bool;
    power: Int as uint32;
}

message(3) ExecuteProposal {
    proposalId: Int as uint32;
}

struct Proposal {
    id: Int as uint32;
    description: String;
    votesFor: Int as uint64;
    votesAgainst: Int as uint64;
    deadline: Int as uint32;
    executed: Bool;
    passed: Bool;
    proposer: Address;
}

contract LabDao with Deployable {
    tokenMaster: Address;
    admin: Address;
    proposalCount: Int as uint32;
    lastAcceptedProposalId: Int as uint32;

    proposals: map<Int, Proposal>;
    voted: map<Int, Bool>;

    init(tokenMaster: Address, admin: Address) {
        self.tokenMaster = tokenMaster;
        self.admin = admin;
        self.proposalCount = 0;
        self.lastAcceptedProposalId = 0;
        self.proposals = emptyMap();
        self.voted = emptyMap();
    }

    receive() {}
    receive(_: String) {}

    receive(msg: CreateProposal) {
        require(msg.description != "", "Description cannot be empty");
        require(msg.duration >= 60, "Duration must be >= 60 seconds");

        let id: Int = self.proposalCount;
        let deadline: Int = now() + msg.duration;

        self.proposals.set(id, Proposal {
            id: id,
            description: msg.description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: deadline,
            executed: false,
            passed: false,
            proposer: sender(),
        });

        self.proposalCount = self.proposalCount + 1;
    }

    receive(msg: Vote) {
        require(msg.proposalId < self.proposalCount, "Proposal not found");
        require(msg.power > 0, "Power must be positive");

        let proposal: Proposal = self.proposals.get(msg.proposalId)!!;
        require(now() < proposal.deadline, "Voting ended");
        require(!proposal.executed, "Already executed");

        let addrInt: Int = sender().asSlice().loadUint(256);
        let voteKey: Int = msg.proposalId * 1000000000 + addrInt % 1000000000;
        let alreadyVoted: Bool? = self.voted.get(voteKey);
        require(alreadyVoted == null || alreadyVoted!! == false, "Already voted");

        self.voted.set(voteKey, true);

        if (msg.support) {
            proposal.votesFor = proposal.votesFor + msg.power;
        } else {
            proposal.votesAgainst = proposal.votesAgainst + msg.power;
        }

        self.proposals.set(msg.proposalId, proposal);
    }

    receive(msg: ExecuteProposal) {
        require(msg.proposalId < self.proposalCount, "Proposal not found");

        let proposal: Proposal = self.proposals.get(msg.proposalId)!!;
        require(now() >= proposal.deadline, "Voting is still active");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        proposal.passed = proposal.votesFor > proposal.votesAgainst;

        if (proposal.passed) {
            self.lastAcceptedProposalId = msg.proposalId;
        }

        self.proposals.set(msg.proposalId, proposal);
    }

    get fun getProposal(id: Int): Proposal? {
        return self.proposals.get(id);
    }

    get fun getProposalCount(): Int {
        return self.proposalCount;
    }

    get fun getTokenMaster(): Address {
        return self.tokenMaster;
    }

    get fun getAdmin(): Address {
        return self.admin;
    }

    get fun getLastAcceptedProposalId(): Int {
        return self.lastAcceptedProposalId;
    }

    get fun getHasVoted(proposalId: Int, voter: Address): Bool {
        let addrInt: Int = voter.asSlice().loadUint(256);
        let voteKey: Int = proposalId * 1000000000 + addrInt % 1000000000;
        let alreadyVoted: Bool? = self.voted.get(voteKey);
        if (alreadyVoted == null) {
            return false;
        }
        return alreadyVoted!!;
    }
}
