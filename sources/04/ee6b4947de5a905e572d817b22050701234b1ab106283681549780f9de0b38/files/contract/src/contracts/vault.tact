import "@stdlib/ownable";
import "./jetton/jetton.tact";

message Mint {
  amount: Int;
  receiver: Address;
}

message VaultContent {
  name: String;
  symbol: String;
  decimals: Int? = 9;
}

contract Vault with Jetton {
  seqno: Int as uint64;
  asset: Address;
  totalSupply: Int as coins;
  owner: Address;
  content: Cell;
  mintable: Bool;
  maxSupply: Int? as coins;
  init(seqno: Int, asset: Address, owner: Address, content: VaultContent){
    self.seqno = seqno;
    self.asset = asset;
    self.totalSupply = 0;
    self.owner = owner;
    self.mintable = true;
    self.content = content.toCell();
    self.maxSupply = null;
  }

  receive("identify"){
    dump(self.seqno);
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