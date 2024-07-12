import "@stdlib/deploy";
import "@stdlib/ownable";

struct Stake {
    amount: Int as coins;
    timestamp: Int as uint64;
}

struct User {
    stakes: map<Int, Stake>;
    lastClaimTimestamp: Int as uint64;
    totalStaked: Int as coins;
    referrer: Address?;
    stakeCount: Int;
    referralReward: Int;
    withdrawn: Int;
}

message ReferralAddress{
    referral: Address;
    amount: Int;
}

contract Stakee with Deployable, OwnableTransferable {
    owner: Address;
    users: map<Address, User>;
    dailyRoi: Int;
    referralPercentage: Int;
    globalTotalStaked: Int = 0;
    TIME_STEP: Int = 60;//86400;
    
    init(owner: Address, _dailyRoi: Int, _referralPercentage: Int) {
        self.owner = owner;
        self.dailyRoi = _dailyRoi;
        self.referralPercentage = _referralPercentage;
    }

    receive(receiverAddress: ReferralAddress) {
        // let slice: Slice = context().raw;
        self.doStake(context().sender,receiverAddress);
    }

    fun doStake(sender: Address, _details: ReferralAddress) {
        let fee = ton("0.01");
        require(context().value >= _details.amount + fee, "Insufficient funds sent");
        let amount: Int = _details.amount;
        let user: User = self.getOrCreateUser(sender, _details.referral);

        user.stakeCount = user.stakeCount + 1;
        let stakeId: Int = user.stakeCount;
        user.stakes.set(stakeId, Stake{amount: amount, timestamp: now()});
        user.totalStaked = user.totalStaked + amount;
        let referralReward: Int = (amount * self.referralPercentage) / 100;

        if (user.referrer != null) {
            user.referralReward += referralReward;
        }
        self.users.set(sender, user);

        // self.globalTotalStaked += amount;

        // Calculate the amount to refund
        let refundAmount = context().value - _details.amount - fee;
        // Refund excess amount if any
        if (refundAmount > 0) {
            self.globalTotalStaked += refundAmount;
            send(SendParameters{
                to: sender(),
                value: refundAmount,
                mode: SendIgnoreErrors
            });
        }

        
    }

    fun getOrCreateUser(address: Address, referrer: Address?): User {
        if (self.users.get(address) != null) {
            return self.users.get(address)!!;
        } else {
            return User{
                stakes: emptyMap(),
                lastClaimTimestamp: now(),
                totalStaked: 0,
                referrer: referrer,
                stakeCount: 0,
                referralReward: 0,
                withdrawn: 0
            };
        }
    }

    receive("claim_rewards") {
        let sender: Address = context().sender;
        require(self.users.get(sender) == null,"User not found");
        
        let user: User = self.users.get(sender)!!;

        let currentTime: Int = now();
        let daysSinceLastClaim: Int = (currentTime - user.lastClaimTimestamp) / self.TIME_STEP;
        let totalReward: Int = 0;

        let i: Int = 1;
        repeat(user.stakeCount) {
            if (user.stakes.get(i) != null) {
                let stake: Stake = user.stakes.get(i)!!;
                let stakeAge: Int = (currentTime - stake.timestamp) / self.TIME_STEP;
                let daysToReward: Int = min(stakeAge, daysSinceLastClaim);
                let reward: Int = (stake.amount * self.dailyRoi * daysToReward) / 10000;
                totalReward = totalReward + reward;
            }
            i = i + 1;
        }

        require(totalReward > 0, "No rewards to claim");

        user.lastClaimTimestamp = currentTime;
        self.users.set(sender, user);

        send(SendParameters{
            to: sender,
            value: totalReward,
            mode: SendIgnoreErrors
        });
    }

    receive("unstake") {
        let slice: Slice = context().raw;
        let stakeId: Int = slice.loadInt(32);
        let sender: Address = context().sender;
        require(self.users.get(sender) == null,"User not found");
        
        let user: User = self.users.get(sender)!!;

        require(user.stakes.get(stakeId) == null,"Stake not found");
        
        let stake: Stake = user.stakes.get(stakeId)!!;

        user.stakes.set(stakeId,null);
        user.totalStaked = user.totalStaked - stake.amount;
        self.users.set(sender, user);

        send(SendParameters{
            to: sender,
            value: stake.amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    get fun availableToWithdraw(userAddress: Address): Int{
        require(self.users.get(userAddress) == null,"User not found");
        
        let user: User = self.users.get(userAddress)!!;

        let currentTime: Int = now();
        let daysSinceLastClaim: Int = (currentTime - user.lastClaimTimestamp) / self.TIME_STEP;
        let totalReward: Int = 0;

        let i: Int = 1;
        repeat(user.stakeCount) {
            if (user.stakes.get(i) != null) {
                let stake: Stake = user.stakes.get(i)!!;
                let stakeAge: Int = (currentTime - stake.timestamp) / self.TIME_STEP;
                let daysToReward: Int = min(stakeAge, daysSinceLastClaim);
                let reward: Int = (stake.amount * self.dailyRoi * daysToReward) / 10000;
                totalReward = totalReward + reward;
            }
            i = i + 1;
        }
        return totalReward;
    }

    get fun getUserInfo(userAddress: Address): User? {
        return self.users.get(userAddress);
    }

    get fun getTotalStaked(): Int {
        return self.globalTotalStaked;
    }
}