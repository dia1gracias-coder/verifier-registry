import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

import "../tact-utils/contracts/jetton/jetton.tact";
import "../tact-utils/contracts/common/messages.tact";

import "./events.tact";
import "./array.tact";
// import "./payout.tact";

// Message for updating whitelisted jettons
message UpdateWhitelist {
  whitelist: map<Address, Address>; // master -> wallet
}

// Message for registering bets
message PlaceBet {
  betKey: String;
  symbol: String;
  master: Address?; // jettonMaster
}

// Message triggering end of round
message EndRound {
  roundId: Int as uint32;
  tonPrice: Int as uint256;
  jettonPrice: map<Address, Int as uint256>;
}

message SetBetDetails { 
  player: Address;
  betKey: String;
  symbol: String;
  wallet: Address?;
  amount: Int as coins;
}

contract Bet {
  parent: Address;  
  seqno: Int as uint256;
  player: Address?;
  betKey: String?;  
  amount: Int? as coins;
  symbol: String?;

  init(parent: Address, seqno: Int) {
    self.parent = parent;
    self.seqno = seqno;
  }

  receive(msg: SetBetDetails) {
    self.player = msg.player; 
    self.amount = msg.amount;
    self.symbol = msg.symbol;
    self.betKey = msg.betKey;
  }

  get fun details(): BetDetails {    
    return BetDetails{
        player: self.player!!,
        betKey: self.betKey!!, 
        amount: self.amount!!,
        symbol: self.symbol!!
    };
  }
}

const JettonTransferGas: Int = ton("0.05");

contract Moneypot with Deployable, Ownable, Resumable {
  override const storageReserve: Int = ton("0.1");
  owner: Address;
  stopped: Bool;

  // Whitelisted tokens (jetton wallets addresses)
  whitelistedJettonWallet: map<Address, Int as uint8> = emptyMap();
  whitelistedJettonMaster: map<Address, Address> = emptyMap();

  // Rounds
  roundsSeqno: Int as uint32 = 0;
  lastWinner: Address?;

  // Total balance of round
  roundStartBet: Int as uint32 = 0;
  roundTonTotal: Int as coins = 0;
  roundJettonTotal: map<Address, Int as coins>;

  // Bets
  bets: Array;
  betsSeqno: Int as uint32 = 0;
  lastBetter: Address;

  init(owner: Address) {
    self.owner = owner;
    self.stopped = false;
    self.lastBetter = owner;
    self.roundTonTotal = 0;
    self.roundJettonTotal = emptyMap(); 
    self.bets = emptyArray();
  }

  // Getters
  get fun tonAddress(): Address {
    return myAddress();
  }

  get fun tonBalance(): Int {
    return myBalance();
  }

  get fun tonAmount(): Int {
    return self.roundTonTotal;
  }

  get fun jettonAmount(): map<Address, Int as coins> {
    return self.roundJettonTotal;
  }

  get fun totalBetsNumber(): Int {
    return self.betsSeqno;
  }

  get fun currentRoundNumber(): Int {
    return self.roundsSeqno;
  }

  get fun betAddress(seqno: Int): Address {
    return contractAddress(initOf Bet(myAddress(), seqno));
  }

  //
  // Game logic
  //

  fun processNewBet(bet: BetDetails) {
    self.bets.append(bet);
    // // dump(bet.symbol);   
    
    if (bet.symbol == "TON") {
      self.roundTonTotal += bet.amount;
      emit(BetPlaced{
        roundId: self.roundsSeqno,
        betId: self.betsSeqno,
        betKey: bet.betKey,
        symbol: bet.symbol,
        address: bet.player,
        tonAmount: bet.amount,
        jettonAmount: 0,
      }.toCell());
    } else {      
      let currentValue = self.roundJettonTotal.get(myAddress());
      if (currentValue == null) {        
        self.roundJettonTotal.set(myAddress(), bet.amount);  
      } else {
        self.roundJettonTotal.set(myAddress(), currentValue!! + bet.amount);      
      }      
      
      emit(BetPlaced{
        roundId: self.roundsSeqno,
        betId: self.betsSeqno,
        betKey: bet.betKey,
        symbol: bet.symbol,
        address: bet.player,
        tonAmount: 0,
        jettonAmount: bet.amount,
      }.toCell());
    }

    // Deploy bet as a child contract
    let init: StateInit = initOf Bet(myAddress(), self.betsSeqno);
    send(SendParameters{
        to: contractAddress(init),
        body: SetBetDetails{
          player: bet.player,
          betKey: bet.betKey,
          symbol: bet.symbol,
          amount: bet.amount,
        }.toCell(),      
        value: ton("0.02"),             // pay for the deployment and leave some TON in the child for storage
        mode: SendIgnoreErrors,
        code: init.code,                // prepare the initial code when deploying the child contract
        data: init.data
    });

    self.betsSeqno += 1;
    self.lastBetter = bet.player;    
  }

  receive(msg: PlaceBet){    
    // Check that the contract is not stopped
    self.requireNotStopped();

    // Get the current context
    let ctx: Context = context();    

    // Update state
    self.processNewBet(BetDetails {
      player: ctx.sender,
      betKey: msg.betKey,
      symbol: msg.symbol,
      amount: ctx.value
    });  
  }

  receive(msg: TransferNotification) {    
    let betCell = msg.forwardPayload;
    // dump(msg.sender);
    // dump(msg.amount);
    require(betCell != null, "Missing bet information");
    let bet = PlaceBet.fromCell(betCell!!);
    // dump(bet.toCell().asSlice());    
    // dump(bet.master);  
    // dump(bet.symbol);
    

    // Get the current context
    let ctx: Context = context();   
    let senderWallet = ctx.sender;
    // dump(senderWallet);

    // Calling m.exists(key) is more gas-efficient than executing m.get(key) != null,
    // although both approaches yield the same results.
    // require(self.whitelistedJettonWallet.exists(bet.master), "Jetton wallet not whitelisted");    

    // Update state
    self.processNewBet(BetDetails {
      player: msg.sender,
      betKey: bet.betKey,
      symbol: bet.symbol,
      amount: msg.amount
    });  
  }  

  receive(msg: EndRound){
    // self.requireOwner();
    // Check that the contract is not stopped
    self.requireNotStopped();
    // Get the current context
    let ctx: Context = context();

    // Extract prices data
    let jettonPrice = msg.jettonPrice;
    let tonPrice = msg.tonPrice;

    // Check end round conditions are met
    let potTonValueUSDT = self.roundTonTotal * tonPrice;
    let potJettonValueUSDT = self.roundJettonTotal.get(myAddress())!! * jettonPrice.get(myAddress())!!;
    let potValueUSDT = potTonValueUSDT + potJettonValueUSDT;

    // dump(potTonValueUSDT);
    // dump(potJettonValueUSDT);
    // dump(potValueUSDT);
    
    // Generate a new random number, which is an unsigned 256-bit integer
    let randSeed: Int = random(0, potValueUSDT);
    // dump(randSeed);

    // Determine winner bet
    let winner = myAddress();
    let betId = self.roundStartBet;
    let betWeight = 0;   
    do {    
      // extract bet data
      // dump(betId);
      // let betAddress = self.betAddress(betId);
      // // dump(betAddress);
      let bet = self.bets.getIdx(betId);
      // dump(bet.symbol);
      let betOwner = bet.player;
      // dump(betOwner);

      // calculate bet weight
      let betValueUSDT = 0;
      if (bet.symbol == "TON") {
        betValueUSDT = bet.amount * tonPrice;
      } else {
        betValueUSDT = bet.amount * jettonPrice.get(myAddress())!!;
      }      
      betWeight = betValueUSDT;
      
      // let betWeight = betAmount * potValueUSDT / betWeight;      
      betId += 1;
      winner = betOwner;
      // dump(winner);
      // dump(randSeed);
      if (randSeed > betWeight) {
        randSeed -= betWeight;
      }
    } until (randSeed <= betWeight);

    // Finish round
    self.roundStartBet = self.roundsSeqno;
    self.roundsSeqno += 1;
    self.bets.deleteAll();
    // dump(self.roundsSeqno);

    // Payout reward to winner
    self.lastWinner = winner;

    // Fee calcution
    let fee_nom = 8; // 8%
    let fee_denom = 100;
    if (100 * betWeight > 80 * potValueUSDT) {
      fee_nom = 5; // 5%
    }    
    let tonPrize = (self.roundTonTotal * (fee_denom - fee_nom)) / fee_denom;
    let jettonPrize = self.roundJettonTotal;

    // Send TON prize to winner
    send(SendParameters{
      // bounce is set to true by default
      to: winner,
      value: tonPrize,
      mode: SendIgnoreErrors, // don't stop in case of errors      
    });

    // Distribute jettons to winner    
    foreach (master, amount in jettonPrize) {
      // dump(master);
      let prizeAmount = amount * (fee_denom - fee_nom) / fee_denom;
      // let wallet: Address = self.whitelistedJettonMaster.get(master)!!;
      
      send(SendParameters{
            to: winner,
            value: JettonTransferGas,
            body: TokenTransfer{
                // To prevent replay attacks
                queryId: 42,
                // Jetton amount to transfer
                amount: prizeAmount,
                // Where to transfer Jettons:
                // this is an address of the Jetton wallet
                // owner and not the Jetton wallet itself
                destination: winner,
                // Where to send a confirmation notice of a successful transfer
                // and the rest of the incoming message value
                responseDestination: myAddress(),
                // Can be used for custom logic of Jettons themselves,
                // and without such can be set to null
                customPayload: null,
                // Amount to transfer with JettonTransferNotification,
                // which is needed for the execution of custom logic
                forwardAmount: 0, // if its 0, the notification won't be sent!
                // Compile-time way of expressing:
                //     beginCell().storeUint(0xF, 4).endCell().beginParse()
                // For more complicated transfers, adjust accordingly
                forwardPayload: null,
            }.toCell(),
        });
    }
    
    // Send message to payout beacon
    // let init: StateInit = initOf PayoutBeacon(ctx.sender, myAddress());
    // let address: Address = contractAddress(init);
    // self.forward(address,
    //   TryPayout{address: self.lastBetter, value: self.roundTonTotal}.toCell(),
    //   true,
    //   init
    // );

    emit(RoundEnded{
      roundId: msg.roundId,
      winner: winner,
      tonAmount: self.roundTonTotal,
      jettonAmount: self.roundJettonTotal
    }.toCell());
  }

  //
  // Admin operations
  //

  receive(msg: UpdateWhitelist) {
    self.requireOwner();
    foreach (master, wallet in msg.whitelist) {
      self.whitelistedJettonMaster.set(master, wallet);
      self.whitelistedJettonWallet.set(wallet, 0);
    }
    // dump(self.whitelistedJettonMaster);
    // dump(self.whitelistedJettonWallet);
  }

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