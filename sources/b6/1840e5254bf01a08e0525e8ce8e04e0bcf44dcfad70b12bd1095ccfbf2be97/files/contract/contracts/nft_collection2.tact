// --- IMPORTS ---
import "@stdlib/ownable"; // We need this for airdrop/withdraw

// --- CONSTANTS ---
const minTonsForStorage: Int = ton("0.04");
const gasConsumption: Int = ton("0.04");

// --- OUR NEW CONSTANTS ---
const mint_pack: Int = 1;
const airdrop_pack: Int = 2;
const withdraw: Int = 3;
const MAX_SUPPLY: Int = 11110;      // 1111 packs * 10 NFTs
const MAINNET_PRICE: Int = ton("10");
const TESTNET_PRICE: Int = ton("0.3");
const GAS_PER_ITEM: Int = ton("0.1"); // Gas to deploy 1 item + send notification

// --- MESSAGES ---
message LogEventMintRecord {
    minter: Address;
    item_id: Int;
    generate_number: Int;
}
message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}
message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}
struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}
struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}

// --- OUR NEW MESSAGES ---
message(mint_pack) MintPack {
}
message(airdrop_pack) AirdropPack {
    to_address: Address;
}
message(withdraw) Withdraw {
}

// =======================================================
//
//               NFT COLLECTION CONTRACT
//
// =======================================================
contract NftCollection with Ownable {
    next_item_index: Int as uint32 = 0;
    owner: Address;
    royalty_params: RoyaltyParams?;                      
    collection_content: Cell;   
    is_testnet: Bool; // Our new state variable for price

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams, is_testnet: Bool){
        self.owner = owner_address;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
        self.is_testnet = is_testnet;    // Set the network flag
    }

    // --- Empty receive for deployment ---
    receive() {
        cashback(sender());
    }
    
    // --- 🚀 10-PACK MINT FUNCTION ---
    receive(msg: MintPack) {
        require(self.next_item_index + 10 <= MAX_SUPPLY, "Mint has ended");

        let price: Int = self.is_testnet ? TESTNET_PRICE : MAINNET_PRICE;
        let total_gas_fee: Int = GAS_PER_ITEM * 10;
        let required_value: Int = price + total_gas_fee;
        
        let ctx: Context = context();
        require(ctx.value > required_value, "Not enough TON sent");

        let i: Int = 0;
        repeat(10) {
            self.mint(ctx.sender, GAS_PER_ITEM);
            i = i + 1;
        }

        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors
        });

        emit(LogEventMintRecord{ minter: ctx.sender, item_id: self.next_item_index - 10, generate_number: 10 }.toCell());
    }

    // --- 🚀 10-PACK AIRDROP FUNCTION ---
    receive(msg: AirdropPack) {
        self.requireOwner(); 
        require(self.next_item_index + 10 <= MAX_SUPPLY, "Airdrop would exceed max supply");
        let total_gas_fee: Int = GAS_PER_ITEM * 10;
        require(context().value > total_gas_fee, "Not enough TON for gas");
        
        let i: Int = 0;
        repeat(10) {
            self.mint(msg.to_address, GAS_PER_ITEM);
            i = i + 1;
        }
    }

    // --- 🚀 WITHDRAW FUNCTION ---
    receive(msg: Withdraw) {
        self.requireOwner(); 
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors
        });
    }

    // --- Internal Mint Helper ---
    fun mint(new_owner: Address, gas_value: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: gas_value,
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: new_owner, 
                    response_destination: self.owner, 
                    custom_payload: self.collection_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        self.next_item_index = self.next_item_index + 1;
    }

    // --- Royalty Get Method ---
    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context();
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  (self.royalty_params!!).numerator,
                denominator: (self.royalty_params!!).denominator,
                destination: self.owner
            }.toCell()
        });        
    }

    // --- 🚀 METADATA GET FUNCTIONS (FIXED) ------------------ //

    get fun get_collection_data(): CollectionData {     
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: self.collection_content,
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
    }
    
    // This is the TEP-64 function that builds the final metadata URL.
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        // 1. Parse the cell (which has two refs)
        let cs = individual_content.beginParse(); 
        let discarded_ref = cs.loadRef(); // This loads and discards Ref 1 (collection.json)
        
        // 2. Load the base URL from Ref 2
        let common_base_url_slice = cs.loadRef().asSlice(); // This is "ipfs://.../metadata/"
        
        //
        // 🚀 THIS IS THE FIX 🚀
        //
        // Use the modulo operator to always get a number from 0-9
        let metadata_index: Int = index % 10; 
        
        // 3. Build the final URL: "ipfs://.../metadata/0.json", etc.
        let item_url_builder = beginCell()
            .storeSlice(common_base_url_slice)
            .storeSlice(metadata_index.toString().asSlice()) // Use the new 0-9 index
            .storeSlice(".json".asSlice());

        // 4. Return the standard TEP-64 off-chain content cell
        let content_full = beginCell()
            .storeInt(0x01, 8) // Off-chain content prefix
            .storeRef(item_url_builder.endCell())
            .endCell();
            
        return content_full;
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params!!;
    }
}

// =======================================================
//
//                 NFT ITEM CONTRACT
//
// =======================================================
contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;
    owner: Address?;
    individual_content: Cell?; // This MUST be optional: Cell?

    init(collection_address: Address, item_index: Int){
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
        self.owner = null;
        self.individual_content = null;
    }

    // --- MINT & TRANSFER FUNCTION ---
    receive(msg: Transfer){
        let ctx: Context = context();
        let msgValue: Int = self.msgValue(ctx.value);
        
        if (self.is_initialized == false) {
            // MINT (This is correct)
            require(ctx.sender == self.collection_address, "Mint must come from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner; 
            self.individual_content = msg.custom_payload;

            // NOTIFICATION (This is correct)
            send(SendParameters{
                to: msg.new_owner,
                value: 0,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: OwnershipAssigned{
                    query_id: msg.query_id,
                    prev_owner: self.collection_address, 
                    forward_payload: emptySlice()
                }.toCell()
            });
        } else {
            // TRANSFER (This is correct)
            require(ctx.sender == self.owner!!, "Not the owner");
            
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
            self.owner = msg.new_owner;
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
            mode: 64,
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

    // --- 🚀 METADATA GET FUNCTION (FIXED) ---
    get fun get_nft_data(): GetNftData {
        // This function must return the raw 'individual_content' cell.
        // The wallet will then pass this to the collection's 'get_nft_content' function.
        
        let owner: Address = self.owner!!; 
        if (self.owner == null) {
            // Handle the case where the NFT is un-owned (e.g. before first transfer)
            owner = newAddress(0, 0); 
        }
        
        // Ensure individual_content is not null before returning.
        // If it is null, we return an empty cell.
        let content: Cell = self.individual_content!!;
        if (self.individual_content == null) {
            content = emptyCell();
        }

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: owner,
            individual_content: content // Return the raw cell
        };
    }
}