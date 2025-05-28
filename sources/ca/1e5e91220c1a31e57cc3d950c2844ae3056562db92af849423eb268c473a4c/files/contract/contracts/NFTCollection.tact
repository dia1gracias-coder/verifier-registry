//Source from https://github.com/tact-lang/tact/blob/793ea9b6/src/benchmarks/contracts/nft-collection.tact

// import "./constants";
// import "./messages-nft";
// import "./NFTItem";

import "./message";
import "./NFTItem";
import "@stdlib/ownable";

const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

contract NFTCollection with Ownable {
    owner: Address;
    next_item_index: Int as uint32 = 0;
    royalty_params: RoyaltyParams?;
    collection_content: Cell;

    init(owner: Address, collection_content: Cell, royalty_params: RoyaltyParams) {
        self.owner = owner;
        self.collection_content = collection_content;
        self.royalty_params = royalty_params;
    }

    receive(){

    }

    receive("Mint"){
        let ctx: Context = context(); // get sender Info
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue -= (storageFee + gasConsumption);
        self.mint(ctx.sender, msgValue);

        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) {
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
                    custom_payload: self.collection_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        // dump(self.next_item_index); // Reference at: https://tact-by-example.org/03-emit
        self.next_item_index += 1;
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
                destination: self.owner
            }.toCell()
        });        
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append(myAddress().toString());
        b.append("/meta.json"); // You can changed this your self.

        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
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
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params!!;
    }

    fun get_raw_address(address: Address): String {
        let slice = address.asSlice();

        let tag = slice.loadUint(3);          // Read tag (but we can ignore it for this purpose)
        let chain = slice.loadInt(8);         // Workchain ID: 0 or -1
        let hash = slice.loadUint(256);       // Address hash (as BigInt)

        // Convert chain to string
        let chainStr = chain.toString();

        //Need to convert this hash from a number to hex interpretation of the number
        //TODO cant figure out how to convert from int to hex string
        let hashHex = hash.toString();
        // let hashHex = self.toHexString(hash, 64);

        // Return raw address format string: "0:abcd..."
        let b: StringBuilder = beginString();
        b.append(chainStr);
        b.append(":");
        b.append(hashHex);
        return b.toString();
    }
}
