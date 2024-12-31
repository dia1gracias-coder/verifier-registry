import "@stdlib/deploy";
import "@stdlib/ownable";

message TryPayout {
  address: Address;
  value: Int as coins;
}

message PayoutOk {
  address: Address;
  value: Int as coins;
}

message PayoutFailed {
  address: Address;
  value: Int as coins;
}

contract PayoutBeacon with Ownable, Deployable {
  override const storageReserve: Int = ton("0.1");
  owner: Address;
  master: Address;
  completed: Bool;

  init(owner: Address, master: Address){
    self.owner = owner;
    self.master = master;
    self.completed = false;
  }

  receive(msg: TryPayout){
    // Check context
    let ctx: Context = context();
    require(ctx.sender == self.master, "Invalid sender");
    // Send response
    if (!self.completed) {
        self.completed = true;
        self.forward(ctx.sender, PayoutOk{ value: msg.value, address: self.owner }.toCell(), true, null);
    } else {
        self.forward(ctx.sender, PayoutFailed{ value: msg.value, address: self.owner }.toCell(), false, null);
    }
  }

  bounced(msg: bounced<PayoutOk>) {
    // Reset completed flag is our message bounced
    self.completed = false;
    // Send notification
    self.forward(self.owner, "Payout failed".asComment(), false, null);
  }

  get fun master(): Address {
    return self.master;
  }

  get fun completed(): Bool {
    return self.completed;
  }
}