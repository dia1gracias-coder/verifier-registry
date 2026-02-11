import "@stdlib/deploy";

// Стандартные сообщения TEP-62
message(0x5fcc3d14) NFTTransfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseTo: Address?;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x2fcb26a2) GetStaticData { queryId: Int as uint64; }

message(0x8b771735) ReportStaticData {
    queryId: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

// Стандартное сообщение "Сдача" (Excesses)
message(0xd53276db) Excesses {
    queryId: Int as uint64;
}

// Сообщение для инициализации
message(0x6a1b3d10) InitItemOffchain {
    owner: Address;
    suffix: String; 
}

struct GetNftData {
    inited: Bool;
    index: Int;
    collection: Address;
    owner: Address;
    individual_content: Cell;
}

contract OakenItem {
    index: Int as uint256;
    collection: Address;
    owner: Address;
    suffix: String;
    is_initialized: Bool;

    init(index: Int, collection: Address) {
        self.index = index;
        self.collection = collection;
        self.owner = collection; 
        self.suffix = "";
        self.is_initialized = false;
    }

    receive(msg: InitItemOffchain) {
        require(sender() == self.collection, "Item: Access denied");
        require(!self.is_initialized, "Already initialized");

        self.owner = msg.owner;
        self.suffix = msg.suffix;
        self.is_initialized = true;
    }

    receive(msg: NFTTransfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        self.owner = msg.newOwner;

        if (msg.forwardAmount > 0) {
            send(SendParameters{
                to: msg.newOwner,
                value: msg.forwardAmount,
                mode: SendPayGasSeparately,
                body: msg.forwardPayload.asCell()
            });
        }

        // --- ИСПРАВЛЕНИЕ: Правильный возврат сдачи ---
        // Используем Excesses (0xd53276db), чтобы кошелек понимал, что операция завершена успешно
        if (msg.responseTo != null) {
            send(SendParameters{
                to: msg.responseTo!!,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: Excesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    receive(msg: GetStaticData) {
        let ctx: Context = context();
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            body: ReportStaticData{
                queryId: msg.queryId,
                index: self.index,
                collection: self.collection
            }.toCell()
        });
    }

    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        b.append(self.suffix);

        return GetNftData{
            inited: self.is_initialized,
            index: self.index,
            collection: self.collection,
            owner: self.owner,
            individual_content: b.toCell()
        };
    }
}