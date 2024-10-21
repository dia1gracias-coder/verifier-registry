struct JettonWalletData {
    balance: Int;//amount of jettons on wallet
    owner: Address;//address of wallet owner
    master: Address;//address of jetton master
    code: Cell;// code of the jetton wallet contract
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;//arbitrary request number
    amount: Int as coins;//amount of transferred jettons in elementary units
    destination: Address;// address of the new owner of the jettons
    responseDestination: Address?;//address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins.
    customPayload: Cell?;//optional custom data (which is used by either sender or receiver jetton wallet for inner logic)
    forwardTonAmount: Int as coins;//the amount of nanotons to be sent to the destination address
    forwardPayload: Cell?;//custom data that should be sent to the destination address
}

message(0x178d4519) TokenTransferInternal {
    queryId: Int as uint64;//arbitrary request number
    amount: Int as coins;//amount of transferred jettons in elementary units
    from: Address;//address of wallet owner
    responseDestination: Address?;//address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins.
    forwardTonAmount: Int as coins;//the amount of nanotons to be sent to the destination address
    forwardPayload: Cell?;//custom data that should be sent to the destination address
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;//arbitrary request number
    amount: Int as coins;//amount of transferred jettons in elementary units
    from: Address;//address of wallet owner
    forwardPayload: Cell?;//custom data that should be sent to the destination address
}

message(0x595f07bc) TokenBurn {
    queryId: Int as uint64;//arbitrary request number
    amount: Int as coins;//amount of burned jettons
    responseDestination: Address?;//address where to send a response with confirmation of a successful burn and the rest of the incoming message coins
    customPayload: Cell?;//optional custom data
}

message(0x7bdd97de) TokenBurnNotification {
    queryId: Int as uint64;//arbitrary request number
    amount: Int as coins;//amount of burned jettons
    sender: Address;//address of wallet owner
    responseDestination: Address?;//address where to send a response with confirmation of a successful burn and the rest of the incoming message coins
}

message(0xd53276db) TokenExcesses {
    queryId: Int as uint64;//arbitrary request number
}

message TokenUpdateContent {
    content: Cell;
}

// take_wallet_address#d1735400
// queryId:uint64 wallet_address:MsgAddress owner_address:(Maybe ^MsgAddress) = InternalMsgBody;
message(0xd1735400) TakeWalletAddress {
    queryId: Int as uint64;
    walletAddress: Address;
    ownerAddress: Slice as remaining;
}
