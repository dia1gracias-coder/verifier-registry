import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./jetton_wallet";

contract PrivateSaleWallet with Ownable, Deployable {
  master: Address;
  owner: Address;
  balance: Int as coins = 0;
  maxBalance: Int as coins;
  // Init method
  init(master: Address, owner: Address, maxBalance: Int){
    self.master = master;
    self.owner = owner;
    self.maxBalance = maxBalance;
  }

  receive(msg: BuyTokenInternal){
    require(self.master == sender(), "Only master");
    require(msg.amount < self.maxBalance, "Cant buy more tokens");
    require((msg.amount + self.balance) < self.maxBalance, "Cant buy more tokens");
    self.balance = self.balance + msg.amount;
    send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue + SendIgnoreErrors,
        body: BuyTokenNotification{amount: msg.amount, sender: msg.sender}.toCell()
      }
    );
  }

  receive(msg: ClaimTokensInternal){
    require(sender() == self.master, "Invalid Sender");
    require(self.balance > 0, "Not enough balance");
    require(msg.sender == self.owner, "Invalid Sender");
    // Get user private sale jetton wallet (THE BANK)
    let privateSaleJettonInit: StateInit = initOf JettonWallet(msg.jetton, myAddress());
    // Transfer jettons from THE BANK to RECIVER=
    send(SendParameters{
        to: contractAddress(privateSaleJettonInit),
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer{
          queryId: 26,
          amount: self.balance,
          destination: msg.sender,
          response_destination: msg.sender,
          forward_ton_amount: 0,
          forward_payload: emptySlice()
        }.toCell()
      }
    );
    self.balance = 0;
  }

  get fun get_wallet_data(): PrivateSaleWalletData {
    return PrivateSaleWalletData{balance: self.balance, owner: self.owner, master: self.master};
  }

  get fun balance(): Int {
    return self.balance;
  }

  get fun get_wallet_address(jetton: Address): Address {
    let init: StateInit = initOf JettonWallet(jetton, myAddress());
    return contractAddress(init);
  }
}