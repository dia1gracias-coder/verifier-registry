import "@stdlib/deploy";
import "@stdlib/ownable";
import "./vault.tact";
message NewVault {
  asset: Address;
  name: String;
  symbol: String;
}
message NewVaultResponse {
  seqno: Int as uint256;
}

contract Factory with Deployable, OwnableTransferable {
  owner: Address;
  numVaults: Int as uint256 = 0;
  init(){
    self.owner = sender(); // set the owner as the deployer
  }

  receive(msg: NewVault){
    self.numVaults = (self.numVaults + 1);
    let init: StateInit = initOf Vault(myAddress(), self.numVaults);
    send(SendParameters{
        to: contractAddress(init),
        body: UpdateVault{
          owner: sender(),
          asset: msg.asset,
          content: VaultContent{name: msg.name, symbol: msg.symbol}
        }.toCell(),
        value: ton("0.01"),
        mode: SendIgnoreErrors,
        code: init.code,
        data: init.data
      }
    );
    self.reply(NewVaultResponse{seqno: self.numVaults}.toCell());
  }

  get fun numVaults(): Int {
    return self.numVaults;
  }

  get fun vaultAddress(seqno: Int): Address {
    return contractAddress(initOf Vault(myAddress(), seqno));
  }
}