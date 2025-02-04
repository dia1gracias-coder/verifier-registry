import "@stdlib/deploy";

import "./structs/balance.tact";
import "./messages.tact";

contract QstMeSponsor with Deployable {
  id: Int as uint64;
  parent: Address;
  sponsored: Balance;

  init(
    parent: Address,
    id: Int
  ) {
    self.parent = parent;
    self.id = id;
    self.sponsored = Balance { ton: 0, usdt: 0 };
  }

  receive(msg: Sponsor) {
    require(self.id == msg.sponsor, "Invalid sponsor id");
    require(sender() == self.parent, "Only main contract can register sponsorship");

    self.sponsored.ton += msg.amount;

    send(SendParameters{
      to: self.parent,
      value: msg.amount,
      body: ApproveSponsorship {
        sponsor: msg.sponsor,
        amount: Balance {
          ton: msg.amount,
          usdt: 0,
        },
      }.toCell(),
    });

    self.reply(SponsorshipApproved { sponsor: msg.sponsor, amount: msg.amount }.toCell());
  }

  receive(msg: RegisterSponsorship) {
    require(sender() == self.parent, "Only main contract can register sponsorship");

    self.sponsored = self.sponsored.add(msg.amount);

    send(SendParameters{
      to: self.parent,
      value: 0,
      mode: SendRemainingValue | SendIgnoreErrors,
      body: ApproveSponsorship {
          sponsor: msg.sponsor,
          amount: msg.amount,
        }.toCell(),
    });
  }

  get fun getBalance(): Balance {
    return self.sponsored;
  }
}
