struct PayloadVotes {
    payload: String;
    votes: Int;
    guarded: Bool; // true - if any guard voted for this payload
}

struct RoundParticipantInfo {
    address: Address;
    votes: Int;
    payloadHash: Int;
    guard: Bool;
}

contract VotingRound with Deployable {

    // parent consensus contract; immutable
    parent: Address;

    // round index; immutable
    round: Int;

    // key - sha256(payload), value - payload+votes
    payloadsByHash: map<Int, PayloadVotes>;

    // key - participant address, value - hash(payload)
    participantsPayload: map<Address, Int>;

    // key - index, value - participant address
    participants: map<Int, RoundParticipantInfo>;
    participantsCount: Int;

    // key - index, value - sha256(payload)
    payloads: map<Int, Int>;
    payloadsCount: Int;

    finalized: Bool;
    winnerPayload: String?;
    winnerVotes: Int?;
    winnerGuarded: Bool;

    init(parent: Address, round: Int) {
        self.parent = parent;
        self.round = round;
        self.participants = emptyMap();
        self.participantsCount = 0;
        self.payloads = emptyMap();
        self.payloadsCount = 0;
        self.finalized = false;
        self.winnerGuarded = false;
    }

    receive("check opened round") {
        self.reply(InternalRoundOpened{round: self.round}.toCell());
    }

    receive(msg: InternalVote) {
        require(sender() == self.parent, "parent only");
        require(!self.finalized, "round was finalized");
        require(msg.round == self.round, "wrong round");

        let existingVote: Int? = self.participantsPayload.get(msg.participant);
        require(existingVote == null, "already voted");

        let payloadHash: Int = sha256(msg.payload);

        self.participants.set(
            self.participantsCount,
            RoundParticipantInfo{address: msg.participant, votes: msg.votes, payloadHash: payloadHash, guard: msg.guard}
        );
        self.participantsCount = self.participantsCount + 1;

        let existingPayloadVotes: PayloadVotes? = self.payloadsByHash.get(payloadHash);
        if (existingPayloadVotes == null) {
            let payloadVotes: PayloadVotes = PayloadVotes{payload: msg.payload, votes: msg.votes, guarded: msg.guard};
            self.payloadsByHash.set(payloadHash, payloadVotes);
            self.payloads.set(self.payloadsCount, payloadHash);
            self.payloadsCount = self.payloadsCount + 1;
        } else {
            let payloadVotes: PayloadVotes = existingPayloadVotes!!;
            let updatedVotes: Int = payloadVotes.votes + msg.votes;
            let guarded: Bool = payloadVotes.guarded || msg.guard;
            self.payloadsByHash.set(payloadHash, PayloadVotes{payload: msg.payload, votes: updatedVotes, guarded: guarded});
        }
        self.participantsPayload.set(msg.participant, payloadHash);
    }

    receive(msg: InternalFinalize) {
        require(sender() == self.parent, "parent only");
        require(!self.finalized, "already finalized");
        require(msg.minVotes > 0, "min votes required");

        let rewards: Int = context().value;

        let i: Int = 0;
        let candidatePayload: String? = null;
        let candidateVotes: Int? = null;
        let candidateGuarded: Bool = false;
        while (i < self.payloadsCount) {
            let payloadHash: Int? = self.payloads.get(i);
            require(payloadHash != null, "invalid payload hash by counter");
            let payloadHashSafe: Int = payloadHash!!;

            let payloadVotes: PayloadVotes? = self.payloadsByHash.get(payloadHashSafe);
            require(payloadVotes != null, "invalid payload votes by hash");
            let payloadVotesSafe: PayloadVotes = payloadVotes!!;

            let votes: Int = payloadVotesSafe.votes;

            if (candidateVotes == null || votes > candidateVotes!!) {
                candidatePayload = payloadVotesSafe.payload;
                candidateVotes = votes;
                candidateGuarded = payloadVotesSafe.guarded;
            }
            i = i + 1;
        }

        require(candidateGuarded, "guard must vote for candidate"); // todo is guard vote required?
        require(candidateVotes != null && candidateVotes!! > msg.minVotes, "min votes not exceeded");

        self.winnerPayload = candidatePayload;
        self.winnerVotes = candidateVotes;
        self.winnerGuarded = candidateGuarded;

        let j: Int = 0;

        let winnerPayloadHash: Int = sha256(self.winnerPayload);
        let goodParticipants: map<Int, Address> = emptyMap();
        let goodParticipantsCount: Int = 0;
        let goodParticipantsVotes: map<Address, Int> = emptyMap();
        let badParticipants: map<Int, Address> = emptyMap();
        let badParticipantsCount: Int = 0;
        let badParticipantsVotes: map<Address, Int> = emptyMap();

        while (j < self.participantsCount) {
            let participantInfo: RoundParticipantInfo = self.participants.get(j)!!;
            let participantReward: Int = 0;
            if  (winnerPayloadHash == participantInfo.payloadHash) {
                goodParticipants.set(goodParticipantsCount, participantInfo.address);
                goodParticipantsVotes.set(participantInfo.address, participantInfo.votes);
                goodParticipantsCount = goodParticipantsCount + 1;
            } else {
                badParticipants.set(badParticipantsCount, participantInfo.address);
                badParticipantsVotes.set(participantInfo.address, participantInfo.votes);
                badParticipantsCount = badParticipantsCount + 1;
            }
            j = j + 1;
        }
        self.finalized = true;

        send(
            SendParameters{
                to: self.parent,
                body: InternalFinalized{
                    round: self.round,
                    winnerPayload: self.winnerPayload!!,
                    winnerVotes: self.winnerVotes!!,
                    winnerGuarded: self.winnerGuarded,
                    goodParticipants: goodParticipants,
                    goodParticipantsCount: goodParticipantsCount,
                    goodParticipantsVotes: goodParticipantsVotes,
                    badParticipants: badParticipants,
                    badParticipantsCount: badParticipantsCount,
                    badParticipantsVotes: badParticipantsVotes
                }.toCell(),
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors
            }
        );
    }

    get fun participantsCount(): Int {
        return self.participantsCount;
    }

    get fun winnerPayload(): String? {
        return self.winnerPayload;
    }

    get fun winnerVotes(): Int? {
        return self.winnerVotes;
    }

    get fun winnerGuarded(): Bool {
        return self.winnerGuarded;
    }
}