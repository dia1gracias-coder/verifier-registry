type ForwardPayloadRemainder = RemainingBitsAndRefs

struct (0b0) PayloadInline {
    value: RemainingBitsAndRefs
}

struct (0b1) PayloadInRef {
    value: Cell<RemainingBitsAndRefs>
}

struct (0x0f8a7ea5) AskToTransfer {
    queryId: uint64
    jettonAmount: coins
    transferRecipient: address
    sendExcessesTo: address?
    customPayload: cell?
    forwardTonAmount: coins
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: ForwardPayloadRemainder
}

struct (0x7362d09c) TransferNotificationForRecipient {
    queryId: uint64
    jettonAmount: coins
    transferInitiator: address?
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: ForwardPayloadRemainder
}

struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64
}

struct (0x096819ff) SetPaused {
    paused: bool
}

struct (0x39a55555) SetJettonWallets {
    usdtWallet: address
    hooWallet: address
}

struct (0xbdf4ceaa) WithdrawUnsold {
    amount: coins
    destination: address
}

struct (0xd372158c) TopUpTons {}

struct (0xc87e919d) WithdrawUsdt {
    queryId: uint64
    amount: coins
}

struct (0x4a6f73e2) BuyWithTon {
    queryId: uint64
}

struct (0x7a5b1f9c) SetTonPrice {
    priceUsdtMicro: coins
}

struct (0x2c8e4d1a) FlushToTreasury {
    queryId: uint64
}

struct (0x6b3f9a7e) WithdrawTon {
    queryId: uint64
    amount: coins
}

fun emptyForwardPayload(): slice {
    return beginCell().storeUint(0, 1).endCell().beginParse();
}
