import "../nft/NFTItem.tact";

message(0x95d21749) CreateMarketItemFromOther {
    query_id: Int as uint64;
    nft_sale_address: Address;
    nft_address: Address;
    prev_owner: Address;
    full_price: Int as coins;
}





trait MarketMasterStandard {

    next_item_index: Int;


    //*********************************//
    //             Messages            //
    //*********************************//

    // @dev Create market item with nft_sale_address
    receive(msg: CreateMarketItemFromOther) {
        self._create_market_item_import(msg);
    }

    // @dev Create market item when transfer from nft
    receive(msg: OwnershipAssigned) {
        self._create_market_item_our(msg);
    }


    //*********************************//
    //       Internal functions        //
    //*********************************//


    abstract inline fun _create_market_item_our(msg: OwnershipAssigned);
    abstract inline fun _create_market_item_import(msg: CreateMarketItemFromOther);

    abstract inline fun _get_market_item_state(index: Int): StateInit;
    abstract inline fun _get_sale_nft_state(nft_address: Address, full_price: Int): StateInit;

    //*********************************//
    //             Getters             //
    //*********************************//


    get fun get_market_item_state(index: Int): StateInit {
        return self._get_market_item_state(index);
    }

    get fun get_market_item_address(index: Int): Address {
        return contractAddress(self._get_market_item_state(index));
    }

    get fun get_current_index(): Int {
        return self.next_item_index;
    }

}