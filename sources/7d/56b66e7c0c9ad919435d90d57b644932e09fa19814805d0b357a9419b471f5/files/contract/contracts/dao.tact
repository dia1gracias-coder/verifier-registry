import "@stdlib/deploy";
import "@stdlib/ownable";
import "./proposal";

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

const STAKE_MESSAGE_PAYLOAD: String = "STAKE";

contract Dao with Deployable, Ownable {
    owner: Address;
    jettonAmount: Int as coins;
    jettonMasterContract: Address?;
    myJettonWalletAddress: Address;

    minVoteCount: Int as uint32;
    proposalsCount: Int as uint32;
    proposals: map<Int, Address>;

    stakeMembers: map<Address, Int as coins>;
    minStakeAmount: Int as coins;

    init(minVoteCount: Int, minStakeAmount: Int, jettonMasterContract: Address, jettonWalletCode: Cell){
        self.owner = sender();
        self.minVoteCount = minVoteCount;
        self.minStakeAmount = minStakeAmount;
        self.jettonMasterContract = jettonMasterContract;
        self.proposalsCount = 0;
        self.proposals = emptyMap();
        self.jettonAmount = 0;

        let initData = JettonWalletData{balance: 0, ownerAddress: myAddress(), 
                                        jettonMasterAddress: jettonMasterContract,
                                        jettonWalletCode: jettonWalletCode};
        self.myJettonWalletAddress = contractAddress(StateInit{code: jettonWalletCode, data: initData.toCell()});
    }

    receive(msg: Propose){
        let ctx: Context = context();

        self.checkMembership(ctx.sender);
        // require(ctx.sender == self.owner, "Only owner can create proposals (for the moment)");
        require(msg.actionType == "transfer" || msg.actionType == "mint", "Invalid action type");

        let initProposal: StateInit = initOf Proposal(myAddress(), self.proposalsCount);
        let proposalContractAddress = contractAddress(initProposal);
        self.proposals.set(self.proposalsCount, proposalContractAddress);
        
        send(SendParameters{
                to: proposalContractAddress,
                value: ton("0.02"),
                bounce: false,
                body: ProposalLaunch{
                    startTimestamp: msg.startTimestamp,
                    endTimestamp: msg.endTimestamp,
                    title: msg.title,
                    description: msg.description,
                    action: msg.actionType,
                    target: msg.target,
                    value: msg.value,
                    executed: false
                }.toCell(),
                mode: SendRemainingValue,
                code: initProposal.code,
                data: initProposal.data
            }
        );
        self.proposalsCount += 1;
    }

    receive(msg: Vote){
        let ctx: Context = context();
        // TODO: check membership
        // require(self.isMember(ctx.sender), "Only DAO members can vote");
        // require(!voterVotes[ctx.sender].exists(), "Voter already voted");

        self.checkMembership(ctx.sender);
        require(self.proposals.exists(msg.proposalId), "Proposal does not exist");
        
        send(SendParameters{
                to: self.proposals.get(msg.proposalId)!!,
                value: ton("0.01"),
                bounce: true,
                body: RouteProposalVote{proposalId: msg.proposalId, sender: ctx.sender, choice: msg.choice}.toCell(),
                mode: SendBounceIfActionFail
            }
        );
    }

    receive(msg: JettonTransferNotification){
        require(context().sender == self.myJettonWalletAddress, "Only DAO's Jetton wallet can send notifications");

        require(msg.forwardPayload == STAKE_MESSAGE_PAYLOAD.asSlice(), 
                "Include `STAKE` in the payload of the transfer for staking jettons");

        require(msg.amount >= self.minStakeAmount, "Staked amount is less than the minimum required for membership"); 
        self.jettonAmount += msg.amount;

        if (self.stakeMembers.exists(msg.sender)){
            self.stakeMembers.set(msg.sender, self.stakeMembers.get(msg.sender)!! + msg.amount);
        } else {
            self.stakeMembers.set(msg.sender, msg.amount);
        }

        // Forward excesses
        self.forward(msg.sender, null, false, null);
    }

    receive(msg: Unstake) {
        let unstakeSender = context().sender;
        require(self.stakeMembers.exists(unstakeSender), "Only members who previously staked jettons can unstake");
        require(self.stakeMembers.get(unstakeSender)!! >= msg.amount, "Insufficient staked amount");
        require(msg.amount > 0, "Invalid unstake amount");

        self.stakeMembers.set(unstakeSender, self.stakeMembers.get(unstakeSender)!! - msg.amount);
        self.jettonAmount -= msg.amount;

        if (self.stakeMembers.get(unstakeSender)!! == 0){
            self.stakeMembers.del(unstakeSender)
        }

        send(SendParameters{
            to: self.myJettonWalletAddress, // notify jetton wallet
            value: ton("0.02"),
            bounce: false,
            body: JettonTransfer{
                queryId: now(),
                amount: msg.amount,
                destination: unstakeSender,
                responseDestination: self.myJettonWalletAddress,
                customPayload: null,
                forwardTonAmount: ton("0.001"),
                forwardPayload: rawSlice("F")
            }.toCell()
        });
    }

    fun checkMembership(sender: Address) {
        require(self.stakeMembers.exists(sender) && self.stakeMembers.get(sender)!! >= self.minStakeAmount, 
                "Only members who staked jettons can propose/vote");
    }

    // fun executeProposal(proposalId: Int) {
    //     require(self.proposals[proposalId].exists(), "Proposal does not exist");

    //     let proposal = Proposal.fromCell(self.proposals[proposalId]);

    //     require(!proposal.executed, "Proposal already executed");

    //     // count "yes" votes
    //     let voterVotes = self.votes[proposalId];
    //     let approvals = voterVotes.values().filter(v => v == true).length();
    //     require(approvals >= self.minVoteCount, "Not enough votes to execute");

    //     //TODO: Implement executions

    //     // Mark as executed and update storage
    //     proposal.executed = true;
    //     self.proposals[proposalId] = proposal.toCell();
    // }

    // fun isMember(sender: Address): Bool {
    //     let walletAddress = self.getJettonWallet(sender);
    //     let balance = self.getTokenBalance(walletAddress);
    //     return balance >= self.minMembershipBalance;
    // }

    // fun getJettonWallet(owner: Address): Address {
    //     let result = call(self.jettonMasterContract, "get_wallet_address", owner);
    //     return result.parseAddress();
    // }

    // // Helper to get Jetton balance
    // fun getTokenBalance(wallet: Address): Int {
    //     let result = call(wallet, "get_balance", ());
    //     return result.parseInt();
    // }

    // // Get proposal details
    // get fun proposalDetails(proposalId: Int): Proposal {
    //     require(self.proposals[proposalId].exists(), "Proposal does not exist");
    //     return Proposal.fromCell(self.proposals[proposalId]);
    // }

    // Get the current proposal count

    get fun currentProposalCount(): Int {
        return self.proposalsCount;
    }

    get fun ownerAddress(): Address {
        return self.owner;
    }

    get fun minVoteCount(): Int {
        return self.minVoteCount;
    }

    get fun proposals(): map<Int, Address> {
        return self.proposals;
    }
}