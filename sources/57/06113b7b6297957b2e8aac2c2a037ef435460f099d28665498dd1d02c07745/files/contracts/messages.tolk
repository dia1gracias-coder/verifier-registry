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

struct (0xd372158c) TopUpTons {}

/// Backend-signed withdrawal entitlement. The per-wallet monotonic sequence
/// provides replay protection without an ever-growing dictionary in the minter.
struct ApeClaimDetails {
    recipientAddress: address
    jettonAmount: coins
    claimSequence: uint64
    expiresAt: uint32
}

struct (0x41504556) ApeClaimVoucher {
    voucherDomain: uint256
    minterAddress: address
    details: Cell<ApeClaimDetails>
}

struct (0x41504543) ClaimApeJettons {
    queryId: uint64
    voucher: Cell<ApeClaimVoucher>
    signature: bits512
}

struct (0x41504549) ClaimInternalTransfer {
    queryId: uint64
    jettonAmount: coins
    claimSequence: uint64
    payerAddress: address
    serviceFee: coins
    overpayment: coins
}

struct ClaimAcknowledgementContext {
    jettonAmount: coins
    claimSequence: uint64
    recipientAddress: address
    payerAddress: address
    serviceFee: coins
    overpayment: coins
}

struct (0x41504541) ClaimMintAcknowledged {
    queryId: uint64
    context: Cell<ClaimAcknowledgementContext>
}

struct (0x41504550) RequestTransferPolicy {
    queryId: uint64
    walletOwnerAddress: address
}

struct (0x41504551) TransferPolicyDecision {
    queryId: uint64
    allowed: bool
}

struct (0x41504601) SetApeServiceFee {
    queryId: uint64
    serviceFee: coins
}

struct (0x41504602) SetApeClaimsPaused {
    queryId: uint64
    paused: bool
}

struct (0x41504603) SetApeTransfersFrozen {
    queryId: uint64
    frozen: bool
}

struct (0x41504604) SetApeTreasury {
    queryId: uint64
    treasuryAddress: address
}

struct (0x41504605) SetApeVoucherSigner {
    queryId: uint64
    signerPublicKey: uint256
}

/// Irreversible. Admin remains available for transfer freeze and metadata.
struct (0x41504606) CloseApeMintingForever {
    queryId: uint64
}

/// Admin-only withdrawal of an explicit amount of accumulated TON. The
/// destination is deliberately fixed to the configured APE treasury.
struct (0x41504607) WithdrawApeTreasuryTons {
    queryId: uint64
    amount: coins
}

fun ForwardPayloadRemainder.checkIsCorrectTlbEither(self) {
    var mutableCopy = self;
    if (mutableCopy.loadMaybeRef() != null) {
        mutableCopy.assertEnd();
    }
}
