import "./MarketNFTSale.tact";

message(0x8ce51689) ProvideSaleNft {
    query_id: Int as uint64;
    nft_sale_address: Address?;
    full_price: Int as coins;
    nft_address: Address;
    owner: Address;
}


struct MarketItemData {
    is_init: Bool;
    market_address: Address;
    nft_sale_address: Address;
    nft_address: Address;
    full_price: Int;
    item_index: Int;
}

trait MarketItemStandard {

    is_init: Bool;

    market_address: Address;
    nft_sale_address: Address;
    nft_address: Address;

    full_price: Int;
    item_index: Int;

    owner: Address;



    //*********************************//
    //             Messages            //
    //*********************************//

    receive(msg: ProvideSaleNft) {
        self._init(msg);
    }

    //*********************************//
    //       Internal functions        //
    //*********************************//

    virtual inline fun _init(msg: ProvideSaleNft) { 
        if(self.is_init == true) {
            return;
        }

        let ctx: Context = context();
        require(self.market_address == ctx.sender, "Market only");

        self.is_init = true;
        self.full_price = msg.full_price;
        self.nft_address = msg.nft_address;
        self.owner = msg.owner;

        if(msg.nft_sale_address != null) {
            self.nft_sale_address = msg.nft_sale_address!!;
        } else {
            let sale_init = self._get_sale_nft_state();

            self.nft_sale_address = contractAddress(sale_init);

            send(SendParameters{
                to: contractAddress(sale_init),
                value: 0,
                mode: SendRemainingValue,
                body: Init{
                    owner: self.owner
                }.toCell(),
                data: sale_init.data,
                code: sale_init.code,
            });
        }

    }

    abstract inline fun _get_sale_nft_state(): StateInit;

    virtual inline fun _get_market_item_data(): MarketItemData {
        return MarketItemData{
            is_init: self.is_init,
            market_address: self.market_address,
            nft_sale_address: self.nft_sale_address,
            nft_address: self.nft_address,
            full_price: self.full_price,
            item_index: self.item_index
        }
    }

    //*********************************//
    //             Getters             //
    //*********************************//

    get fun get_market_item_data(): MarketItemData {
        return self._get_market_item_data();
    }

    get fun get_sale_nft_state(): StateInit {
        return self._get_sale_nft_state();
    }

}