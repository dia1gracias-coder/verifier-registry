import "@stdlib/deploy";
import "@stdlib/ownable";
import "./vault.tact";
message NewVault {
  asset: Address;
  name: String;
  symbol: String;
}
message VaultCreated {
  owner: Address;
  asset: Address;
  address: Address;
}

contract Factory with Deployable, OwnableTransferable {
  owner: Address;
  init(){
    self.owner = sender(); // set the owner as the deployer
  }

  receive(msg: NewVault){
    let vaultInit: StateInit = self._get_vault_state_init(sender(), msg.asset);
    let vaultAddress: Address = contractAddress(vaultInit);
    send(SendParameters{
        to: vaultAddress,
        value: ton("0.1"),
        mode: SendIgnoreErrors,
        code: vaultInit.code,
        data: vaultInit.data,
        body: VaultUpdateContent{name: msg.name, symbol: msg.symbol}.toCell()
      }
    );
    emit(VaultCreated{
        owner: sender(),
        asset: msg.asset,
        address: vaultAddress
      }.toCell()
    );
  }

  inline fun _get_vault_state_init(owner: Address, asset: Address): StateInit {
    return initOf Vault(owner, asset);
  }

  get fun vault(owner: Address, asset: Address): Address {
    return contractAddress(self._get_vault_state_init(owner, asset));
  }

  get fun myVault(asset: Address): Address {
    return self.vault(sender(), asset);
  }
}