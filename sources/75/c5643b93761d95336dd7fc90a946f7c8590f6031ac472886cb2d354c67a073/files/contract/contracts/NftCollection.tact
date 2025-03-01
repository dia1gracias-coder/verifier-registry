import "@stdlib/deploy";
import "@stdlib/ownable";
import "./Upgradable";
import "./messages";
import "./NftItem";

contract NftCollection with Deployable, Ownable, Upgradable {
    owner              : Address;
    max_supply         : Int as uint32 = 2;
    next_item_index    : Int as uint32 = 0;
    collection_content : Cell;

    init(owner_address: Address, collection_content: Cell){
        self.owner = owner_address;
        self.collection_content = collection_content; 
    }

    receive(msg: Mint){
        self.requireOwner();

        let ctx: Context = context(); // get sender Info
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        self.mint(msg.recipient, msg.content, msgValue);

        emit(LogEventMintRecord{ minter: sender(), content: msg.content, recipient: msg.recipient, item_id: self.next_item_index }.toCell());
    }

    // ===== Private Methods ===== //
    fun mint(recipient: Address, content: Cell, msgValue: Int) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        require(self.next_item_index <= self.max_supply, "Max supply reached");
        
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to     : contractAddress(nft_init), 
                value  : msgValue, 
                bounce : false,
                mode   : SendIgnoreErrors,
                body   : Transfer {
                    response_destination : self.owner,
                    query_id  : 0,
                    new_owner : recipient,
                    custom_payload  : content,
                    forward_amount  : 0,
                    forward_payload : emptySlice()
                }.toCell(),
                code : nft_init.code,
                data : nft_init.data
            });
        // dump(self.next_item_index); // Reference at: https://tact-by-example.org/03-emit
        self.next_item_index += 1;
    }

    receive(msg: UpdateSettings) {
        self.requireOwner();
        require(msg.max_supply >= self.next_item_index, "New max supply cannot be less than current supply");
        
        self.max_supply = msg.max_supply;
    }

    receive(msg: Withdraw) {
        self.requireOwner();
        require(msg.amount > 0, "Amount must be positive");
        require(myBalance() > msg.amount, "Insufficient contract balance");

        send(SendParameters{
            to    : msg.destination,
            value : msg.amount,
            mode  : SendPayGasSeparately,
            body  : "Withdrawal processed".asComment()
        });
    }

    get fun get_supply_info(): SupplyInfo {
        return SupplyInfo{
            current_supply : self.next_item_index,
            max_supply     : self.max_supply
        };
    }
    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        // b.append("metadata.json");
        return CollectionData{
            next_item_index    : self.next_item_index, 
            collection_content : b.toCell(), 
            owner_address      : self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b  : StringBuilder = beginString();
        let ic : String        = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }
}
