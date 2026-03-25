import "@stdlib/deploy";
import "@stdlib/ownable";

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message CreateProposal {
    description: String;
    deadline: Int as uint64;
    actionTarget: Address;
    actionAmount: Int as coins;
}

message Execute {
    proposalId: Int as uint32;
}

message SetJettonWallet {
    wallet: Address;
}

struct Proposal {
    description: String;
    deadline: Int as uint64;
    yesVotes: Int as coins;
    noVotes: Int as coins;
    executed: Bool;
    actionTarget: Address;
    actionAmount: Int as coins;
    proposer: Address;
}

contract DAO with Deployable, Ownable {

    owner: Address;
    jettonMaster: Address;
    jettonWalletOfDAO: Address;
    proposals: map<Int as uint32, Proposal>;
    nextProposalId: Int as uint32;

    init(owner: Address, jettonMaster: Address) {
        self.owner = owner;
        self.jettonMaster = jettonMaster;
        self.jettonWalletOfDAO = owner;
        self.nextProposalId = 0;
    }

    receive(msg: SetJettonWallet) {
        self.requireOwner();
        self.jettonWalletOfDAO = msg.wallet;
    }

    receive(msg: CreateProposal) {
        require(msg.deadline > now(), "Deadline must be in the future");

        let id: Int = self.nextProposalId;
        self.proposals.set(id, Proposal {
            description: msg.description,
            deadline: msg.deadline,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            actionTarget: msg.actionTarget,
            actionAmount: msg.actionAmount,
            proposer: sender()
        });
        self.nextProposalId = self.nextProposalId + 1;

        self.reply("".asComment());
    }

    receive(msg: JettonTransferNotification) {
        require(sender() == self.jettonWalletOfDAO, "Not our jetton wallet");

        let payload: Slice = msg.forwardPayload;
        if (payload.bits() < 33) { return; }

        let proposalId: Int = payload.loadUint(32);
        let support: Int = payload.loadUint(1);

        let propOpt: Proposal? = self.proposals.get(proposalId);
        require(propOpt != null, "Proposal not found");
        let prop: Proposal = propOpt!!;

        require(now() < prop.deadline, "Voting has ended");

        if (support == 1) {
            prop.yesVotes = prop.yesVotes + msg.amount;
        } else {
            prop.noVotes = prop.noVotes + msg.amount;
        }

        self.proposals.set(proposalId, prop);
    }

    receive(msg: Execute) {
        let propOpt: Proposal? = self.proposals.get(msg.proposalId);
        require(propOpt != null, "Proposal not found");
        let prop: Proposal = propOpt!!;

        require(now() >= prop.deadline, "Voting still in progress");
        require(!prop.executed, "Already executed");
        require(prop.yesVotes > prop.noVotes, "Proposal rejected");

        send(SendParameters {
            to: prop.actionTarget,
            value: prop.actionAmount,
            mode: SendPayGasSeparately,
            bounce: false,
            body: "DAO Execution".asComment()
        });

        prop.executed = true;
        self.proposals.set(msg.proposalId, prop);
    }

    get fun getProposal(id: Int): Proposal? {
        return self.proposals.get(id);
    }

    get fun getProposalById(id: Int): Proposal {
        let propOpt: Proposal? = self.proposals.get(id);
        require(propOpt != null, "Proposal not found");
        return propOpt!!;
    }

    get fun getNextProposalId(): Int {
        return self.nextProposalId;
    }

    get fun getJettonWallet(): Address {
        return self.jettonWalletOfDAO;
    }

    get fun getJettonMaster(): Address {
        return self.jettonMaster;
    }

    get fun getOwner(): Address {
        return self.owner;
    }
}
