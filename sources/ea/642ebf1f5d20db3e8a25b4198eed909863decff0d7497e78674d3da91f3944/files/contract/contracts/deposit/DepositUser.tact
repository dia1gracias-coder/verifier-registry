import "./shared.tact";


contract DepositUser(
  factory: Address,
  user: Address,
  amount: Int as coins,
  counter: Int as uint32, 
  lastUpdate: Int as uint64,
  ){

  receive() {}

  receive(msg: NotifyDeposit) {
    require(sender() == self.factory,"Unautorized");
    require(msg.user == self.user,"Invalid Message");
    require(msg.amount > 0,"Invalid Amount");
    self.amount += msg.amount;
    self.counter += 1;
    self.lastUpdate = now();

    message(MessageParameters{
      to: sender(),
      value: 0,
      mode: SendRemainingValue,
      bounce: false,
      body: NotifyDepositEvent{
        user: self.user,
        before: self.amount - msg.amount,
        after: self.amount,
        counter: self.counter,
      }.toCell()
    })
  }

  get fun factory(): Address {
    return self.factory;
  }

  get fun user(): Address {
    return self.user;
  }

  get fun amount(): Int {
    return self.amount;
  }
  
  get fun lastUpdate(): Int {
    return self.lastUpdate;
  }
}

