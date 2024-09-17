import "./message.tact";
import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";


contract GenieLaunchpad with Deployable, OwnableTransferable, Stoppable, Resumable {

    cliffDuration: Int as uint256;
    vestingStartTime: Int as uint256;
    vestingDuration: Int as uint256;
    vestingInterval: Int as uint256;
    cliffPercentage: Int as uint32;

    projectName: String;
    projectStartTime: Int as uint256; 
    projectEndTime: Int as uint256;
    ICOToken: Address;
    ICOTokenJetton: Address;
    owner: Address;
    totalRaised: Int as uint256;
    totalParticipants: Int as uint32;
    maxCap: Int as uint256;
    minBuy: Int as uint256;
    maxBuy: Int as uint256;
    tokenPrice: Int as uint256;

    userDetails: map<Address, User>;

    stopped: Bool;


    init(
        cliffDuration: Int,
        vestingStartTime: Int,
        vestingDuration: Int,
        vestingInterval: Int,
        cliffPercentage: Int,
        projectName: String,
        projectStartTime: Int,
        projectEndTime: Int,
        ICOToken: Address,
        ICOTokenJetton: Address,
        owner: Address,
        maxCap: Int,
        minBuy: Int,
        maxBuy: Int,
        tokenPrice: Int
        ){
        
        require(maxCap > 0 && tokenPrice > 0,
            "Invalid max cap or token price"
        );

        require(minBuy > 0 && maxBuy > 0,
            "Invalid max cap or token price"
        );

        self.ICOTokenJetton = ICOTokenJetton;

        self.cliffDuration = cliffDuration;
        self.vestingStartTime = vestingStartTime;
        self.vestingDuration = vestingDuration;
        self.vestingInterval = vestingInterval;
        self.cliffPercentage = cliffPercentage;

        self.projectName = projectName;
        self.projectStartTime = projectStartTime;
        self.projectEndTime = projectEndTime;
        self.ICOToken = ICOToken;
        self.owner = owner;
        self.totalRaised = 0;
        self.totalParticipants = 0;
        self.maxCap = maxCap;
        self.minBuy = minBuy;
        self.maxBuy = maxBuy;
        self.tokenPrice = tokenPrice; 

        self.stopped = false; 
    }

    receive(msg: UpdateVestingSchedules) {
        
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        if(self.vestingStartTime != 0){
            require(msg._vestingStartTime >= now(), "Vesting Already Started");
        }

        require(
            msg._vestingStartTime > self.projectEndTime,
            "Vesting Timestamp is greater than project end time"
        );

        self.vestingStartTime = msg._vestingStartTime;
        self.vestingDuration = msg._vestingDuration;
        self.vestingInterval = msg._vestingInterval;
        self.cliffDuration = msg._cliffDuration;
        self.cliffPercentage = msg._cliffPercentage;

        dump("Vesting Schedule Updated");
    }

    receive (msg:ICOJetton) {
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        self.ICOTokenJetton = msg._token;
    }

    receive("DepositTokens") {
        self.requireNotStopped();
        require(now() >= self.projectStartTime, "Sale not started yet");
        require(now() <= self.projectEndTime, "Sale Ended");

        let ctx: Context = context();
        let _amount: Int = ctx.value;
        require(_amount >= ton("0.02"), "AMOUNT_INVALID");

        let userInfoPre: User? = self.userDetails.get(sender());

        if userInfoPre == null {
            self.userDetails.set(sender(), User{investedAmount: 0, claimedTokens: 0, investedTimestamp: 0, lastClaimedTimestamp: 0});
        } 

        let userInfo: User = self.userDetails.get(sender())!!;

        let expectedAmount: Int = _amount + userInfo.investedAmount;
        require(expectedAmount >= self.minBuy, "Contribution amount must be at least minBuy amount");
        require(expectedAmount <= self.maxBuy, "Contribution amount exceeds the maximum allowed amount.");
        require(
            _amount + self.totalRaised <= self.maxCap,
            "Total contribution amount would exceed the campaign's maximum cap."
        );

        if (userInfo.investedAmount == 0) {
            self.totalParticipants = self.totalParticipants + 1 ;
        }
        send(SendParameters{
            to: self.owner,
            bounce: true,
            value: _amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });

        self.totalRaised = self.totalRaised + _amount;
        self.userDetails.set(sender(), User{investedAmount : userInfo.investedAmount + _amount,claimedTokens : 0,investedTimestamp : now(),lastClaimedTimestamp : 0});
        dump("Token Deposited");
    }

    receive(msg:Claim) {
        self.requireNotStopped();
        require(now() > self.projectEndTime, "Sale still active");
        let claimableAmount: Int = self.calculateUnlockedToken(sender());
        require(claimableAmount > 0, "No tokens to claim");

        let userInfo: User = self.userDetails.get(sender())!!;

        let ctx: Context = context();

        let forwardPayload: Cell = beginCell()
            .storeUint(0, 1)              
            .storeUint(0, 0)  
            .endCell();


        let body:Cell = beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(now(), 64)
            .storeCoins(claimableAmount) 
            .storeAddress(ctx.sender) 
            .storeAddress(myAddress())
            .storeUint(0, 1) 
            .storeCoins(ton("0.001")) 
            .storeUint(1, 1) 
            .storeRef(forwardPayload)
            .endCell();

            send(SendParameters{
            value: ton("0.04"),
            mode: SendIgnoreErrors,
            to: self.ICOTokenJetton,
            bounce: false,
            body: body
        });

        self.userDetails.set(sender(), 
        User{
            investedAmount : userInfo.investedAmount,
            claimedTokens : userInfo.claimedTokens + claimableAmount,
            investedTimestamp : userInfo.investedTimestamp,
            lastClaimedTimestamp : now()
        });

    }

    receive(msg: WithdrawToken) {
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        require(msg._tokenAmount > 0, "Amount must greater than zero");

        let ctx: Context = context();

        let forwardPayload: Cell = beginCell()
            .storeUint(0, 1)              
            .storeUint(0, 0)  
            .endCell();


        let body:Cell = beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(now(), 64)
            .storeCoins(msg._tokenAmount) 
            .storeAddress(ctx.sender) 
            .storeAddress(myAddress())
            .storeUint(0, 1) 
            .storeCoins(ton("0.001")) 
            .storeUint(1, 1) 
            .storeRef(forwardPayload)
            .endCell();

        send(SendParameters{
            value: ton("0.04"),
            mode: SendIgnoreErrors,
            to: msg._token,
            bounce: false,
            body: body
        });
    }

    receive("WithdrawTon") {
        require(sender() == self.owner, "Only owner is allowed to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - ton("0.01"),
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

   get fun calculateUnlockedToken(_wallet : Address) : Int {
        let userInfoPre: User? = self.userDetails.get(_wallet);
        if userInfoPre == null {
            return 0;
        } 

        let userInfo: User = self.userDetails.get(_wallet)!!;

        let total: Int = (userInfo.investedAmount * 1000000000) / self.tokenPrice;

        if (now() < self.vestingStartTime + self.cliffDuration) {
            return 0;
        } 
        else if (now() >= self.vestingStartTime + self.cliffDuration + self.vestingDuration) {
            return total - userInfo.claimedTokens;
        } 
        else {
            let elapsedTime: Int = now() - (self.vestingStartTime + self.cliffDuration);
            let vestingPeriods: Int = elapsedTime / self.vestingInterval;

            let cliffReleaseAmount: Int = (total * self.cliffPercentage) / 100; 
            let totalVested: Int = cliffReleaseAmount +
                (((total - cliffReleaseAmount) * vestingPeriods * self.vestingInterval) / self.vestingDuration);
            return totalVested - userInfo.claimedTokens;
        }
    }

    get fun userDetails(_address: Address): User? {
       return self.userDetails.get(_address);
    }

    get fun cliffDuration(): Int {
        return self.cliffDuration;
    }

    get fun vestingStartTime(): Int {
        return self.vestingStartTime;
    }

    get fun vestingDuration(): Int {
        return self.vestingDuration;
    }

    get fun vestingInterval(): Int {
        return self.vestingInterval;
    }

    get fun cliffPercentage(): Int {
        return self.cliffPercentage;
    }

    get fun projectName(): String {
        return self.projectName;
    }

    get fun projectStartTime(): Int {
        return self.projectStartTime;
    }

    get fun projectEndTime(): Int {
        return self.projectEndTime;
    }

    get fun ICOToken(): Address {
        return self.ICOToken;
    }

    get fun totalRaised(): Int {
        return self.totalRaised;
    }

    get fun totalParticipants(): Int {
        return self.totalParticipants;
    }

    get fun maxCap(): Int {
        return self.maxCap;
    }

    get fun minBuy(): Int {
        return self.minBuy;
    }

    get fun maxBuy(): Int {
        return self.maxBuy;
    }

    get fun tokenPrice(): Int {
        return self.tokenPrice;
    }
}
