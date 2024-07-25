import "@stdlib/deploy";

message Add {
  queryId: Int as uint64;
  amount: Int as uint32;
}

message Subtract {
  queryId: Int as uint64;
  amount: Int as uint32;
}

contract Fireplace with Deployable {
  counter: Int as uint32;

  init() {
    self.counter = 0;
  }

  receive(msg: Add) {
    self.counter += msg.amount;
  }

  receive(msg: Subtract) {
    self.counter -= msg.amount;
  }

  get fun counter(): Int {
    return self.counter;
  }
}
