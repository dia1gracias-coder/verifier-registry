import "@stdlib/deploy";

// Структура для хранения информации о победителе
struct Winner {
    userId: Int;
    tgId: Int;
    firstName: String?;
    lastName: String?;
    username: String?;
    ticketId: Int;
    createdAt: Int; // timestamp
}

// Структура для хранения информации о розыгрыше
struct DrawResult {
    drawId: Int;
    ownerId: Int;
    winnersCount: Int;
    totalTickets: Int;
    drawType: String;
    completedAt: Int; // timestamp
    winners: map<Int, Winner>; // Map winner index -> Winner
}

// Сообщение для записи результатов розыгрыша
message RecordDrawResult {
    drawId: Int;
    ownerId: Int;
    winnersCount: Int;
    totalTickets: Int;
    drawType: String;
    winners: map<Int, Winner>;
}

// Сообщение для получения результатов розыгрыша
message GetDrawResult {
    drawId: Int;
}

// Ответное сообщение с результатами
message DrawResultResponse {
    exists: Bool;
    drawResult: DrawResult?;
}

contract DrawContract with Deployable {
    
    // Хранилище результатов розыгрышей (drawId -> DrawResult)
    draws: map<Int, DrawResult>;
    
    // Владелец контракта
    owner: Address;
    
    // Количество записанных розыгрышей
    totalDraws: Int as uint32 = 0;

    init() {
        self.owner = sender();
    }

    // Функция для записи результатов розыгрыша
    receive(msg: RecordDrawResult) {
        // Проверяем, что отправитель - владелец контракта
        require(sender() == self.owner, "Only owner can record draw results");
        
        // Проверяем, что розыгрыш еще не записан
        require(self.draws.get(msg.drawId) == null, "Draw already recorded");
        
        // Создаем новый результат розыгрыша
        let drawResult: DrawResult = DrawResult{
            drawId: msg.drawId,
            ownerId: msg.ownerId,
            winnersCount: msg.winnersCount,
            totalTickets: msg.totalTickets,
            drawType: msg.drawType,
            completedAt: now(),
            winners: msg.winners
        };
        
        // Сохраняем результат
        self.draws.set(msg.drawId, drawResult);
        self.totalDraws = self.totalDraws + 1;
        
        // Отправляем подтверждение
        self.reply("Draw result recorded successfully".asComment());
    }

    // Get-метод для получения результатов розыгрыша
    get fun getDrawResult(drawId: Int): DrawResult? {
        return self.draws.get(drawId);
    }

    // Get-метод для получения победителя по индексу
    get fun getWinner(drawId: Int, winnerIndex: Int): Winner? {
        let drawResult: DrawResult? = self.draws.get(drawId);
        if (drawResult != null) {
            return drawResult!!.winners.get(winnerIndex);
        }
        return null;
    }

    // Get-метод для проверки существования розыгрыша
    get fun drawExists(drawId: Int): Bool {
        return self.draws.get(drawId) != null;
    }

    // Get-метод для получения общего количества розыгрышей
    get fun getTotalDraws(): Int {
        return self.totalDraws;
    }

    // Get-метод для получения владельца
    get fun getOwner(): Address {
        return self.owner;
    }

    // Функция для изменения владельца (только текущий владелец)
    receive("change_owner") {
        require(sender() == self.owner, "Only owner can change ownership");
        self.owner = sender();
    }
} 