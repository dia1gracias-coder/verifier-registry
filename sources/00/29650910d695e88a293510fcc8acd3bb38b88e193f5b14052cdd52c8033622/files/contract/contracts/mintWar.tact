import "./imports/stdlib.fc";
const minTonsForStorage: Int = ton("0.04");
const gasConsumption: Int = ton("0.04");

message MintEvent {
  sender: Address;
  value: Int as uint256;
  rate: Int as uint256;
  points: Int as uint256;
}

message MintJetton {
  rate: Int as uint256;
}

struct AccountState {
  points: Int as uint256;
  fees:  Int as uint256;
  totalPoints: Int as uint256;
  totalFees: Int as uint256;
}

contract MintWar {
  admin: Address;
  mintStartAt: Int;
  mintEndAt: Int;
  totalPoints: Int as uint256;
  totalFees:  Int as uint256;
  pointsOf: map<Address, Int as uint256>;
  feesOf: map<Address, Int as uint256>;

  init(admin: Address, mintStartAt: Int, mintEndAt: Int) {
    self.admin = admin;
    self.totalPoints = 0;
    self.totalFees = 0;
    self.mintStartAt = mintStartAt;
    self.mintEndAt = mintEndAt;
  }

  fun msg_value(value: Int): Int {
    let ton_balance_before_msg: Int = myBalance() - value;
    let storage_fee: Int = minTonsForStorage - min(ton_balance_before_msg, minTonsForStorage);
    return value - (storage_fee + gasConsumption);
  }

  receive(){}
  receive(msg: Slice) {}
  
  receive(msg: MintJetton) {
    require(msg.rate>0 && msg.rate<=100000, "Invalid rate");
    require(context().value >= ton("0.2"), "Insufficient fee");
    require(now()>=self.mintStartAt, "Mint not start");
    require(now()<self.mintEndAt, "Mint ended");

    let myfee: Int? = self.feesOf.get(sender());
    if (myfee == null) {
      self.feesOf.set(sender(), context().value);
    }else{
      self.feesOf.set(sender(), context().value+myfee!!);
    }
    self.totalFees = self.totalFees + context().value;
    let num: Int = random(0,100000);
    if (num < msg.rate) {
      // success
      let point: Int = context().value*100000/msg.rate;
      self.totalPoints = self.totalPoints + point;
      let userPoints: Int? = self.pointsOf.get(sender());
      if (userPoints == null) {
        self.pointsOf.set(sender(), point);
      }else{
        self.pointsOf.set(sender(), (userPoints!!)+point);
      }

      emit(
        MintEvent{
          sender: sender(),
          value: context().value,
          rate: msg.rate,
          points: point
        }.toCell()
      );
    }else{
      emit(
        MintEvent{
          sender: sender(),
          value: context().value,
          rate: msg.rate,
          points: 0
        }.toCell()
      );
    }
  }

  receive("ClaimFee") {
    require(sender() == self.admin, "Only owner can claim fee");
    send(SendParameters{
        to: self.admin,
        value: myBalance() - ton("0.1"),
        bounce: false,
        mode: SendPayGasSeparately
    });
  }

  // -------------- Get Method -------------- // 
  get fun get_points_by_address(address: Address): Int {
    let userPoints: Int? = self.pointsOf.get(address);
    if (userPoints == null) {
      return 0;
    }else{
      return userPoints!!;
    }
  }
  get fun get_shares_by_address(address: Address): Int {
    let userPoints: Int? = self.pointsOf.get(address);
    if (userPoints == null) {
      return 0;
    }else{
      return userPoints!!*100000/self.totalPoints;
    }
  }
  get fun get_totalPoints(): Int {
    return self.totalPoints;
  }
  get fun get_all_accounts(): map<Address, Int as uint256>{
    return self.pointsOf;
  }
  get fun get_account_state(address: Address): AccountState{
    let userPoints: Int? = self.pointsOf.get(address);
    if (userPoints == null) {
      userPoints = 0;
    }

    let fees: Int? = self.feesOf.get(address);
    if (fees == null) {
      fees = 0;
    }

    return AccountState { 
      points: userPoints!!,
      fees: fees!!,
      totalPoints: self.totalPoints,
      totalFees: self.totalFees
    };
  }
}