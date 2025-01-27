import "./constant";
import "./struct";
message(0x178d4519) JettonMint {
    origin: Address; // address of origin mint request (may be wallet v4)
    receiver: Address; // address of receiver
    amount: Int; // amount of jettons to mint
    custom_payload: Cell?; // optional custom data
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x0f8a7ea5) JettonTransfer {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    destination: Address; // address of the new owner of the jettons
    response_destination: Address; // address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins.
    custom_payload: Cell?; // optional custom payload
    forward_ton_amount: Int as coins; // the amount of nanotons to be sent to the destination address.
    forward_payload: Slice as remaining; // optional custom data that should be sent to the destination address.
}
message(0x7362d09c) JettonTransferNotification {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    sender: Address; // address of the sender of the jettons
    forward_payload: Slice as remaining; // optional custom payload
}
message(0x595f07bc) JettonBurn {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to burn
    response_destination: Address; // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
    custom_payload: Cell?; // optional custom payload
}
message(0xd53276db) Excesses {
    query_id: Int as uint64; // arbitrary request number
}
message(0x178d4519) JettonInternalTransfer {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to transfer
    from: Address; // address of the sender of the jettons
    response_address: Address; // address where to send a response with confirmation of a successful transfer and the rest of the incoming message coins.
    forward_ton_amount: Int as coins; // the amount of nanotons to be sent to the destination address.
    forward_payload: Slice as remaining; // optional custom data that should be sent to the destination address.
}
message(0x7bdd97de) JettonBurnNotification {
    query_id: Int as uint64; // arbitrary request number
    amount: Int as coins; // amount of jettons to burn
    sender: Address; // address of the sender of the jettons
    response_destination: Address; // address where to send a response with confirmation of a successful burn and the rest of the incoming message coins.
}
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index: Int as uint256;
    collection: Address;
}
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64; // arbitrary request number
    new_owner: Address; // new owner of the NFT item
    response_destination: Address; // address where to send a response with confirmation of a successful transfer and the rest of the incoming message coins if not empty address
    custom_payload: Cell?; // optional custom data
    forward_amount: Int as coins; // the amount of nanotons to be sent to the new owner
    forward_payload: Slice as remaining; // optional custom data that should be sent to the new owner
}
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}
message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64; // arbitrary request number for sending ReportRoyaltyParams back with send mode 64
}
message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64; // corresponding request number
    numerator: Int as uint16; // numerator to calculate royalty percentage, maximum 65535
    denominator: Int as uint16; // denominator to calculate royalty percentage, maximum 65535
    destination: Address; // Address to receive royalty
}

// Custom Message

message(0x7a308480) Mint {
    amount: Int as coins;
    receiver: Address;
}
message(0x7a308481) AdminMint {
    country: Int as uint16;
    amount: Int as coins;
    receiver: Address;
}
message(0x7a308482) BuyToken {
    country: Int as uint16;
    amount: Int as coins;
}
message(0x7a308483) SellToken {
    country: Int as uint16;
    amount: Int as coins;
    seller: Address;
}
message(0x7a308484) BurnTokenInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    user: Address;
}
message(0x7a308485) DeployCountry {
    id: Int as uint16;
    jetton_content: Cell;
    nft_content: Cell;
    royalty_params: RoyaltyParams;
}
message(0x7a308486) ChangeTransactionFee {
    tx_fee: Int as uint16;
}
message(0x7a308487) ChangeFeeWallet {
    fee_wallet: Address;
}
message(0x7a308488) BatchAddUserHoldings {
    country: Int as uint16;
    user_amount: map<Address, Int>;
    length: Int as uint16;
}
message(0x7a308489) BatchRemoveUserHoldings {
    country: Int as uint16;
    user_amount: map<Address, Int>;
    length: Int as uint16;
}
message(0x7a30848a) ChangeAsymptote {
    country: Int as uint16;
    asymptote: Int;
}
message(0x7a30848b) ChangeScaleParam {
    country: Int as uint16;
    scale_param: Int;
}
message(0x7a30848c) ChangeTokenLockStatus {
    country: Int as uint16;
    status: Bool;
}
message(0x7a30848d) RedeemTokens {
    country: Int as uint16;
    amount: Int as coins;
    receiver: Address;
}
message(0x7a30848e) StakeTokens {
    country: Int as uint16;
    amount: Int as coins;
}
message(0x7a30848f) AttackCost {
    nonce: Int;
    country: Int as uint16;
    user_amount: map<Address, Int>;
}
// User Holding Messages
message(0x8a29df80) AddHoldings {
    query_id: Int as uint64;
    amount: Int as coins;
    user: Address;
}
message(0x8a29df81) RemoveHoldings {
    query_id: Int as uint64;
    amount: Int as coins;
    user: Address;
}
message(0x8a29df8f) BatchUpdateAsymptote {
    query_id: Int;
    country_asymptotes: map<Int as uint16, Int>;
    length: Int as uint16;
}
message(0x8a29df90) BatchUpdateScaleParam {
    query_id: Int;
    country_scale_params: map<Int as uint16, Int>;
    length: Int as uint16;
}
message(0x8a29df91) RemoveCountryHolding {
    country: Int as uint64;
    percentage: Int as uint32;
}
message(0x8a29df92) BatchRemoveCountryHolding {
    query_id: Int;
    country_percentage: map<Int as uint16, Int as uint32>;
    length: Int as uint16;
}
message(0x8a29df93) AddCountryHolding {
    country: Int as uint64;
    amount: Int as coins;
}
message(0x8a29df94) BatchAddCountryHolding {
    query_id: Int;
    country_amount: map<Int as uint16, Int>;
    length: Int as uint16;
}
message(0x8a29df95) MintCustomAttack {
    query_id: Int;
    country: Int as uint16;
    owner: Address;
}
message(0x8a29df96) MintCustomAttackInternal {
    query_id: Int;
    owner: Address;
}
message(0x8a29df97) WithdrawAllTon {
    query_id: Int;
}
message(0x8a29df98) ChangeGrowthRate {
    country: Int as uint16;
    growth_rate: Int;
}
message(0x8a29df99) BatchUpdateGrowthRate {
    query_id: Int;
    country_growth_rates: map<Int as uint16, Int>;
    length: Int as uint16;
}
message(0x8a29df9a) BatchDeployCountries {
    query_id: Int;
    countries: map<Int as uint16, CountryForDeployment>;
    length: Int as uint16;
}
message(0x8a29df9b) BatchMint {
    query_id: Int;
    mints: map<Int as uint16, TokenToMint>;
    length: Int as uint16;
}