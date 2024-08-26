import "@stdlib/deploy";
import "@stdlib/ownable";
// One round of treasure snatching information
struct RoundInfo {
  // Purchase records
  quotient: map<Int as uint32, BuyInfo>; // key is sequence number
  // Order anti-duplication records, key is order number, value is sequence number
  orders: map<Int as uint32, Int as uint16>;
  // Total number of lucky numbers
  sum: Int as uint16;
  // Number of purchased numbers
  arrLength: Int as uint16;
  // Number of orders
  sequence: Int as uint16;
  // Whether it has ended
  finish: Bool;
  // Winning number
  winner: Int as uint16;
  // Award amount
  awardAmount: Int as coins;
  // Start time
  startTime: Int as uint32;
  // End time
  endTime: Int as uint32;
}
struct BuyInfo {
  // Starting lucky number
  startLuckyNum: Int as uint16;
  // Purchase quantity
  nifiNum: Int as uint16;
  // Purchaser's address
  address: Address;
}
// Winning information
struct WinnerInfo {
  // Winning number
  luckyNum: Int as uint16;
  // Winner's address
  address: Address;
}
// Signature data
struct SignData {
  // Round ID
  round: Int as uint32;
  // Purchase quantity
  nifiAmount: Int as uint16;
  // Order number, unique, used to prevent duplicate purchases
  orderNumber: Int as uint32;
  // Buyer's address
  address: Address;
}
// admin creates a new round msg
message NewRoundMsg {
  // Round ID
  round: Int as uint32;
  // Total number of lucky numbers
  sum: Int as uint16;
  // Start time
  startTime: Int as uint32;
  // End time
  endTime: Int as uint32;
  // Award amount
  awardAmount: Int as coins;
}

// admin closes the round
message CloseRoundMsg {
  round: Int as uint32;
}

// User purchase msg
message BuyMsg {
  // Round ID
  round: Int as uint32;
  // Purchase quantity
  nifiAmount: Int as uint16;
  // Order number, unique, used to prevent duplicate purchases
  orderNumber: Int as uint32;
  // Signature
  signature: Cell;
}
message BuyEvent {
  // Round ID
  round: Int as uint32;
  // Purchase quantity
  amount: Int as uint16;
  // Purchase address
  buy: Address;
  // Order number, unique, used to prevent duplicate purchases
  orderNumber: Int as uint32;
  // Purchase sequence number (the first lucky number of this purchase)
  luckyNumberIndex: Int as uint16;
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
  // Round ID
  round: Int as uint32;
  // Prize sending txId
  txId: Int as uint256;
}


contract SnatchTresasureContract with Deployable, OwnableTransferable {
  override const storageReserve: Int = ton("0.1");  // Reserve 0.1 Ton as contract storage fee when installing the contract
  rounds: map<Int as uint32, RoundInfo>;  // Record round information and corresponding round purchase information, key is round Id
  owner: Address;
  publicKey: Int as uint256;
  records: map<Int as uint32, Int as uint256>; // Record corresponding round and corresponding round prize sending txId, key is round Id
  winners: map<Int as uint32, Int as uint16>; // Record corresponding round and corresponding round winning information, key is round Id, value is the winning number

  // Constructor
  init(owner: Address, pub: Slice){
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
        quotient: emptyMap(),
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
    let exist: Int? = round.orders.get(msg.orderNumber);
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
    round.orders.set(msg.orderNumber, ind);
    round.quotient.set(round.sequence,
      BuyInfo{
        startLuckyNum: ind,
        nifiNum: msg.nifiAmount,
        address: ctx.sender
      }
    );

    round.arrLength = round.arrLength + msg.nifiAmount;
  
    if (round.sum == round.arrLength) {
      round.finish = true;
    }

    self.rounds.set(msg.round, round);

    // Trigger event
    let eventLog:BuyEvent=BuyEvent{
        round: msg.round,
        amount: msg.nifiAmount,
        buy: ctx.sender,
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

  // Get the winning information of a specific round
  get fun getRoundWinner(round: Int): WinnerInfo? {
    let winnerNum: Int? = self.winners.get(round);
    if winnerNum== null {
      return null;
    }
    let r:Int=winnerNum!!;
    let roundInfo: RoundInfo = self.rounds.get(round)!!;
    foreach (_, value in roundInfo.quotient) {
      if value.startLuckyNum<= r&& r<(value.startLuckyNum+value.nifiNum) {
      return WinnerInfo{
        luckyNum: r,
        address: value.address
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
  get fun getOrderExist(round: Int, order: Int): Int? {
    let info: RoundInfo = self.rounds.get(round)!!;
    return info.orders.get(order);
  }
  // Get the purchase information of a specific sequence number in a specific round
  get fun getBuyInfo(round: Int, seqNum: Int): BuyInfo? {
    let info: RoundInfo = self.rounds.get(round)!!;
    return info.quotient.get(seqNum);
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