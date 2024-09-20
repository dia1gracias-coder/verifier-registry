struct ContractData {
    owner: Address;
    superOperator: Address;
    jettonMasterAddress: Address;
    jettonWalletAddress: Address;
}
message(0x178d4519) Operation {
    query_id: Int as uint64;
    jetton_amount: Int as coins;
    from_address: Address;
    response_address: Address;
    forward_ton_amount: Int as coins;
    no_forward: Bool;
}
message(0x642b7d07) JettonMint {
    query_id: Int as uint64;
    to_address: Address;
    ton_amount: Int as coins;
    operation: Operation;
}
message UpdateContractOwnerAddress {
    address: Address;
}
message UpdateSuperOperatorAddress {
    address: Address;
}
message UpdateJettonMasterAddress {
    address: Address;
}
message UpdateJettonWalletAddress {
    address: Address;
}
message(0xfc708bd2) Mint {
    amount: Int;
    receiver: Address;
}
message UpdateJettonOwnerAddress{
    address: Address;
}
message(0x6ba59489) UpdateOwnerAddress {
    address: Address;
}
struct JettonData {
    total_supply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell;
    wallet_code: Cell;
}
message UpdateJettonData{
    data: JettonData;
}
message(0xd53276db) TokenExcesses {
    query_id: Int as uint64;
}
message(0x595f07bc) TokenBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}
message(0x0f8a7ea5) JettonTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}
message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}
struct SetStatus {
    query_id: Int as uint64;
    status: Int as uint64;
}
struct Burn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address?;
    custom_payload: Cell?;
}
struct Transfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}
struct MasterMsg {
    sum_type: String;
    set_status: SetStatus;
    burn: Burn;
    transfer: Transfer;
}
message(0x235caf52) JettonCallTo {
    query_id: Int as uint64;
    to_address: Address;
    ton_amount: Int as coins;
    master_msg: MasterMsg;
}
message(0x6501f354) JettonChangeAdmin {
    query_id: Int as uint64;
    new_admin_address: Address;
}
