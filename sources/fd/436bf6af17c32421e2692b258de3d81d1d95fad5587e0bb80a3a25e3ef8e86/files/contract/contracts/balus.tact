import "@stdlib/deploy";

struct Content {
  id: Int;
  owner: Address;
  text: String;
  initialPrice: Int;
  increasement: Int;
  commision: Int;
  pool: Int;
  supply: Int;
  holders: map<Address, Int>;
}

message SetServiceFee {
  createServiceFee: Int;
  tradeCommision: Int;
}

message Create {
  text: String;
  initialPrice: Int;
  increasement: Int;
  commision: Int;
}

message Buy {
  contentId: Int;
  amount: Int;
}

message Sell {
  contentId: Int;
  amount: Int;
}

message Withdraw {
  reserve: Int;
  to: Address;
}

message CreateEvent {
  from: Address;
  contentId: Int;
  content: Content;
}

message BuyEvent {
  from: Address;
  contentId: Int;
  start: Int;
  amount: Int;
  price: Int;
}

message SellEvent {
  from: Address;
  contentId: Int;
  start: Int;
  amount: Int;
  price: Int;
}

contract Balus with Deployable {
  deployer: Address;
  nextId: Int;
  createServiceFee: Int;
  tradeCommision: Int;
  tvl: Int;

  contentMap: map<Int, Content>;

  init() {
    self.deployer = sender();
    self.nextId = 0;
    self.createServiceFee = ton("0.1");
    self.tradeCommision = 5000;
    self.tvl = 0;
  }

  fun calcPrice(c: Content, point: Int): Int {
    return point * c.initialPrice + point * point * point / c.increasement;
  }

  receive(msg: SetServiceFee) {
    require(sender() == self.deployer, "No permission");
    self.createServiceFee = msg.createServiceFee;
    self.tradeCommision = msg.tradeCommision;
    send(SendParameters{
      to: sender(),
      bounce: true,
      value: 0,
      mode: SendIgnoreErrors + SendRemainingValue,
      body: "Refund for update config".asComment()
    });
  }

  receive(msg: Withdraw) {
    require(sender() == self.deployer, "No permission");
    require(myBalance() >= self.tvl + msg.reserve, "Insufficient withdrawable balance in the pool");
    nativeReserve(self.tvl + msg.reserve, ReserveExact);
    send(SendParameters{
      to: msg.to,
      bounce: true,
      value: 0,
      mode: SendIgnoreErrors + SendRemainingBalance,
      body: "Refund for withdraw".asComment()
    });
  }

  receive(msg: Create) {
    require(context().value >= self.createServiceFee, "Insufficient creation fee");
    let c: Content = Content{
      id: self.nextId,
      owner: sender(),
      text: msg.text,
      initialPrice: msg.initialPrice,
      increasement: msg.increasement,
      commision: msg.commision,
      pool: 0,
      supply: 0,
      holders: emptyMap()
    };
    nativeReserve(self.createServiceFee, ReserveExact + ReserveAddOriginalBalance);
    self.contentMap.set(self.nextId, c);
    self.nextId += 1;
    emit(CreateEvent{from: sender(), contentId: self.nextId, content: c}.toCell());
    send(SendParameters{
      to: sender(),
      bounce: true,
      value: 0,
      mode: SendRemainingBalance + SendIgnoreErrors,
      body: "Refund for create content".asComment()
    });
  }

  receive(msg: Buy) {
    require(self.contentMap.get(msg.contentId) != null, "Traded content does not exist");
    require(msg.amount > 0, "Amount should greater than 0");
    let input: Int = context().value;
    let content: Content = self.contentMap.get(msg.contentId)!!;
    let price: Int = self.calcPrice(content, content.supply + msg.amount) - self.calcPrice(content, content.supply) + 1;
    require(context().value >= price, "Insufficient payment amount");
    
    let holdCount: Int? = content.holders.get(sender());
    if (holdCount == null) {
      content.holders.set(sender(), msg.amount);
    } else {
      content.holders.set(sender(), holdCount!! + msg.amount);
    }

    let priceWithoutCommision: Int = price - price * content.commision / 10000;
    content.pool += priceWithoutCommision;
    self.tvl += priceWithoutCommision;

    let originalSupply: Int = content.supply;
    content.supply += msg.amount;
    self.contentMap.set(msg.contentId, content);
    emit(BuyEvent{
      from: sender(),
      contentId: msg.contentId,
      start: originalSupply,
      amount: msg.amount,
      price: price
    }.toCell());
    let incomeOfOwner: Int = price * content.commision / 10000 - price * content.commision / 10000 * self.tradeCommision / 10000;
    send(SendParameters{
      to: content.owner,
      bounce: true,
      value: incomeOfOwner,
      mode: SendIgnoreErrors,
      body: "Royalty".asComment()
    });
    nativeReserve(price - incomeOfOwner, ReserveExact + ReserveAddOriginalBalance);
    send(SendParameters{
      to: sender(),
      bounce: true,
      value: 0,
      mode: SendRemainingBalance + SendIgnoreErrors,
      body: "Refund for buy".asComment()
    });
  }

  receive(msg: Sell) {
    require(self.contentMap.get(msg.contentId) != null, "Traded content does not exist");
    require(msg.amount > 0, "Sell amount must greater than 0");

    let content: Content = self.contentMap.get(msg.contentId)!!;
    let holdCount: Int? = content.holders.get(sender());
    require(holdCount != null && holdCount!! >= msg.amount, "Insufficient shares held");

    let price: Int = self.calcPrice(content, content.supply) - self.calcPrice(content, content.supply - msg.amount);
    let priceWithoutCommision: Int = price - price * content.commision / 10000;
    content.pool -= priceWithoutCommision;
    self.tvl -= priceWithoutCommision;

    let originalSupply: Int = content.supply;
    content.supply -= msg.amount;
    content.holders.set(sender(), holdCount!! - msg.amount);
    self.contentMap.set(msg.contentId, content);
    emit(SellEvent{
      from: sender(),
      contentId: msg.contentId,
      start: originalSupply,
      amount: msg.amount,
      price: price
    }.toCell());
    send(SendParameters{
      to: sender(),
      bounce: true,
      value: priceWithoutCommision,
      mode: SendIgnoreErrors,
      body: "Earnings".asComment()
    });
    send(SendParameters{
      to: sender(),
      bounce: true,
      value: 0,
      mode: SendRemainingValue + SendIgnoreErrors,
      body: "Refund for sell".asComment()
    });
  }

  get fun allContent(): map<Int, Content> {
    return self.contentMap;
  }

  get fun content(id: Int): Content? {
    return self.contentMap.get(id);
  }

  get fun createServiceFee(): Int {
    return self.createServiceFee;
  }

  get fun tradeCommision(): Int {
    return self.tradeCommision;
  }

  get fun tvl(): Int {
    return self.tvl;
  }

  get fun balance(): Int {
    return myBalance();
  }

}
