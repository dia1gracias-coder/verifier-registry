import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

import "./messages.tact";
import "./events.tact";
import "./payout.tact";

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

message PlaceBet {
  // TO DO: batch bets
}

message BetPlaced {
  betId: Int as uint32;
  address: Address;
  tonAmount: Int as coins;
  jettonAmount: map<Address, Int as coins>;
}

message RoundPayoutCompleted {
  address: Address;
  tonAmount: Int as coins;
  jettonAmount: map<Address, Int as coins>;
}

contract MoneypotMaster with Deployable, Ownable, Resumable {
  override const storageReserve: Int = ton("0.1");
  owner: Address;
  stopped: Bool;
  jettonWalletAddress: Address;
  jettonAmount: Int as coins = 0;

  // bets
  bets_seqno: Int as uint32 = 0;
  last_better: Address;

  init(owner: Address, jettonWalletCode: Cell, jettonMasterAddress: Address){
    self.owner = owner;
    self.stopped = false;
    self.last_better = owner;

    self.jettonWalletAddress = calculateJettonWalletAddress(
        myAddress(),
        jettonMasterAddress,
        jettonWalletCode,
    );
  }

  receive(msg: JettonTransferNotification) {
      require(
          sender() == self.jettonWalletAddress,
          "Notification not from your jetton wallet!",
      );

      self.jettonAmount += msg.amount;

      // Forward excesses
      self.forward(msg.sender, null, false, null);
  }

  // Getters
  get fun tonAddress(): Address {
    return myAddress();
  }

  get fun jettonAddress(): Address {
    return self.jettonWalletAddress;
  }

  get fun jettonAmount(): Int {
    return self.jettonAmount;
  }


  //
  // Game logic
  //

  //
  // Bet operations
  //

  receive(msg: PlaceBet){    
    // Check that the contract is not stopped
    self.requireNotStopped();

    // Get the current context
    let ctx: Context = context();
    
    emit(BetPlaced{
      betId: self.bets_seqno,
      address: ctx.sender,
      tonAmount: ctx.value,
      jettonAmount: emptyMap(),
    }.toCell());
    self.bets_seqno += 1;
    self.last_better = ctx.sender;
  }

  receive(msg: EndRound){
    self.requireOwner();
    // Check that the contract is not stopped
    self.requireNotStopped();
    // Get the current context
    let ctx: Context = context();

    // Check end round conditions are met
    let pot_value = myBalance();
    let value = pot_value - self.storageReserve;

    // Check min value
    require(value >= ton("1.0"), "Check withdraw min value");
    // Check balance before sending forward to save some gas on depletion
    require(myBalance() > ((ton("1.0") + self.storageReserve) + value),
      "Insufficient balance on master"
    );

    // Determine winner
    let winner = self.last_better;
    
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
    emit(RoundPayoutCompleted{address: ok.address, tonAmount: ok.value, jettonAmount: emptyMap()}.toCell());
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