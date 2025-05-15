import "./packages/nft/NFTItem.tact";

contract NftItem with NFTItemStandard {
    override const gasConsumption: Int = ton("0.05");

    collection_address: Address;
    index: Int;
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool = false;

    init(collection_address: Address, index: Int) {
        self.collection_address = collection_address;
        self.index = index;
        self.owner = collection_address;
        self.individual_content = emptyCell();
    }
}
