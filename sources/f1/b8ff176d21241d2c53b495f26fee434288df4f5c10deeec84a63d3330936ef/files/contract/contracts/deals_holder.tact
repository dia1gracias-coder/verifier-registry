import "@stdlib/deploy";

// --- СТРУКТУРЫ ДАННЫХ ---

struct DealData {
    userA: Address;
    userB: Address;
    amountA: Int as coins;
    amountB: Int as coins;
}

// --- СООБЩЕНИЯ (COMMANDS) ---

// Биржа добавляет сделку (Opcode 0x100 = 256)
message(0x100) AddDeal {
    dealId: Int as uint64;
    userA: Address;
    userB: Address;
    amountA: Int as coins;
    amountB: Int as coins;
}

// Биржа выплачивает выигрыш (Opcode 0x200 = 512)
message(0x200) Payout {
    dealId: Int as uint64;
    amountToPay: Int as coins;
    winner: Address;
}

// Биржа отменяет одну сделку (Opcode 0x300 = 768)
message(0x300) CancelSingle {
    dealId: Int as uint64;
}

// Пользователь требует возврат (Opcode 0x400 = 1024)
message(0x400) EmergencyClaim {
    dealId: Int as uint64;
}

// Биржа забирает комиссии и закрывает контракт (Opcode 0x500 = 1280)
message(0x500) WithdrawFees {
}

// --- ЛОГИКА КОНТРАКТА ---

contract MultiDeal with Deployable {

    owner: Address;
    startTime: Int as uint32;
    deals: map<Int, DealData>; // Словарь: ID -> Данные

// Инициализация (Конструктор)
    init(owner: Address, startTime: Int) {
        self.owner = owner;
        self.startTime = startTime;
    }

// 1. Добавление сделки (вызывает Биржа)
    receive(msg: AddDeal) {
        // Проверяем, что прислали достаточно TON для покрытия возвратов
        let requiredValue: Int = msg.amountA + msg.amountB;
        // context().value - это сколько монет пришло в этом сообщении
        require(context().value >= requiredValue, "Not enough funds sent for deal budget");

        let deal: DealData = DealData{
            userA: msg.userA,
            userB: msg.userB,
            amountA: msg.amountA,
            amountB: msg.amountB
        };

        self.deals.set(msg.dealId, deal);
    }

// 2. Выплата выигрыша (Только Владелец)
    receive(msg: Payout) {
        require(sender() == self.owner, "Access denied: Owner only");

        // Получаем сделку (!! означает "я уверен, что она существует", иначе упадет ошибка)
        let deal: DealData = self.deals.get(msg.dealId)!!;

        // Отправляем выигрыш победителю
        // Mode: SendPayGasSeparately (1) - Биржа платит за газ обработки, чтобы победитель получил точную сумму
        send(SendParameters{
            to: msg.winner,
            value: msg.amountToPay,
            mode: SendPayGasSeparately,
            body: "Win".asComment()
        });

        // Удаляем сделку из памяти (возвращаем газ, освобождаем сторидж)
        self.deals.set(msg.dealId, null);
    }

// 3. Отмена одной сделки (Только Владелец)
    receive(msg: CancelSingle) {
        require(sender() == self.owner, "Access denied: Owner only");

        let deal: DealData = self.deals.get(msg.dealId)!!;

        // Возврат А
        if (deal.amountA > 0) {
            send(SendParameters{
                to: deal.userA,
                value: deal.amountA,
                mode: SendPayGasSeparately,
                body: "Refund".asComment()
            });
        }

        // Возврат Б
        if (deal.amountB > 0) {
            send(SendParameters{
                to: deal.userB,
                value: deal.amountB,
                mode: SendPayGasSeparately,
                body: "Refund".asComment()
            });
        }

        // Чистим память
        self.deals.set(msg.dealId, null);
    }

// 4. Экстренный вывод (Любой участник, если прошло 3 дня)
    receive(msg: EmergencyClaim) {
        // Проверка времени: 3 дня = 259200 секунд
        require(now() > (self.startTime + 259200), "Too early for emergency claim");

        let deal: DealData = self.deals.get(msg.dealId)!!;

        // Проверяем, что запрос делает один из участников
        require(sender() == deal.userA || sender() == deal.userB, "Not a participant");

        // Возвращаем средства
        if (deal.amountA > 0) {
            send(SendParameters{
                to: deal.userA, value: deal.amountA, mode: SendPayGasSeparately, body: "Emergency Refund".asComment()
            });
        }

        if (deal.amountB > 0) {
            send(SendParameters{
                to: deal.userB, value: deal.amountB, mode: SendPayGasSeparately, body: "Emergency Refund".asComment()
            });
        }

        self.deals.set(msg.dealId, null);
    }

// 5. Забрать комиссии и закрыть контракт (Только Владелец)
    receive(msg: WithdrawFees) {
        require(sender() == self.owner, "Access denied");

        // SendRemainingBalance (128) + SendDestroyIfZero (32) = 160
        // Отправляем всё, что осталось на балансе, владельцу и удаляем аккаунт.
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance | SendDestroyIfZero,
            body: "Fees".asComment()
        });
    }

// Геттер для фронтенда (проверка статуса сделки)
    get fun deal(dealId: Int): DealData? {
        return self.deals.get(dealId);
    }
}