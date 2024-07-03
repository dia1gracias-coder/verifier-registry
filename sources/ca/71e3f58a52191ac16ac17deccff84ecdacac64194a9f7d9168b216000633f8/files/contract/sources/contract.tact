import "./message.tact";
const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

contract NftCollection {
    next_item_index: Int as uint32 = 0;
    minted_count: Int as uint32 = 0;
    owner_address: Address;
    royalty_params: RoyaltyParams?;
    collection_content: Cell;
    paused: Bool = false;
    maxSupply: Int as uint32 = 10000; //250001
    nft_owners: map<Int, Address>;
    base_uri: String;

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams) {
        self.owner_address = owner_address;
        self.collection_content = collection_content;
        self.royalty_params = royalty_params;
        self.base_uri = "https://gateway.pinata.cloud/ipfs/QmbGkPMiJzuJzcFY9ugzZcyUDxSM6EpPNw2z6PXhbqrdUN/";
        self.nft_owners = emptyMap();
    }

    receive("Mint") {
        require(!self.paused, "Minting is paused!!!");
        require(self.next_item_index < self.maxSupply, "Max supply reached!!");
        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= ton("5"), "Insufficient funds sent for minting!");

        let additionalFee: Int = ton("4.85");
        let requiredAmount: Int = additionalFee + minTonsForStorage + gasConsumption;
        require(msgValue >= requiredAmount, "Insufficient funds sent for minting");

        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);

        send(SendParameters{
            to: self.owner_address,
            value: additionalFee,
            bounce: false,
            mode: 1,
            body: emptyCell()
        });
        msgValue = msgValue - additionalFee;

        self.mint(ctx.sender, msgValue);

        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }

    receive(msg: MintSpecificNft) {
        require(!self.paused, "Minting is paused!");
        require(msg.id < self.maxSupply, "Max supply reached!");
        require(self.nft_owners.get(msg.id) == null, "NFT with this ID already exists");

        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= ton("5"), "Insufficient funds sent for minting");

        let additionalFee: Int = ton("4.85");
        let requiredAmount: Int = additionalFee + minTonsForStorage + gasConsumption;
        require(msgValue >= requiredAmount, "Insufficient funds sent for minting");

        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);

        send(SendParameters{
            to: self.owner_address,
            value: additionalFee,
            bounce: false,
            mode: 1,
            body: emptyCell()
        });
        msgValue = msgValue - additionalFee;

        self.mintSpecific(ctx.sender, msgValue, msg.id);

        emit(LogEventMintRecord{ minter: sender(), item_id: msg.id, generate_number: nativeRandom() }.toCell());
    }

    receive("MintRandom") {
        require(!self.paused, "Minting is paused!!!");
        require(self.minted_count < self.maxSupply, "Max supply reached!!");

        let ctx: Context = context();
        let msgValue: Int = ctx.value;

        require(msgValue >= ton("5"), "Insufficient funds sent for minting!");

        let additionalFee: Int = ton("4.85");
        let requiredAmount: Int = additionalFee + minTonsForStorage + gasConsumption;
        require(msgValue >= requiredAmount, "Insufficient funds sent for minting");

        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);

        send(SendParameters{
            to: self.owner_address,
            value: additionalFee,
            bounce: false,
            mode: 1,
            body: emptyCell()
        });
        msgValue = msgValue - additionalFee;

        // Generate a random NFT ID
        let randomId: Int = self.generateRandomId();

        self.mintSpecific(ctx.sender, msgValue, randomId);
        // self.minted_count = self.minted_count + 1; to check
        //self.next_item_index = self.next_item_index + 1;

        emit(LogEventMintRecord{ minter: sender(), item_id: randomId, generate_number: nativeRandom() }.toCell());
    }

    receive("PauseMinting") {
        require(context().sender == self.owner_address, "Only owner can pause minting");
        self.paused = true;
    }

    receive("ResumeMinting") {
        require(context().sender == self.owner_address, "Only owner can resume minting");
        self.paused = false;
    }

    receive("WithdrawBalance") {
        require(context().sender == self.owner_address, "Only owner can withdraw balance!");
        let balance: Int = myBalance() - gasConsumption;
        send(SendParameters{
            to: self.owner_address,
            value: balance,
            bounce: false,
            mode: 1,
            body: emptyCell()
        });
    }

    // Method to get the total number of minted NFTs
    get fun get_minted_count(): Int {
        return self.minted_count;
    }

// ------------------ Get Function  ------------------ //
    get fun mint(sender: Address, msgValue: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
            to: contractAddress(nft_init),
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer {
                query_id: 0,
                new_owner: sender,
                response_destination: self.owner_address,
                custom_payload: self.collection_content,
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });
        self.nft_owners.set(self.next_item_index, sender);
        self.next_item_index = self.next_item_index + 1;
        self.minted_count = self.minted_count + 1;
    }

    get fun mintSpecific(sender: Address, msgValue: Int, nftId: Int) {
        require(nftId >= 0, "Invalid NFT ID");
        let nft_init: StateInit = self.getNftItemInit(nftId);
        send(SendParameters{
            to: contractAddress(nft_init),
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer {
                query_id: 0,
                new_owner: sender,
                response_destination: self.owner_address,
                custom_payload: self.collection_content,
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });
        self.nft_owners.set(nftId, sender);
        self.next_item_index = self.next_item_index + 1;
    }

    receive(msg: GetRoyaltyParams) {
        let ctx: Context = context();
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64,
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator: self.royalty_params!!.numerator,
                denominator: self.royalty_params!!.denominator,
                destination: self.owner_address
            }.toCell()
        });
    }

    get fun get_collection_data(): CollectionData {
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("collection.json");
        return CollectionData{
            next_item_index: self.next_item_index,
            collection_content: b.toCell(),
            owner_address: self.owner_address
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address? {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params!!;
    }

    get fun get_metadata_url(nft_id: Int): String {
        let b: StringBuilder = beginString();
        b.append(self.base_uri);
        b.append(nft_id.toString());
        b.append(".json");
        return b.toString();
    }

    fun generateRandomId(): Int {
        let randomId: Int = nativeRandom() % self.maxSupply;
        while (self.nft_owners.get(randomId) != null) {
            randomId = (randomId + 1) % self.maxSupply;
        }
        return randomId;
    }
}

contract NftItem {
    collection_address: Address;
    item_index: Int;
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;

    init(collection_address: Address, item_index: Int) {
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer) {
        let ctx: Context = context();
        let msgValue: Int = self.msgValue(ctx.value);

        if (!self.is_initialized) {
            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            send(SendParameters{
                to: msg.response_destination!!,
                value: msgValue,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        } else {
            require(ctx.sender == self.owner!!, "not owner");
            self.owner = msg.new_owner;
            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: ctx.sender,
                        forward_payload: msg.forward_payload
                    }.toCell()
                });
            }

            msgValue = msgValue - ctx.readForwardFee();
            if (msg.response_destination != null) {
                send(SendParameters{
                    to: msg.response_destination!!,
                    value: msgValue - msg.forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: false,
                    body: Excesses { query_id: msg.query_id }.toCell()
                });
            }
        }
    }

    receive(msg: GetStaticData) {
        let ctx: Context = context();
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64,
            bounce: false,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = self.individual_content!!.asSlice().asString();
        b.append(collectionData);
        b.append(self.item_index.toString());
        b.append(".json");

        return GetNftData {
            is_initialized: self.is_initialized,
            index: self.item_index,
            collection_address: self.collection_address,
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }
}
