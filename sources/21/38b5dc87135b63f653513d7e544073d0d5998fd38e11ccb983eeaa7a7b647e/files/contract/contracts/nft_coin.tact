import "@stdlib/deploy";
import "./imports/Nft/nft.tact";

message Mint {
    receiver: Address;
}

contract NFTCoin with NftCollection, Deployable{
    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    royalty_params: RoyaltyParams?;                      
    collection_content: Cell; 

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams){
        self.owner_address = owner_address;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
    }

    receive(msg: Mint){
        let ctx: Context = context(); // get sender Info        
        require(ctx.sender == self.owner_address, "Not owner");

        let msgValue: Int = self.msgValue(ctx.value);
        self.mint(msg.receiver, msgValue);

        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }




} 