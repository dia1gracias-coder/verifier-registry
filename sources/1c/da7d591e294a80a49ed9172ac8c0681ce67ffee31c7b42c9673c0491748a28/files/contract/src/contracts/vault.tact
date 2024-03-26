import "@stdlib/ownable";
import "./jetton/jetton.tact";

message VaultUpdateContent {
  name: String;
  symbol: String;
  decimals: Int? = 9;
}

message Mint {
  amount: Int;
  receiver: Address;
}

contract Vault with Jetton {
  // vault owner
  owner: Address;

  // underlaying asset
  asset: Address;

  // jetton
  totalSupply: Int as coins;
  content: Cell;
  mintable: Bool;
  maxSupply: Int? as coins;

  // init
  init(owner: Address, asset: Address){
    self.owner = owner;
    self.asset = asset;

    // jetton
    self.totalSupply = 0;
    self.mintable = true;
    self.content =  emptyCell();
    self.maxSupply = null;
  }

  receive(msg: VaultUpdateContent) {
    self.requireOwner();
    self.content = msg.toCell();
  }

  receive(msg: Mint){
    let ctx: Context = context();
    require(ctx.sender == self.owner, "Not Owner");
    require(self.mintable, "Can't Mint Anymore");
    self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
  }

  receive("Owner: MintClose"){
    let ctx: Context = context();
    require(ctx.sender == self.owner, "Not Owner");
    self.mintable = false;
  }

  get fun asset(): Address {
    return self.asset;
  }
}