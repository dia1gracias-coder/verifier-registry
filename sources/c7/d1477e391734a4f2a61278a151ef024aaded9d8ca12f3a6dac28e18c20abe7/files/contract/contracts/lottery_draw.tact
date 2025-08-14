import "@stdlib/deploy";

struct Ticket_Owner{
    participent: Address;
    reward: Int;
    hasClaimed: Bool;
}
message Ticket{
    ticketId: Int;
}
message TicketId{
    ticket: Int;
}

message DecreaseTime {
    seconds: Int;
}
message IncreaseTime {
    seconds: Int;
}

message IncreaseTicket {        
    ticket: Int;
}
message DecreaseTicket {        
    ticket: Int;
}
message(0xa1ed4eaa) Prepare_rewards {   
}
message(0xa1ed4eab) Distribute_rewards {
}
message (0xa1ed4eac) Ownership {
    name: String;
}
contract LotteryDraw with Deployable {

        owner : Address;
        bid: Int;
        adminPercentage: Int;
        floorPercentage: Int;
        bonusPercentage: Int;
        decayFactorNumerator: Int;
        decayFactorDenominator: Int;
        fixedPointScale: Int;
        admin: Address?;
        tickets: map<Int, Int>;
        rewards: map<Address, Int> ;
        hasClaimed: map<Address, Bool>;
        participents: map<Int ,Ticket_Owner>;
        totalPool: Int;
        participantCount: Int;
        rewardsPrepared: Bool;
        rewardsDistributed: Bool;
        minPrize: Int;
        remainingPool: Int;
        bonusCount: Int;
        guaranteedWinPool: Int;
        decayWinnerSum: Int;
        remainingDecaySum: Int;
        startTime:Int;
        endTime: Int;
        maxTicket: Int;

    init (  _adminPct: Int,  _floorPct: Int, _bonusPct: Int, _decayNum: Int, _decayDenom: Int, _Bid: Int,_HowLong: Int , _MaxTicket : Int) {
        self.owner =sender();
        self.bid=_Bid;
        self.adminPercentage = _adminPct;
        self.floorPercentage = _floorPct;
        self.bonusPercentage = _bonusPct;
        self.decayFactorNumerator = _decayNum;
        self.decayFactorDenominator = _decayDenom;
        self.fixedPointScale = 1000000;
        self.admin = sender();
        self.totalPool = 0;
        self.participantCount = 0;
        self.rewardsPrepared = false;
        self.minPrize=0;
        self.remainingPool=0;
        self.decayWinnerSum=0;
        self.bonusCount=0;
        self.remainingDecaySum=0;
        self.guaranteedWinPool=0;
        self.rewardsDistributed=false;
        self.startTime=now();
        self.endTime=now()+_HowLong*60*60;
        self.maxTicket = _MaxTicket;
    }
    receive(){
        //ton
        cashback(sender());
    }
    receive(ticket: Ticket) {
        
        require(self.participantCount < self.maxTicket,"Sorry! we have ran out of tickets..");
        require(self.bid <= context().value,"Amount is not enough for buying....");
        require(self.startTime <= now() && self.endTime>=now(),"Sorry! We have finished selling tickets...");
        
        require(!self.rewardsPrepared, "Rewards already prepared");
        let ticketId : Int = ticket.ticketId; // Assume ticketId included
        require(self.participents.get(ticketId)==null,"Duplicate ticket not allowed");
        self.participantCount += 1;
        self.tickets.set(self.participantCount,ticket.ticketId);
        self.participents.set(ticketId,Ticket_Owner{ participent:sender(),reward:0,hasClaimed:false });       
        
        let extra: Int = (context().value - self.bid);
        self.totalPool += self.bid;
    // If there's extra money, send it back
    if (extra > 0) {
        send(SendParameters{
            to: sender(),
            value: extra,
            mode: SendIgnoreErrors + SendRemainingBalance
        });
    }
    }
    
  receive(msg: Prepare_rewards) {
        require(sender() == self.owner, "Only admin");
        require(!self.rewardsPrepared, "Already prepared");
        require(self.participantCount > 0, "No participants");

        let adminCut: Int = self.totalPool * self.adminPercentage / 100;
        let prizePool: Int = self.totalPool - adminCut;
        let totalMinPrize = prizePool * self.floorPercentage / 100;
        self.remainingPool = prizePool - (totalMinPrize);
        self.minPrize = totalMinPrize / self.participantCount;
        if (self.remainingPool < 0) {
            self.remainingPool = 0;
        }

        self.bonusCount = self.participantCount * self.bonusPercentage / 100;
        self.guaranteedWinPool = self.remainingPool / 2;

        let decayWinnerSum: Int = 0;
        let i: Int=1;
        while ( i <= self.bonusCount) {
            decayWinnerSum += self.get_decay_weight(i);
            i+=1;
        }
        self.decayWinnerSum = decayWinnerSum ;
       let remainingDecaySum: Int = 0;
            while ( i <=self.participantCount) {
                remainingDecaySum += self.get_decay_weight(i);
                i+=1;
            }
        self.remainingDecaySum=remainingDecaySum;
        self.rewardsPrepared = true;
    }
    receive(msg: Distribute_rewards){
        require(sender() == self.owner, "Only admin");
        require(!self.rewardsDistributed, "Reward Already Distributed");
        require(self.rewardsPrepared, "first prepared reward then distribute reward");
        let salt: Int =1;
        let i : Int = self.participantCount;
        while (i>0) {
            //let j: Int = self.random_uint(i + 1,salt);
            let j: Int=random(salt,i + 1);
            let temp: Int? =self.tickets.get(i);
            self.tickets.set(i,self.tickets.get(j));
            self.tickets.set(j,temp);
            i-=i;
        }
        let guaranteedWinPool: Int= self.guaranteedWinPool;
        let remainingPool: Int= self.remainingPool - self.guaranteedWinPool;
        let bonusPrize: Int = 0;
        let orderIndex: Int = 1;
        let decayWinnerSum: Int =self.decayWinnerSum;
        let remainingDecaySum: Int =self.remainingDecaySum;
        let fixedPointScale:Int =self.fixedPointScale;
        let minPrize: Int=self.minPrize;
        while (orderIndex <= self.participantCount){
        if (orderIndex <=self.bonusCount) {
            let weight: Int = self.get_decay_weight(orderIndex-1);
            bonusPrize = ((guaranteedWinPool * weight) / (decayWinnerSum ));
        } else {
            let weight: Int = self.get_decay_weight(orderIndex-1);
            bonusPrize = (remainingPool * weight) / (remainingDecaySum );
        }
            let totalReward: Int = minPrize + bonusPrize;
            let ticketId: Int? = self.tickets.get(orderIndex);
            if(ticketId!=null){
             let  ticketowner: Ticket_Owner= self.participents.get(ticketId!!)!!;
             ticketowner.reward =totalReward;
             self.participents.set(ticketId!!, ticketowner);
        }
        
        orderIndex+=1;
        }
        self.rewardsDistributed=true;
    }
    receive(tk:TicketId){
        require(self.participents.get(tk.ticket)!=null,"Sorry!This Ticket has not participated in draw!");
        require(self.rewardsDistributed, "Reward Not Distributed Yet. wait for draw!!");
        require(self.participents.get(tk.ticket)!!.hasClaimed==false,"You have already claimed your reward!");
        let amount : Int?= self.participents.get(tk.ticket)!!.reward;
        require(amount!=null, "you have not participated in draw!!");
        let data: Ticket_Owner=self.participents.get(tk.ticket)!!;
        data.hasClaimed=true;
        data.reward=0;
        self.participents.set(tk.ticket,data);
        if(amount!=null){
        send(SendParameters {to: sender(), value: amount!!, body: "Hello, World".asComment() });
        }
    }
    // Function to send cashback to the sender
    fun cashback(sender: Address) {
        let cashbackAmount: Int = self.bid * 10 / 100; // 10% cashback
        send(SendParameters {
            to: sender,
            value: cashbackAmount,
            body: "Cashback".asComment()
        });
    }   
   //functo increase time

    receive(msg: IncreaseTime) {
        require(sender() == self.owner, "Only admin can increase time");
        self.endTime += msg.seconds;
    }
    // Function to decrease time
    receive(msg: DecreaseTime) {
        require(sender() == self.owner, "Only admin can decrease time");
        require(self.endTime - msg.seconds >= self.startTime, "Cannot decrease time beyond start time");
        self.endTime -= msg.seconds;
    }
    // Function to set a new owner
    receive(newOwner: Ownership) {
        require(sender() == self.owner, "Only current owner can transfer ownership");
        self.owner = sender();
    }       
    // Function to increase ticket count
    receive(msg: IncreaseTicket) {
        require(sender() == self.owner, "Only admin can increase ticket count");
        self.maxTicket += msg.ticket;
    }

    // Function to decrease ticket count    
    receive(msg: DecreaseTicket) {
        require(sender() == self.owner, "Only admin can decrease ticket count");
        require(self.maxTicket - msg.ticket >= 0, "Cannot decrease ticket count below zero");
        self.maxTicket -= msg.ticket;
    }       

    // This is a placeholder for a random number generation function.
   get fun random_uint(max: Int, salt: Int): Int {
         //randomi(salt,max);
    let data = beginCell()
        .storeUint(now(), 64)
        .storeUint(salt, 32)
        .endCell().asSlice();
        let hashVal: Int = sha256(data);
        dump(hashVal);
    
    return (hashVal % max + max) % max; 
}

    get fun get_decay_weight(index: Int) : Int {
       let numPower: Int = pow(self.decayFactorNumerator, index);
        let denomPower: Int= pow(self.decayFactorDenominator, index);
        return numPower * self.fixedPointScale / denomPower;
    }
    get fun get_participant_count() :Int {
        return self.participantCount;
    }
    get fun get_total_Pool() :Int {
        return self.totalPool;
    }
    get fun get_Ticket_Data(tk: Int) :Ticket_Owner? {
        return self.participents.get(tk);
    }
    get fun get_Ticket_TotalData() :map<Int,Ticket_Owner> {
        return self.participents;
    }
    get fun get_Ticket_map() :map<Int,Int> {
        return self.tickets;
    }
    get fun get_BonusCount() :Int{
        return self.bonusCount;
    }
    get fun get_prize(index: Int):Int{
       return (self.guaranteedWinPool * self.get_decay_weight(index) / self.decayWinnerSum) ;
    }
     get fun get_MinPrize() :Int{
        return self.minPrize;
    }
}