import "@stdlib/deploy";
struct VoteInfo {
    isVoted: Bool;
    voteTime: Int as uint256;
}
message VoteMsg {
    voteId: Int as uint32;
}

contract Vote with Deployable {
    owner: Address;
    voteCount: map<Int, Int>;
    voterInfo: map<Address, VoteInfo>;
    init(owner: Address){
        self.owner = owner;
    }

    fun vote(voteId: Int) {
        let ctx: Context = context();
        let voter: VoteInfo = self.voterInfo.get(ctx.sender)!!;
        require(!(voter.isVoted), "Already voted");
        self.voterInfo.set(ctx.sender, VoteInfo{isVoted: true, voteTime: now()});
        self.voteCount.set(voteId, (self.voteCount.get(voteId)!! + 1));
        self.reply("Voted!".asComment());
    }

    receive(msg: VoteMsg){
        self.vote(msg.voteId);
    }

    get fun voteCount(voteId: Int): Int {
        return self.voteCount.get(voteId)!!;
    }

    get fun voterInfo(address: Address): VoteInfo {
        return self.voterInfo.get(address)!!;
    }
}