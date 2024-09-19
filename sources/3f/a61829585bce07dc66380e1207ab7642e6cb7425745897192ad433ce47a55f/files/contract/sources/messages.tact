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
message(0x235caf52) JettonCallTo {

}
