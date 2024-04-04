import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";
import "./events";
import "./external_messages";
import "./voting_round";
import "./internal_messages";
import "./owner_messages";

contract WitnessConsensus with Deployable, OwnableTransferable, Resumable {

    // required by ownable
    owner: Address;

    // required by stoppable/resumable
    stopped: Bool;

    // TRON genesis block ts; must be immutable
    genesisTimestamp: Int;
    // voting round period (ms); must be immutable
    roundPeriod: Int;

    minStake: Int;
    stakeFreezeTime: Int;
    minVotesForQuorum: Int;

    // key - participant, value - staked TON amount
    participants: map<Address, Int>;

    // rewards that might be claimed by participants
    pendingRewards: map<Address, Int>;

    // key - guard-participant address, value - is active guard
    guards: map<Address, Bool>;

    // key - participant, value - unstake cliff time
    unfreeze: map<Address, Int>;

    // last opened voting round
    openedRound: Int;

    // total TONs available for rewards
    rewardsBudget: Int as coins;
    // rewards per round
    roundReward: Int as coins;

    version: Int;

    init(owner: Address) {
        self.version = 1;
        self.owner = owner;
        self.stopped = false; // todo stop by default?
        self.minStake = ton("0.1");
        self.minVotesForQuorum = ton("0.3");
        self.stakeFreezeTime = 1 * 60 * 60 * 1000;
        self.genesisTimestamp = 1522108800;
        self.roundPeriod = 6 * 60 * 60;
        self.openedRound = 0;
        self.rewardsBudget = 0;
        self.roundReward = ton("0.0001");
    }

    get fun openedRound(): Int {
        return self.openedRound;
    }

    get fun isParticipant(participant: Address): Bool {
        let stake: Int? = self.participants.get(participant);
        return stake != null;
    }

    get fun participantStake(participant: Address): Int {
        let stake: Int? = self.participants.get(participant);
        if (stake == null) {
            return 0;
        } else {
            return stake!!;
        }
    }

    get fun pendingReward(participant: Address): Int? {
        return self.pendingRewards.get(participant);
    }

    receive("top up rewards") {
        self.requireNotStopped();

        let tons: Int = context().value;
        dump(tons);

        self.rewardsBudget = self.rewardsBudget + tons;
    }

    receive(msg: SetRoundReward) {
        self.requireOwner();
        require(msg.amount < ton("1"), "too much"); // todo upper limit

        self.roundReward = msg.amount;
    }

    receive("participate") {
        self.requireNotStopped();

        let tons: Int = context().value;
        dump(tons);

        let currentStake: Int? = self.participants.get(sender());

        let updatedStake: Int = 0;
        if (currentStake == null) {
            require(tons >= self.minStake, "min stake");
            updatedStake = tons;
        } else {
            updatedStake = tons + currentStake!!;
        }
        self.participants.set(sender(), updatedStake);
        dump(updatedStake);

        let unfreezeTime: Int = now() + self.stakeFreezeTime;
        self.unfreeze.set(sender(), unfreezeTime);
        dump(unfreezeTime);

        emit(NewParticipantEvent{address: sender(), votes: tons, unfreezeTime: unfreezeTime}.toCell());
    }

    receive("claim reward") {
        self.requireNotStopped();

        let pendingReward: Int? = self.pendingRewards.get(sender());
        require(pendingReward != null && pendingReward!! > 0, "no rewards");

        self.pendingRewards.set(sender(), null);
        send(
            SendParameters{
                to: sender(),
                value: pendingReward!!,
                mode: SendIgnoreErrors
            }
        );
    }

    receive(msg: PromoteToGuard) {
        self.requireOwner();
        self.requireNotStopped();

        let currentStake: Int? = self.participants.get(msg.address);
        require(currentStake != null, "not a participant");
        require(currentStake!! >= self.minStake, "min stake");

        self.guards.set(msg.address, true);
    }

    get fun checkGuardAddress(address: Address): Bool {
        return self.guards.get(address) == true;
    }

    receive(msg: RevokeGuard) {
        self.requireOwner();
        self.requireNotStopped();

        let guard: Bool? = self.guards.get(msg.address);
        require(guard == true, "not a guard");

        self.guards.set(msg.address, null);
    }

    receive("quit") {
        self.requireNotStopped();

        let stakeAmount: Int? = self.participants.get(sender());
        require(stakeAmount != null, "not a participant");

        let stakeAmountSafe: Int = stakeAmount!!;

        let unfreezeTime: Int? = self.unfreeze.get(sender());
        require(unfreezeTime != null, "unfreeze not found");

        let unfreezeTimeSafe: Int = unfreezeTime!!;
        require(unfreezeTimeSafe > now(), "unfreeze not passed yet");

        self.participants.set(sender(), null);
        self.unfreeze.set(sender(), null);

        send(SendParameters {
                to: sender(),
                bounce: true,
                value: stakeAmountSafe
            }
        );
        emit(ParticipantQuitEvent{address: sender(), votes: stakeAmountSafe, unfreezeTime: unfreezeTimeSafe}.toCell());
    }

    receive(msg: FinalizeRound) {
        require(self.openedRound >= msg.round, "only opened rounds can be finalized");
        let currentRound: Int = (now() - self.genesisTimestamp) / self.roundPeriod;
        require(msg.round <= currentRound, "only passed rounds can be finalized");
        let init: StateInit = initOf VotingRound(myAddress(), msg.round);

        let rewards: Int = 0;
        if (self.rewardsBudget >= self.roundReward) { // todo finalize w/o rewards?
            rewards = self.roundReward;
        }
        send(
            SendParameters{
                to: contractAddress(init),
                body: InternalFinalize{minVotes: self.minVotesForQuorum}.toCell(),
                value: rewards,
                mode: SendRemainingValue + SendIgnoreErrors
            }
        );
    }

    receive (msg: InternalFinalized) {
        self.requireNotStopped();
        let init: StateInit = initOf VotingRound(myAddress(), msg.round);
        require(sender() == contractAddress(init), "bad sender");

        require(self.openedRound >= msg.round, "only opened rounds can be finalized");
        let currentRound: Int = (now() - self.genesisTimestamp) / self.roundPeriod;
        require(msg.round < currentRound, "only passed rounds can be finalized");

        if (self.rewardsBudget > self.roundReward) {
            let i: Int = 0;
            while (i < msg.goodParticipantsCount) {
                let receiver: Address = msg.goodParticipants.get(i)!!;
                let votes: Int = msg.goodParticipantsVotes.get(receiver)!!;
                let reward: Int = (self.roundReward * votes) / msg.winnerVotes!!;
                dump(receiver);
                dump(votes);
                dump(reward);

                let pendingReward: Int? = self.pendingRewards.get(receiver);
                let pendingRewardSafe: Int = 0;
                if (pendingReward != null) {
                    pendingRewardSafe = pendingReward!!;
                }
                let updatedReward: Int = pendingRewardSafe + reward;
                self.pendingRewards.set(receiver, updatedReward);
                i = i + 1;
            }
        }

        let j: Int = 0;
        while (j < msg.badParticipantsCount) {
            let badParticipant: Address = msg.badParticipants.get(j)!!;
            let currentStake: Int = self.participants.get(badParticipant)!!;
            let reducedAmount: Int = currentStake * 5 / 1000; // 0.5% TODO decide penalty size
            self.rewardsBudget = self.rewardsBudget + reducedAmount; // penalty goes to rewards budget
            let reducedStake: Int = currentStake - reducedAmount;
            self.participants.set(badParticipant, reducedStake);

            j = j + 1;
        }
    }

    receive(msg: OpenRound) {
        self.requireNotStopped();

        require(msg.round > self.openedRound, "already opened");

        let currentRound: Int = (now() - self.genesisTimestamp) / self.roundPeriod;
        dump("current round by contract");
        dump(currentRound);
        require(msg.round == currentRound, "invalid round");

        let init: StateInit = initOf VotingRound(myAddress(), msg.round);
        send(
            SendParameters{
                to: contractAddress(init),
                value: 0, // TODO check deployment/storage fees
                mode: SendRemainingValue + SendIgnoreErrors,
                code: init.code,
                data: init.data,
                body: "check opened round".asComment()
            }
        );
    }

    receive(msg: InternalRoundOpened) {
        self.requireNotStopped();

        require(msg.round > self.openedRound, "already opened");
        let init: StateInit = initOf VotingRound(myAddress(), msg.round);
        require(sender() == contractAddress(init), "bad sender");

        self.openedRound = msg.round;
    }

    receive(msg: Vote) {
        self.requireNotStopped();

        let stakeAmount: Int? = self.participants.get(sender());
        require(stakeAmount != null, "not a participant");
        let stakeAmountSafe: Int = stakeAmount!!;

        let unfreezeTime: Int? = self.unfreeze.get(sender());
        require(unfreezeTime != null, "unfreeze not found");

        let unfreezeTimeSafe: Int = unfreezeTime!!;
        require(unfreezeTimeSafe > now(), "unfreeze passed");

        let currentRound: Int = (now() - self.genesisTimestamp) / self.roundPeriod;
        require(msg.round == currentRound, "invalid round");

        let internalVote: InternalVote = InternalVote{
            round: currentRound,
            payload: msg.payload,
            participant: sender(),
            guard: self.guards.get(sender()) == true,
            votes: stakeAmountSafe};
        let init: StateInit = initOf VotingRound(myAddress(), currentRound);

        if (self.openedRound == currentRound) {
            send(
                SendParameters{
                    to: contractAddress(init),
                    body: internalVote.toCell(),
                    value: 0, /// TODO: https://github.com/tact-lang/tact/issues/31
                    mode: SendRemainingValue + SendIgnoreErrors /// TODO: issues/31
                }
            );
        }
    }

    get fun votingRoundAddress(round: Int): Address {
        return contractAddress(initOf VotingRound(myAddress(), round));
    }
}
