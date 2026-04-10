struct (0x00000000) CommentMessage {
    comment: RemainingBitsAndRefs
}

// Outgoing: NFT transfer
struct (0x5fcc3d14) NftTransfer {
    queryId: uint64
    newOwner: address
    responseAddress: address
    customPayload: cell? = null
    forwardAmount: coins = 0 as coins
    forwardPayload: cell? = null
}

// Outgoing: jetton transfer via our jetton wallet
struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address
    customPayload: cell? = null
    forwardTonAmount: coins = 0 as coins
    forwardPayload: cell? = null
}

// Incoming: NFT ownership assigned to us
struct (0x05138d91) OwnershipAssigned {
    queryId: uint64
    prevOwner: address
    forwardPayload: RemainingBitsAndRefs
}

// Incoming: jetton wallet notifies about received jettons
struct (0x7362d09c) JettonTransferNotification {
    queryId: uint64
    amount: coins
    sender: address
    forwardPayload: RemainingBitsAndRefs
}

// Incoming: emergency from marketplace (complete offers only)
struct (0x0000022B) EmergencyMessage {
    payload: cell
}

// Incoming: cancel offer (op=3)
struct (0x00000003) CancelOfferOp {
    rest: RemainingBitsAndRefs
}

// Incoming: deploy offer smc using TON
struct (0x664c0905) DeployTonOp {
    payload: RemainingBitsAndRefs
}

// Incoming: set jetton wallet address with signature verification
struct (0xfb5dbf47) DeployJettonOp {
    signature: bits512
    payload: cell
}

type OfferMessage =
    | CommentMessage
    | OwnershipAssigned
    | JettonTransferNotification
    | EmergencyMessage
    | CancelOfferOp
    | DeployJettonOp
    | DeployTonOp
