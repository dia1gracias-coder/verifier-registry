import "./packages/market/MarketItem.tact";
import "./market_sale_nft.tact";

contract MarketItem with MarketItemStandard {
    is_init: Bool = false;

    market_address: Address;
    nft_sale_address: Address = newAddress(0, 0);
    nft_address: Address = newAddress(0, 0);

    full_price: Int = 0;
    item_index: Int;

    owner: Address = newAddress(0, 0);


    init(market_address: Address, item_index: Int) { 
        self.market_address = market_address;
        self.item_index = item_index;
    }

    //*********************************//
    //       Internal functions        //
    //*********************************//

    override inline fun _get_sale_nft_state(): StateInit {
        return initOf MarketSaleNft(
            self.market_address, 
            self.nft_address, 
            self.full_price, 
            newAddress(0, 0),
            0
        )
    }
}


// import "@stdlib/deploy";
// import "./helpers/messages.tact";
// import "./sale_nft.tact";


// contract MarketItem with Deployable {

//     marketplace_address: Address;
//     item_index: Int as uint64;

//     nft_sale_address: Address;
//     is_init: Bool = false;

//     full_price: Int as coins = 0;
//     nft_address: Address;

//     nft_complete: Bool = false;

//     init(marketplace_address: Address, item_index: Int) {
//         self.marketplace_address = marketplace_address;
//         self.item_index = item_index;

//         self.nft_sale_address = newAddress(0, 0);
//         self.nft_address = newAddress(0, 0);
//     }

//     receive(msg: ProvideSaleNft) {
//         require(sender() == self.marketplace_address, "Market only");
//         require(!self.is_init, "Market item is init");

//         self.nft_address = msg.nft_address;
//         self.full_price = msg.full_price;

//         if(msg.nft_sale_address != null) {
//             self.is_init = true;
//             self.nft_sale_address = msg.nft_sale_address!!;
//         } else {
//             send(SendParameters{
//                 to: self.marketplace_address,
//                 value: 0,
//                 mode: SendRemainingValue,
//                 body: GetMarketParams{
//                     query_id: now()
//                 }.toCell()
//             });
//         }
//     }

//     receive(msg: ReportMarketParams) {
//         require(sender() == self.marketplace_address, "Market only");
//         let sale_init: StateInit = initOf SaleNft(self.marketplace_address, self.nft_address , self.full_price, msg.marketplace_fee_address, msg.marketplace_fee);

//         self.nft_sale_address = contractAddress(sale_init);
//         dump(context().value);

//         send(SendParameters{
//             to: contractAddress(sale_init),
//             value: 0,
//             mode: SendRemainingValue,
//             data: sale_init.data,
//             code: sale_init.code,
//         });
//     }

//     // ---- Private Methods ---- //

   


//     // ---- Getters ---- //

//     get fun get_nft_address(): Address {
//         return self.nft_address;
//     }

//     get fun get_nft_sale_address(): Address {
//         return self.nft_sale_address;
//     }

//     get fun get_marketplace_address(): Address {
//         return self.marketplace_address;
//     }

//     get fun get_item_index(): Int {
//         return self.item_index;
//     }

//     get fun get_full_price(): Int {
//         return self.full_price;
//     }


    
// }
