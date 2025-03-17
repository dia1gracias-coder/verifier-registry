import "./messages.tact";
import "@stdlib/deploy";

const minTonsForStorageCollection: Int = ton("0.1");
const minTonsForStorageSoulbound: Int = ton("0.03");
const gasConsumption: Int = ton("0.02");

contract SoulboundCollection with Deployable {
    // Soulbound ID 
    next_item_index: Int as uint32 = 1;  
    // Collection Data (name, description, URI)             
    collection_content: Cell;   


    // Int value is not used (to create a list of address)
    admin_list: map<Address, Int>;

    init(collection_content: Cell){
        // Init collection data
        self.collection_content = collection_content; 
        
        // Init admin list
        self.admin_list = emptyMap();
        self.admin_list.set(sender(), 0);
    }

    receive(msg: Mint){
        // Verify admin
        let sender = sender();
        require(self.admin_list.exists(sender), "Only admin can mint");

        // Transaction info
        let ctx: Context = context(); 

        // Calculate fees to store and to create new soulbound contract
        let msg_value: Int = ctx.value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = minTonsForStorageCollection - min(ton_balance_before_msg, minTonsForStorageCollection);
        msg_value = msg_value - (storage_fee + gasConsumption);

        self.mint(msg.new_owner, msg.anima_collection, sender, msg_value);

        emit(LogEventMintRecord{ minter: sender, new_owner: msg.new_owner, item_id: self.next_item_index }.toCell());
    }

    fun mint(new_owner: Address, anima_collection: String, sender: Address, msg_value: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");

        // We do not check for the anima collection 
        // If contract already exists, it will just call "InitSoulbound" on it and ignore deployment (code and data fields)
        let nft_init: StateInit = self.get_nft_item_init(new_owner, anima_collection);

        // Create the Soulbound contract (through nft_init) and call InitSoulbound on it
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: msg_value, 
                bounce: true,
                mode: SendIgnoreErrors,
                // Call InitSoulbound on contract after deployment
                body: InitSoulbound {
                    item_index: self.next_item_index,
                    response_destination: sender,
                    custom_payload: self.collection_content,
                }.toCell(),
                // Deployment part
                code: nft_init.code,
                data: nft_init.data,
            });
        
        self.next_item_index = self.next_item_index + 1;
    }

    receive(msg: Burn) {
        // Verify admin
        let sender = sender();
        require(self.admin_list.exists(sender), "Only admin can burn");

         // Transaction info
        let ctx: Context = context(); 

        // Calculate fees to store and to call burn on soulbound contract
        let msg_value: Int = ctx.value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = minTonsForStorageCollection - min(ton_balance_before_msg, minTonsForStorageCollection);
        msg_value = msg_value - (storage_fee + gasConsumption);

        self.burn(msg.owner, msg.anima_collection, sender, msg_value);

         emit(LogEventBurnRecord{owner: msg.owner, anima_collection: msg.anima_collection}.toCell());
    }
    
    fun burn(owner: Address, anima_collection: String, response_destination: Address, msg_value: Int) {
        // Call burn on contract even if it potentially does not exist (it bounces)
        let soulbound_address = self.get_nft_address_by_owner_and_anima_collection(owner, anima_collection);

        send(SendParameters{
            to: soulbound_address, 
            value: msg_value, 
            bounce: true, // Bounce to verify if contract exists
            mode: 0,
            // BURN CALL ON NFT
            body: Burn {
                owner: owner,
                anima_collection: anima_collection,
                response_destination: response_destination,
            }.toCell(),
         });
    }

    receive(msg: AddAdmin) {
        require(self.admin_list.exists(sender()), "Only admin can add admin");
        self.admin_list.set(msg.admin_to_add, 0);
    }

    receive(msg: RemoveAdmin) {
        require(self.admin_list.exists(sender()), "Only admin can remove admin");
        let found = self.admin_list.del(msg.admin_to_remove);
        require(found, "Address not found in admin list");
    }

    // Empty receive to send ton to the contract
    receive() {}

    // Get soulbound contract address from owner address and anima collection name
    get fun get_nft_address_by_owner_and_anima_collection(owner: Address, anima_collection: String): Address{      
        let initCode: StateInit = self.get_nft_item_init(owner, anima_collection);
        return contractAddress(initCode);
    }

    get fun get_nft_item_init(owner: Address, anima_collection: String): StateInit {
        return initOf Soulbound(myAddress(), owner, anima_collection);
    }

    get fun next_nft_id(): Int {
        return self.next_item_index;
    }

    get fun admins_list(): map<Address, Int> {
        return self.admin_list;
    }

    get fun get_collection_data(): Cell {
        return self.collection_content;
    }
}

contract Soulbound {
    collection_address: Address;
    item_index: Int?; 

    owner: Address;
    anima_collection: String;
    individual_content: Cell?;

    is_initialized: Bool = false;

    init(collection_address: Address, new_owner: Address, anima_collection: String){
        // Call must be from collection contract
        require(sender() == collection_address, "Not from collection contract");

        self.collection_address = collection_address;
        self.owner = new_owner;
        self.anima_collection = anima_collection;
    }

    receive(msg: InitSoulbound) {
        let ctx = context();
        let msg_value: Int = self.msgValue(ctx.value);

        // Call must be from collection contract and contract must not be initiliazed
        require(ctx.sender == self.collection_address, "Not from collection contract");
        require(!self.is_initialized, "Already initialized");

        // To avoid multiple InitSoulbound call
        self.is_initialized = true;

        // Init item index and content
        self.item_index = msg.item_index;
        self.individual_content = msg.custom_payload;

        // Send back fees
        send(SendParameters{
                to: msg.response_destination,
                value: msg_value,
                mode: SendPayGasSeparately,
        });
    }

    receive(msg: Burn) {
        // Call must be from collection contract
        require(sender() == self.collection_address, "Not from collection contract");

        let ctx = context();
        let msg_value: Int = self.msgValue(ctx.value);

        // Destroy contract by sending all contract's balance to caller
        send(SendParameters{
                to: msg.response_destination,
                value: msg_value,
                mode: SendRemainingBalance | SendDestroyIfZero,
        });
    }

    fun msgValue(value: Int): Int {
        let ton_balance_before_msg: Int = myBalance() - value;
        let storage_fee: Int = minTonsForStorageSoulbound - min(ton_balance_before_msg, minTonsForStorageSoulbound);
        return value - storage_fee;
    }

    // Empty receive to send ton to the contract
    receive() {}

    get fun get_nft_data(): GetNftData {
        // String result => Collection Name + NFT ID 
        let b: StringBuilder = beginString();
        let collection_data: String = (self.individual_content!!).asSlice().asString();
        b.append(collection_data);
        b.append(self.item_index!!.toString());

        return GetNftData {
            index: self.item_index!!, 
            collection_address: self.collection_address, 
            owner_address: self.owner,
            anima_collection: self.anima_collection,
            individual_content: b.toCell()
        };
    }

    get fun nft_id(): Int {
        return self.item_index!!;
    }

    get fun nft_uri(): String {
        let cs = self.individual_content!!.beginParse();
        
        // Skip name reference
        cs.loadRef();
        
        // Skip description reference
        cs.loadRef();
        
        // Load and parse URI from reference cell
        let uriCell = cs.loadRef();
        let baseUri = uriCell.beginParse().asString();
        
        // Convert item_index to string
        let indexStr = self.item_index!!.toString();
        
        let b: StringBuilder = beginString();
        b.append(baseUri);
        b.append(indexStr);
        
        return b.toString();
    }
}
