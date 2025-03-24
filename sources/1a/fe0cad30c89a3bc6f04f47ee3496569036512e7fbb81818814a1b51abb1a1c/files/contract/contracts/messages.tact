struct JettonData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    wallet_code: Cell;
}

struct JettonWalletData {
    balance: Int;
    owner: Address;
    master: Address;
    code: Cell;
}

struct FeeData {
    owner: Address;
    numerator: Int as uint64;
    denominator: Int as uint64;
}

message Test {
    query_id: Int as uint64;
    id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x0f8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x178d4519) TokenTransferInternal {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) TokenBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}
message(0x7bdd97de) TokenBurnNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
    send_excess: Bool;
}

message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}

message ChangeFeeExcesses {
    query_id: Int as uint64;
}

message(0x2c76b973) ProvideWalletAddress {
    query_id: Int as uint64;
    owner_address: Address;
    include_address: Bool;
}

message(0xd1735400) TakeWalletAddress {
    query_id: Int as uint64;
    wallet_address: Address;
    owner_address: Slice as remaining;
}

message(0x8e7669fc) ChangeFee {
    numerator: Int as uint64;
    denominator: Int as uint64;
}

message(0xe0c12dc2) TokenTransferWithFee {
    query_id: Int as uint64;
    numerator: Int as uint64;
    denominator: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message Mint {
    amount: Int;
    receiver: Address;
}

message(0x5fcc3d14) NftTransfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0xa98f9950) NftOwnershipAssigned {
    query_id: Int as uint64;
    index: Int as uint256;
    prev_owner: Address;
    BIP_value: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x6f89f5e3) NftExcesses {
    query_id: Int as uint64;
}

message(0x2fcb26a2) NftGetStaticData {
    query_id: Int as uint64;
}

message(0x8b771735) NftReportStaticData {
    query_id: Int as uint64;
    index: Int as uint256;
    owner: Address;
    collection: Address;
    BIP_value: Int as coins;
}

message(0x72371923) NftDestroy {
    query_id: Int as uint64;
    response_destination: Address;
}

message(0x72cd2391) NftDeploy {
    query_id: Int as uint64;
    index: Int as uint256;
    owner: Address;
    content: Cell;
    BIP_value: Int as coins;
}

message(0xf6a53bb4) RequestNftDeploy {
    query_id: Int as uint64;
    amount: Int as coins;
    owner: Address;
    content: Cell;
    BIP_value: Int as coins;
}