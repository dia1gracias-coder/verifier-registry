import "@stdlib/deploy";

message UnStake {
    index: Int;
}
message StakeData {
    amount: Int;
}

struct IndexStake {
    m: map<Int,Stake> = emptyMap();//index,Stake
}

struct Stake {
    amount: Int;
    endTime: Int;
}

contract NestedStaking with Deployable {

    stakes: map<Address, IndexStake>;
    index: Int as uint32 = 0;
    LOCKUP_PERIOD: Int as uint32 = 2;

    receive(msg: UnStake) {
        let existingStake: IndexStake = self.stakes.get(sender())!!;
        // Check if the stake exists and if it's not already removed (null)
        let stake = existingStake.m.get(msg.index);
        require(stake != null, "Stake not found or already removed");
        //
        require(stake!!.amount > 0, "Stake amount is zero");
        require(stake!!.endTime <= now(), "Lock period not yet over");

        send(SendParameters{
            to: sender(),
            bounce: false, // Change bounce to false to allow graceful fallback
            value: stake!!.amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
        //
        // Set the stake at the given index to null (marking it as removed)
        existingStake.m.set(msg.index, null);
        // Optionally, update the map back into stakes if needed
        self.stakes.set(sender(), existingStake);
    }

    receive("deleteRoot") {
        self.stakes.set(sender(),null);
    }

    receive(msg: StakeData) {
        let endTime = now() + self.LOCKUP_PERIOD;
        let fiz: IndexStake = IndexStake{};
        let existingStake = self.stakes.get(sender());
        if (existingStake != null) {
            fiz = existingStake!!;
        }
        let stake: Stake = Stake{amount: context().value,endTime: endTime};
        fiz.m.set(self.index,stake);
        self.stakes.set(sender(),fiz);
        self.index = self.index + 1;
    }

    get fun stakeIndex(index: Int): Stake {
        let existingStake = self.stakes.get(sender())!!;
        return existingStake.m.get(index)!!;
    }

    get fun stakes(): map<Address, IndexStake> {
        return self.stakes;
    }
}