import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";

struct VestingSchedule {
    beneficiary: Address;
    start: Int as uint32;
    duration: Int as uint32;
    amountTotal: Int as coins;
    released: Int as coins;
}

contract VestingContract with Deployable, Ownable {
    const ForStorage: Int = ton("0.25");

    owner: Address;
    jettonAddress: Address;
    recipient: Address;

    vestingSchedules: map<Int as uint256, VestingSchedule>;
    holdersVestingCount: map<Address, Int as uint8>;
    referralTree: map<Address, Address>;

    vestingSchedulesTotalAmount: Int as coins = 0;
    stage: Int as uint8;
    rate: Int as uint32;
    durationVesting: Int as uint32;
    cliff: Int as uint32;
    slicePeriod: Int as uint32;
    tonRate: Int as coins;
    minAmount: Int as coins;

    init(jettonAddress: Address, recipient: Address) {
        self.owner = sender();
        self.jettonAddress = jettonAddress;
        self.recipient = recipient;

        self.durationVesting = 57024000;//660 days
        self.cliff = 6480000;//2.5 month
        self.slicePeriod = 86400;//1 day
        self.rate = 150000000;
        self.stage = 1;
        self.tonRate = 5440000000;

        self.minAmount = 900000000000;

        self.referralTree.set(recipient, sender());

    }

    fun onlyOwner(){
        require(sender() == self.owner, "only owner can use this method");
    }

    fun notSender(address: Address) {
        require(sender() != address, "address same as yours");
    }

    fun minimalAmount() {
        require(context().value*(self.tonRate/1000000000) >= self.minAmount, "minimal amount is 1000 usdt");
    }

    fun referralPayment(sponsor: Address, amount: Int) {
        let bonusOne: Int = (amount*7)/100;
        self.sendPayment(sponsor, bonusOne);
        let levelTwo: Address? = self.referralTree.get(sponsor);
        if(levelTwo != null) {
            let bonusTwo: Int = (amount*5)/100;
            self.sendPayment(levelTwo!!, bonusTwo);
            let levelThree: Address? = self.referralTree.get(levelTwo!!);
            if(levelThree != null) {
                let bonusThree: Int = (amount*3)/100;
                self.sendPayment(levelThree!!, bonusThree);
            }
        }
    }

    fun sendPayment(address: Address, value: Int) {
        send(SendParameters{
            to: address,
            bounce: true,
            value: value,
            mode: SendIgnoreErrors,
			body: "referral income".asComment(),
        });   
    }

    fun computeVestingIdByData(holder: Address, index: Int): Int {
        let sb: StringBuilder = beginString();
        sb.append(holder.toString());
        sb.append(index.toString());
        return sha256(sb.toString());
    }

    fun computeClaimAmount(schedule: VestingSchedule?): Int {
        let currentTime: Int = now();

        if (currentTime >= schedule!!.start+schedule!!.duration) {
            return schedule!!.amountTotal-schedule!!.released;
        } else {
            let timeFromStart: Int = currentTime - schedule!!.start;
            let secondsPerSlice: Int = self.slicePeriod;
            let vestedSlicePeriods: Int = timeFromStart/secondsPerSlice;
            let vestedSeconds: Int = vestedSlicePeriods*secondsPerSlice;
            let vestedAmount: Int = (schedule!!.amountTotal*vestedSeconds)/schedule!!.duration;
            vestedAmount = vestedAmount-schedule!!.released;
            return vestedAmount;
        }
    }

    fun addVestingSchedule(jettonAmount: Int, beneficiary: Address, start: Int, durationVesting: Int) {
        let vesting: VestingSchedule = VestingSchedule{ 
            beneficiary: beneficiary,
            start: start,
            duration: durationVesting,
            amountTotal: jettonAmount,
            released: 0
        };

        let counter: Int? = self.holdersVestingCount.get(beneficiary);
        if (counter == null) {
            self.vestingSchedules.set(self.computeVestingIdByData(beneficiary, 1), vesting);
            self.holdersVestingCount.set(beneficiary, 1);
        } else {
            self.vestingSchedules.set(self.computeVestingIdByData(beneficiary, counter!!+1), vesting);
            self.holdersVestingCount.set(sender(), counter!!+1);
        }
    }

    receive(msg: OrderJetton) {
        self.minimalAmount();
        self.notSender(msg.sponsorAddress);
        //require(self.referralTree.get(msg.sponsorAddress) != null, "your sponsor after sponsor not activate in the system");
        if(self.referralTree.get(sender()) == null) {
            self.referralTree.set(sender(), msg.sponsorAddress);
        }

        let jettonAmount: Int = context().value*self.tonRate/self.rate;
        self.addVestingSchedule(jettonAmount, sender(), now()+self.cliff, self.durationVesting);
        self.vestingSchedulesTotalAmount += jettonAmount;
		
        self.referralPayment(msg.sponsorAddress, context().value);
    }

    receive(msg: String) {
        
    }

    receive(msg: Slice) {
        
    }

    receive(msg: Claim) {
        let beneficiary: Address = sender();
        let schedule: VestingSchedule = self.vestingSchedules.get(msg.hash)!!;
        let owner: Address = schedule.beneficiary;
        if (beneficiary == owner) {
            let vestedAmount: Int = self.computeClaimAmount(schedule);
            self.vestingSchedules.set(msg.hash, VestingSchedule{
                beneficiary: schedule.beneficiary,
                start: schedule.start,
                duration: schedule.duration,
                amountTotal: schedule.amountTotal,
                released: schedule.released+vestedAmount
            });

            send(SendParameters{  
                to: self.jettonAddress,
                value: 0,
                mode: SendRemainingValue,
                bounce: false,
                body: TokenTransfer{
                    queryId: 0,
                    amount: vestedAmount,
                    destination: beneficiary,
                    response_destination: myAddress(),
                    custom_payload: emptyCell(),
                    forward_ton_amount: 0,
                    forward_payload: emptySlice()
                }.toCell()
            });
        }
    }

    receive(msg: RevokeVesting) {
        self.onlyOwner();
        let hash: Int = self.computeVestingIdByData(msg.address, msg.index);
        let lastCount: Int? = self.holdersVestingCount.get(msg.address);
        self.vestingSchedules.set(hash, null);
        self.holdersVestingCount.set(msg.address, lastCount!!-1);
    }

    receive(msg: ActivateReferralLink) {
        self.notSender(msg.sponsorAddress);
        if (self.referralTree.get(msg.sponsorAddress) != null) {
            if(self.referralTree.get(sender()) == null) {
                self.referralTree.set(sender(), msg.sponsorAddress);
            }
        }
    }

    receive(msg: ActivateReferralLinkByOwner) {
        self.onlyOwner();
        if (self.referralTree.get(msg.sponsorAddress) != null) {
            if(self.referralTree.get(msg.referralAddress) == null) {
                self.referralTree.set(msg.referralAddress, msg.sponsorAddress);
            }
        }
    }

    receive(msg: SetCrowdsaleStage) {
        self.onlyOwner();
        if (msg.stage == 2) {
            self.stage = msg.stage;
            self.durationVesting = 46656000; //540 days
            self.rate = 250000000;
        } else if (msg.stage == 3) {
            self.stage = msg.stage;
            self.durationVesting = 36288000; //420 days
            self.rate = 350000000;
        } 
    }

    receive(msg: SetTonRate) {
        self.onlyOwner();
        self.tonRate = msg.rate;
    }

    receive(msg: SetJettonAddress) {
        self.onlyOwner();
        self.jettonAddress = msg.jettonAddress;
    }

    receive(msg: SetMinimalAmount) {
        self.onlyOwner();
        self.minAmount = msg.minAmount;
    }

    receive(msg: AddVestingScheduleByManual) {
        self.onlyOwner();
        self.addVestingSchedule(msg.jettonAmount, msg.beneficiary, msg.start+msg.cliff, msg.durationVesting);
        self.vestingSchedulesTotalAmount += msg.jettonAmount;
    }

    receive("withdraw all"){
        self.onlyOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    receive("withdraw tons"){
        self.onlyOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - self.ForStorage,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    get fun get_sponsor(referral: Address): Address? {
        return self.referralTree.get(referral);
    }

    get fun get_vested_hash(address: Address, index: Int): Int {
        let hash: Int = self.computeVestingIdByData(address, index);
        return hash;
    }

    get fun get_count_vesting(address: Address): Int {
        if (self.holdersVestingCount.get(address) == null) {
            return 0;
        }
        return self.holdersVestingCount.get(address)!!;
    }

    get fun get_vested_jettons_info(address: Address, index: Int): VestingSchedule? {
        let hash: Int = self.computeVestingIdByData(address, index);
        return self.vestingSchedules.get(hash);
    }

    get fun get_vested_jettons_all(): map<Int as uint256, VestingSchedule> {
        return self.vestingSchedules;
    }

    get fun referral_tree(): map<Address, Address> {
        return self.referralTree;
    }

    get fun get_vested_jettons(address: Address, index: Int): Int {
        let hash: Int = self.computeVestingIdByData(address, index);
        return self.vestingSchedules.get(hash)!!.amountTotal;
    }

    get fun get_vested_jettons_start(address: Address, index: Int): Int {
        let hash: Int = self.computeVestingIdByData(address, index);
        return self.vestingSchedules.get(hash)!!.start;
    }

    get fun get_vested_jettons_released(address: Address, index: Int): Int {
        let hash: Int = self.computeVestingIdByData(address, index);
        return self.vestingSchedules.get(hash)!!.released;
    }

    get fun get_vested_jettons_claim(hash: Int): Int {
        let schedule: VestingSchedule? = self.vestingSchedules.get(hash);
        let vestedAmount: Int = self.computeClaimAmount(schedule);
        return vestedAmount;
    }

    get fun get_total_vested_jettons(): Int {
        return self.vestingSchedulesTotalAmount;
    }

    get fun balance(): String {
        return myBalance().toCoinsString();
    }

    get fun ton_rate(): Int {
        return self.tonRate;
    }

    get fun rate(): Int {
        return self.rate;
    }

    get fun stage(): Int {
        return self.stage;
    }
    
    get fun min_amount(): Int {
        return self.minAmount;
    }
}
