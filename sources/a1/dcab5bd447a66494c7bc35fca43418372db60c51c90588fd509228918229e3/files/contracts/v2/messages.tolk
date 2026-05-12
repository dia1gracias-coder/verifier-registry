
type ForwardPayloadRemainder = RemainingBitsAndRefs

struct (0x0f8a7ea5) AskToTransfer {
    queryId: uint64
    jettonAmount: coins
    transferRecipient: address
    sendExcessesTo: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: ForwardPayloadRemainder
}

struct (0x7362d09c) TransferNotificationForRecipient {
    queryId: uint64
    jettonAmount: coins
    transferInitiator: address?
    forwardPayload: ForwardPayloadRemainder
}

struct (0x178d4519) InternalTransferStep {
    queryId: uint64
    jettonAmount: coins
    transferInitiator: address?
    sendExcessesTo: address?
    forwardTonAmount: coins
    forwardPayload: ForwardPayloadRemainder
}

struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64
}

struct (0x595f07bc) AskToBurn {
    queryId: uint64
    jettonAmount: coins
    sendExcessesTo: address?
    customPayload: cell?
}

struct (0x7bdd97de) BurnNotificationForMinter {
    queryId: uint64
    jettonAmount: coins
    burnInitiator: address
    sendExcessesTo: address?
}

struct (0x2c76b973) RequestWalletAddress {
    queryId: uint64
    ownerAddress: address
    includeOwnerAddress: bool
}

struct (0xd1735400) ResponseWalletAddress {
    queryId: uint64
    jettonWalletAddress: address?
    ownerAddress: Cell<address>?
}

struct (0x00000015) MintNewJettons {
    queryId: uint64
    mintRecipient: address
    tonAmount: coins
    internalTransferMsg: Cell<InternalTransferStep>
}

struct (0x00000003) ChangeAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0x00000004) ChangeMinterContent {
    queryId: uint64
    newContent: cell
}

struct (0x10000001) SetBuyTax {
    queryId: uint64
    buyTaxPercent: uint8
}

struct (0x10000002) SetSellTax {
    queryId: uint64
    sellTaxPercent: uint8
}

struct (0x10000003) SetFeeWallet {
    queryId: uint64
    feeWalletAddress: address
}

struct (0x10000004) SetPaused {
    queryId: uint64
    paused: bool
}

struct (0x10000005) AddToWhitelist {
    queryId: uint64
    sellerAddress: address
}

struct (0x10000006) RemoveFromWhitelist {
    queryId: uint64
    sellerAddress: address
}

struct (0x10000007) SetWhitelistEnabled {
    queryId: uint64
    whitelistEnabled: bool
}

struct (0x10000008) AddDexPool {
    queryId: uint64
    dexPoolAddress: address
}

struct (0x10000009) RemoveDexPool {
    queryId: uint64
    dexPoolAddress: address
}

struct (0x1000000A) UpgradeCode {
    queryId: uint64
    newCode: cell
}

struct (0x10000020) TransferViaMinterRequest {
    queryId: uint64
    jettonAmount: coins
    senderOwnerAddress: address
    transferRecipient: address
    sendExcessesTo: address?
    forwardTonAmount: coins
    forwardPayload: ForwardPayloadRemainder
}

struct (0x10000021) UpdateWalletPermissions {
    queryId: uint64
    canSell: bool
}