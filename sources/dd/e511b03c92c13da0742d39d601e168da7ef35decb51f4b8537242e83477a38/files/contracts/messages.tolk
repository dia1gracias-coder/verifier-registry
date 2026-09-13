

struct (0b0) PayloadInline {
    value: RemainingBitsAndRefs
}

struct (0b1) PayloadInRef {
    value: Cell<RemainingBitsAndRefs>
}

struct (0x5fcc3d14) AskToChangeOwnership {
    queryId: uint64
    newOwnerAddress: address
    sendExcessesTo: address?
    customPayload: cell?
    forwardTonAmount: coins
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}

struct (0x05138d91) NotificationForNewOwner {
    queryId: uint64
    oldOwnerAddress: address?
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}

struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64
}

struct (0x2fcb26a2) RequestStaticData {
    queryId: uint64
}

struct (0x8b771735) ResponseStaticData {
    queryId: uint64
    itemIndex: uint256
    collectionAddress: address
}


struct (0x4eb1f0f9) ChangeDnsRecord {
    queryId: uint64
    key: uint256
    value: cell?
}


struct (0x0f8a7ea5) JettonTransfer {
    queryId: uint64
    amount: coins
    destination: address
    sendExcessesTo: address?
    customPayload: cell?
    forwardTonAmount: coins
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}

struct (0x595f07bc) JettonBurn {
    queryId: uint64
    amount: coins
    sendExcessesTo: address?
    customPayload: cell?
}

struct (0x7362d09c) JettonTransferNotification {
    queryId: uint64
    amount: coins
    senderAddress: address
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: RemainingBitsAndRefs
}


struct (0x67726d01) RelayBid {
    queryId: uint64
    bidder: address
    amount: coins
    domain: cell
    grmWallet: address
}

struct (0x67726d02) RequestFunds {
    queryId: uint64
    itemIndex: uint256
    amount: coins
    bidder: address
}

struct (0x67726d03) RejectBid {
    queryId: uint64
    itemIndex: uint256
    amount: coins
    bidder: address
}

struct (0x67726d04) FinalizeAuction {
    queryId: uint64
}


struct (0x67726d12) RescueJettons {
    queryId: uint64
    amount: coins
    walletAddress: address
    to: address
}

struct (0x67726d13) WithdrawTon {
    queryId: uint64
}

struct (0x67726d14) ChangeOwner {
    queryId: uint64
    newOwnerAddress: address?
}

struct (0x67726d15) ChangeContent {
    queryId: uint64
    newContent: cell
}

