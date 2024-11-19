import "@stdlib/deploy";
import "./messages";
import "./traits";
import "./structs";
import "./private_sale";

contract JettonMaster with Jetton, Deployable {
  totalSupply: Int as coins;
  owner: Address;
  content: Cell;
  mintable: Bool;
  max_supply: Int as coins;
  init(owner: Address, content: Cell, max_supply: Int){
    self.totalSupply = 0;
    self.owner = owner;
    self.mintable = true;
    self.content = content;
    self.max_supply = max_supply; // Initial Setting for max_supply
  }

  receive(msg: Mint){
    let ctx: Context = context();
    self.requireOwner();
    require(self.mintable, "Can't Mint Anymore");
    self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
  }

  receive("Owner: MintClose"){
    let ctx: Context = context();
    self.requireOwner();
    self.mintable = false;
  }

  receive("Mint: 100"){
    let ctx: Context = context();
    require(self.mintable, "Not mintable");
    require((self.totalSupply + 100) <= self.max_supply, "Max supply exceeded");
    self.mint(ctx.sender, 100, self.owner);
  }

  receive(msg: MintPrivateSale){
    self.requireOwner();
    require(self.mintable, "Not mintable");
    //  Get init and address of private sale contract
    let init: StateInit = initOf PrivateSale(myAddress(), self.owner);
    let privateSaleAddress: Address = contractAddress(init);
    //  Deploy Private Sale Contract
    send(SendParameters{
        to: privateSaleAddress,
        value: 0,
        mode: SendIgnoreErrors + SendRemainingValue,
        code: init.code,
        data: init.data,
        body: TransferPrivateSaleInternal{totalSupply: msg.totalSupply}.toCell()
      }
    );
  }

  // receive(msg: TransferPrivateSaleInternalCallBack){
  //   let ctx: Context = context();
  //   require(self.mintable, "Not mintable");
  //   //  Get init and address of private sale contract
  //   let init: StateInit = initOf PrivateSale(myAddress(), self.owner);
  //   let privateSaleAddress: Address = contractAddress(init);
  //   require(ctx.sender == privateSaleAddress, "Only Private Sale");
  //   //  Fund the contract
  //   let ownerWallet: Address = self.get_wallet_address(self.owner);
  //   send(SendParameters{
  //       to: ownerWallet,
  //       value: 0,
  //       mode: SendIgnoreErrors + SendRemainingValue
  //       body: TokenTransfer{
  //         queryId: 45,
  //         amount: msg.totalSupply,
  //         destination: privateSaleAddress,
  //         response_destination: self.owner,
  //         forward_ton_amount: 0,
  //         forward_payload: emptySlice()
  //       }.toCell()
  //     }
  //   );
  // }

  get fun private_sale_addres(): Address {
    let init: StateInit = initOf PrivateSale(myAddress(), self.owner);
    return contractAddress(init);
  }
}