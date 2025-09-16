// contracts/TestStore.tact

import "@stdlib/deploy"; // optional helper to make deploying easier

message SetValue {
  value: Int;
}

contract TestStore with Deployable {
  // Persisted state; "as getter" auto-generates a get-method named `value`
  value: Int;

  init() {
    self.value = 99;  // default
  }

  // Anyone can set the value by sending an internal message of type SetValue
  receive(msg: SetValue) {
    self.value = msg.value;
  }

  // Explicit getter (optional; you already get `value()` from "as getter")
  get fun getValue(): Int {
    return self.value;
  }
}
