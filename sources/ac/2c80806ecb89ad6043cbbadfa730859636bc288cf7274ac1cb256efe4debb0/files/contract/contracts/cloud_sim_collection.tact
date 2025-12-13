// ========================================
// NFT ITEM
// ========================================

// TEP-62 tarzı get_nft_data için struct
struct NftData {
    init: Int;         // 0 veya 1 (bizde hep 1, deploy olmuş NFT)
    index: Int;
    collection: Address;
    owner: Address;
    content: Cell;
}

contract CloudSimNft {
    index: Int;
    collection: Address;
    owner: Address;
    content: Cell;

    init(index: Int, collection: Address, owner: Address, content: Cell) {
        self.index = index;
        self.collection = collection;
        self.owner = owner;
        self.content = content;
    }

    // Basit getter'lar
    get fun get_owner(): Address { return self.owner; }
    get fun get_index(): Int { return self.index; }
    get fun get_content(): Cell { return self.content; }

    // TEP-62 uyumlu get_nft_data (struct tek değer döndürüyor)
    get fun get_nft_data(): NftData {
        return NftData{
            init: 1,
            index: self.index,
            collection: self.collection,
            owner: self.owner,
            content: self.content
        };
    }
}

// ========================================
// BASE URI'yi CELL ASCII OLARAK YAZAN FONKSİYON
// https://raw.githubusercontent.com/SamedBrll/cloudsim-metadata/refs/heads/main/
// ========================================
fun buildBaseUri(): Cell {
    let b = beginCell();

    // "https://"
    b.storeUint(104, 8); // h
    b.storeUint(116, 8); // t
    b.storeUint(116, 8); // t
    b.storeUint(112, 8); // p
    b.storeUint(115, 8); // s
    b.storeUint(58, 8);  // :
    b.storeUint(47, 8);  // /
    b.storeUint(47, 8);  // /

    // "raw"
    b.storeUint(114, 8); // r
    b.storeUint(97, 8);  // a
    b.storeUint(119, 8); // w

    // ".githubusercontent"
    b.storeUint(46, 8);  // .
    b.storeUint(103, 8); // g
    b.storeUint(105, 8); // i
    b.storeUint(116, 8); // t
    b.storeUint(104, 8); // h
    b.storeUint(117, 8); // u
    b.storeUint(98, 8);  // b
    b.storeUint(117, 8); // u
    b.storeUint(115, 8); // s
    b.storeUint(101, 8); // e
    b.storeUint(114, 8); // r
    b.storeUint(99, 8);  // c
    b.storeUint(111, 8); // o
    b.storeUint(110, 8); // n
    b.storeUint(116, 8); // t
    b.storeUint(101, 8); // e
    b.storeUint(110, 8); // n
    b.storeUint(116, 8); // t

    // ".com"
    b.storeUint(46, 8);  // .
    b.storeUint(99, 8);  // c
    b.storeUint(111, 8); // o
    b.storeUint(109, 8); // m

    // "/SamedBrll"
    b.storeUint(47, 8);  // /
    b.storeUint(83, 8);  // S
    b.storeUint(97, 8);  // a
    b.storeUint(109, 8); // m
    b.storeUint(101, 8); // e
    b.storeUint(100, 8); // d
    b.storeUint(66, 8);  // B
    b.storeUint(114, 8); // r
    b.storeUint(108, 8); // l
    b.storeUint(108, 8); // l

    // "/cloudsim-metadata"
    b.storeUint(47, 8);  // /
    b.storeUint(99, 8);  // c
    b.storeUint(108, 8); // l
    b.storeUint(111, 8); // o
    b.storeUint(117, 8); // u
    b.storeUint(100, 8); // d
    b.storeUint(115, 8); // s
    b.storeUint(105, 8); // i
    b.storeUint(109, 8); // m
    b.storeUint(45, 8);  // -
    b.storeUint(109, 8); // m
    b.storeUint(101, 8); // e
    b.storeUint(116, 8); // t
    b.storeUint(97, 8);  // a
    b.storeUint(100, 8); // d
    b.storeUint(97, 8);  // a

    // "/refs/heads/main/"
    b.storeUint(47, 8);  // /
    b.storeUint(114, 8); // r
    b.storeUint(101, 8); // e
    b.storeUint(102, 8); // f
    b.storeUint(115, 8); // s
    b.storeUint(47, 8);  // /
    b.storeUint(104, 8); // h
    b.storeUint(101, 8); // e
    b.storeUint(97, 8);  // a
    b.storeUint(100, 8); // d
    b.storeUint(115, 8); // s
    b.storeUint(47, 8);  // /
    b.storeUint(109, 8); // m
    b.storeUint(97, 8);  // a
    b.storeUint(105, 8); // i
    b.storeUint(110, 8); // n
    b.storeUint(47, 8);  // /

    return b.endCell();
}

// ========================================
// COLLECTION DATA struct (TEP-62 get_collection_data için)
// ========================================
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}

// ========================================
// COLLECTION
// ========================================
contract CloudSimCollection {

    owner: Address;
    maxSupply: Int;
    mintPrice: Int;
    nextIndex: Int;
    baseUri: Cell;

    
    // OPCODE'lar
    const OP_MINT: Int = 1;
    const OP_SET_MINT_PRICE: Int = 2;
    const OP_WITHDRAW: Int = 3;
    const OP_MINT_EVENT: Int = 4;

    init(owner: Address) {
        self.owner = owner;
        self.maxSupply = 10000;
        // Test için 0.2 TON (mainnette 7 TON vs yaparsın)
        self.mintPrice = 300_000_000; // 0.2 TON
        // ID'ler: 0..9999 → 000000.json..009999.json
        self.nextIndex = 0;

        self.baseUri = buildBaseUri();
    }

    fun digitAscii(d: Int): Int {
        return 48 + d; // '0' + d
    }

    // 6 haneli dosya adı + ".json"
    fun buildFileName(i: Int): Cell {
        let b = beginCell();

        // 6 haneli sayı (000000–009999)
        b.storeUint(self.digitAscii((i / 100000) % 10), 8);
        b.storeUint(self.digitAscii((i / 10000) % 10), 8);
        b.storeUint(self.digitAscii((i / 1000) % 10), 8);
        b.storeUint(self.digitAscii((i / 100) % 10), 8);
        b.storeUint(self.digitAscii((i / 10) % 10), 8);
        b.storeUint(self.digitAscii((i / 1) % 10), 8);

        // ".json"
        b.storeUint(46, 8);  // .
        b.storeUint(106, 8); // j
        b.storeUint(115, 8); // s
        b.storeUint(111, 8); // o
        b.storeUint(110, 8); // n

        return b.endCell();
    }

    // Sadece collection için "collection.json" üretelim
    fun buildCollectionFileName(): Cell {
        let b = beginCell();

        // "collection.json"
        b.storeUint(99, 8);  // c
        b.storeUint(111, 8); // o
        b.storeUint(108, 8); // l
        b.storeUint(108, 8); // l
        b.storeUint(101, 8); // e
        b.storeUint(99, 8);  // c
        b.storeUint(116, 8); // t
        b.storeUint(105, 8); // i
        b.storeUint(111, 8); // o
        b.storeUint(110, 8); // n

        b.storeUint(46, 8);  // .
        b.storeUint(106, 8); // j
        b.storeUint(115, 8); // s
        b.storeUint(111, 8); // o
        b.storeUint(110, 8); // n

        return b.endCell();
    }

    // NFT item content: ref0 = baseUri, ref1 = fileName
    fun buildContent(i: Int): Cell {
        let b = beginCell();

        b.storeRef(self.baseUri);           // base uri
        b.storeRef(self.buildFileName(i));  // filename

        return b.endCell();
    }

    // ===============================
    // TEP-62: get_collection_data
    // next_item_index, collection_content, owner_address
    // ===============================
    get fun get_collection_data(): CollectionData {
        // collection_content = baseUri + "collection.json"
        let b = beginCell();
        b.storeRef(self.baseUri);
        b.storeRef(self.buildCollectionFileName());
        let collectionContent = b.endCell();

        return CollectionData{
            next_item_index: self.nextIndex,
            collection_content: collectionContent,
            owner_address: self.owner
        };
    }

    // ===============================
    // MINT / ADMIN LOGIC – OPCODE ile
    // ===============================
    receive() {
        let ctx: Context = context();
        let body: Slice = inMsg();

        // Body tamamen boşsa → ignore
        if (body.bits() == 0 && body.refs() == 0) {
            return;
        }

        // İlk 32 bit opcode
        if (body.bits() < 32) {
            return;
        }
        let opcode = body.loadUint(32);

        // ---------------------------
        // MINT
        // ---------------------------
        if (opcode == self.OP_MINT) {
            // Gönderilen TON mintPrice'dan azsa mint yok
            if (ctx.value < self.mintPrice) {
                return;
            }

            // Supply dolmuşsa mint yok
            if (self.nextIndex >= self.maxSupply) {
                return;
            }

            // ID: 0..9999 (JSON dosya isimleriyle uyumlu)
            let id = self.nextIndex;
            self.nextIndex += 1;

            let metadata = self.buildContent(id);

            let initState: StateInit = initOf CloudSimNft(
                id,
                myAddress(),
                ctx.sender,
                metadata
            );

            let nftAddr = contractAddress(initState);

            // NFT item'ı deploy et
            send(SendParameters{
                to: nftAddr,
                value: 300_000_000,
                bounce: false,
                mode: 1,
                code: initState.code,
                data: initState.data,
                body: null
            });





            // Mint event log → owner'a 0-valued internal msg
            let eb = beginCell();
            eb.storeUint(self.OP_MINT_EVENT, 32);
            eb.storeUint(id, 64);
            eb.storeAddress(ctx.sender);
            let eventBody = eb.endCell();

            send(SendParameters{
                to: self.owner,
                value: 0,
                bounce: false,
                mode: 1,       // sadece event (gas kontrat kasasından)
                body: eventBody
            });

            return;
        }

        // ---------------------------
        // ADMIN: MINT PRICE GÜNCELLE
        // opcode = OP_SET_MINT_PRICE
        // body: [opcode:32][new_price:coins]
        // ---------------------------
        if (opcode == self.OP_SET_MINT_PRICE) {
            // Sadece owner değiştirebilir
            if (ctx.sender != self.owner) {
                return;
            }

            if (body.bits() < 64) {
                return;
            }

            let newPrice = body.loadCoins();
            if (newPrice <= 0) {
                return;
            }

            self.mintPrice = newPrice;
            return;
        }

        // ---------------------------
        // ADMIN: WITHDRAW
        // opcode = OP_WITHDRAW
        // body: [opcode:32]
        // Tüm bakiyeyi owner'a yollar
        // ---------------------------
        if (opcode == self.OP_WITHDRAW) {
            if (ctx.sender != self.owner) {
                return;
            }

            // Kontrat bakiyesinin tamamını owner'a aktar
            send(SendParameters{
                to: self.owner,
                value: 0,
                bounce: false,
                mode: SendRemainingValue,   // tüm kalan değeri gönder
                body: null
            });

            return;
        }

        // Diğer opcode'ları yok say
        return;
    }

    // Mint edilen miktar
    get fun get_minted(): Int {
        return self.nextIndex;
    }
}
