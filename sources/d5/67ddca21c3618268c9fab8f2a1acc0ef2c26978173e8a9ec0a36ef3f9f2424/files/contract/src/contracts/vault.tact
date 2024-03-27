import "@stdlib/ownable";
import "./jetton/jetton.tact";

struct VaultContent {
  name: String;
  symbol: String;
  decimals: Int? = 9;
}

message UpdateVault {
  owner: Address;
  asset: Address;
  content: VaultContent;
}

message Mint {
  amount: Int;
  receiver: Address;
}

contract Vault with Jetton {
  factory: Address;
  seqno: Int as uint256;

  // vault owner
  owner: Address;

  // underlaying asset
  asset: Address? = null;

  // jetton
  totalSupply: Int as coins;
  content: Cell;
  mintable: Bool;
  maxSupply: Int? as coins;

  // init
  init(factory: Address, seqno: Int){
    self.factory = factory;
    self.seqno = seqno;
    self.owner = factory;

    // jetton
    self.totalSupply = 0;
    self.mintable = true;
    self.content =  emptyCell();
    self.maxSupply = null;
  }

  receive(msg: UpdateVault) {
    require(sender() == self.factory, "Factory only");
    self.owner = msg.owner;
    self.asset = msg.asset;
    self.content = msg.content.toCell();
  }

  // receive(msg: Mint){
  //   let ctx: Context = context();
  //   require(ctx.sender == self.owner, "Not Owner");
  //   require(self.mintable, "Can't Mint Anymore");
  //   self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
  // }

  // receive("Owner: MintClose"){
  //   let ctx: Context = context();
  //   require(ctx.sender == self.owner, "Not Owner");
  //   self.mintable = false;
  // }

  get fun asset(): Address? {
    return self.asset;
  }
}