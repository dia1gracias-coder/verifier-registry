import "@stdlib/deploy"; 

// Определение сообщения для завершения лотереи
message Finalize {
    confirmation: Bool;  // Поле для подтверждения завершения
}

// Определение сообщения для изменения интервала
message SetInterval {
    newInterval: Int;
}

// Определение сообщения для ставки
message PlaceBet {
    value: Int;  // Сумма ставки
}

contract Lottery {
    owner: Address;                         
    participants: map<Address, Int>;        
    totalAmount: Int;                       
    interval: Int;                          
    startTime: Int;                         
    participantCount: Int = 0; // Переменная для хранения количества участников

    // Инициализация контракта
    init(owner: Address, interval: Int) {
        self.owner = owner;
        self.interval = interval;
        self.startTime = now();
        self.participants = emptyMap();  
        self.totalAmount = 0;
    }

    // Приём ставок
    receive(msg: PlaceBet) {
        require(msg.value >= ton("2"), "Minimum bet is 2 TON");  // Проверка минимальной ставки
        
        // Получаем существующую ставку
        let existingBetOption: Int? = self.participants.get(sender()); // Получаем значение или null, если ключ не существует
        
        // Если значение отсутствует, устанавливаем по умолчанию 0
        let existingBet: Int = existingBetOption != null ? existingBetOption!! : 0; // Принудительное преобразование

        self.participants.set(sender(), existingBet + msg.value); // Обновляем сумму ставки
        self.totalAmount += msg.value; // Увеличиваем общий фонд

        // Увеличиваем счётчик участников, если это новый участник
        if (existingBet == 0) {
            self.participantCount += 1; // Увеличиваем количество участников
        }
    }

    // Завершение лотереи
    receive(msg: Finalize) {
        require(now() >= self.startTime + self.interval, "Lottery interval not yet passed");
        require(msg.confirmation, "Confirmation required to finalize the lottery"); // Проверка подтверждения
        let winner: Address = self.selectWinner();
        let prize: Int = (self.totalAmount * 90) / 100;
        let commission: Int = self.totalAmount - prize;

        send(SendParameters{to: winner, value: prize, mode: SendPayGasSeparately});
        send(SendParameters{to: self.owner, value: commission, mode: SendPayGasSeparately});

        self.resetLottery();
    }

    // Выбор победителя
    fun selectWinner(): Address {
        // Проверяем, есть ли участники
        require(self.participantCount > 0, "No participants to choose from."); // Проверяем, есть ли участники

        // Генерируем случайный индекс
        let randomIndex: Int = now() % self.participantCount; // Генерируем случайный индекс

        // Перебираем участников, чтобы найти победителя
        let index: Int = 0; // Индекс для перебора
        foreach (address, value in self.participants) {
            if (index == randomIndex) {
                return address; // Возвращаем адрес победителя
            }
            index += 1; // Увеличиваем индекс
        }

        // Если победитель не найден, возвращаем адрес владельца
        return self.owner; // Возвращаем адрес владельца контракта
    }

    // Сброс лотереи
    fun resetLottery() {
        self.participants = emptyMap();
        self.totalAmount = 0;
        self.participantCount = 0; // Сбрасываем счётчик участников
        self.startTime = now();
    }

    // Изменение интервала лотереи
    receive(msg: SetInterval) {
        require(sender() == self.owner, "Only owner can set the interval");
        self.interval = msg.newInterval;
    }

    // Получение баланса
    get fun balance(): Int {
        return myBalance(); // Возвращаем текущий баланс без вычитания STORAGE
    }

    // Получение владельца
    get fun owner(): Address {
        return self.owner;
    }
}
