import "@stdlib/deploy";
import "@stdlib/ownable";
//一轮抢宝信息
struct RoundInfo {
  //购买记录
  quotient: map<Int as uint32, BuyInfo>; //key is sequence number
  // 订单防重记录,key是订单号 value is sequence number
  orders: map<Int as uint32, Int as uint16>;
  //总共多少个幸运号码
  sum: Int as uint16;
  //已经购买的号码数
  arrLength: Int as uint16;
  //订单数
  sequence: Int as uint16;
  //是否结束
  finish: Bool;
  //中奖号码
  winner: Int as uint16;
  //奖金
  awardAmount: Int as coins;
  //开始时间
  startTime: Int as uint32;
  //结束时间
  endTime: Int as uint32;
}
struct BuyInfo {
  //开始的幸运号码
  startLuckyNum: Int as uint16;
  //购买数量
  nifiNum: Int as uint16;
  //购买者地址
  address: Address;
}
//中奖信息
struct WinnerInfo {
  //中奖号码
  luckyNum: Int as uint16;
  //中奖者地址
  address: Address;
}
//签名数据
struct SignData {
  //轮次ID
  round: Int as uint32;
  //购买数量
  nifiAmount: Int as uint16;
  //订单号,唯一，用于防止重复购买
  orderNumber: Int as uint32;
  //买方地址
  address: Address;
}
// admin 新建轮次msg
message NewRoundMsg {
  //轮次ID
  round: Int as uint32;
    //总共多少个幸运号码
  sum: Int as uint16;
    //开始时间
  startTime: Int as uint32;
    //结束时间
  endTime: Int as uint32;
    //奖金
  awardAmount: Int as coins;
}

// admin 关闭轮次
message CloseRoundMsg {
  round: Int as uint32;
}

// 用户购买msg
message BuyMsg {
  //轮次ID
  round: Int as uint32;
  //购买数量
  nifiAmount: Int as uint16;
  //订单号,唯一，用于防止重复购买
  orderNumber: Int as uint32;
  //签名
  signature: Cell;
}
message BuyEvent {
  //轮次ID
  round: Int as uint32;
  //购买数量
  amount: Int as uint16;
  //购买地址
  buy: Address;
  //订单号,唯一，用于防止重复购买
  orderNumber: Int as uint32;
  //购买序号(本次购买的幸运号码的第一个)
  luckyNumberIndex: Int as uint16;
}
// 开奖
message DrawMsg {
  round: Int as uint32;
}
//clean msg
message CleanMsg {
  round: Int as uint32;
}
//send prizes msg
message PrizeMsg {
  //轮次ID
  round: Int as uint32;
    //奖品发送txId
  txId: Int as uint256;
}


contract SnatchTresasureContract with Deployable, OwnableTransferable {
  override const storageReserve: Int = ton("0.1");  //安装合约的时候，保留0.1Ton作为合约存储费
  rounds: map<Int as uint32, RoundInfo>;//记录轮次信息和对应轮次购买信息,key是轮次Id
  owner: Address;
  publicKey: Int as uint256;
//  roundIndex: Int as uint32;
  records: map<Int as uint32, Int as uint256>; // 记录对应轮次以及对应轮次奖品发送txId，key是轮次Id
  winners: map<Int as uint32, Int as uint16>; // 记录对应轮次以及对应轮次中奖信息，key是轮次Id，Value是中奖号

  //构造函数
  init(owner: Address, pub: Slice){
//    dump(pub);
    self.owner = owner;
//    self.roundIndex = 1; // 从1开始
    self.rounds = emptyMap();
    self.records = emptyMap();
    self.winners = emptyMap();
    self.publicKey = pub.loadUint(256);
  }

  // admin user 开始新一轮
  receive(msg: NewRoundMsg){
    self.requireOwner();
    //判断roundId是否已经存在
    require (self.rounds.get(msg.round) == null,"round already exist");
    require (self.winners.get(msg.round) == null,"round already exist");
    //创建新一轮
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
//    self.roundIndex = (self.roundIndex + 1);
    let str:StringBuilder = beginComment().concat("new round:").concat(msg.round.toString());
    self.reply(str.toCell());
  }

  // 检查是否可以close round
  receive(msg: CloseRoundMsg){
    self.requireOwner();
    let round: RoundInfo = self.rounds.get(msg.round)!!;
    // 当满足开奖则不能close
    require(round.sum != round.arrLength, "can not close");
    round.finish = true;
    self.rounds.set(msg.round, round);
    let str:StringBuilder = beginComment().concat("close round:").concat(msg.round.toString());
    self.reply(str.toCell());
  }

  // 用户下注
  // add emit event
  receive(msg: BuyMsg){
    let ctx: Context = context();
    let round: RoundInfo = self.rounds.get(msg.round)!!;
    require(!(round.finish), "current round is finish");
    // check nowtime < endtime
    require(round.endTime > now(), "current round time is over");
    let exist: Int? = round.orders.get(msg.orderNumber);
    if (exist != null) {
      // 订单重复判断
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
    //更新购买信息
    round.sequence = (round.sequence + 1);
    let ind: Int = (round.arrLength + 1);
    round.orders.set(msg.orderNumber, round.sequence);
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

    // 触发事件
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
    //返回Gas余额
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

  //开奖
  receive(msg: DrawMsg){
    self.requireOwner();
    //防止重复开奖
    require(self.winners.get(msg.round) == null,"current round has already been drawn");
    //检查轮次是否已经售卖完毕，可以开奖
    let round: RoundInfo = self.rounds.get(msg.round)!!;
    require(round.finish, "current round is not finish yet");
    //开奖，产生随机数
    let r: Int = random(1, (round.sum + 1));
    round.winner = r;
    self.rounds.set(msg.round, round);
    // 开奖结果写入winners
    self.winners.set(msg.round,r);
    // 告之中奖结果
    let str:StringBuilder = beginComment().concat("draw round:").concat(msg.round.toString())
    .concat(",lucky number:").concat(r.toString());
    self.reply(str.toCell());
    
  }

  //  回写发奖txid记录
  receive(msg: PrizeMsg){
    self.requireOwner();
    self.records.set(msg.round, msg.txId);
    let str:StringBuilder = beginComment().concat("award round:").concat(msg.round.toString());
    //.concat(",tx:").concat(msg.txId.toString());
    self.reply(str.toCell());
    
  }

  // 清理历史round Data
  receive(msg: CleanMsg){
    self.requireOwner();
    let deletionSuccess: Bool = self.rounds.del(msg.round);
    let str:StringBuilder = beginComment().concat("clean round:").concat(msg.round.toString());
    self.reply(str.toCell());
  }

  // 获取某轮次的中奖信息
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
  // 获取所有中奖记录
  get fun getWinnerRecord(): map<Int as uint32,Int as uint16> {
    return self.winners;
  }
  // 获取某轮次的信息
  get fun getRoundInfoState(key: Int): RoundInfo? {
    return self.rounds.get(key);
  }
  // 获取某轮次的颁奖记录
  get fun getPrizeTxId(round: Int): Int? {
    return self.records.get(round);
  }
  // 获取所有颁奖记录
  get fun getPrizeRecord(): map<Int as uint32, Int as uint256> {
    return self.records;
  }
  // 获取某轮次的指定订单的购买信息，如果差不多则返回空，查到则返回是第几个订单
  get fun getOrderExist(round: Int, order: Int): Int? {
    let info: RoundInfo = self.rounds.get(round)!!;
    return info.orders.get(order);
  }
  // 获取某轮次的第几号购买记录的购买信息
  get fun getBuyInfo(round: Int, seqNum: Int): BuyInfo? {
    let info: RoundInfo = self.rounds.get(round)!!;
    return info.quotient.get(seqNum);
  }
  //验证签名是否有效
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
  //获取公钥信息
  get fun getPubkey(): Int {
    return self.publicKey;
  }

}