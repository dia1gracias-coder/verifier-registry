import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";
import "./messages";
import "./private_sale_wallet";
import "./jetton_wallet";

/*
    TonDB Private sale contract
    Owner can stop,resume and transfer the contract ownership
    Owner can set startTime and endTime
    Owner can set price per token (TON)
    Owner can change min and max token for buy
*/
contract PrivateSale with Resumable, Deployable {
  const MIN_TON_FOR_STORAGE: Int = ton("0.05");
  // Init State
  master: Address;
  owner: Address;
  // Flags
  stopped: Bool = false;
  claimable: Bool = false;
  // Units
  totalSupply: Int as coins = 0;
  price: Int as coins = 0;
  minBuyToken: Int as coins = 0;
  maxBuyToken: Int as coins = 0;
  balance: Int as coins = 0;
  // Times
  startTime: Int as uint32 = 0;
  endTime: Int as uint32 = 0;
  claimStartTime: Int as uint32 = 0;
  claimEndTime: Int as uint32 = 0;
  // Init
  init(master: Address, owner: Address){
    self.master = master;
    self.owner = owner;
  }

  // Master methods
  receive(msg: TransferPrivateSaleInternal){
    require(sender() == self.master, "Master Only");
    self.totalSupply = msg.totalSupply;
    self.balance = msg.totalSupply;
    send(SendParameters{to: self.owner, value: 0, mode: SendIgnoreErrors, body: "Private Sale Deployed".asComment()});
  }

  // Owner Methods
  receive(msg: ChangeSaleData){
    self.requireOwner();
    self.startTime = msg.startTime;
    self.endTime = msg.endTime;
    self.price = msg.price;
    self.minBuyToken = msg.minBuyToken;
    self.maxBuyToken = msg.maxBuyToken;
    send(SendParameters{to: sender(), value: 0, mode: SendRemainingValue, body: "Sale Data Changed".asComment()});
  }

  receive(msg: ChangeClaimData){
    self.requireOwner();
    self.claimStartTime = msg.claimStartTime;
    self.claimEndTime = msg.claimEndTime;
    self.claimable = msg.claimable;
    send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue + SendIgnoreErrors,
        body: "Claim Data Changed".asComment()
      }
    );
  }

  receive("withdraw all"){
    self.requireOwner();
    send(SendParameters{to: sender(), bounce: true, value: 0, mode: SendRemainingBalance + SendIgnoreErrors});
  }

  receive("withdraw safe"){
    self.requireOwner();
    send(SendParameters{
        to: sender(),
        bounce: true,
        value: (myBalance() - context().value) - self.MIN_TON_FOR_STORAGE,
        mode: SendRemainingValue + SendIgnoreErrors
      }
    );
  }

  receive(msg: Withdraw){
    self.requireOwner();
    let amount: Int = min(msg.amount, (myBalance() - context().value) - self.MIN_TON_FOR_STORAGE);
    require(amount > 0, "Insufficient balance");
    send(SendParameters{to: sender(), bounce: true, value: amount, mode: SendRemainingValue + SendIgnoreErrors});
  }

  // Public Methods
  receive(){
    dump("funds received");
  }

  receive("buy"){
    // Check sale avalability
    self.requireNotStopped();
    require(now() >= self.startTime, "Sale not started");
    require(now() <= self.endTime, "Sale ended");
    // Check amount
    let amount = context().value / self.price;
    require(amount >= self.minBuyToken, "Insufficient amount to buy");
    require(amount <= self.maxBuyToken, "Can't buy more than max amount");
    // Get private sale wallet address
    let privateSaleWalletInit: StateInit = initOf PrivateSaleWallet(myAddress(), sender(), self.maxBuyToken);
    let privateSaleWalletAddres: Address = contractAddress(privateSaleWalletInit);
    // Deploy private sale wallet address
    send(SendParameters{
        to: privateSaleWalletAddres,
        value: 0,
        mode: SendRemainingValue,
        body: BuyTokenInternal{amount: amount, sender: sender()}.toCell(),
        code: privateSaleWalletInit.code,
        data: privateSaleWalletInit.data
      }
    );
  }

  receive(msg: BuyTokenNotification){
    let privateSaleWalletInit: StateInit = initOf PrivateSaleWallet(myAddress(), msg.sender, self.maxBuyToken);
    let privateSaleWalletAddress: Address = contractAddress(privateSaleWalletInit);
    // Get Private Sale Jetton Wallet
    // This is where funds of private sale is stored
    let selfJettonWalletAddress: Address = self.jetton_wallet_address();
    // Subtract from balance
    self.balance = self.balance - msg.amount;
    // Add to user balance
    send(SendParameters{
        to: selfJettonWalletAddress,
        value: 0,
        mode: SendIgnoreErrors + SendRemainingValue,
        body: TokenTransfer{
          queryId: 25,
          amount: msg.amount,
          destination: privateSaleWalletAddress,
          response_destination: myAddress(),
          forward_ton_amount: 0,
          forward_payload: emptySlice()
        }.toCell()
      }
    );
  }

  receive("claim"){
    // Check claim avalability
    self.requireNotStopped();
    require(self.claimable == true, "Claim unavalable");
    require(now() >= self.claimStartTime, "Claim not started");
    require(now() <= self.claimStartTime, "Claim ended");
    // Get users private sale wallet (THE BANK)
    let privateSaleInit: StateInit = initOf PrivateSaleWallet(myAddress(), sender(), self.maxBuyToken);
    // Send message to the bank
    send(SendParameters{
        to: contractAddress(privateSaleInit),
        value: 0,
        mode: SendRemainingValue,
        code: privateSaleInit.code,
        data: privateSaleInit.data,
        body: ClaimTokensInternal{sender: sender(), jetton: self.master}.toCell()
      }
    );
  }

  // Getters

  get fun totalSupply(): Int {
    return self.totalSupply;
  }

  get fun master(): Address {
    return self.master;
  }

  get fun get_claim_data(): ClaimData {
    return ClaimData{startTime: self.claimStartTime, endTime: self.claimEndTime, claimable: self.claimable};
  }

  get fun get_sale_data(): SaleData {
    return
      SaleData{
        startTime: self.startTime,
        endTime: self.endTime,
        stopped: self.stopped,
        price: self.price,
        minBuyToken: self.minBuyToken,
        maxBuyToken: self.maxBuyToken
      };
  }

  get fun get_wallet_address(owner: Address): Address {
    let init: StateInit = initOf PrivateSaleWallet(myAddress(), owner, self.maxBuyToken);
    return contractAddress(init);
  }

  get fun balance(): Int {
    return myBalance();
  }

  get fun jettonBalance(): Int {
    return self.balance;
  }

  // Methods

  fun jetton_wallet_address(): Address {
    let init: StateInit = initOf JettonWallet(self.master, myAddress());
    return contractAddress(init);
  }
}