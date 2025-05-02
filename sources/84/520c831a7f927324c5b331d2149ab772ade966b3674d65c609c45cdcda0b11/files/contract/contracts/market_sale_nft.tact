import "./packages/market/MarketNFTSale.tact";


contract MarketSaleNft with MarketNFTSale {
    is_complete: Bool = false; 
    created_at: Int; 
    marketplace_address: Address;
    nft_address: Address;
    nft_owner_address: Address = newAddress(0, 0);
    full_price: Int;
    marketplace_fee_address: Address;
    marketplace_fee: Int; 
    royalty_amount: Int = 0; 
    royalty_address: Address = newAddress(0, 0); 
    sold_at: Int  = 0;
    query_id: Int = 0;

    nft_collection: Address?;

    is_init: Bool = false;


    init(
        marketplace_address: Address, 
        nft_address: Address, 
        full_price: Int,
        marketplace_fee_address: Address,
        marketplace_fee: Int,
    ) {
        self.marketplace_address = marketplace_address;
        self.nft_address = nft_address;
        self.full_price = full_price + nft_transfer_value;
        self.marketplace_fee_address = marketplace_fee_address;
        self.marketplace_fee = marketplace_fee;

        self.created_at = now();
    }


}
