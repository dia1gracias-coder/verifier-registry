import "@stdlib/ownable";

import "../messages.tact";

trait OperatorControl with Ownable {
  owner: Address;
  operators: map<Address, Bool>;

  receive(msg: GrantOperator) {
    self.requireOwner();
    self.operators.set(msg.address, true);
  }

  receive(msg: RevokeOperator) {
    self.requireOwner();
    self.operators.set(msg.address, false);
  }

  fun requireOperator() {
    require(self.isOperator(sender()), "OperatorControl: caller is not an operator");
  }

  get fun isOperator(address: Address): Bool {
    let operatorStatus = self.operators.get(address);
    if (operatorStatus != null) {
      return operatorStatus!!;
    }
    return false;
  }
}