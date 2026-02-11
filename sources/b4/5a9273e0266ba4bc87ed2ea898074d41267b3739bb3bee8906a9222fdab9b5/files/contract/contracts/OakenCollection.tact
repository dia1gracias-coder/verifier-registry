import "@stdlib/deploy";
import "./OakenItem.tact";

// --- Сообщения ---
message(0x4f6d4a01) Mint {
    queryId: Int as uint64;
}

// Админские функции
message(0x4f6d4a02) ChangeOwner { newOwner: Address; }
message(0x4f6d4a03) SetContent { content: Cell; }
message(0x4f6d4a04) SetBaseUrl { url: String; }
message(0x4f6d4a05) SetMintStatus { paused: Bool; }
message(0x4f6d4a06) Withdraw { amount: Int; }

// --- Структуры ---
struct CollectionData {
    next_index: Int;
    content: Cell;
    owner: Address;
}

struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}

// --- Константы ---
// Ставим 1 TON как минимальный порог входа. 
// Скрипт на сайте может присылать больше (5 или 10 TON), контракт это примет.
const MINT_PRICE: Int = 1000000000; 
const MIN_GAS: Int = 200000000;     // 0.2 TON (Поднял для безопасности транзакций)

contract OakenCollection with Deployable {
    owner: Address;
    next_index: Int as uint256;
    collection_content: Cell; 
    item_base_url: String;    
    paused: Bool;

    init(owner: Address, collection_content: Cell, item_base_url: String) {
        self.owner = owner;
        self.collection_content = collection_content;
        self.item_base_url = item_base_url;
        self.next_index = 0;
        self.paused = false;
    }

    // --- Minting Logic ---
    receive(msg: Mint) {
        let ctx: Context = context();
        require(self.paused == false, "Mint is paused");
        require(ctx.value >= MINT_PRICE + 150000000, "Not enough funds"); // Проверка минимума

        // 1. Считаем адрес будущего айтема
        let itemInit: StateInit = initOf OakenItem(self.next_index, myAddress());
        let itemAddress: Address = contractAddress(itemInit);

        // 2. Деплоим айтем (0.05 TON)
        send(SendParameters{
            to: itemAddress,
            value: 50000000, 
            bounce: false,
            mode: SendPayGasSeparately,
            body:  Deploy{ queryId: msg.queryId }.toCell(),
            code: itemInit.code,
            data: itemInit.data
        });

        // 3. Формируем имя файла
        let s: StringBuilder = beginString();
        s.append(self.next_index.toString());
        s.append(".json");

        // 4. Инициализируем айтем (0.05 TON)
        send(SendParameters{
            to: itemAddress,
            value: 50000000,
            bounce: true,
            mode: SendPayGasSeparately,
            body: InitItemOffchain{
                owner: ctx.sender,
                suffix: s.toString()
            }.toCell()
        });

        // 5. Отправляем ПРИБЫЛЬ Владельцу
        // ВАЖНО: Мы отправляем не фикс, а (Вся Сумма - Расходы). 
        // Так работает Bonding Curve: заплатили 5 TON -> ты получил ~4.8 TON.
        // Оставляем 0.15 TON в контракте на покрытие текущего газа и деплой айтемов.
        let profit: Int = ctx.value - 150000000;
        
        if (profit > 0) {
            send(SendParameters{
                to: self.owner,
                value: profit,
                mode: SendIgnoreErrors, // Чтобы не крашнулось, если сумма мала
                body: "Mint Profit".asComment()
            });
        }

        // 6. Увеличиваем счетчик
        self.next_index = self.next_index + 1;
        
        // Сдача пользователю тут не нужна, так как мы отправили весь остаток владельцу как прибыль.
        // Это упрощает логику и убирает ошибки с delivery.
    }

    // --- Admin functions ---
    
    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "Only owner");
        self.owner = msg.newOwner;
    }

    receive(msg: SetMintStatus) {
        require(sender() == self.owner, "Only owner");
        self.paused = msg.paused;
    }

    receive(msg: Withdraw) {
        require(sender() == self.owner, "Only owner");
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendPayGasSeparately
        });
    }

    receive(msg: SetBaseUrl) {
        require(sender() == self.owner, "Only owner");
        self.item_base_url = msg.url;
    }

    // --- Getters ---
    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_index: self.next_index,
            content: self.collection_content,
            owner: self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address {
        let init: StateInit = initOf OakenItem(item_index, myAddress());
        return contractAddress(init);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        b.append(self.item_base_url);
        b.append(individual_content.asSlice().asString());
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return RoyaltyParams{
            numerator: 5,
            denominator: 100, // 5%
            destination: self.owner
        };
    }
}