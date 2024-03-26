import "@stdlib/deploy";
import "@stdlib/ownable";
import "./vault.tact";
message NewVault {
  asset: Address;
  content: VaultContent;
}
message NewVaultResponse {
  seqno: Int as uint256;
}

contract Factory with Deployable, OwnableTransferable {
  owner: Address;
  numVaults: Int as uint64;
  init(){
    self.owner = sender();
    self.numVaults = 0;
  }

  receive(msg: NewVault){
    self.numVaults = (self.numVaults + 1);
    let init: StateInit = initOf Vault(self.numVaults,
      msg.asset,
      sender(),
      msg.content
    );
    send(SendParameters{
        to: contractAddress(init),
        value: ton("0.1"),
        mode: SendIgnoreErrors,
        code: init.code,
        data: init.data,
        body: "identify".asComment()
      }
    );
    self.reply(NewVaultResponse{seqno: self.numVaults}.toCell());
  }
}