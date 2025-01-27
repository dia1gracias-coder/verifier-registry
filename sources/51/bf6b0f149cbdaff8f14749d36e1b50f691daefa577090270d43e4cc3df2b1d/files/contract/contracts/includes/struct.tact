struct JettonData {
    total_supply: Int as coins; // the total number of issues jettons
    mintable: Bool; // flag which indicates whether number of jettons can increase admin_address
    admin_address: Address; // address of smart-contrac which control Jetton
    jetton_content: Cell; // data in accordance to Token Data Standard #64
    jetton_wallet_code: Cell; // code of wallet for that jetton
}
struct UserAmount {
    user: Address;
    amount: Int as coins;
}
struct CountryData {
    buyable: Bool;
    sellable: Bool;
    token_locked: Bool;
    asymptote: Int;
    scale_param: Int;
    growth_rate: Int;
    total_holding: Int as coins;
    token_address: Address;
}
struct CountryHolders {
    users: map<Address, Int>;
}
struct CountryForDeployment {
    id: Int as uint16;
    jetton_content: Cell;
    nft_content: Cell;
    royalty_params: RoyaltyParams;
}
struct TokenToMint {
    country: Int as uint16;
    amount: Int as coins;
    receiver: Address;
}
struct WalletData {
    balance: Int as coins; // amount of jettons on wallet
    owner: Address; // address of wallet owner;
    jetton: Address; // address of Jetton master-address
    jetton_wallet_code: Cell; // with code of this wallet
}
// user holdings
struct UserHoldingData {
    holding: Int as coins;
    owner: Address;
    country: Address;
    init_code: Cell;
}
// NFT

struct NftData {
    is_initialized: Bool; // it should be `init`, but it is a reserved keyword in tact. if not zero, then this NFT is fully initialized and ready for interaction.
    index: Int; // numerical index of this NFT in the collection. For collection-less NFT - arbitrary but constant value.
    collection_address: Address; // address of the smart contract of the collection to which this NFT belongs. For collection-less NFT this parameter should be addr_none
    owner_address: Address; // address of the current owner of this NFT
    individual_content: Cell; // if NFT has collection - individual NFT content in any format; if NFT has no collection - NFT content in format that complies with standard TEP-64
}
struct CollectionData {
    next_item_index: Int; // collection should issue NFT with sequential indexes starting from 1. -1 value implies non-sequential collections.
    collection_content: Cell; // collection content format should comply with TEP64
    owner_address: Address; // collection owner address, zero address if no owner
}
struct RoyaltyParams {
    numerator: Int as uint16; // numerator to calculate royalty percentage
    denominator: Int as uint16; // denominator to calculate royalty percentage
    destination: Address; // Address to receive royalty
}