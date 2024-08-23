struct CollectionData {
    next_item_index: Int as uint64;
    collection_content: Cell;
    owner_address: Address;
}

struct IndividualData {
    index: Int as uint64;
}

trait NFTCollectionBase {
    next_item_index: Int;
    collection_content: Cell; // https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md
    owner_address: Address;

    abstract inline fun _get_nft_item_state_init(index: Int): StateInit;

    get fun get_nft_address_by_index(index: Int): Address {
        let initCode: StateInit = self._get_nft_item_state_init(index);
        return contractAddress(initCode);
    }

    virtual inline fun _get_collection_data(): CollectionData {
        return CollectionData {
            next_item_index: self.next_item_index,
            collection_content: self.collection_content,
            owner_address: self.owner_address
        };
    }
    get fun get_collection_data(): CollectionData {
        return self._get_collection_data();
    }

    virtual inline fun _get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return self._get_nft_content(index, individual_content);
    }
}

