



message NotifyDeposit {
  user: Address;
  amount: Int;
}

message NotifyDepositEvent {
  user: Address;
  before: Int as coins;
  after: Int as coins;
  counter: Int as uint32;
}


message Deposit {}

message TakeFund {}

contract DepositTonUser(
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


contract DepositTon(admin: Address) {

  receive() {}

  receive(msg: Deposit) {

    require(context().value > ton("0.02"),"Invalid Amount");

    let init = initOf DepositTonUser(
      myAddress(),
      sender(),
      0, 
      0,
      0
    );

    send(SendParameters{
        to: contractAddress(init),
        value: ton("0.01"),              // pay for message, the deployment and give some TON for storage
        mode: SendIgnoreErrors,
        code: init.code,                // attaching the state init will cause the message to deploy
        data: init.data,
        body: NotifyDeposit{
          user: sender(),
          amount: context().value - ton("0.02"),
        }.toCell(),
    });

  }

  receive(msg: TakeFund) {
    require(sender() == self.admin,"Unautorized");
    message(MessageParameters{
        to: self.admin,
        value: 0,
        mode: SendRemainingBalance,
        bounce: false,
    });
  }

  receive(msg: NotifyDepositEvent) {
    require(sender() == contractAddress(initOf DepositTonUser(
      myAddress(),
      msg.user,
      0, 
      0,
      0
    )),"Unautorized");
    emit(msg.toCell());
  }

}