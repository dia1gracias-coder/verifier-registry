import "@stdlib/deploy";
import "./constant";
import "./nft-item";

contract ManagerNFT with NftStandart {
    deployed: Bool = false;
    collection: Address;
    owner: Address;
    index: Int;
    content: Cell;

    init(collection: Address, index: Int) {
        self.collection = collection;
        self.index = index;
        self.owner = self.collection;
        self.content = emptyCell();
    }
}