import "@stdlib/deploy";
import "@stdlib/ownable";
import "./imports/globals";
import "./imports/messages";
import "./nft_item";

struct CollectionData {
    next_item_index: Int as uint32;
    collection_content: Cell;
    owner: Address;
}

struct RoyaltyParams {
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

contract NftCollection with Deployable, OwnableTransferable {

    next_item_index: Int as uint32 = 0;
    owner: Address;
    royalty_params: RoyaltyParams;                      
    collectionContentUrl: Cell; 
    commonContentUrl: Cell;   

    init(owner: Address, collectionContentUrl: Cell, commonContentUrl: Cell, royalty_params: RoyaltyParams){
        self.owner = owner;
        self.royalty_params = royalty_params;
        self.collectionContentUrl = collectionContentUrl; 
        self.commonContentUrl = commonContentUrl; 
    }

    receive(msg : MintWithContent){
        let ctx: Context = context(); // get sender Info

        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);

        self.mint(ctx.sender, msgValue, msg.nftOffchainId);
    }

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int, nftOffchainId: String?) {
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
                    response_destination: self.owner,
                    custom_payload: emptyCell(),
                    forward_amount: 0,
                    forward_payload: emptySlice(),
                    nft_offchain_id: nftOffchainId
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        self.next_item_index = self.next_item_index + 1;
    }

    receive(msg: GetRoyaltyParams) {   
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  self.royalty_params.numerator,
                denominator: self.royalty_params.denominator,
                destination: self.owner
            }.toCell()
        });        
    }

    receive(msg: UpdateCollectionContent) {
        // Only Owner of the this NFT Collection can update it.
        self.requireOwner();

        self.royalty_params = RoyaltyParams{
            numerator: msg.numerator,
            denominator: msg.denominator,
            destination: msg.destination
        };

        self.collectionContentUrl = msg.collectionContentUrl;
        self.commonContentUrl = msg.commonContentUrl;
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collectionContentUrl.asSlice().asString();
        b.append(collectionDataString);
        b.append("collection.json"); // You can changed this your self.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner: self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, self.owner, self.commonContentUrl, self.owner);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }
}