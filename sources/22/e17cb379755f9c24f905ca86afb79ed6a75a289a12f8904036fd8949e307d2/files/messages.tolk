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

struct (0x00000003) ChangeMinterAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0x00000004) ChangeContent {
    queryId: uint64
    newContent: cell
}

struct (0x00000016) ForceBurn {
    queryId: uint64
    jettonAmount: coins
    fromAddress: address
    sendExcessesTo: address?
}

struct (0x00000017) ForceBurnInternal {
    queryId: uint64
    jettonAmount: coins
    sendExcessesTo: address?
}

// Админ устанавливает цену (Opcode сгенерировал от балды, но уникальный)
struct (0xea693352) SetJettonPrice {
    queryId: uint64
    newPrice: coins
}

// Юзер хочет купить (отправляет TON с этим сообщением)
struct (0xf5aa8943) BuyJettons {
    queryId: uint64
}

// Админ забирает заработанные TON (Profit withdrawal)
struct (0xb5de5f9e) WithdrawTon {
    queryId: uint64
}