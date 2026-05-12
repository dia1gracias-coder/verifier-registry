type ForwardPayloadRemainder = RemainingBitsAndRefs

const SELL_TAX_BPS = 1000
const BUY_TAX_BPS = 1000
const SELL_TAX_DENOMINATOR = 10000

const STONFI_V2_SWAP_OP = 0x6664de2a
const DEDUST_JETTON_SWAP_OP = 0xe3a0d482

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
    transferInitiator: address
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

struct (0x642b7d07) MintNewJettons {
    queryId: uint64
    mintRecipient: address
    tonAmount: coins
    internalTransferMsg: Cell<InternalTransferStep>
}

struct (0x6501f354) ChangeMinterAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0xfb88e119) ClaimMinterAdmin {
    queryId: uint64
}

struct (0x7431f221) DropMinterAdmin {
    queryId: uint64
}

struct (0x2508d66a) UpgradeMinterCode {
    queryId: uint64
    newData: cell
    newCode: cell
}

struct (0xcb862902) ChangeMinterMetadata {
    queryId: uint64
    newMetadata: cell
}

struct (0x42545953) SetWalletBuyTaxSource {
    queryId: uint64
    walletOwner: address
    enabled: bool
}

struct (0x42545957) SetBuyTaxSourceForWallet {
    queryId: uint64
    enabled: bool
}

struct (0xd372158c) TopUpTons {}

fun ForwardPayloadRemainder.checkIsCorrectTlbEither(self) {
    var mutableCopy = self;
    if (mutableCopy.loadMaybeRef() != null) {
        mutableCopy.assertEnd();
    }
}

fun isDexSwapOp(op: int): bool {
    return op == STONFI_V2_SWAP_OP || op == DEDUST_JETTON_SWAP_OP;
}

fun slice.startsWithDexSwapOp(self): bool {
    if (self.remainingBitsCount() >= 32) {
        return isDexSwapOp(self.preloadUint(32));
    }

    if (
        self.remainingBitsCount() == 1 && self.preloadUint(1) == 1 && self.remainingRefsCount() == 1
    ) {
        var wrappedPayload = self;
        wrappedPayload.loadUint(1);
        return wrappedPayload.loadRef().beginParse().startsWithDexSwapOp();
    }

    return false;
}

fun ForwardPayloadRemainder.isDexSwapPayload(self): bool {
    var payload = self;
    val payloadRef = payload.loadMaybeRef();
    if (payloadRef != null) {
        payload.assertEnd();
        return payloadRef.beginParse().startsWithDexSwapOp();
    }

    return payload.startsWithDexSwapOp();
}

fun calcSellTaxAmount(jettonAmount: coins): coins {
    return jettonAmount * SELL_TAX_BPS / SELL_TAX_DENOMINATOR;
}

fun calcBuyTaxAmount(jettonAmount: coins): coins {
    return jettonAmount * BUY_TAX_BPS / SELL_TAX_DENOMINATOR;
}
