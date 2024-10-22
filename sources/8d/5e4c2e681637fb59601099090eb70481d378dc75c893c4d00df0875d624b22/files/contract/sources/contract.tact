import "@stdlib/deploy";
import "@stdlib/ownable";
// One round of treasure snatching information
struct RoundInfo {
  orders: map<Int as uint32, BuyInfo>;  // key is order number
  sum: Int as uint16;                   // Total number of lucky numbers
  arrLength: Int as uint16;             // Number of purchased numbers
  sequence: Int as uint16;              // Number of orders
  finish: Bool;                         // Whether it has ended
  winner: Int as uint16;                // Winning number
  awardAmount: Int as coins;            // Award amount
  startTime: Int as uint32;             // Start time
  endTime: Int as uint32;               // End time
}
struct BuyInfo {
  startLuckyNum: Int as uint16;         // Starting lucky number
  nifiNum: Int as uint16;               // Purchase quantity
}
// Winning information
struct WinnerInfo {
  luckyNum: Int as uint16;              // Winning number
}
// Signature data
struct SignData {
  round: Int as uint32;                 // Round ID
  nifiAmount: Int as uint16;            // Purchase quantity
  orderNumber: Int as uint32;           // Order number, unique, used to prevent duplicate purchases
  address: Address;                     // Buyer's address
}
// admin creates a new round msg
message NewRoundMsg {
  round: Int as uint32;                 // Round ID
  sum: Int as uint16;                   // Total number of lucky numbers
  startTime: Int as uint32;             // Start time
  endTime: Int as uint32;               // End time
  awardAmount: Int as coins;            // Award amount
}

// admin closes the round
message CloseRoundMsg {
  round: Int as uint32;
}

// User purchase msg
message BuyMsg {
  round: Int as uint32;                 // Round ID
  nifiAmount: Int as uint16;            // Purchase quantity
  orderNumber: Int as uint32;           // Order number, unique, used to prevent duplicate purchases
  signature: Cell;                      // Signature       
}
message BuyEvent {
  round: Int as uint32;                 // Round ID
  amount: Int as uint16;                // Purchase quantity
  orderNumber: Int as uint32;           // Order number, unique, used to prevent duplicate purchases
  luckyNumberIndex: Int as uint16;      // Purchase sequence number (the first lucky number of this purchase)
}
// Draw a prize
message DrawMsg {
  round: Int as uint32;
}
// Clean msg
message CleanMsg {
  round: Int as uint32;
}
// Send prizes msg
message PrizeMsg {
  round: Int as uint32;                  // Round ID  
  txId: Int as uint256;                  // Prize sending txId  
}

struct OrderInfo {
  orderNumber: Int as uint32;           // Order number, unique, used to prevent duplicate purchases
  startLuckyNum: Int as uint16;         // Starting lucky number
  nifiNum: Int as uint16;               // Purchase quantity
}

message BatchSyncOrderMsg {
  round: Int as uint32;
  order1: OrderInfo; 
  order2: OrderInfo; 
  order3: OrderInfo; 
  order4: OrderInfo; 
  order5: OrderInfo; 
  order6: OrderInfo; 
  order7: OrderInfo; 
  order8: OrderInfo; 
  order9: OrderInfo; 
  order10: OrderInfo; 
  order11: OrderInfo; 
  order12: OrderInfo; 
  order13: OrderInfo; 
  order14: OrderInfo; 
}


contract SnatchTresasureContract with Deployable, OwnableTransferable {
  override const storageReserve: Int = ton("0.1");  // Reserve 0.1 Ton as contract storage fee when installing the contract
  rounds: map<Int as uint32, RoundInfo>;            // Record round information and corresponding round purchase information, key is round Id
  owner: Address;
  publicKey: Int as uint256;
  records: map<Int as uint32, Int as uint256>;      // Record corresponding round and corresponding round prize sending txId, key is round Id
  winners: map<Int as uint32, Int as uint16>;       // Record corresponding round and corresponding round winning information, key is round Id, value is the winning number

  // Constructor
  init(owner: Address, pub: Slice, msg:String){
    self.owner = owner;
    self.rounds = emptyMap();
    self.records = emptyMap();
    self.winners = emptyMap();
    self.publicKey = pub.loadUint(256);
  }

  // admin user starts a new round
  receive(msg: NewRoundMsg){
    self.requireOwner();

    // Check if the roundId already exists
    require (self.rounds.get(msg.round) == null,"round already exist");
    require (self.winners.get(msg.round) == null,"round already exist");

    // Create a new round
    self.rounds.set(msg.round,
      RoundInfo{
        orders: emptyMap(),
        sum: msg.sum,
        arrLength: 0,
        finish: false,
        sequence: 0,
        winner: 0,
        awardAmount: msg.awardAmount,
        startTime: msg.startTime,
        endTime: msg.endTime
      }
    );
    let str:StringBuilder = beginComment().concat("new round:").concat(msg.round.toString());
    self.reply(str.toCell());
  }

  // Check if the round can be closed
  receive(msg: CloseRoundMsg){
    self.requireOwner();
    let round: RoundInfo = self.rounds.get(msg.round)!!;

    // Cannot close when the conditions for drawing are met
    require(round.sum != round.arrLength, "can not close");
    round.finish = true;
    self.rounds.set(msg.round, round);
    let str:StringBuilder = beginComment().concat("close round:").concat(msg.round.toString());
    self.reply(str.toCell());
  }

  // User places a bet
  // add emit event
  receive(msg: BuyMsg){
    let ctx: Context = context();
    let round: RoundInfo = self.rounds.get(msg.round)!!;
    require(!(round.finish), "current round is finish");

    // check nowtime < endtime
    require(round.endTime > now(), "current round time is over");
    let exist: BuyInfo? = round.orders.get(msg.orderNumber);
    if (exist != null) {
      // Order duplication check
      require(round.endTime < now(), "current round time is over1");
      require(false, "order repetition");
    }

    // check singner
    let data: Cell = self.getSignData(msg,ctx.sender);
    let hash: Int = data.hash();
    let check: Bool = checkSignature(hash,
      msg.signature.asSlice(),
      self.publicKey
    );
    require(check, "signature verify failed");
    require(round.sum >= (round.arrLength + msg.nifiAmount), "over bet amount");

    // Update purchase information
    round.sequence = (round.sequence + 1);
    let ind: Int = (round.arrLength + 1);
    round.orders.set(msg.orderNumber, BuyInfo{
        startLuckyNum: ind,
        nifiNum: msg.nifiAmount,
      });

    round.arrLength = round.arrLength + msg.nifiAmount;
  
    if (round.sum == round.arrLength) {
      round.finish = true;
    }

    self.rounds.set(msg.round, round);

    // Trigger event
    let eventLog:BuyEvent=BuyEvent{
        round: msg.round,
        amount: msg.nifiAmount,
        orderNumber: msg.orderNumber,
        luckyNumberIndex: ind
      };
    send(SendParameters{
      to: self.owner,
      value: 0,
      mode: SendPayGasSeparately + SendIgnoreErrors,
      bounce: false,
      body: eventLog.toCell()
    }
    );
    // Return Gas balance
    let str:StringBuilder = beginComment().concat("good luck order:").concat(msg.orderNumber.toString());
    self.reply(str.toCell());
  }

  fun getSignData(msg: BuyMsg,addr:Address) : Cell {
    let data: SignData = SignData{
      round:msg.round,
      nifiAmount:msg.nifiAmount,
      orderNumber:msg.orderNumber,
      address:addr,
    };
    return data.toCell();
  }

  // Draw a prize
  receive(msg: DrawMsg){
    self.requireOwner();
    // Prevent duplicate draws
    require(self.winners.get(msg.round) == null,"current round has already been drawn");
    // Check if the round has sold out and can be drawn
    let round: RoundInfo = self.rounds.get(msg.round)!!;
    require(round.finish, "current round is not finish yet");
    // Draw a prize, generate a random number
    let r: Int = random(1, (round.sum + 1));
    round.winner = r;
    self.rounds.set(msg.round, round);
    // Write the draw result into winners
    self.winners.set(msg.round,r);
    // Announce the winning result
    let str:StringBuilder = beginComment().concat("draw round:").concat(msg.round.toString())
    .concat(",lucky number:").concat(r.toString());
    self.reply(str.toCell());
    
  }

  // Write back the prize sending txid record
  receive(msg: PrizeMsg){
    self.requireOwner();
    self.records.set(msg.round, msg.txId);
    let str:StringBuilder = beginComment().concat("award round:").concat(msg.round.toString());
    self.reply(str.toCell());
    
  }

  // Clean historical round data
  receive(msg: CleanMsg){
    self.requireOwner();
    let deletionSuccess: Bool = self.rounds.del(msg.round);
    let str:StringBuilder = beginComment().concat("clean round:").concat(msg.round.toString());
    self.reply(str.toCell());
  }

  receive(msg: BatchSyncOrderMsg) {
    self.requireOwner();  // Ensure the caller is the contract owner
    let roundInfo: RoundInfo = self.rounds.get(msg.round)!!;  // Fetch the information for the specified round
    require(!(roundInfo.finish), "current round is finish");

    let totalNifiNum: Int = 0;
    let fromOrderNumber: Int = 0;
    let toOrderNumber: Int = 0;
    if msg.order1.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order1.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order1.orderNumber, BuyInfo{startLuckyNum: msg.order1.startLuckyNum, nifiNum: msg.order1.nifiNum});
      totalNifiNum += msg.order1.nifiNum;
      roundInfo.sequence += 1;
      fromOrderNumber = msg.order1.orderNumber;
      toOrderNumber = msg.order1.orderNumber;
    }
    if msg.order2.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order2.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order2.orderNumber, BuyInfo{startLuckyNum: msg.order2.startLuckyNum, nifiNum: msg.order2.nifiNum});
      totalNifiNum += msg.order2.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order2.orderNumber;
    }
    if msg.order3.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order3.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order3.orderNumber, BuyInfo{startLuckyNum: msg.order3.startLuckyNum, nifiNum: msg.order3.nifiNum});
      totalNifiNum += msg.order3.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order3.orderNumber;
    }
    if msg.order4.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order4.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order4.orderNumber, BuyInfo{startLuckyNum: msg.order4.startLuckyNum, nifiNum: msg.order4.nifiNum});
      totalNifiNum += msg.order4.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order4.orderNumber;
    }
    if msg.order5.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order5.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order5.orderNumber, BuyInfo{startLuckyNum: msg.order5.startLuckyNum, nifiNum: msg.order5.nifiNum});
      totalNifiNum += msg.order5.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order5.orderNumber;
    }
    if msg.order6.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order6.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order6.orderNumber, BuyInfo{startLuckyNum: msg.order6.startLuckyNum, nifiNum: msg.order6.nifiNum});
      totalNifiNum += msg.order6.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order6.orderNumber;
    }
    if msg.order7.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order7.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order7.orderNumber, BuyInfo{startLuckyNum: msg.order7.startLuckyNum, nifiNum: msg.order7.nifiNum});
      totalNifiNum += msg.order7.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order7.orderNumber;
    }
    if msg.order8.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order8.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order8.orderNumber, BuyInfo{startLuckyNum: msg.order8.startLuckyNum, nifiNum: msg.order8.nifiNum});
      totalNifiNum += msg.order8.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order8.orderNumber;
    }
    if msg.order9.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order9.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order9.orderNumber, BuyInfo{startLuckyNum: msg.order9.startLuckyNum, nifiNum: msg.order9.nifiNum});
      totalNifiNum += msg.order9.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order9.orderNumber;
    }
    if msg.order10.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order10.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order10.orderNumber, BuyInfo{startLuckyNum: msg.order10.startLuckyNum, nifiNum: msg.order10.nifiNum});
      totalNifiNum += msg.order10.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order10.orderNumber;
    }
    if msg.order11.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order11.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order11.orderNumber, BuyInfo{startLuckyNum: msg.order11.startLuckyNum, nifiNum: msg.order11.nifiNum});
      totalNifiNum += msg.order11.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order11.orderNumber;
    }
    if msg.order12.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order12.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order12.orderNumber, BuyInfo{startLuckyNum: msg.order12.startLuckyNum, nifiNum: msg.order12.nifiNum});
      totalNifiNum += msg.order12.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order12.orderNumber;
    }
    if msg.order13.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order13.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order13.orderNumber, BuyInfo{startLuckyNum: msg.order13.startLuckyNum, nifiNum: msg.order13.nifiNum});
      totalNifiNum += msg.order13.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order13.orderNumber;
    }
    if msg.order14.nifiNum > 0 {
      require(roundInfo.orders.get(msg.order14.orderNumber) == null, "Duplicate order ID");
      roundInfo.orders.set(msg.order14.orderNumber, BuyInfo{startLuckyNum: msg.order14.startLuckyNum, nifiNum: msg.order14.nifiNum});
      totalNifiNum += msg.order14.nifiNum;
      roundInfo.sequence += 1;
      toOrderNumber = msg.order14.orderNumber;
    }

    // Update the purchase quantity and sequence number count
    roundInfo.arrLength += totalNifiNum;

    // Ensure the total purchase quantity does not exceed the allowed maximum for the round
    require(roundInfo.sum >= roundInfo.arrLength, "Purchase amount exceeds the limit");

    // If all lucky numbers have been sold, mark the round as finished
    if (roundInfo.sum == roundInfo.arrLength) {
      roundInfo.finish = true;
    }

    // Store the updated roundInfo
    self.rounds.set(msg.round, roundInfo);
    let reply:StringBuilder = beginComment().concat("batch sync orders: from ").concat(fromOrderNumber.toString()).concat(" to ").concat(toOrderNumber.toString());
    self.reply(reply.toCell());
  }

  // Get the winning information of a specific round
  get fun getRoundWinner(round: Int): WinnerInfo? {
    let winnerNum: Int? = self.winners.get(round);
    if winnerNum== null {
      return null;
    }
    let r:Int=winnerNum!!;
    let roundInfo: RoundInfo = self.rounds.get(round)!!;
    foreach (_, value in roundInfo.orders) {
      if value.startLuckyNum<= r&& r<(value.startLuckyNum+value.nifiNum) {
      return WinnerInfo{
        luckyNum: r,
      };
      }
    }
    return null;  
  }
  // Get all winning records
  get fun getWinnerRecord(): map<Int as uint32,Int as uint16> {
    return self.winners;
  }
  // Get the information of a specific round
  get fun getRoundInfoState(key: Int): RoundInfo? {
    return self.rounds.get(key);
  }
  // Get the prize awarding record of a specific round
  get fun getPrizeTxId(round: Int): Int? {
    return self.records.get(round);
  }
  // Get all prize awarding records
  get fun getPrizeRecord(): map<Int as uint32, Int as uint256> {
    return self.records;
  }
  // Get the purchase information of a specified order in a specific round. If not found, return null; if found, return the order number.
  get fun getOrderExist(round: Int, order: Int): Bool? {
    let info: RoundInfo = self.rounds.get(round)!!;
    return info.orders.get(order) == null;
  }
  // Get the purchase information of a specific sequence number in a specific round
  get fun getBuyInfo(round: Int, orderNumber: Int): BuyInfo? {
    let info: RoundInfo = self.rounds.get(round)!!;
    return info.orders.get(orderNumber);
  }
  // Verify if the signature is valid
  get fun verifySignature(round: Int, nifiAmount: Int, orderNumber: Int,signature: Cell,addr: Address) : Bool {
    let msg: BuyMsg=BuyMsg{
      round: round,
      nifiAmount: nifiAmount,
      orderNumber: orderNumber,
      signature: signature
    };
    let data: Cell =self.getSignData(msg,addr);
    let hash: Int = data.hash();
    let check: Bool = checkSignature(hash, msg.signature.asSlice(), self.publicKey);

    return check;
  }
  // Get public key information
  get fun getPubkey(): Int {
    return self.publicKey;
  }

}