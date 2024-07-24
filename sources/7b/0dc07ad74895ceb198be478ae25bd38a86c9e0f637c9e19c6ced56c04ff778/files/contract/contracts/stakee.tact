import "@stdlib/deploy";
import "@stdlib/ownable";



struct User {
    lastClaimTimestamp: Int as uint64;
    totalStaked: Int as coins;
    referrer: Address;
    referralReward: Int;
    referralCount: Int;
    withdrawn: Int;
    availableToWithdraw: Int;
}

message ReferralAddress{
    referral: Address;
    amount: Int;
}

message UnstakeAmount{
    amount: Int;
}

contract Stakee with Deployable, OwnableTransferable {
    ID: Int as uint32;
    owner: Address;
    users: map<Address, User>;
    APY: Int;
    referralPercentage: Int;
    adminPercentage: Int;
    deductPercentage: Int;
    globalTotalStaked: Int = 0;
    TIME_STEP: Int = 365 * 86400;
    MIN_STORAGE_FEE: Int = ton("0.05");
    TOTAL_STAKED: Int = 0;
    
    init(id: Int,owner: Address, _APY: Int, _referralPercentage: Int, _adminPercentage: Int, _deductPercentage: Int) {
        self.ID = id;
        self.owner = owner;
        self.APY = _APY;
        self.referralPercentage = _referralPercentage;
        self.adminPercentage = _adminPercentage;
        self.deductPercentage = _deductPercentage;
        let user:User = User{
                lastClaimTimestamp: now(),
                totalStaked: 0,
                referrer: owner,
                referralReward: 0,
                referralCount: 0,
                withdrawn: 0,
                availableToWithdraw: 0
            };

        self.users.set(owner,user);
    }

    receive()
    {

    }

    receive(receiverAddress: ReferralAddress) {
        self.doStake(context().sender,receiverAddress);
    }

    receive(unstake: UnstakeAmount) {
        self.doUnstake(unstake.amount);
    }

    fun doStake(sender: Address, _details: ReferralAddress) {
        let fee = ton("0.01");
        require(context().value >= _details.amount + fee, "Insufficient funds sent");
        let amount: Int = _details.amount;
        let user: User = self.getOrCreateUser(sender, _details.referral);
        user.totalStaked = user.totalStaked + amount;
        let referralReward: Int = (amount * self.referralPercentage) / 1000;

        if (user.referrer != null) {
            let ref: User = self.users.get(user.referrer)!!;
            ref.referralReward += referralReward;
            self.users.set(user.referrer, ref);
        }
        self.users.set(sender, user);

        self.globalTotalStaked += amount;

        // Calculate the amount to refund
        let refundAmount = context().value - _details.amount - fee;
        // Refund excess amount if any
        if (refundAmount > 0) {
            send(SendParameters{
                to: sender(),
                value: refundAmount,
                mode: SendIgnoreErrors
            });
        }

        // Send fees to admin
        send(SendParameters{
            to: self.owner,
            value: amount * self.adminPercentage / 1000,
            mode: SendIgnoreErrors
        });

    }

    fun doUnstake(amount: Int) {
        let slice: Slice = context().raw;
        let sender: Address = context().sender;
        let feeSent: Int = context().value;
        require(self.users.get(sender) != null, "User not found");
        
        let user: User = self.users.get(sender)!!;
        require(user.totalStaked >= amount, "Invalid amount");
        
        self.doClaimRewards(sender);

        require((myBalance()-feeSent) >= (amount+self.MIN_STORAGE_FEE),"Balance is low");

        let userWrite: User = self.users.get(sender)!!;
        userWrite.totalStaked -= amount;
        self.globalTotalStaked -= amount;
        self.users.set(sender, userWrite);

        send(SendParameters{
            to: sender,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });

    }

    fun getOrCreateUser(address: Address, referrer: Address): User {
        if (self.users.get(address) != null) {
            self.doClaimRewards(address);
            return self.users.get(address)!!;
        } else {
            let ref: User = self.users.get(referrer)!!;
            ref.referralCount += 1;
            self.users.set(referrer, ref);

            return User{
                lastClaimTimestamp: now(),
                totalStaked: 0,
                referrer: referrer,
                referralReward: 0,
                referralCount: 0,
                withdrawn: 0,
                availableToWithdraw: 0
            };
        }
    }

    receive("claim_rewards_staked") {
        let sender: Address = context().sender;
        let feeSent: Int = context().value;

        self.doClaimRewards(sender);
        let user: User = self.users.get(sender)!!;

        let amount: Int = user.availableToWithdraw;
        require(amount > 0, "No stake reward to claim");
       
        amount -= (amount*self.deductPercentage)/1000;

        let contractBalance: Int = myBalance() - feeSent;
    
        require(contractBalance >= (amount + self.MIN_STORAGE_FEE), "Insufficient balance for withdrawal");

        user.availableToWithdraw = 0;
        self.users.set(sender, user);
        
        send(SendParameters{
            to: sender,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });

    }

    fun doClaimRewards(_user: Address){
        let sender: Address = _user;
        require(self.users.get(sender) != null, "User not found");
        
        let user: User = self.users.get(sender)!!;

        let currentTime: Int = now();
        
        let stakeAge: Int = (currentTime - user.lastClaimTimestamp);
        let totalReward: Int = (user.totalStaked * self.APY * stakeAge) / (1000 * self.TIME_STEP);

        user.availableToWithdraw += totalReward;
        user.lastClaimTimestamp = currentTime;
        self.users.set(sender, user);
    }

    receive("claim_referral") {
        let sender: Address = context().sender;
        let feeSent: Int = context().value;
        require(self.users.get(sender) != null, "User not found");

        let user: User = self.users.get(sender)!!;
        let reward: Int = user.referralReward;

        require(reward > 0, "No referral reward to claim");
        let userWrite: User = self.users.get(sender)!!;
        userWrite.referralReward = 0;
        self.users.set(sender, userWrite);

        reward -= (reward*self.deductPercentage)/1000;


        require((myBalance()-feeSent) >= (reward+self.MIN_STORAGE_FEE),"Balance is low");

        send(SendParameters{
            to: sender,
            value: reward,
            mode: SendRemainingValue + SendIgnoreErrors
        });

    }

    get fun getUserInfo(userAddress: Address): User {
        return self.users.get(userAddress)!!;
    }

    get fun getTotalStaked(): Int {
        return self.globalTotalStaked;
    }

    get fun getAPY(): Int {
        return self.APY;
    }

    get fun getTimeStep(): Int {
        return self.TIME_STEP;
    }

    get fun getMinFee(): Int {
        return self.MIN_STORAGE_FEE;
    }

    get fun getBalance(): Int {
        return myBalance();
    }
}