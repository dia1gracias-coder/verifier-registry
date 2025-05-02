import "./packages/market/MarketMaster.tact";
import "./market_item.tact";
import "./packages/nft/NFTItem.tact";


contract MarketMaster with MarketMasterStandard {
    next_item_index: Int = 0;

    created_at: Int;

    init(created_at: Int) {
        self.created_at = created_at;
    }

    // This is when you don't want to send excesses back
    receive() {}



    //*********************************//
    //       Internal functions        //
    //*********************************//

    override fun _create_market_item_import(msg: CreateMarketItemFromOther) {
        let state: StateInit = self._get_market_item_state(self.next_item_index);

        send(SendParameters{
            to: contractAddress(state),
            value: 0,
            mode: SendRemainingValue,
            body: ProvideSaleNft{
                nft_sale_address: msg.nft_sale_address,
                full_price: msg.full_price,
                nft_address: msg.nft_address,
                query_id: msg.query_id,
                owner: msg.prev_owner,

            }.toCell(),
            code: state.code,
            data: state.data,
        });

        self.next_item_index = self.next_item_index + 1;
    }

    override fun _create_market_item_our(msg: OwnershipAssigned) {
        let ctx: Context = context();

        let full_price = msg.forward_payload.loadCoins();

        let item_init: StateInit = self._get_market_item_state(self.next_item_index);
        let sale_init: StateInit = self._get_sale_nft_state(ctx.sender, full_price);

        send(SendParameters{
            to: contractAddress(item_init),
            value: ctx.value - ton("0.1"),
            mode: SendIgnoreErrors,
            body: ProvideSaleNft{
                query_id: msg.query_id,
                nft_sale_address: null,
                full_price: full_price,
                nft_address: sender(),
                owner: msg.prev_owner,
            }.toCell(),
            code: item_init.code,
            data: item_init.data,
        });


        send(SendParameters{
            to: ctx.sender,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            body: Transfer{
                query_id: msg.query_id,
                new_owner: contractAddress(sale_init),
                response_destination: contractAddress(sale_init),
                custom_payload: emptyCell(),
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
        });

        self.next_item_index = self.next_item_index + 1;

        self.reply("Success".asComment());
    }

    override fun _get_market_item_state(index: Int): StateInit {
        return initOf MarketItem(
            myAddress(),
            index
        );
    }

    override inline fun _get_sale_nft_state(nft_address: Address, full_price: Int): StateInit {
        return initOf MarketSaleNft(
            myAddress(), 
            nft_address, 
            full_price, 
            newAddress(0, 0),
            0
        )
    }


}
