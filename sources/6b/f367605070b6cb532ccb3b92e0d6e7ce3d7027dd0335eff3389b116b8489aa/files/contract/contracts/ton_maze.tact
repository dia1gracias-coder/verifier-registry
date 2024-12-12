import "@stdlib/deploy";

contract TonMaze {
    const minTonsForStorage: Int = ton("0.01");
    const gasConsumption: Int = ton("0.01");
    
    TonToMazeRate: Int; // 1 TON = 200 Maze
    MazeToTonRate: Int;  // 1 Maze = 0.005 TON (с учетом масштаба)

    balance: Int;  // Баланс токенов (Maze) для продажи
    owner: Address;  // Адрес владельца контракта
    master: Address;  // Адрес получателя средств

    init(master: Address, owner: Address) {
        self.balance = 0;  // Изначально на балансе нет токенов
        self.owner = owner;
        self.master = master;
        self.TonToMazeRate = 200;
        self.MazeToTonRate = 5;
    }

    // Функция для обмена TON на Maze токены
    receive(msg: TokenPurchase) {
        let ctx: Context = context();

        // Проверка, что на балансе достаточно токенов для продажи
        require(self.balance >= msg.amount, "Not enough tokens available");

        // Вычисление стоимости в TON для покупки указанного количества Maze
        let totalCost: Int = msg.amount * self.TonToMazeRate / 1000;  // Приводим к правильному масштабу

        // Проверка, что отправленная сумма соответствует стоимости
        require(ctx.value >= totalCost, "Insufficient funds for token purchase");

        // Обновление баланса токенов
        self.balance = self.balance - msg.amount;

        // Перевод средств владельцу контракта
        send(SendParameters{
            to: self.owner,
            value: totalCost,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenPurchaseNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    // Функция для обмена Maze токенов на TON
    receive(msg: TokenSale) {
        let ctx: Context = context();

        // Проверка, что отправленная сумма в Maze больше нуля
        require(msg.amount > 0, "Amount must be greater than 0");

        // Проверка, что на балансе достаточно TON для продажи
        let tonToGive: Int = msg.amount * self.MazeToTonRate / 1000;  // Приводим к правильному масштабу
        require(self.balance >= tonToGive, "Not enough TON for sale");

        // Обновление баланса Maze
        self.balance = self.balance + msg.amount;

        // Перевод средств пользователю (отправка TON)
        send(SendParameters{
            to: ctx.sender,
            value: tonToGive,
            mode: SendRemainingValue,
            bounce: true,
            body: TokenSaleNotification{
                queryId: msg.queryId,
                amount: msg.amount,
                owner: self.owner,
                response_destination: self.owner
            }.toCell()
        });
    }

    // Функция для пополнения баланса токенов (только владельцем)
    fun depositTokens(amount: Int) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only the owner can deposit tokens");
        require(amount > 0, "Amount must be greater than 0");

        self.balance = self.balance + amount;
    }

    // Обработка неудачных транзакций
    fun handleError(msg: TokenPurchaseNotification) {
        // В случае ошибок транзакции мы просто не отправляем токены
        self.balance = self.balance + msg.amount;
    }

    // Getters

    // Getter для получения текущего баланса токенов Maze
    get fun balance(): Int {
        return self.balance;
    }

    // Getter для получения адреса владельца
    get fun owner(): Address {
        return self.owner;
    }

    // Getter для получения адреса мастера
    get fun master(): Address {
        return self.master;
    }

    // Getter для получения курса обмена TON на Maze
    get fun ton_to_maze_rate(): Int {
        return self.TonToMazeRate;
    }

    // Getter для получения курса обмена Maze на TON
    get fun maze_to_ton_rate(): Int {
        return self.MazeToTonRate;
    }
}

// Структуры для покупки и продажи
message TokenPurchase {
    queryId: Int;
    amount: Int;  // Количество токенов Maze для покупки
}

message TokenSale {
    queryId: Int;
    amount: Int;  // Количество токенов Maze для продажи
}

message TokenPurchaseNotification {
    queryId: Int;
    amount: Int;
    owner: Address;
    response_destination: Address;
}

message TokenSaleNotification {
    queryId: Int;
    amount: Int;
    owner: Address;
    response_destination: Address;
}
