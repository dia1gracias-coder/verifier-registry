import "@stdlib/stoppable";
import "./common.tact";

message (0x65548561) ReleaseFunds {
  releaseAmount: Int as coins;
  metadata: String;
}

message (0x75548561) ReturnFunds {
  returnAmount: Int as coins;
  destination: Address?;
  metadata: String;
}                    

message (0x85548561) UpdateDetails {
  dealAddress: Address;

  deadlineUNIX: Int? as uint64;

  referralCustomerAddress: Address?;
  referralFreelancerAddress: Address?;
}

contract DealContract {
  parent: Address;
  oracleAddress: Address?;
  guid: String;
  myUsdtAddress: Address?;
  isFinished: Bool;
  stopped: Bool;

  // deal data

  dealAmount: Int? as coins; // constant
  deadlineUNIX: Int? as uint64;
  client: Address;
  authorRightsOwner: Address?;

  referralCustomerAddress: Address?;
  referralFreelancerAddress: Address?;

  commissions: Commissions?;

  init(parent: Address, client: Address, guid: String) {
    self.parent = parent;
    self.client = client;
    self.guid = guid;
    self.isFinished = false;
    self.stopped = false;
  }

  receive(msg: TokenNotification) {
    self.requireNotStopped();

    let maybeMsgCell = msg.forward_payload.preloadMaybeRef();
 
    let msgSlice = 
      (maybeMsgCell != null) 
      ? maybeMsgCell!!.asSlice()
      : msg.forward_payload;

    let msgId = msgSlice.preloadUint(32);

    // init deal contract data
    if (msgId == 0x95548561 && self.myUsdtAddress == null && self.parent == msg.from) {
      self.myUsdtAddress = sender();

      let deal: OpenDealInternal = OpenDealInternal.fromSlice(msgSlice);
      self.initData(deal);
    }
    // ReleaseFunds
    else if (msgId == 0x65548561 && self.myUsdtAddress != null) { 
      if (msg.from == self.client || msg.from == self.parent || (self.oracleAddress != null && msg.from == self.oracleAddress)) {
        let releaseFunds: ReleaseFunds = ReleaseFunds.fromSlice(msgSlice);
        self.releaseFunds(msg.queryId, msg.from, msg.amount, releaseFunds);
      }
    }
  }

  receive(msg: ReturnFunds) {
    self.requireNotStopped();

    require(self.client == sender() || self.isParent() || self.isOracle(), "Only client or parent or oracle can return funds");

    let ctx = context();

    let destAddress = self.client;
    if (msg.destination != null) {
      destAddress = msg.destination!!;
    }

    send(SendParameters{
       to: self.myUsdtAddress!!,
       value: self.getPercentVal(ctx.value, 800), // %80
       body: TokenTransfer{
          queryId: random(0, 18446744073709551615), // uint64
          amount: msg.returnAmount,
          destination: destAddress,
          response_destination: self.client,
          custom_payload: null,
          forward_ton_amount: 0,
          forward_payload: beginCell().storeBit(false).asSlice()
       }.toCell()
    });
  }

  fun initData(deal: OpenDealInternal) {
    self.oracleAddress = deal.oracleAddress;

    self.dealAmount = deal.dealAmount;

    self.deadlineUNIX = deal.deadlineUNIX;
                                                                  
    self.authorRightsOwner = deal.workerAddress;
                                                                  
    self.referralCustomerAddress = deal.referralCustomerAddress;
    self.referralFreelancerAddress = deal.referralFreelancerAddress;

    self.commissions = deal.commissions;

    let returningAmount = max(0, myBalance() - ton("0.05"));
    send(SendParameters{
      to: self.client,
      value: returningAmount,
      mode: SendIgnoreErrors,
      body: "Return open deal ton funds".asComment()
    });
  }

  fun releaseFunds(queryId: Int, msgAuthor: Address, receivedUsdt:Int, msg: ReleaseFunds) {
    let ctx = context();

    let referralCustomerAmount = self.getReferralCustomerCommission(msg.releaseAmount);
    let referralFreelancerAmount = self.getReferralFreelancerCommission(msg.releaseAmount);
    let transfershipAmount = self.getTransfershipCommission(msg.releaseAmount);
    let summedCommission = referralCustomerAmount + referralFreelancerAmount + transfershipAmount;
    require(receivedUsdt == summedCommission, "Incorrect commissions for the milestone enclosement");

    // by default we have 2 transactions and take 30% TON for each of them
    let percentage = 300;
    if (self.referralCustomerAddress != null && self.referralFreelancerAddress != null) {
      // 4 transactions, 15%
      percentage = 150;
    } else if (self.referralCustomerAddress != null || self.referralFreelancerAddress != null) {
      // 3 transactions, 20%
      percentage = 200;
    }
    
    // pay to the worker
    send(SendParameters{
       to: self.myUsdtAddress!!,
       value: self.getPercentVal(ctx.value, percentage),
       body: TokenTransfer{
          queryId: queryId, 
          amount: msg.releaseAmount,
          destination: self.authorRightsOwner!!,
          response_destination: self.client,
          custom_payload: null,
          forward_ton_amount: 0,
          forward_payload: beginCell().storeBit(false).asSlice()
       }.toCell()
    });

    // pay the commissions
   
    if (self.referralCustomerAddress != null) {
      send(SendParameters{
         to: self.myUsdtAddress!!,
         value: self.getPercentVal(ctx.value, percentage),
         body: TokenTransfer{
            queryId: queryId, 
            amount: referralCustomerAmount,
            destination: self.referralCustomerAddress!!,
            response_destination: self.client, 
            custom_payload: null,
            forward_ton_amount: 0,
            forward_payload: beginCell().storeBit(false).asSlice()
         }.toCell()
      });
    }

    if (self.referralFreelancerAddress != null) {
      send(SendParameters{
         to: self.myUsdtAddress!!,
         value: self.getPercentVal(ctx.value, percentage),
         body: TokenTransfer{
            queryId: queryId, 
            amount: referralFreelancerAmount,
            destination: self.referralFreelancerAddress!!,
            response_destination: self.client, 
            custom_payload: null,
            forward_ton_amount: 0,
            forward_payload: beginCell().storeBit(false).asSlice()
         }.toCell()
      });
    }

    // calculate master commission
    let masterContractCommission: Int = summedCommission; 
    if (self.referralCustomerAddress != null) {
      masterContractCommission -= referralCustomerAmount;
    }
    if (self.referralFreelancerAddress != null) {
      masterContractCommission -= referralFreelancerAmount;
    }

    send(SendParameters{
       to: self.myUsdtAddress!!,
       value: self.getPercentVal(ctx.value, percentage),
       body: TokenTransfer{
          queryId: queryId, 
          amount: masterContractCommission,
          destination: self.parent,
          response_destination: self.client,
          custom_payload: null,
          forward_ton_amount: 0,
          forward_payload: beginCell().storeBit(false).asSlice()
       }.toCell()
    });
  }

  receive(msg: TokenExcesses) {
  }

  receive(msg: SetCommissions) {
    require(self.isParent() || self.isOracle(), "Only parent or oracle can set the commissions");
    self.commissions = msg.commissions;
    self.reply("The deal's commissions were updated".asComment());
  }

  receive(msg: UpdateDetails) {
    require(self.isParent() || self.isOracle(), "Only parent or oracle can update the details");

    if (msg.deadlineUNIX != null) {
      self.deadlineUNIX = msg.deadlineUNIX!!;
    }
      
    if (msg.referralCustomerAddress != null) {
      self.referralCustomerAddress = msg.referralCustomerAddress!!;
    }

    if (msg.referralFreelancerAddress != null) {
      self.referralFreelancerAddress = msg.referralFreelancerAddress!!;
    }

    self.reply("The deal's details were updated".asComment());
  }

  receive(msg: SetOracleAddress) {
    require(self.isParent(), "Only master contract can set the oracle address");
    self.oracleAddress = msg.oracleAddress;
    self.reply("oracleAddress is updated".asComment());
  }

  receive("SetFinished") {
    require(self.isParent() || self.isOracle(), "Only oracle or master contract can set finished");

    self.isFinished = true;
    self.reply("Contract is finished".asComment());
  }

  receive(msg: GetFunds) {
    self.requireNotStopped();

    require(self.isParent(), "Only exclusive rights owner or parent can get funds");

    if (self.isParent() && self.myUsdtAddress != null && msg.usdt != null && msg.usdt == true) {
      send(SendParameters{
         to: self.myUsdtAddress!!,
         value: self.getPercentVal(context().value, 800), // 80% 
         body: TokenTransfer{
            queryId: random(0, 18446744073709551615), // uint64
            amount: msg.amount,
            destination: self.parent, 
            response_destination: self.parent,
            custom_payload: null,
            forward_ton_amount: 0, 
            forward_payload: beginCell().storeBit(false).asSlice()
         }.toCell()
      });
      self.reply("Sent funds to usdt".asComment());
    } else {
      require(myBalance() > msg.amount, "Not enough funds");

      send(SendParameters{
          to: sender(),
          value: msg.amount,
          mode: SendIgnoreErrors,
          body: "Return funds to the exclusive rights owner".asComment(),
      });
    }
  }

  // GETTERS
  get fun getGuid(): String {
    return self.guid;
  }

  get fun getUsdtAddress(): Address? {
    return self.myUsdtAddress;
  }

  get fun getOracleAddress(): Address? {
    return self.oracleAddress;
  }

  get fun getDeadline(): Int? {
    return self.deadlineUNIX;
  }                        

  get fun getClient(): Address {
    return self.client;
  }                        

  get fun getAuthorRightsOwner(): Address? {
    return self.authorRightsOwner;
  }                        

  get fun getExclusiveRightsOwner(): Address? {
    if (self.isFinished()) {
      return self.authorRightsOwner;
    } else {
      return self.client;
    }
  }                        

  get fun getReferralCustomerAddress(): Address? {
    return self.referralCustomerAddress;
  }                        

  get fun getReferralFreelancerAddress(): Address? {
    return self.referralFreelancerAddress;
  }                        

  get fun getCommissions(): Commissions? {
      return self.commissions;
  }

  get fun getTransfershipCommissionPercentage(): Int {
    if (self.commissions != null) {
      return self.commissions!!.transfershipCommissionPercentage;
    } else {
      return 90; // 9.0% by default
    }
  }

  get fun getReferralCustomerCommissionPercentage(): Int {
    if (self.commissions != null) {
      return self.commissions!!.referralCustomerCommissionPercentage;
    } else {
      return 5; // 0.5% by default
    }
  }

  get fun getReferralFreelancerCommissionPercentage(): Int {
    if (self.commissions) != null {
      return self.commissions!!.referralFreelancerCommissionPercentage;
    } else {
      return 5; // 0.5%
    }
  }

  // Returns a summed commision for the transfership (includes referral)
  get fun getSummedCommission(price: Int?): Int {
      return self.getTransfershipCommission(price) + self.getReferralCustomerCommission(price) + self.getReferralFreelancerCommission(price);
  }

  get fun getTransfershipCommission(price: Int?): Int {
      if (price != null) {
          return self.getPercentVal(price!!, self.getTransfershipCommissionPercentage());
      } else {
          return 0;
      }
  }

  get fun getReferralCustomerCommission(price: Int?): Int {
      if (price != null) {
          return self.getPercentVal(price!!, self.getReferralCustomerCommissionPercentage());
      } else {
          return 0;
      }
  }

  get fun getReferralFreelancerCommission(price: Int?): Int {
      if (price != null) {
          return self.getPercentVal(price!!, self.getReferralFreelancerCommissionPercentage());
      } else {
          return 0;
      }
  }

  get fun isFinished(): Bool {
    return self.isFinished;
  }

  receive("Resume") {
    require(self.isParent() || self.isOracle(), "Either parent or oracle can resume");
    self.requireStopped();
    self.stopped = false;
    self.reply("Resumed".asComment());
  }

  receive("Stop") {
    require(self.isParent() || self.isOracle(), "Either parent or oracle can stop");
    self.requireNotStopped();
    self.stopped = true;
    self.reply("Stopped".asComment());
  }

  get fun stopped(): Bool {
    return self.stopped;
  }

  fun requireNotStopped() {
    throwUnless(133, !self.stopped);
  }

  fun requireStopped() {
    require(self.stopped, "Contract not stopped");
  }

  fun isParent(): Bool {
    return sender() == self.parent;
  }

  fun isOracle(): Bool {
    return self.oracleAddress != null && sender() == self.oracleAddress!!;
  }

  fun getPercentVal(v: Int, p: Int): Int {
    let value: Int = v / 1000 * p;
    return value;
  }
}
