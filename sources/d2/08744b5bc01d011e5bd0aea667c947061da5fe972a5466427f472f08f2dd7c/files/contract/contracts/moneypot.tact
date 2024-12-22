import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

message TryPayout {
  address: Address;
  value: Int as coins;
}

message PayoutOk {
  address: Address;
  value: Int as coins;
}

message PayoutFailed {
  address: Address;
  value: Int as coins;
}

message EventPayoutCompleted {
  address: Address;
  value: Int as coins;
}

message RewardWinner {
  address: Address;
  value: Int as coins;
}

contract PayoutBeacon with Ownable, Deployable {
  override const storageReserve: Int = ton("0.1");
  owner: Address;
  master: Address;
  completed: Bool;

  init(owner: Address, master: Address){
    self.owner = owner;
    self.master = master;
    self.completed = false;
  }

  receive(msg: TryPayout){
    // Check context
    let ctx: Context = context();
    require(ctx.sender == self.master, "Invalid sender");
    // Send response
    if (!self.completed) {
        self.completed = true;
        self.forward(ctx.sender, PayoutOk{ value: msg.value, address: self.owner }.toCell(), true, null);
    } else {
        self.forward(ctx.sender, PayoutFailed{ value: msg.value, address: self.owner }.toCell(), false, null);
    }
  }

  bounced(msg: bounced<PayoutOk>) {
    // Reset completed flag is our message bounced
    self.completed = false;
    // Send notification
    self.forward(self.owner, "Payout failed".asComment(), false, null);
  }

  get fun master(): Address {
    return self.master;
  }

  get fun completed(): Bool {
    return self.completed;
  }
}

struct JettonWalletData {
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
}

message(0x7362d09c) JettonTransferNotification {
  queryId: Int as uint64;
  amount: Int as coins;
  sender: Address;
  forwardPayload: Slice as remaining;
}

fun calculateJettonWalletAddress(ownerAddress: Address,
  jettonMasterAddress: Address,
  jettonWalletCode: Cell): Address {
  let initData = JettonWalletData{
    balance: 0,
    ownerAddress,
    jettonMasterAddress,
    jettonWalletCode
  };
  return
    contractAddress(StateInit{code: jettonWalletCode, data: initData.toCell()});
}

struct USDTJettonWalletData {
    status: Int as uint4;
    balance: Int as coins;
    ownerAddress: Address;
    jettonMasterAddress: Address;
}

// And the function to calculate the wallet address may look like this:
fun calculateUSDTJettonWalletAddress(
    ownerAddress: Address,
    jettonMasterAddress: Address,
    jettonWalletCode: Cell
): Address {
    let initData = USDTJettonWalletData{
        status: 0,
        balance: 0,
        ownerAddress,
        jettonMasterAddress,
    };

    return contractAddress(StateInit{
        code: jettonWalletCode,
        data: initData.toCell(),
    });
}

contract MoneypotMaster with Deployable, Ownable, Resumable {
  override const storageReserve: Int = ton("0.1");
  owner: Address;
  stopped: Bool;
  usdtJettonWalletAddress: Address;
  usdtJettonAmount: Int as coins = 0;

  init(owner: Address, usdtJettonWalletCode: Cell, usdtJettonMasterAddress: Address){
    self.owner = owner;
    self.stopped = false;

    self.usdtJettonWalletAddress = calculateUSDTJettonWalletAddress(
        myAddress(),
        usdtJettonMasterAddress,
        usdtJettonWalletCode,
    );
  }

  receive(msg: JettonTransferNotification) {
      require(
          sender() == self.usdtJettonWalletAddress,
          "Notification not from your jetton wallet!",
      );

      self.usdtJettonAmount += msg.amount;

      // Forward excesses
      self.forward(msg.sender, null, false, null);
  }

  // Getters
  get fun tonAddress(): Address {
    return self.owner;
  }

  get fun usdtAddress(): Address {
    return self.usdtJettonWalletAddress;
  }

  //
  // Payout operations
  //

  receive(msg: RewardWinner){
    self.requireOwner();
    // Check that the contract is not stopped
    self.requireNotStopped();
    // Get the current context
    let ctx: Context = context();

    let value = msg.value;
    let winner = msg.address;
    // Check min value
    require(value >= ton("1.0"), "Check withdraw min value");
    // Check balance before sending forward to save some gas on depletion
    require(myBalance() > ((ton("1.0") + self.storageReserve) + value),
      "Insufficient balance on master"
    );
    // Send message to payout beacon
    let init: StateInit = initOf PayoutBeacon(ctx.sender, myAddress());
    let address: Address = contractAddress(init);
    self.forward(address,
      TryPayout{address: winner, value: value}.toCell(),
      true,
      init
    );
  }

  receive(ok: PayoutOk){
    // Check that the contract is not stopped
    self.requireNotStopped();
    // Get the current context
    let ctx: Context = context();
    let init: StateInit = initOf PayoutBeacon(ok.address, myAddress());
    let beaconAddress: Address = contractAddress(init);
    require(ctx.sender == beaconAddress, "Invalid sender");
    // Require required balance
    require(myBalance() > ((ton("1.0") + self.storageReserve) + ok.value),
      "Insufficient balance on master"
    );
    // Emit event
    emit(EventPayoutCompleted{address: ok.address, value: ok.value}.toCell());
    // Send the payout
    send(SendParameters{
        value: ok.value,
        mode: SendRemainingValue,
        to: ok.address,
        body: "Payout сompleted".asComment()
      }
    );
  }

  receive(failed: PayoutFailed){
    send(SendParameters{
        value: 0,
        mode: SendRemainingValue,
        to: failed.address,
        body: "Already paid".asComment()
      }
    );
  }

  //
  // Admin operations
  //

  receive("Deposit"){
    // NOTE: This method is allowed for anyone
    let ctx: Context = context();
    require(ctx.value >= ton("1.0"), "Invalid value");
    send(SendParameters{
        value: ton("0.1"),
        mode: SendIgnoreErrors,
        to: ctx.sender,
        bounce: false,
        body: "Deposit received".asComment()
      }
    );
  }

  receive("Withdraw"){
    self.requireOwner();
    nativeReserve(self.storageReserve, 0);
    send(SendParameters{
        value: 0,
        mode: SendRemainingBalance,
        to: self.owner,
        bounce: false,
        body: "Withdraw completed".asComment()
      }
    );
  }

  receive("Destroy"){
    self.requireOwner();
    send(SendParameters{
        value: 0,
        mode: SendRemainingBalance + SendDestroyIfZero,
        to: self.owner,
        bounce: false,
        body: "Contract destroyed".asComment()
      }
    );
  }
}