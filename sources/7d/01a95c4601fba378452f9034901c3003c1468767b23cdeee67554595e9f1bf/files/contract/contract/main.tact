import "@stdlib/deploy";

// Define a message structure for voting
message Vote {
    candidate: Int as uint32; // 1 = Alice, 2 = Bob
}

contract VotingContract with Deployable {
    
    // State variables to track votes
    votesAlice: Int as uint32;
    votesBob: Int as uint32;

    init() {
        self.votesAlice = 0;
        self.votesBob = 0;
    }

    // Handle vote messages
    receive(msg: Vote) {
        if (msg.candidate == 1) {
            self.votesAlice += 1;
        } else if (msg.candidate == 2) {
            self.votesBob += 1;
        }
    }

    // Getter for Alice's votes
    get fun getVotesForAlice(): Int {
        return self.votesAlice;
    }

    // Getter for Bob's votes
    get fun getVotesForBob(): Int {
        return self.votesBob;
    }
}
