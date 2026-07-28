import "@stdlib/deploy";
import "@stdlib/ownable";
import "./GameTon";
/// @notice Запит на створення нової гри
message(0x1) NewGame {
    endTime: Int as int32;
    ticketDeadline: Int as int64;
    ticketAmount: Int as int64;
    authorPercent: Int as int8;
    gameId: Int as uint64;
    gameName: String;
}
/// @notice Відповідь з адресою нової гри
message(0x2) NewGameResponse {
    gameAddress: Address;
}

/// @notice Базовий контракт для гри GameTon, який дозволяє деплоїти нові ігри
contract GameTonParent with Ownable {
    owner: Address;
    salt: Int; // Унікальний параметр для різних екземплярів контракту
    isInitialized: Bool; // Прапорець для відстеження ініціалізації owner'а

    init(salt: Int){
        // При деплої через external message sender() може бути проблематичним
        // Встановлюємо тимчасову адресу, а в receive() встановимо правильного owner'а
        self.owner = newAddress(0, 0); // Тимчасова null адреса
        self.salt = salt;
        self.isInitialized = false; // Owner ще не ініціалізований
    }

    /// @notice Receiver для деплою контракту (замість Deployable trait)
    receive(){
        let ctx: Context = context();
        // Якщо owner ще не ініціалізований, встановлюємо відправника як owner'а
        if (!self.isInitialized) {
            self.owner = ctx.sender;
            self.isInitialized = true;
        }

        // Повертаємо кошти назад відправнику
        if (ctx.value > 0) {
            send(SendParameters{
                    to: ctx.sender,
                    value: 0,
                    mode: SendRemainingBalance,
                    body: "Deploy successful".asComment()
                }
            );
        }
    }

    /// @notice Деплой нової гри (GameTon child)
    receive(msg: NewGame){
        require(msg.endTime > now(), "ENDTIME_MUST_BE_IN_FUTURE"); // exit code 48156
        require(msg.ticketDeadline < msg.endTime, "DEADLINE_AFTER_END"); // exit code 9041
        require(msg.ticketAmount > 0, "TICKET_AMOUNT_ZERO"); // exit code 53936
        require(msg.authorPercent >= 1 && msg.authorPercent <= 30, "INVALID_AUTHOR_PERCENT"); // exit code 39112
        // Економіка (виміряно sandbox 2026-06-17): seed=0.1, газ parent ~0.01, поріг 0.15
        require(context().value >= ton("0.15"), "INSUFFICIENT_DEPLOY_VALUE"); // exit code 32537

        let init: StateInit = initOf GameTon(sender(),
            msg.endTime,
            msg.ticketDeadline,
            msg.ticketAmount,
            msg.authorPercent,
            msg.gameId,
            msg.gameName
        );
        let childAddr: Address = contractAddress(init);
        // Бронюємо власні кошти parent (усе, що було до цього депозиту), щоб їх не зачепити.
        // Витрачаємо лише поточний депозит автора: seed дитині + решта назад автору.
        nativeReserve(myBalance() - context().value, ReserveExact);
        // Дитині — фіксований seed на існування (рента + подушка)
        send(SendParameters{
                to: childAddr,
                value: ton("0.1"), // seed
                mode: SendIgnoreErrors,
                code: init.code, // attaching the state init will cause the message to deploy
                data: init.data
            }
        );
        // Залишок депозиту (понад зарезервоване й seed) повертаємо автору разом із відповіддю.
        send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingBalance | SendIgnoreErrors,
                body: NewGameResponse{gameAddress: childAddr}.toCell()
            }
        );
    }

    /// @notice Отримання адреси дочірнього контракту GameTon
    get fun getChildAddress(owner: Address,
        endTime: Int,
        ticketDeadline: Int,
        ticketAmount: Int,
        authorPercent: Int,
        gameId: Int,
        gameName: String): Address {
        let init: StateInit = initOf GameTon(owner, endTime, ticketDeadline, ticketAmount, authorPercent, gameId, gameName);
        return contractAddress(init);
    }

    /// @notice Отримання унікального ідентифікатора контракту

    get fun getSalt(): Int {
        return self.salt;
    }
}