message SellFromWallet {
    sellAmount: Int as coins;
}

message UpdateTokenData {
    owner: Address?;
    launchFee: Int?;
    orderFeeBps: Int?;
}

message(0xfcf9e58f) DexProvideLpV2 {
    otherTokenWallet: Address;
    refundAddress: Address;
    excessesAddress: Address;
    additionalData: Cell;
}

message(0xfcf9e58f) DexProvideLpV1 {
    otherTokenWallet: Address;
    minLpOut: Int as coins;
}

message(0xf8a7ea5) TokenTransferPton1 {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Cell?; 
}

struct DexProvideLpExtraData {
    minLpOut: Int as coins;
    receiverAddress: Address;
    bothPositive: Bool;
    forwardGas: Int as coins;
    customPayload: Cell?;
}

message ProcessFee {

}

message GasExcess {
    
}


message(0x7362d09c) TokenNotificationPTon {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Cell?;
}

message TokenTransferInternalCell {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    response_destination: Address?;
    forward_ton_amount: Int as coins;
    forward_payload: Cell?;
}

message SellOrder {
    sellSize: Int as coins;
    amountOutMin: Int as coins;
    seller: Address?;
}


message Deploy {
    tokenDeployer: Address?;
}