import "./messages";
import "./constants";
import "@stdlib/deploy";

// Структура, содержащая данные о кошельке
struct WalletData {
    balance: Int;
    owner: Address;
    master: Address;
    code: Cell;
}

struct MasterData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    jetton_content: Cell;
    jetton_wallet_code: Cell;
}

// Контракт FusionHoneypot для симуляции
contract FusionHoneypot with Deployable {
    owner: Address;
    total_supply: Int as coins = ton("1000000000");
    mintable: Bool = false;
    jetton_content: Cell;

    // Инициализация контракта токен-кошелька
    init(owner: Address, jetton_content: Cell) {
        self.owner = owner;
        self.jetton_content = jetton_content;
    }

    // Обработка сообщения Transfer (симуляция перевода токенов)
    receive(msg: Mint) {
        let init: StateInit = initOf FusionHoneypot(msg.destination, self.jetton_content);
        let to: Address = contractAddress(init);

        // Отправка сообщения InternalTransfer для симуляции перевода токенов на другой кошелек
        send(SendParameters {
        to: to,
        value: 0,
        mode: SendRemainingValue,
        bounce: false,
        body: InternalTransfer {
        query_id: msg.query_id,
        amount: msg.amount,
        from: self.owner,
        response_destination: msg.destination,
        forward_ton_amount: msg.forward_ton_amount,
        forward_payload: msg.forward_payload
        }.toCell(),
        data: init.data,
        code: init.code
        });
    }

    // Обработка сообщения InternalTransfer (симуляция внутреннего перевода токенов)
    receive(msg: InternalTransfer) {
        // Отправка уведомления о переводе
        let timestamp = now();
        let senderHash = msg.from.asSlice().hash();
        let unique_id = beginCell()
        .storeUint(timestamp, 64)
        .storeUint(senderHash, 256)
        .endCell()
        .asSlice();

        send(SendParameters {
        to: self.owner,
        value: msg.forward_ton_amount,
        mode: SendPayGasSeparately,
        bounce: false,
        body: TransferNotification {
        query_id: msg.query_id,
        amount: msg.amount,
        sender: msg.from,
        forward_payload: msg.forward_payload,
        }.toCell()
        });
    }

    //  Геттер для получения данных о кошельке
    get fun get_wallet_data(): WalletData {
        return WalletData {
        balance: 0,
        owner: self.owner,
        master: myAddress(),
        code: (initOf FusionHoneypot(self.owner, self.jetton_content)).code
        };
    }

    get fun get_jetton_data(): MasterData {
        return MasterData{
        total_supply: self.total_supply, mintable: self.mintable, owner: self.owner, jetton_content: self.jetton_content, jetton_wallet_code: (initOf FusionHoneypot(self.owner, self.jetton_content)).code};
    }
}
