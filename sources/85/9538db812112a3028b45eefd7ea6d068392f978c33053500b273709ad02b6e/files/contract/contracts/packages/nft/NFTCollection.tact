/*
    Trait Standard NFT Collection contract
    Standard TEP-0062 - https://github.com/ton-blockchain/TEPs/blob/master/text/0062-nft-standard.md
*/


struct CollectionData {
    next_item_index: Int;     // collection should issue NFT with sequential indexes starting from 1. -1 value implies non-sequential collections.
    collection_content: Cell; // collection content format should comply with TEP64 
    owner_address: Address;   // collection owner address, zero address if no owner
}

trait NftCollectionStandard {

    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;


    //*********************************//
    //       Internal functions        //
    //*********************************//

    // @dev _get_nft_item_state_init calculates init code for NFT item contract by item index
    abstract inline fun _get_nft_item_state_init(item_index: Int): StateInit;

    // @dev _get_nft_content gets the serial number of the NFT item of this collection and the individual content of this NFT item.
    //      returns the full content of the NFT item in format that complies with standard TEP-64.
    // virtual inline fun _get_nft_content(index: Int, individual_content: Cell): Cell {
    //     let builder: StringBuilder = beginString();
    //     let idvStr: String = individual_content.asSlice().asString();
    //     builder.append(idvStr);
    //     return builder.toCell();
    // }

    // @dev get_collection_data returns nft collection data
    virtual inline fun _get_collection_data(): CollectionData {
        return CollectionData {
            next_item_index: self.next_item_index,
            collection_content: self.collection_content,
            owner_address: self.owner_address
        };
    }


    //*********************************//
    //             Getters             //
    //*********************************//

    // @dev get_collection_data calls _get_collection_data and returns the full content of the NFT Collection in format that complies with standard TEP-64.
    get fun get_collection_data(): CollectionData {
        return self._get_collection_data();
    }

    // @dev get_nft_address_by_index gets the serial number of NFT item of this collection and returns its address
    get fun get_nft_address_by_index(index: Int): Address {
        let initCode: StateInit = self._get_nft_item_state_init(index);
        return contractAddress(initCode);
    }

    // // @dev get_nft_content calls _get_nft_content and returns the full content of the NFT item in format that complies with standard TEP-64.
    // get fun get_nft_content(index: Int, individual_content: Cell): Cell {
    //     return self._get_nft_content(index, individual_content);
    // }

    // @dev get_nft_item_address returns the address of the NFT item contract by its index
    get fun get_current_index(): Int {
        return self.next_item_index;
    }

}
