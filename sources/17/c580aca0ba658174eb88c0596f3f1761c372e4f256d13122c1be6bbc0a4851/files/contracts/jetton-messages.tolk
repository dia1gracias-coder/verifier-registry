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

struct (0x178d4519) InternalTransferStep {
    queryId: uint64
    jettonAmount: coins
    transferInitiator: address?
    sendExcessesTo: address?
    forwardTonAmount: coins
    @abi.clientType(PayloadInline | PayloadInRef)
    forwardPayload: ForwardPayloadRemainder
}

// Extension used by protocol-owned wallets: when the recipient wallet rejects
// an InternalTransferStep, the sending wallet restores its Jetton balance and
// reports the exact failed transfer to its owner.  TEP-74 transfers themselves
// remain unchanged; consumers that do not understand this receipt simply never
// receive one because it is sent only to the wallet owner.
struct (0x4a544246) JettonTransferFailed {
    queryId: uint64
    jettonAmount: coins
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

// The standard opcode is retained. FixedSupplyJettonMinter narrows the semantics to one full mint.
struct (0x642b7d07) MintNewJettons {
    queryId: uint64
    mintRecipient: address
    tonAmount: coins
    internalTransferMsg: Cell<InternalTransferStep>
}

struct (0xfd8caa08) FreezeMinting {
    queryId: uint64
}

struct (0x47e053ff) ReserveReady {
    queryId: uint64
    reserveAmount: coins
}

struct (0xd372158c) TopUpTons {}

fun ForwardPayloadRemainder.checkIsCorrectTlbEither(self) {
    var mutableCopy = self;
    if (mutableCopy.loadMaybeRef() != null) {
        mutableCopy.assertEnd();
    }
}
