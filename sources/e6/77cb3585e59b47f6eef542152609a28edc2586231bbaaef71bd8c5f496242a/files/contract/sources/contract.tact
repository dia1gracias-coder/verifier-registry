import "./message.tact";
const minTonsForStorage: Int = ton("0.04");
const gasConsumption: Int = ton("0.04");

contract NftCollection {
    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    royalty_params: RoyaltyParams?;                      
    collection_content: Cell;   

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams){
        self.owner_address = owner_address;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
    }

    receive("Mint 1") {
        let lvl1_cost: Int = ton("0.3");
        let ctx: Context = context(); // get sender Info
        //level 1 nft
        require(ctx.value >= lvl1_cost + gasConsumption, "Not enougth TON to buy lvl 1 NFT");
        
        let level: Int = 1;
        
        self.process_nft_level_buy(ctx, ctx.value - lvl1_cost, level); 
    }

    
    receive("Mint 2") {
        let lvl2_cost: Int = ton("0.5");
        let ctx: Context = context(); // get sender Info
        //level 2 nft
        require(ctx.value >= lvl2_cost + gasConsumption, "Not enougth TON to buy lvl 2 NFT");
        
        let level: Int = 2;
        self.process_nft_level_buy(ctx, ctx.value - lvl2_cost, level); 
    }
    
    
    receive("Mint 3") {
        let lvl3_cost: Int = ton("1.0");
        let ctx: Context = context(); // get sender Info
        //level 3 nft
        require(ctx.value >= lvl3_cost + gasConsumption, "Not enougth TON to buy lvl 3 NFT");
        
        let level: Int = 3;
        self.process_nft_level_buy(ctx, ctx.value - lvl3_cost, level);  
    }


    receive("Mint 4") {
        let lvl4_cost: Int = ton("3.0");
        let ctx: Context = context(); // get sender Info
        //level 4 nft
        require(ctx.value >= lvl4_cost + gasConsumption, "Not enougth TON to buy lvl 4 NFT");
        
        let level: Int = 4;
        self.process_nft_level_buy(ctx, ctx.value - lvl4_cost, level);   
    }


    receive("Mint 5") {
        let lvl5_cost: Int = ton("5.0");
        let ctx: Context = context(); // get sender Info
        //level 5 nft
        require(ctx.value >= lvl5_cost + gasConsumption, "Not enougth TON to buy lvl 5 NFT");
        
        let level: Int = 5;
        self.process_nft_level_buy(ctx, ctx.value - lvl5_cost, level);   
    }


    receive("Mint 6") {
        let lvl6_cost: Int = ton("10.0");
        let ctx: Context = context(); // get sender Info
        //level 6 nft
        require(ctx.value >= lvl6_cost + gasConsumption, "Not enougth TON to buy lvl 6 NFT");
        
        let level: Int = 6;
        self.process_nft_level_buy(ctx, ctx.value - lvl6_cost, level);    
    }


    receive("Mint 7") {
        let lvl7_cost: Int = ton("20.0");
        let ctx: Context = context(); // get sender Info
        //level 7 nft
        require(ctx.value >= lvl7_cost + gasConsumption, "Not enougth TON to buy lvl 7 NFT");
        
        let level: Int = 7;
        self.process_nft_level_buy(ctx, ctx.value - lvl7_cost, level);    
    }


    // ===== Private Methods ===== //
    fun process_nft_level_buy(ctx: Context, bypassValue: Int, level: Int) {
        let tonBalanceBeforeMsg: Int = myBalance() - ctx.value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        self.mint(ctx.sender, bypassValue, level);

        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }

    fun mint(sender: Address, msgValue: Int, level: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index, level);
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
        // dump(self.next_item_index); // Reference at: https://tact-by-example.org/03-emit
        self.next_item_index = self.next_item_index + 1;
    }

    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  (self.royalty_params!!).numerator,
                denominator: (self.royalty_params!!).denominator,
                destination: self.owner_address
            }.toCell()
        });        
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("collection.json"); // You can changed this your self.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index, 0);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int, level: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, level);
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
}

contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;
    level: Int;

    init(collection_address: Address, item_index: Int, level: Int){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
        self.level = level;
    }

    receive(msg: Transfer){
        let ctx: Context = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context
        let msgValue: Int = self.msgValue(ctx.value);
        
        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
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
            self.owner = msg.new_owner;  // change current owner to the new_owner
            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode:  SendPayGasSeparately, 
                    bounce: true,
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
                    bounce: true,
                    body: Excesses { query_id: msg.query_id }.toCell()
                });
            } 
        }
    }
    
    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
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
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        b.append(self.level.toString());
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
