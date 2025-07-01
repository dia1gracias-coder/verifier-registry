// Сначала определим структуру для ставок
struct BetInfo {
    choice: Bool;
    amount: Int;
}

// Структура для ответа get-метода
struct GetSummaryResponse {
    resolved: Bool;
    totalYes: Int;
    totalNo: Int;
    deadline: Int;
    description: String;
}

// Сообщения
message PlaceBet {
    choice: Bool;
}

message ResolveEvent {
    outcome: Bool;
}

message Claim {
}

contract Event {
  // --- Инициализация
  mainAdmin: Address = address("UQDBFoW7wPlwdqnbIJ0SQMR3HdxYEyrXvACmApKmijTDa4kj");
  admin: Address;
  deadline: Int;         // UNIX-время завершения ставок
  description: String;    // описание события (например, hash IPFS)
  resolved: Bool = false;
  result: Bool?;         // true / false
  totalYes: Int = 0;
  totalNo: Int = 0;

  bets: map<Address, BetInfo>;

  // --- Конструктор
  init(_admin: Address, _deadline: Int, _description: String) {
    self.admin = _admin;
    self.deadline = _deadline;
    self.description = _description;
    self.bets = emptyMap();
  }

  // пустой receive для деплоя
  receive() {
    // Деплой успешен, ничего не делаем
  }

  // --- Ставка: принимает Toncoin и выбор (Да / Нет)
  receive(msg: PlaceBet) {
    require(!self.resolved, "Already resolved");
    require(now() < self.deadline, "Betting closed");

    let choice: Bool = msg.choice;
    let amount: Int = context().value;
    require(amount > 0, "Amount must be positive");

    let existing: BetInfo? = self.bets.get(context().sender);

    if (existing != null) {
        let prev: BetInfo = existing!!;
        require(prev.choice == choice, "Cannot bet both Yes and No");

        let newAmount = prev.amount + amount;
        self.bets.set(context().sender, BetInfo{choice: choice, amount: newAmount});
    } else {
        self.bets.set(context().sender, BetInfo{choice: choice, amount: amount});
    }

    if (choice) {
        self.totalYes = self.totalYes + amount;
    } else {
        self.totalNo = self.totalNo + amount;
    }
}


  // --- Завершение: админ указывает исход
  // --- Завершение: только mainAdmin указывает исход
    receive(msg: ResolveEvent) {
    require(context().sender == self.mainAdmin, "Only mainAdmin can resolve");
    require(!self.resolved, "Already resolved");
    self.result = msg.outcome;
    self.resolved = true;
    }


  // --- Выплата: участник сам вызывает и получает выплату
  receive(msg: Claim) {
    require(self.resolved, "Not resolved");

    let betInfo: BetInfo? = self.bets.get(context().sender);
    require(betInfo != null, "No bet");
    let bet: BetInfo = betInfo!!;

    // Только победившие могут требовать выплату
    require(bet.choice == self.result!!, "Wrong side");

    let winPool: Int = self.result!! ? self.totalYes : self.totalNo;
    let losePool: Int = self.result!! ? self.totalNo : self.totalYes;
    let payout: Int = bet.amount + (bet.amount * losePool) / winPool;

    // удаляем ставку, чтобы не было повторных claim
    self.bets.set(context().sender, null);

    // Выплата
    send(SendParameters{
        to: context().sender,
        value: payout,
        mode: SendIgnoreErrors,
        bounce: false
    });
  }

  // --- Информация о событии
  get fun get_summary(): GetSummaryResponse {
    return GetSummaryResponse{
        resolved: self.resolved,
        totalYes: self.totalYes,
        totalNo: self.totalNo,
        deadline: self.deadline,
        description: self.description
    };
  }

  get fun get_bet(user: Address): BetInfo? {
    return self.bets.get(user);
  }
}
 