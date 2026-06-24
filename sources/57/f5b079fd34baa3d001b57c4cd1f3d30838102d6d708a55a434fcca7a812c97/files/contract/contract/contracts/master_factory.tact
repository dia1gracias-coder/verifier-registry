import "@stdlib/deploy";
import "./market.tact";
import "./oracle_pool.tact";

message CreateMarket {
    chat_id: Int as int64;
    dispute_id: Int as uint64;
    oracle_address: Address;
    oracle_pool_address: Address;
    deadline: Int as uint64;
}

message CreateOraclePool {
    chat_id: Int as int64;
    creator_wallet: Address;
    referrer: Address?;
    rate_bps: Int as uint16;
    signature: Slice; // 512-битная подпись от сервера платформы
}

message SetServiceWallet {
    new_service_wallet: Address;
}

message TransferFactoryOwnership {
    new_owner: Address;
}

message SetPlatformPublicKey {
    new_public_key: Int as uint256;
}

// Пользователь сам присылает билет на смену реферала (с подписью сервера)
message UserSetHubReferrer {
    pool_address: Address;
    referrer: Address;
    rate_bps: Int as uint16;
    signature: Slice; // Подпись сервера
}

contract MasterFactory with Deployable {
    owner: Address; 
    service_wallet: Address; 
    public_key: Int as uint256; // Публичный ключ сервера для проверки билетов
    nonce: Int as uint32;

    init(service_wallet: Address, public_key: Int, nonce: Int) {
        self.owner = sender(); 
        self.service_wallet = service_wallet;
        self.public_key = public_key;
        self.nonce = nonce;
    }

    receive(msg: CreateMarket) {
        let init: StateInit = initOf Market(
            myAddress(), 
            self.service_wallet, 
            msg.oracle_address, 
            msg.oracle_pool_address, 
            msg.deadline, 
            msg.dispute_id
        );
        
        send(SendParameters{
            to: contractAddress(init),
            value: 100000000, 
            mode: 1, 
            body: emptyCell(),
            code: init.code,
            data: init.data
        });
    }

    // Деплой пула оракулов с автоматической проверкой реферального билета
    receive(msg: CreateOraclePool) {
        // 1. Собираем ячейку данных для проверки подписи
        let data_builder: Builder = beginCell();
        data_builder = data_builder.storeInt(msg.chat_id, 64);
        data_builder = data_builder.storeAddress(msg.creator_wallet);
        if (msg.referrer != null) {
            data_builder = data_builder.storeBit(true).storeAddress(msg.referrer!!);
        } else {
            data_builder = data_builder.storeBit(false);
        }
        data_builder = data_builder.storeInt(msg.rate_bps, 16);
        let hash: Int = data_builder.endCell().hash();

        // 2. Криптографическая проверка подписи сервера
        require(checkSignature(hash, msg.signature, self.public_key), "Invalid server signature for deployment");

        // 3. Если всё ок - деплоим с уже прописанным рефералом
        let init: StateInit = initOf OraclePool(msg.chat_id, msg.creator_wallet, myAddress(), msg.referrer, msg.rate_bps);
        
        send(SendParameters{
            to: contractAddress(init),
            value: 100000000, 
            mode: 1, 
            body: emptyCell(),
            code: init.code,
            data: init.data
        });
    }

    // Смена реферала пользователем по билету от сервера (0 затрат газа для платформы)
    receive(msg: UserSetHubReferrer) {
        // 1. Собираем ячейку для проверки подписи смены реферала
        let data_builder: Builder = beginCell();
        data_builder = data_builder.storeAddress(msg.pool_address);
        data_builder = data_builder.storeAddress(msg.referrer);
        data_builder = data_builder.storeInt(msg.rate_bps, 16);
        let hash: Int = data_builder.endCell().hash();

        // 2. Проверяем подпись
        require(checkSignature(hash, msg.signature, self.public_key), "Invalid server signature for referrer change");

        // 3. Отправляем приказ на смену реферала в контракт пула
        send(SendParameters{
            to: msg.pool_address,
            value: 50000000, // 0.05 TON на газ
            mode: 1,
            body: SetReferrer{new_referrer: msg.referrer, rate_bps: msg.rate_bps}.toCell()
        });
    }

    receive(msg: SetServiceWallet) {
        require(sender() == self.owner, "Only owner can change service wallet");
        self.service_wallet = msg.new_service_wallet;
    }

    receive(msg: SetPlatformPublicKey) {
        require(sender() == self.owner, "Only owner can change platform public key");
        self.public_key = msg.new_public_key;
    }

    receive(msg: TransferFactoryOwnership) {
        require(sender() == self.owner, "Only owner can transfer factory ownership");
        self.owner = msg.new_owner;
    }

    get fun service_wallet(): Address { return self.service_wallet; }
    get fun owner(): Address { return self.owner; }
    get fun public_key(): Int { return self.public_key; }
}