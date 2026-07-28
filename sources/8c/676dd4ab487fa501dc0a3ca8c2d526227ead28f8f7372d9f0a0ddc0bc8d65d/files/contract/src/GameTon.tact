import "@stdlib/deploy";
import "@stdlib/ownable";
// oraclePubkey і serviceAddress винесені в src/params.tact — генеруються з
// contract/.env.<network> перед білдом (npm run build:testnet / build:mainnet).
import "./params";
/// @notice Повідомлення для купівлі квитків
message(0x10) TicketTransfer {
    ticketCount: Int as int32; // Кількість квитків
    prices: Slice; // Ціни для кожного квитка (по 32 біти на квиток)
}
/// @notice Повідомлення для фіналізації гри (з підписом оракула)
message(0x20) FinalizeGameSigned {
    price: Int as coins; // Фінальна ціна
    timestamp: Int as uint64; // Час фіналізації
    signature: Slice; // Підпис оракула
}
/// @notice Повідомлення для клейму нагороди
message(0x03) Claim {
}
/// @notice Структура квитка
struct Ticket {
    price: Int as coins; // Ціна, яку вказав гравець
    timestamp: Int as int64; // Час купівлі квитка
    wallet: Address; // Адреса гравця
}
/// @notice Конфігурація гри (для view)
struct GameConfig {
    endTime: Int as int32;
    ticketDeadline: Int as int64;
    ticketAmount: Int as int64;
    authorPercent: Int as int8;
    owner: Address;
    beneficiary: Address;
    winner: Address?; // Переможець (якщо визначено)
    winningPrice: Int as int32;
    isFinished: Bool;
    isClaimed: Bool;
    gameId: Int as uint64;
    gameName: String;
}
/// @notice Розподіл винагороди
struct GameDistribution {
    player: Int as int64; // Виграш гравця
    author: Int as int64; // Винагорода автора
    service: Int as int64; // Винагорода сервісу
}
/// @notice Повний облік банку (для on-chain читання банку та часток)
struct GameAccounting {
    total: Int as coins;
    player: Int as coins;
    author: Int as coins;
    service: Int as coins;
}

/// @notice Хешування квитка для унікальності
inline fun hash(addr: Address, timestamp: Int, index: Int): Int {
    return beginCell().storeAddress(addr).storeInt(timestamp, 64).storeInt(index, 32).endCell().hash();
}

inline fun priceExists(priceToCheck: Int, tickets: map<Int, Ticket>): Bool {
    foreach (key, ticket in tickets) {
        if (ticket.price == priceToCheck) {
            return true;
        }
    }
    return false;
}

/// @title GameTon — контракт гри з купівлею квитків, фіналізацією та клеймом

contract GameTon with Ownable {
    endTime: Int as int64; // Час завершення гри
    ticketDeadline: Int as int64; // Дедлайн купівлі квитків
    ticketAmount: Int as int64; // Вартість одного квитка
    authorPercent: Int as int8; // Відсоток автору
    owner: Address; // Автор гри
    gameId: Int as uint64; // Ідентифікатор гри (для коментарів/звітів)
    gameName: String; // Коротка назва гри

    tickets: map<Int, Ticket> = emptyMap(); // Всі квитки
    winner: Address? = null; // Переможець
    winningPrice: Int as int32 = 0; // Виграшна ціна
    isFinished: Bool = false; // Чи завершено гру
    isClaimed: Bool = false; // Чи вже клеймлено
    staked: Int as coins = 0; // Сума всіх ставок гравців (для обліку призу)

    /// @notice Ініціалізація контракту
    init(owner: Address,
        endTime: Int,
        ticketDeadline: Int,
        ticketAmount: Int,
        authorPercent: Int,
        gameId: Int,
        gameName: String){
        require(ticketDeadline < endTime, "DEADLINE_AFTER_END"); // exit code 9041
        require(authorPercent >= 1 && authorPercent <= 30, "INVALID_PERCENT"); // exit code 17488
        require(endTime > now(), "ENDTIME_MUST_BE_IN_FUTURE"); // exit code 48156

        self.owner = owner;
        self.endTime = endTime;
        self.ticketDeadline = ticketDeadline;
        self.ticketAmount = ticketAmount;
        self.authorPercent = authorPercent;
        self.gameId = gameId;
        self.gameName = gameName;
    }

    receive(){
        // Повертаємо кошти назад відправнику
        // let ctx: Context = context();
        // if (ctx.value > 0) {
        //     send(SendParameters{to: ctx.sender, value: 0, mode: SendRemainingBalance, body: "Refund".asComment()});
        // }
    }

    /// @notice Купівля квитків
    /// @dev Кожен квиток має свою ціну, всі квитки записуються у map
    receive(msg: TicketTransfer){
        require(msg.ticketCount > 0 && msg.ticketCount <= 8, "MAX_TICKETS_EXCEEDED"); // exit code 54531
        require(now() < self.ticketDeadline, "TICKETS_CLOSED"); // exit code 24126

        let expectedAmount: Int = self.ticketAmount * msg.ticketCount;
        require(context().value == expectedAmount, "INVALID_TON_AMOUNT"); // exit code 14504

        self.staked += context().value; // Накопичуємо суму ставок гравців

        let slice: Slice = msg.prices;
        let sender: Address = sender();
        let timestamp: Int = now();
        let i: Int = 0;
        do
            {
                let price: Int = slice.loadInt(32);
                require(!priceExists(price, self.tickets), "PRICE_ALREADY_USED"); // exit code 8990
                let ticket = Ticket{price, timestamp, wallet: sender};
                let key: Int = hash(sender, timestamp, price);
                self.tickets.set(key, ticket);
                i += 1;
            }
        until (i >= msg.ticketCount);
    }

    /// @notice Фіналізація гри (тільки з валідним підписом оракула)
    /// @dev Визначає переможця, зберігає його адресу та виграшну ціну
    receive(msg: FinalizeGameSigned){
        require(now() > self.endTime, "GAME_NOT_FINISHED"); // exit code 37565
        require(!self.isFinished, "ALREADY_FINALIZED"); // exit code 20720
        require(msg.timestamp == self.endTime, "INVALID_TIMESTAMP"); // exit code 13949

        let data: Slice = beginCell().storeUint(msg.timestamp, 64).storeInt(msg.price, 32).asSlice();
        let isValid: Bool = checkDataSignature(data, msg.signature, oraclePubkey);
        require(isValid, "INVALID_SIGNATURE"); // exit code 45972
        self.finalizeGameInternal(msg.price, msg.timestamp);
        // Повертаємо невикористаний газ тригеру з коментарем (winningPrice вже встановлено)
        send(SendParameters{ to: sender(), value: 0, mode: SendRemainingValue | SendIgnoreErrors, bounce: false, body: self.finalizeRefundComment().asComment() });
    }

    /// @notice Клейм нагороди (може зробити переможець, owner або serviceAddress)
    /// @dev Виплачує винагороду переможцю, автору та сервісу
    receive(msg: Claim){
        require(!self.isClaimed, "ALREADY_CLAIMED"); // exit code 16036
        require(self.winner != null, "NO_WINNER"); // exit code 50453
        require(self.isFinished, "NOT_FINISHED"); // exit code 57109

        let senderAddr: Address = sender();
        let winner: Address = self.winner!!;
        let owner: Address = self.owner;
        // Дозволяємо клеймити переможцю, owner або serviceAddress
        require(senderAddr == winner || senderAddr == self.owner || senderAddr == serviceAddress, "UNAUTHORIZED"); // exit code 46955

        let reserve: Int = ton("0.02"); // на ренту + forward-fee; лишається в контракті
        let incoming: Int = context().value;
        let bankBal: Int = myBalance() - incoming;            // банк БЕЗ платежу тригера
        let distributable: Int = bankBal > reserve ? (bankBal - reserve) : 0;
        let pot: Int = min(self.staked, distributable);
        let leftover: Int = distributable - pot;
        let dist: GameDistribution = self.distribution(pot);

        send(SendParameters{
                to: winner,
                value: dist.player,
                mode: SendPayFwdFeesSeparately,
                bounce: false,
                body: self.payoutComment("winner prize").asComment()
            }
        );
        send(SendParameters{
                to: beneficiaryAddress,
                value: dist.service,
                mode: SendPayFwdFeesSeparately,
                bounce: false,
                body: self.payoutComment("service fee").asComment()
            }
        );
        send(SendParameters{
                to: owner,
                value: dist.author + leftover,
                mode: SendPayFwdFeesSeparately,
                bounce: false,
                body: self.payoutComment("author + leftover").asComment()
            }
        );
        // Повертаємо невикористаний газ тригеру з коментарем (рефанд не з банку, а з incoming)
        send(SendParameters{ to: sender(), value: 0, mode: SendRemainingValue | SendIgnoreErrors, bounce: false, body: self.payoutComment("claim gas refund").asComment() });
        self.isClaimed = true;
    }

    inline fun finalizeGameInternal(finalPrice: Int, finalTimestamp: Int) {
        let bestDiff: Int = 9999999999999999999999;
        let bestPrice: Int = 0;
        let bestAddr: Address? = null;
        foreach (key, ticket in self.tickets) {
            let diff: Int = abs(finalPrice - ticket.price);
            if (diff < bestDiff) {
                bestDiff = diff;
                bestPrice = ticket.price;
                bestAddr = ticket.wallet;
            }
        }
        require(bestAddr != null, "NO_TICKETS"); // exit code 6753

        self.winner = bestAddr;
        self.winningPrice = bestPrice;
        self.isFinished = true;
    }

    /// @notice Коментар виплати з роллю отримувача та номером гри (англійською)
    fun payoutComment(role: String): String {
        let sb: StringBuilder = beginString();
        sb.append("TTTM #");
        sb.append(self.gameId.toString());
        sb.append(" ");
        sb.append(self.gameName);
        sb.append(": ");
        sb.append(role);
        return sb.toString();
    }

    /// @notice Коментар finalize-рефанду тригеру з виграшною ціною
    fun finalizeRefundComment(): String {
        let sb: StringBuilder = beginString();
        sb.append("TTTM #");
        sb.append(self.gameId.toString());
        sb.append(" ");
        sb.append(self.gameName);
        sb.append(": finalize refund, winning price ");
        sb.append(self.winningPrice.toString());
        return sb.toString();
    }

    /// @notice Повертає конфігурацію гри

    get fun config(): GameConfig {
        return
            GameConfig{
                endTime: self.endTime,
                ticketDeadline: self.ticketDeadline,
                ticketAmount: self.ticketAmount,
                authorPercent: self.authorPercent,
                owner: self.owner,
                beneficiary: beneficiaryAddress,
                winner: self.winner,
                winningPrice: self.winningPrice,
                isFinished: self.isFinished,
                isClaimed: self.isClaimed,
                gameId: self.gameId,
                gameName: self.gameName
            };
    }

    /// @notice Повертає розподіл винагороди для заданої суми

    get fun distribution(total: Int): GameDistribution {
        let authorRaw: Int = (total * self.authorPercent) / 100;
        let serviceCut: Int = (authorRaw * 20) / 100;
        let authorNet: Int = authorRaw - serviceCut;
        let playerShare: Int = total - authorRaw;
        return GameDistribution{player: playerShare, author: authorNet, service: serviceCut};
    }

    /// @notice Реальний банк (баланс − reserve) і його розподіл — on-chain істина для UI/бекенду

    get fun distributable(): GameAccounting {
        let reserve: Int = ton("0.02");
        let bal: Int = myBalance();
        let d: Int = bal > reserve ? (bal - reserve) : 0;
        let pot: Int = self.staked < d ? self.staked : d;
        let leftover: Int = d - pot;
        let dist: GameDistribution = self.distribution(pot);
        return GameAccounting{
            total: pot,
            player: dist.player,
            author: dist.author + leftover,
            service: dist.service
        };
    }

    /// @notice Баланс контракту

    get fun balance(): Int {
        return myBalance();
    }

    /// @notice Всі квитки (map)

    get fun ticketsFlat(): map<Int, Ticket> {
        return self.tickets;
    }
}
