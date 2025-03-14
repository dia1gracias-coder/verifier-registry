message GrantOperator {
  address: Address;
}

message RevokeOperator {
  address: Address;
}

trait OperatorControl {
  owner: Address;
  operators: map<Address, Bool>;

  receive(msg: GrantOperator) {
    require(sender() == self.owner, "OperatorControl: caller is not an owner");
    self.operators.set(msg.address, true);

    self.reply("Operator role granted".asComment())
  }

  receive(msg: RevokeOperator) {
    require(sender() == self.owner, "OperatorControl: caller is not an owner");
    self.operators.del(msg.address);

    self.reply("Operator role revoked".asComment())
  }

  fun requireOperator() {
    require(self.isOperator(sender()), "OperatorControl: caller is not an operator");
  }

  fun requireOwnerOrOperator() {
    require(self.isOperator(sender()) || sender() == self.owner, "OperatorControl: caller is neither owner nor operator");
  }

  get fun isOperator(address: Address): Bool {
    let operatorStatus = self.operators.get(address);
    if (operatorStatus != null) {
      return operatorStatus!!;
    }
    return false;
  }
}