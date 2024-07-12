import "./imports/stdlib.fc";
import "./message.tact";

@name(store_dict)
extends native storeDict(self: Builder, c: Cell): Builder;

@name(store_slice)
extends native store_slice(self: Builder, s: Slice): Builder;

contract Register {
    admin: Address;
    royalty_params: RoyaltyParams;                      
    collection_content: Cell;   
    next_item_index: Int as uint32 = 0;
    treasury: Address;

    symbol_record: map<Int as uint256, Int as uint32>;          // symbolHashing -> nft_item_index ID
    contractAddressRecord: map<Int as uint32, AddressList>;     // item_index -> jettonRootAddress & nftItemAddress
    tempTokenContent: map<Int as uint256, Cell>;

    jettonRootCode: Cell;
    jettonWalletCode: Cell;
    is_open: Bool = true;

    init(_collection_content: Cell, _royalty_params: RoyaltyParams, _treasury: Address, jettonRootCode: Cell, jettonWalletCode: Cell, initSymbol_record: map<Int as uint256, Int as uint32>){
        self.admin = sender();
        self.collection_content = _collection_content; 
        self.royalty_params = _royalty_params;
        self.treasury = _treasury;
        self.jettonRootCode = jettonRootCode;
        self.jettonWalletCode = jettonWalletCode;
        self.symbol_record = initSymbol_record;
    }

    receive(msg: AdminAddSymbol) {
        require(sender() == self.admin, "not admin");
        let symbolHashing: Int = msg.symbol.hash();
        self.symbol_record.set(symbolHashing, msg.theoryItemIndex);
        self.forward(sender(), "Success added the symbol".asComment(), false, null);
    }
    
    receive(msg: AdminRemoveSymbol) {
        require(sender() == self.admin, "not admin");
        let symbolHashing: Int = msg.symbol.hash();
        self.symbol_record.set(symbolHashing, null);
        self.forward(sender(), "Success remove the symbol".asComment(), false, null);
    }
    
    receive("Click") {
        require(sender() == self.admin, "not admin");
        if (self.is_open) {
            self.is_open = false;
        } else {
            self.is_open = true;
        }
        self.forward(sender(), "Success".asComment(), false, null);
    }

    receive("Protocol Claim") { // Claim the Register Fee
        send(SendParameters{ to: self.treasury, value: myBalance() - ton("0.1"), mode: SendIgnoreErrors, bounce: false });
    }

    receive(msg: ReigsterTokenTick) { // 0x4fef0a87
        require(self.is_open, "contract is closed");
        require(msg.symbol.asSlice().bits() <= 1023, "symbol too long"); 
        
        let symbol_length: Int = msg.symbol.asSlice().bits() / 8;
        require(symbol_length >= 2, "symbol too short, at least 2 chars");

        let symbolHashing: Int = msg.symbol.hash();
        require(self.symbol_record.get(symbolHashing) == null, "symbol already registered");
        
        let registerCost: Int = self.registerCost(symbol_length);
        require(context().value >= registerCost, "not enough value for tonCoin to register");
        require(msg.symbol.asSlice().ss_is_lower(), "symbol must be lower case");
        
        // --- Store the Token Content --- 
        self.tempTokenContent.set(sha256("name"), beginCell().storeUint(0, 8).store_slice(msg.name.asSlice()).endCell());
        self.tempTokenContent.set(sha256("description"), beginCell().storeUint(0, 8).store_slice(msg.description.asSlice()).endCell());
        self.tempTokenContent.set(sha256("image"), beginCell().storeUint(0, 8).store_slice(msg.image.asSlice()).endCell());
        self.tempTokenContent.set(sha256("symbol"), beginCell().storeUint(0, 8).store_slice(msg.symbol.asSlice()).endCell());
        let jettonContent: Cell = beginCell().storeUint(0, 8).storeDict(self.tempTokenContent.asCell()!!).endCell();
        self.tempTokenContent = emptyMap(); 

        let ss: Slice = msg.minting_info.beginParse();
        require(ss.bits() > 0, "minting info must be non-empty");

        let start_time: Int = ss.loadUint(32);
        require(start_time >= now() && start_time < 4294967295, "the starting sholuld be higher than now"); 

        let max_supply: Int = ss.loadCoins();
        require(max_supply > 0, "max supply must be positive");

        let init_supply: Int = ss.loadCoins();
        require(init_supply >= 0, "init supply must be positive");

        // [init_supply / max_supply] can't over 90% or lower than 10%
        let initial_ratio_reserve: Int = init_supply * 100 / max_supply;
        require(initial_ratio_reserve >= 0 && initial_ratio_reserve <= 90, "the ratio is incorrect");
        
        let cost_per_mint: Int = ss.loadCoins();
        require(cost_per_mint >= ton("0.25"), "cost per mint must be more than 0.25 TON");

        let total_duration_hours: Int = ss.loadUint(16);
        require(total_duration_hours > 0 && total_duration_hours < 65535, "total duration must be positive");

        let initial_mint_rate: Int = ss.loadUint(32);
        require(initial_mint_rate > 0 && initial_mint_rate < 4294967295, "initial mint rate must be positive");

        let percent_of_fee_back: Int = ss.loadUint(8);
        require(percent_of_fee_back > 0 && percent_of_fee_back <= 90, "percent_of_fee_back must be positive"); // the percentage of the register can earn from the minting revenue

        self.mintTokenTick(sender(), msg.minting_info, jettonContent, symbolHashing);
        nativeReserve(ton("0.15"), 2);
        send(SendParameters{ to: self.treasury, value: 0, mode: SendRemainingBalance, bounce: false });
    }

    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams { query_id: msg.query_id, numerator:  self.royalty_params.numerator, denominator: self.royalty_params.denominator, destination: self.royalty_params.destination }.toCell()
        });        
    }

    // ===== Private Methods ===== //
    fun mintTokenTick(sender: Address, minting_info: Cell, jettonContent: Cell, symbolHashing: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        self.symbol_record.set(symbolHashing, self.next_item_index);  

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let jettonRootInitData: Cell = self.get_jetton_root_init_data(self.next_item_index, jettonContent);
        let jettonRootInit: StateInit = StateInit { data: jettonRootInitData, code: self.jettonRootCode };
        
        // Storing the addresses in the contractAddressRecord
        self.contractAddressRecord.set(
            self.next_item_index, 
            AddressList { nftItemAddress: contractAddress(nft_init), jettonRootAddress: contractAddress(jettonRootInit), jettonContent: jettonContent }
        );

        let packedJettonRootData: Cell = beginCell().storeRef(jettonRootInitData).endCell();
        self.next_item_index = self.next_item_index + 1;
        send(SendParameters{
            to: contractAddress(nft_init), 
            value: ton("0.5"),
            mode: SendPayGasSeparately,
            body: Transfer { // 0x5fcc3d14 / 1607220500
                query_id: 0,
                new_owner: sender,
                response_destination: self.treasury,
                custom_payload: minting_info,
                forward_amount: 0,
                forward_payload: packedJettonRootData.asSlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data,
            bounce: false
        });
    }

    fun get_jetton_root_init_data(item_index: Int, jettonContent: Cell): Cell {
        let nftItemAddr: Address = self.get_nft_address_by_index(item_index);
        let data: Cell = beginCell()
                            .storeCoins(0)                      // total_supply
                            .storeSlice(nftItemAddr.asSlice())  // admin_address
                            .storeRef(jettonContent)            // jetton_content
                            .storeRef(self.jettonWalletCode)    // jetton_wallet_code

                            .storeUint(0, 32)   // start_time (32 bits)
                            .storeCoins(0)      // max_supply
                            .storeCoins(0)      // init_supply
                            .storeCoins(0)      // cost_per_mint

                            .storeUint(0, 16)   // total_duration_hours
                            .storeUint(0, 32)   // initial_mint_rate
                            .storeUint(0, 32)   // lastMintTimestamp
                            .storeUint(0, 32)   // acutalMintTimes

                            .storeUint(0, 8)   // percent_of_fee_back
                            .storeSlice(self.treasury.asSlice())
                        .endCell(); 
        return data;
    }

    fun jettonRootInit(item_index: Int, jettonContent: Cell): StateInit {
        let data: Cell = self.get_jetton_root_init_data(item_index, jettonContent);
        let rootInit: StateInit = StateInit { data: data, code: self.jettonRootCode }; 
        return rootInit;
    }

    fun getJettonWalletInit(item_index: Int, owner: Address, jettonMaster: Address): StateInit {
        let packData: Cell = beginCell()
                                .storeCoins(0)                      // balance
                                .storeSlice(owner.asSlice())        // owner_address
                                .storeSlice(jettonMaster.asSlice()) // jettonMaster_address
                                .storeRef(self.jettonWalletCode)    // jetton_wallet_code
                                .storeUint(0, 32)                   // unlock_time
                                .storeUint(0, 8)                    // minting_times
                            .endCell();
                        
        let walletInit: StateInit = StateInit { data: packData, code: self.jettonWalletCode }; 
        return walletInit; 
    }

    fun getNftItemInit(item_index: Int): StateInit {
        return initOf TokenTick(myAddress(), item_index, self.admin, self.collection_content, self.jettonRootCode);
    }

    // ================ Get Functions ================ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("metadata.json");
        return CollectionData {
            next_item_index: self.next_item_index,  
            collection_content: b.toCell(), 
            owner_address: self.admin 
        };
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun get_royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }

    get fun registerCost(symbol_length: Int): Int {
        if (symbol_length == 2) {
            return ton("100");
        } else if (symbol_length == 3) {
            return ton("50");
        } else if (symbol_length == 4){
            return ton("20");
        } else {
            return ton("10");
        }
    }

    get fun get_contractInfo_list_by_index(item_index: Int): AddressList {
        return self.contractAddressRecord.get(item_index)!!;
    }

    get fun get_nft_address_by_index(item_index: Int): Address {      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun get_jettonRoot_minter_by_index(item_index: Int): Address {
        return (self.contractAddressRecord.get(item_index)!!).jettonRootAddress;
    }

    get fun get_jetton_wallet_address_by_id_owner(item_index: Int, owner: Address): Address {
        let list: AddressList = (self.contractAddressRecord.get(item_index)!!);
        return contractAddress(self.getJettonWalletInit(item_index, owner, list.jettonRootAddress));
    }

    get fun get_contractInfo_list_by_tickName(symbol_cell: Cell): AddressList {
        let item_index: Int? = self.symbol_record.get(symbol_cell.hash());
        return self.contractAddressRecord.get(item_index!!)!!;
    }

    get fun get_registerContract_balance(): Int {
        return myBalance();
    }
}

// -------------------- NFT Item -------------------- //
contract TokenTick {
    const minTonsForStorage: Int = ton("0.04");
    const gasConsumption: Int = ton("0.04");
    
    collection_address: Address;
    item_index: Int; 
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool;
    jettonRootCode: Cell;

    jettonRootAddr: Address?;
    treasury: Address?;

    init(collection_address: Address, item_index: Int, owner: Address, individual_content: Cell, jettonRootCode: Cell){
        require(sender() == collection_address, "not collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = owner;
        self.individual_content = individual_content;
        self.is_initialized = false;
        self.jettonRootCode = jettonRootCode;
    }

    receive("Claim") {
        require(sender() == self.owner, "not owner of NFT item");
        send(SendParameters{
            to: self.jettonRootAddr!!,
            value: 0,
            mode: SendRemainingValue,
            body: ClaimReward { query_id: 0, receiver: sender() }.toCell()
        });
    }

    receive(msg: Transfer){ // 0x5fcc3d14
        let ctx: Context = context();        
        require(ctx.sender == self.owner || ctx.sender == self.collection_address, "not owner");
        let msgValue: Int = ctx.value - self.gasConsumption - (self.minTonsForStorage - min(self.minTonsForStorage, myBalance() - ctx.value));

        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            self.is_initialized = true;
            self.owner = msg.new_owner;

            let initCode: StateInit = self.JettonRootInit(msg.forward_payload.loadRef());
            self.jettonRootAddr = contractAddress(initCode);
            send(SendParameters{
                to: contractAddress(initCode),
                value: msgValue,
                mode: SendPayGasSeparately,
                bounce: false,
                body: JettonInitial { // 0x16
                    query_id: msg.query_id,
                    minting_info: msg.custom_payload!!
                }.toCell(),
                code: initCode.code,
                data: initCode.data
            });

        } else {
            self.owner = msg.new_owner;
            msgValue = msgValue - ctx.readForwardFee(); 

            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode: SendPayGasSeparately, 
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: ctx.sender,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }); 
            }

            if (msg.response_destination != null) { 
                send(SendParameters { 
                    to: msg.response_destination,
                    value: msgValue - msg.forward_amount,
                    mode: SendPayGasSeparately,
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

    fun JettonRootInit(initData: Cell): StateInit {
        let data: Cell = initData;
        let rootInit: StateInit = StateInit { data: data, code: self.jettonRootCode }; 
        return rootInit;
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = self.individual_content.asSlice().asString();
        b.append(collectionData);
        b.append(self.item_index.toString());
        b.append(".json");
        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner,
            individual_content: b.toCell()
        };
    }
}

extends fun ss_is_lower(self: Slice): Bool {
    let bits: Int = self.bits();
    let i: Int = 0;
    while (i < bits) {
        let str_as_int: Int = self.loadUint(8);
        if ((str_as_int < 0x30 || str_as_int > 0x39) && (str_as_int < 0x61 || str_as_int > 0x7A)) {
            return false;
        } 
        i = i + 8;
    }
    return true;
}