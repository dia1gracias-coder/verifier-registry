import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

message ReferralPer {
    rank: Int;
    percentage: Int;
}

message UpdateTreasuryAddress {
    treasuryAddress: Address;
}

message UpdateGovnAddress {
    govnAddress: Address;
}

message UpdateRewardPoolAddress {
    rewardPoolAddress: Address;
}

message Deposit {
    userId: String;
    amount: Int as coins;
    petConfigId: String;
}

message Distribution {
    amount: Int as coins;
    transactionId: Int;
    referralOneAddress: Address?;
    referralOneCommissionRate: Int?;
    referralTwoAddress: Address?;
    referralTwoCommissionRate: Int?;
    referralThreeAddress: Address?;
    referralThreeCommissionRate: Int?;
    referralFourAddress: Address?;
    referralFourCommissionRate: Int?;
    referralFiveAddress: Address?;
    referralFiveCommissionRate: Int?;
}

message Withdraw {
    amount: Int as coins;
}

contract ReferralDistributionV2 with Deployable, Resumable, OwnableTransferable {
    const MinTonForStorage: Int = ton("0.05");
    const MinGasConsumption: Int = ton("0.05");
    const HighestPerGap: Int = 10000; // 0.00% to 100.00%
    const MaxReferralRank: Int = 5;
    owner: Address;
    govnAddress: Address = address("0QBIpSWj7JWgCAvWfUHeB5t-r5BlpbSe0YTrhDQ8sQe2joJk");
    treasuryAddress: Address = address("0QBIpSWj7JWgCAvWfUHeB5t-r5BlpbSe0YTrhDQ8sQe2joJk");
    rewardPoolAddress: Address = address("0QAeVC13e5YsQoL850K24g6sU1E_NuNLsWHun7pYGmUy18eE");
    stopped: Bool;
    referralPer: map<Int, Int>;
    init(){
        self.owner = sender();
        self.stopped = false;
        self.referralPer.set(0, 500); // 5% - Treasury
        self.referralPer.set(1, 4000); // 40%
        self.referralPer.set(2, 2500); // 25%
        self.referralPer.set(3, 1500); // 15%
        self.referralPer.set(4, 1000); // 10%
        self.referralPer.set(5, 500); // 5%
    }

    // Update rank percentage
    receive(msg: ReferralPer) {
        self.requireOwner();
        require(msg.rank <= self.MaxReferralRank, "Rank not available");
        require(msg.rank >= 0, "Rank not available");

        let sum: Int = self.percentageSum();
        require(sum - self.referralPer(msg.rank) + msg.percentage <= self.HighestPerGap, "Total Percentage >= 100");

        self.referralPer.set(msg.rank, msg.percentage);
    }

    // Update Treasury Address
    receive(msg: UpdateTreasuryAddress) {
        self.requireOwner();
        self.treasuryAddress = msg.treasuryAddress;
    }

    // Update Treasury Address
    receive(msg: UpdateGovnAddress) {
        self.requireOwner();
        self.govnAddress = msg.govnAddress;
    }

    // Update Reward Pool Address
    receive(msg: UpdateRewardPoolAddress) {
        self.requireOwner();
        self.rewardPoolAddress = msg.rewardPoolAddress;
    }

    // Deposit 
    receive(msg: Deposit) {
        self.requireNotStopped();
        let ctx: Context = context();
        let receivedTon: Int = ctx.value;
        if(myBalance() - receivedTon < self.MinTonForStorage) {
            receivedTon -= (self.MinTonForStorage + receivedTon - myBalance());
        }

        receivedTon -= self.MinGasConsumption; // gas fee
        require(receivedTon > 0, "Insufficient Amount");
        require(msg.amount <= receivedTon, "Insufficient Amount");

        let replyComment: StringBuilder = 
            beginString().
            concat("userId ").
            concat(msg.userId).
            concat(" ").
            concat("amount ").
            concat(msg.amount.toString()).
            concat(" ").
            concat("petConfigId ").
            concat(msg.petConfigId);

        send(SendParameters{to: sender(), value: receivedTon - msg.amount, mode: SendIgnoreErrors, body: replyComment.toString().asComment()});
    }

    // Distribution 
    receive(msg: Distribution) {
        self.requireNotStopped();
        let ctx: Context = context();
        self.requireGovnAddress(ctx);

        let contractBalance: Int = myBalance();
        let amountForRewardPool: Int = msg.amount;
        require(contractBalance >= msg.amount + self.MinTonForStorage + self.MinGasConsumption, "Insufficient Amount");

        let amountForTreasury: Int = msg.amount * self.referralPer(0) / self.HighestPerGap;
        amountForRewardPool -= amountForTreasury;
        send(SendParameters{to: self.treasuryAddress, value: amountForTreasury, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false });

        if(msg.referralOneAddress != null && msg.referralOneCommissionRate != null) {
            let amountToSend: Int = msg.amount * self.referralPer(1) / self.HighestPerGap * msg.referralOneCommissionRate!! / self.HighestPerGap;
            send(SendParameters{to: msg.referralOneAddress!!, value: amountToSend, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false });
            amountForRewardPool -= amountToSend;
        }
        
        if(msg.referralTwoAddress != null && msg.referralTwoCommissionRate != null) {
            let amountToSend: Int = msg.amount * self.referralPer(2) / self.HighestPerGap * msg.referralTwoCommissionRate!! / self.HighestPerGap;
            send(SendParameters{to: msg.referralTwoAddress!!, value: amountToSend, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false });
            amountForRewardPool -= amountToSend;
        }

        if(msg.referralThreeAddress != null && msg.referralThreeCommissionRate != null) {
            let amountToSend: Int = msg.amount * self.referralPer(3) / self.HighestPerGap * msg.referralThreeCommissionRate!! / self.HighestPerGap;
            send(SendParameters{to: msg.referralThreeAddress!!, value: amountToSend, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false });
            amountForRewardPool -= amountToSend;
        }

        if(msg.referralFourAddress != null && msg.referralFourCommissionRate != null) {
            let amountToSend: Int = msg.amount * self.referralPer(4) / self.HighestPerGap * msg.referralFourCommissionRate!! / self.HighestPerGap;
            send(SendParameters{to: msg.referralFourAddress!!, value: amountToSend, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false });
            amountForRewardPool -= amountToSend;
        }

        if(msg.referralFiveAddress != null && msg.referralFiveCommissionRate != null) {
            let amountToSend: Int = msg.amount * self.referralPer(5) / self.HighestPerGap * msg.referralFiveCommissionRate!! / self.HighestPerGap;
            send(SendParameters{to: msg.referralFiveAddress!!, value: amountToSend, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false });
            amountForRewardPool -= amountToSend;
            
        }

        if(amountForRewardPool >= ton("0.02")) {
            send(SendParameters{to: self.rewardPoolAddress, value: amountForRewardPool, mode: SendIgnoreErrors + SendPayGasSeparately, bounce: false });
        }

        let replyComment: StringBuilder = 
            beginString().
            concat("transactionId ").
            concat(msg.transactionId.toString());

        self.reply(replyComment.toString().asComment());
    }

    // Partial Withdraw
    receive(msg: Withdraw){
        self.requireOwner();
        let amount: Int = min(msg.amount, ((myBalance() - context().value) - self.MinTonForStorage));
        require(amount > 0, "Insufficient balance");
        send(SendParameters{to: sender(), bounce: true, value: amount, mode: (SendIgnoreErrors + SendRemainingValue)});
    }

    // Withdraw All
    receive("Withdraw All"){
        self.requireOwner();
        send(SendParameters{to: sender(), bounce: true, value: 0, mode: (SendIgnoreErrors + SendRemainingBalance)});
    }

    fun percentageSum(): Int {
        let sum :Int = 0;
        let i :Int = 0;
        while(i <= self.MaxReferralRank){
            sum += self.referralPer.get(i)!!;
            i += 1;
        }

        return sum;
    }

    fun requireGovnAddress(ctx: Context) {
        require(ctx.sender == self.govnAddress, "Only govn address can call this function");
    }

    get fun referralPer(key: Int): Int {
        require(key <= self.MaxReferralRank, "Rank not available");
        require(key >= 0, "Rank not available");

        return self.referralPer.get(key)!!; 
    }

    get fun treasuryAddress(): Address {
        return self.treasuryAddress; 
    }

    get fun govnAddress(): Address {
        return self.govnAddress; 
    }

    get fun rewardPoolAddress(): Address {
        return self.rewardPoolAddress; 
    }

    get fun currentBalance(): Int {
        return myBalance(); 
    }
}