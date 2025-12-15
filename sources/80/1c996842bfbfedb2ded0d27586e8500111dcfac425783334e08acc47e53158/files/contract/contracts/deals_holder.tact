import "@stdlib/deploy";

// Если пришедшая сумма < 0.5 TON, то это считается активацией, и сдача возвращается.
const DEPLOY_THRESHOLD: Int = ton("0.5");
const DEAL_ADD_CANCEL_FEE: Int = ton("0.01"); // комиссия и газ за добавление, перевод
const DEPLOY_FEE: Int = ton("0.05"); // комиссия за деплой, делится между сделками

// --- СТРУКТТУРЫ ДАННЫХ ---

struct DealData {
    userA: Address;
    userB: Address;
    amountA: Int as coins;
    amountB: Int as coins;
}

// --- СООБЩЕНИЯ (COMMANDS) ---

// (Opcode 0x100)
message(0x100) AddDeal {
    dealId: Int as uint64;
    userA: Address;
    userB: Address;
    amountA: Int as coins;
    amountB: Int as coins;
}

// (Opcode 0x200)
message(0x200) Payout {
    dealId: Int as uint64;
    amountToPay: Int as coins;
    winner: Address;
}

// (Opcode 0x300)
message(0x300) CancelSingle {
    dealId: Int as uint64;
}

// (Opcode 0x400)
message(0x400) EmergencyClaim {
    dealId: Int as uint64;
}

// (Opcode 0x500)
message(0x500) WithdrawFees {
}

// --- ЛОГИКА КОНТРАКТА ---

// Opcode для сообщения DeactivateAndWithdraw
// const Opcodes = {
//     add_deal: 0x100, // Используется в вашем скрипте manage_match.ts
//     deactivate_and_withdraw: 0xdeadbeef // Уникальный Opcode для деактивации
//     };

// Сообщение, которое будет отправлено с кошелька owner
// (Opcode 0xdeadbeef)
message(0xdeadbeef) DeactivateAndWithdraw {}

contract MultiDeal with Deployable {

    owner: Address;
    startTime: Int as uint32;
    eventId: Int as uint64;
    deals: map<Int, DealData>;
    dealsCount: Int as uint32; // нельзя уменьшать! иначе при отмене последних сделок будет неправильно считаться комиссия

// Инициализация (Конструктор)
    init(owner: Address, eventId: Int, startTime: Int) {
        self.owner = owner;
        self.eventId = eventId;     // <-- СОХРАНЯЕМ ID СОБЫТИЯ
        self.startTime = startTime;
        self.dealsCount = 0;
    }

// Дефолтный прием средств (ТОЛЬКО ДЕПОЗИТ ОТ ВЛАДЕЛЬЦА)
    receive() {
        // Требуем, чтобы отправителем был только владелец
        require(sender() == self.owner, "Access denied: Owner only");

        let incomingValue: Int = context().value;

        // CASE 1: Активация/Деплой (например, 0.1 TON).
        // Если пришла небольшая сумма (< 0.5 TON), возвращаем всю сдачу.
        if (incomingValue < DEPLOY_THRESHOLD) {

            // Используем mode: 64, чтобы отправить обратно весь оставшийся баланс,
            // кроме минимального количества, необходимого для оплаты газа.
            // При этом мы не указываем конкретную сумму (value: 0),
            // что соответствует желанию "не оставлять минимальную сумму".
            send(SendParameters {
                to: sender(),
                value: 0, // Не указываем конкретную сумму
                mode: 64, // <-- ОТПРАВИТ ВСЮ СДАЧУ (оставит только газ)
                bounce: true
//                 body: "Activation change returned".asComment()
            });
            // На балансе останется только газ, необходимый для выполнения будущих транзакций.

        }
        // CASE 2: Полное Пополнение (сумма >= 0.5 TON).
        // Условие if не срабатывает, команда send() не вызывается, вся сумма (за вычетом газа) остается на контракте.
    }

// 1. Добавление сделки
    receive(msg: AddDeal) {
        // 1. Проверяем, что сделки с таким ID ещё нет
        require(msg.dealId > 0, "Invalid deal id");
        require(self.deals.get(msg.dealId) == null, "Deal already exists");

//         let requiredValue: Int = msg.amountA + msg.amountB;
//         require(context().value >= requiredValue, "Not enough funds sent");

        // 3. Записываем сделку
        self.deals.set(msg.dealId, DealData{
            userA: msg.userA,
            userB: msg.userB,
            amountA: msg.amountA,
            amountB: msg.amountB
        });

        self.dealsCount = self.dealsCount + 1; // <-- УВЕЛИЧИВАЕМ СЧЕТЧИК
    }


// 2. Выплата выигрыша (Только Владелец)
    receive(msg: Payout) {
        require(sender() == self.owner, "Access denied: Owner only");

        // 1. Проверяем, что сделка существует, чтобы дважды не выплатить
        let dealOpt = self.deals.get(msg.dealId);
        require(dealOpt != null, "Deal not found");

        let deal: DealData = dealOpt!!;

        // 2. Проверяем, что победитель — один из участников
        require(
        msg.winner == deal.userA || msg.winner == deal.userB,
        "Winner must be userA or userB"
        );

        let DEPLOY_DEAL_FEE: Int = DEPLOY_FEE / self.dealsCount;
        let fee: Int = DEAL_ADD_CANCEL_FEE + DEPLOY_DEAL_FEE;

        let sb: StringBuilder = beginString();
        sb.append("Payout for deal #");
        sb.append(msg.dealId.toString());
        sb.append(", fee ");
        sb.append(fee.toCoinsString());

        let sendAmount: Int = msg.amountToPay - fee;

        // 3. Выплата
        send(SendParameters{
            to: msg.winner,
            value: sendAmount,      // сумма выигрыша с вычетом комиссии
            mode: SendDefaultMode,
            bounce: false,
            body: sb.toString().asComment()
        });

        // 4. Удаляем данные сделки — дешевле чем set(..., null)
        self.deals.del(msg.dealId);
    }


// 3. Отмена одной сделки (Только Владелец)
    receive(msg: CancelSingle) {
        require(sender() == self.owner, "Access denied: Owner only");
        require(self.dealsCount > 0, "Deals count should be > 0");

        let dealOpt = self.deals.get(msg.dealId);
        require(dealOpt != null, "Deal not found"); // <-- ДОБАВЛЕНА ПРОВЕРКА
        let deal: DealData = dealOpt!!;

        let DEPLOY_DEAL_FEE: Int = DEPLOY_FEE / self.dealsCount;

        let sbA: StringBuilder = beginString();
        sbA.append("Refund deal #");
        sbA.append(msg.dealId.toString());
        sbA.append(", fee ");

        let sbB: StringBuilder = beginString();
        sbB.append("Refund deal #");
        sbB.append(msg.dealId.toString());
        sbB.append(", fee ");

        let totalAmount: Int = deal.amountA + deal.amountB;

        if (totalAmount > 0) {
            // Считаем долю комиссии пропорционально вкладу
            // Пример: A=1, B=2. Total=3. Fee=0.01.
            // FeeA = (0.01 * 1) / 3 = 0.0033
            let feeA: Int = ((DEAL_ADD_CANCEL_FEE + DEPLOY_DEAL_FEE) * deal.amountA) / totalAmount;
            let feeB: Int = (DEAL_ADD_CANCEL_FEE + DEPLOY_DEAL_FEE) - feeA; // Остаток комиссии берет B

            // Вычитаем комиссию из возврата
            let sendA: Int = deal.amountA - feeA;
            let sendB: Int = deal.amountB - feeB;

            sbA.append(feeA.toCoinsString());
            sbB.append(feeB.toCoinsString());

            if (sendA > 0) {
                send(SendParameters{
                    to: deal.userA,
                    value: sendA,
                    mode: SendDefaultMode,
                    bounce: false,
                    body: sbA.toString().asComment()
                });
            }

            if (sendB > 0) {
                send(SendParameters{
                    to: deal.userB,
                    value: sendB,
                    mode: SendDefaultMode,
                    bounce: false,
                    body: sbB.toString().asComment()
                });
            }
        }


        self.deals.del(msg.dealId);

        if (self.deals.isEmpty()){
            send(SendParameters {
                to: self.owner,
                value: 0,
                mode: 160,
                body: "Deals processed, contract deactivated".asComment()
            });
        }
    }

// 4. Экстренный вывод (Любой участник, если прошло 3 дня)
    receive(msg: EmergencyClaim) {
        require(now() > (self.startTime + 259200), "Too early for emergency claim"); // 3 дня
        let deal: DealData = self.deals.get(msg.dealId)!!;
        require(sender() == deal.userA || sender() == deal.userB, "Not a participant");

        if (deal.amountA > 0) {
            send(SendParameters{ to: deal.userA, value: deal.amountA, mode: SendPayGasSeparately, body: "Emergency Refund".asComment() });
        }
        if (deal.amountB > 0) {
            send(SendParameters{ to: deal.userB, value: deal.amountB, mode: SendPayGasSeparately, body: "Emergency Refund".asComment() });
        }
        self.deals.set(msg.dealId, null);
    }

// 5. Забрать комиссии (Только Владелец)
    receive(msg: WithdrawFees) {
        require(sender() == self.owner, "Access denied: Owner only");
        send(SendParameters{ to: self.owner, value: 0, mode: SendRemainingBalance | SendDestroyIfZero, body: "Fees".asComment() });
    }

// НОВЫЙ МЕТОД: Возврат всех средств и деактивация контракта
// Только для Owner
    receive(msg: DeactivateAndWithdraw) {
        // 1. Проверка, что отправитель - Owner
        require(context().sender == self.owner, "Only owner can deactivate.");

        // 2. Отправка всех средств на адрес owner и уничтожение контракта
        // mode: 128 - SendRemainingValue (отправить все, что осталось, и уничтожить контракт)
        send(SendParameters {
            to: self.owner,
            value: 0,
            mode: 160,
            body: "Event processed, contract Deactivated".asComment()
        });
    }

// Геттер для фронтенда
    get fun deal(dealId: Int): DealData? {
        return self.deals.get(dealId);
    }

    get fun count(): Int {
        return self.dealsCount;
    }
}