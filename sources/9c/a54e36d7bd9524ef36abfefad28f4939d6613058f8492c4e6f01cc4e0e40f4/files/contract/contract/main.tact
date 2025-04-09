import "@stdlib/deploy";

// Структура TokenDetails - точная копия из Solidity
struct TokenDetails {
    token: Address;      // address token
    supported: Bool;     // bool supported
    price: Int;         // uint256 price
    creator: Address;    // address creator
    name: String;       // string name
    symbol: String;     // string symbol
}

// Сообщения для основных операций
message(0x01) CreateICOSale {
    token: Address;
    price: Int;
}

message(0x02) BuyToken {
    token: Address;
    amount: Int;
}

message(0x03) WithdrawToken {
    token: Address;
    amount: Int;
}

message(0x04) TransferTON {
    to: Address;
    amount: Int as coins;
}

// Jetton Transfer Notification
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

// Jetton Wallet Data
message GetWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    walletCode: Cell;
}

contract ICOMarketplace with Deployable {
    owner: Address;                              // address public owner
    tokenDetails: map<Address, TokenDetails>;    // mapping(address => TokenDetails)
    allSupportedTokens: map<Int, Address>;      // address[] public allSupportedTokens
    tokensCount: Int as uint32;                 // Counter for tokens
    
    init() {
        self.owner = sender();
        self.tokensCount = 0;
    }

    // Отклоняем прямые переводы TON (аналог receive() в Solidity)
    receive() {
        require(false, "Contract does not accept TON directly");
    }

    // Создание ICO продажи (аналог createICOSale в Solidity)
    receive(msg: CreateICOSale) {
        // Проверяем что токен существует через Jetton API
        let walletData: GetWalletData = self.getJettonWalletData(msg.token);
        require(walletData.balance > 0, "Token does not exist");
        
        // Получаем информацию о токене
        let name: String = self.getJettonName(msg.token);
        let symbol: String = self.getJettonSymbol(msg.token);
        
        // Создаем новую запись
        self.tokenDetails.set(msg.token, TokenDetails{
            token: msg.token,
            supported: true,
            price: msg.price,
            creator: sender(),
            name: name,
            symbol: symbol
        });
        
        self.allSupportedTokens.set(self.tokensCount, msg.token);
        self.tokensCount = self.tokensCount + 1;
    }

    // Покупка токенов (аналог buyToken в Solidity)
    receive(msg: BuyToken) {
        require(msg.amount > 0, "Amount must be greater than 0");
        
        let details: TokenDetails = self.tokenDetails.get(msg.token)!!;
        require(details.supported, "Token not supported");
        
        // Вычисляем стоимость с проверкой переполнения
        let totalCost: Int = self.multiply(details.price, msg.amount);
        require(context().value >= totalCost, "Incorrect TON amount sent");
        
        // Отправляем TON создателю
        send(SendParameters{
            to: details.creator,
            value: totalCost,
            mode: SendRemainingValue
        });

        // Запрашиваем трансфер токенов
        self.requestJettonTransfer(msg.token, sender(), msg.amount);
    }

    // Вывод токенов (аналог withdrawToken в Solidity)
    receive(msg: WithdrawToken) {
        require(msg.amount > 0, "Amount must be greater than 0");
        
        let details: TokenDetails = self.tokenDetails.get(msg.token)!!;
        require(details.supported, "Token not supported");
        require(sender() == details.creator, "Not token creator");
        
        // Проверяем баланс
        let balance: Int = self.getJettonBalance(msg.token);
        require(balance >= msg.amount, "Insufficient token balance");
        
        // Запрашиваем трансфер токенов
        self.requestJettonTransfer(msg.token, sender(), msg.amount);
    }

    // Перевод TON (аналог transferEther в Solidity)
    receive(msg: TransferTON) {
        require(context().value >= msg.amount, "Insufficient funds sent");
        
        send(SendParameters{
            to: msg.to,
            value: msg.amount,
            mode: SendRemainingValue
        });
    }

    // Безопасное умножение (аналог multiply в Solidity)
    fun multiply(x: Int, y: Int): Int {
        require(y == 0 || (x * y) / y == x, "Multiplication overflow");
        return x * y;
    }

    // Функции для работы с Jetton
    fun getJettonWalletData(token: Address): GetWalletData {
        let body: Cell = beginCell()
            .storeUint(0x2c76b973, 32) // getWalletData
            .storeUint(0, 64)          // queryId
            .endCell();

        send(SendParameters{
            to: token,
            value: ton("0.1"),
            mode: SendRemainingValue,
            body: body
        });

        return GetWalletData{
            balance: 0,
            owner: myAddress(),
            master: token,
            walletCode: beginCell().endCell()
        };
    }

    fun getJettonSymbol(token: Address): String {
        let body: Cell = beginCell()
            .storeUint(0x2c76b973, 32) // getSymbol
            .storeUint(0, 64)          // queryId
            .endCell();

        send(SendParameters{
            to: token,
            value: ton("0.1"),
            mode: SendRemainingValue,
            body: body
        });

        return "";
    }

    fun getJettonName(token: Address): String {
        let body: Cell = beginCell()
            .storeUint(0x2c76b973, 32) // getName
            .storeUint(0, 64)          // queryId
            .endCell();

        send(SendParameters{
            to: token,
            value: ton("0.1"),
            mode: SendRemainingValue,
            body: body
        });

        return "";
    }

    fun getJettonBalance(token: Address): Int {
        let body: Cell = beginCell()
            .storeUint(0x2c76b973, 32) // getBalance
            .storeUint(0, 64)          // queryId
            .endCell();

        send(SendParameters{
            to: token,
            value: ton("0.1"),
            mode: SendRemainingValue,
            body: body
        });

        return 0;
    }

    fun requestJettonTransfer(token: Address, to: Address, amount: Int) {
        let body: Cell = beginCell()
            .storeUint(0xf8a7ea5, 32)  // transfer op
            .storeUint(0, 64)          // query id
            .storeCoins(amount)        // amount
            .storeAddress(to)          // destination
            .storeAddress(myAddress()) // response destination
            .storeUint(0, 1)          // custom payload flag
            .storeCoins(0)            // forward amount
            .storeUint(0, 1)          // forward payload flag
            .endCell();

        send(SendParameters{
            to: token,
            value: ton("0.1"),
            mode: SendRemainingValue,
            body: body
        });
    }

    // Геттеры - точные копии из Solidity
    get fun getBalance(token: Address): Int {
        require(self.tokenDetails.get(token)!!.supported, "Token not supported");
        return self.getJettonBalance(token);
    }
    
    get fun getSupportedTokens(): map<Int, Address> {
        return self.allSupportedTokens;
    }

    get fun getTokenDetails(token: Address): TokenDetails {
        require(self.tokenDetails.get(token)!!.supported, "Token not supported");
        return self.tokenDetails.get(token)!!;
    }

    get fun getTokensCreatedBy(creator: Address): map<Int, TokenDetails> {
        let result: map<Int, TokenDetails> = emptyMap();
        let resultCount: Int = 0;
        let i: Int = 0;
        
        while (i < self.tokensCount) {
            let token: Address = self.allSupportedTokens.get(i)!!;
            let details: TokenDetails = self.tokenDetails.get(token)!!;
            if (details.creator == creator) {
                result.set(resultCount, details);
                resultCount = resultCount + 1;
            }
            i = i + 1;
        }
        return result;
    }

    get fun getAllTokens(): map<Int, TokenDetails> {
        let result: map<Int, TokenDetails> = emptyMap();
        let i: Int = 0;
        
        while (i < self.tokensCount) {
            let token: Address = self.allSupportedTokens.get(i)!!;
            result.set(i, self.tokenDetails.get(token)!!);
            i = i + 1;
        }
        return result;
    }
} 