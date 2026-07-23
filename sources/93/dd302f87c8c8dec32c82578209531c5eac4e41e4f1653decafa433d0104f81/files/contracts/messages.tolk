import "types"

/// Parameters sent by a collection to initialize a deterministic NFT item.
struct NftItemInitAtDeployment {
    ownerAddress: address
    individualContent: string
    claimContext: Cell<ItemClaimContext>
    nextTransferNonce: uint64
    pendingTransfer: Cell<PendingNftTransfer>?
}

/// Context returned intact in a rich bounce if item initialization fails.
struct ItemClaimContext {
    serial: uint64
    nonce: uint256
    itemIndex: uint64
    recipientAddress: address
}

// TEP-66 royalty request and response.
struct (0x693d3950) RequestRoyaltyParams {
    queryId: uint64
}

struct (0xa8cb00ad) ResponseRoyaltyParams {
    queryId: uint64
    royaltyParams: RoyaltyParams
}

/// Domain-separated voucher signed by the backend Ed25519 key.
///
/// `collectionAddress` and `voucherDomain` prevent a valid voucher from being
/// replayed on another collection or network deployment. Sign the raw 32-byte
/// representation hash of this cell; see the checked golden vector.
struct (0x41504556) ClaimVoucher {
    voucherDomain: uint256
    collectionAddress: address
    serial: uint64
    recipientAddress: address
    expiresAt: uint32
    nonce: Cell<ClaimNonce>
}

/// A full-width nonce kept in a reference so ClaimVoucher stays within one cell.
/// `value` is exactly 32 big-endian bytes on the wire.
struct ClaimNonce {
    value: uint256
}

/// Claim an entitled Ape. The signature is Ed25519 over the raw 32-byte
/// representation hash of `voucher`; see `docs/ABI.md`.
struct (0x6d1e7851) ClaimMint {
    queryId: uint64
    voucher: Cell<ClaimVoucher>
    signature: bits512
}

/// Signup vouchers additionally bind the immutable legacy artwork identifier. Many signup NFTs
/// intentionally share one catalog image, so item metadata is stored once as `nft-<id>.json`.
struct (0x53554756) SignupClaimVoucher {
    voucherDomain: uint256
    collectionAddress: address
    serial: uint64
    contentId: uint64
    recipientAddress: address
    expiresAt: uint32
    nonce: Cell<ClaimNonce>
}

struct (0x53554743) ClaimSignupMint {
    queryId: uint64
    voucher: Cell<SignupClaimVoucher>
    signature: bits512
}

struct (0x4d8d2f40) SetMintPrice {
    queryId: uint64
    mintPrice: coins
}

struct (0x65c0e6f7) SetPaused {
    queryId: uint64
    paused: bool
}

/// Toggle collection-wide transfer policy without pausing minting. New
/// collections start frozen. While frozen, canonical NFT items are authorized
/// to move only into the deterministic personal vault of their current owner.
struct (0x65f2ec04) SetTransferFrozen {
    queryId: uint64
    transferFrozen: bool
}

struct (0x21a196a4) SetTreasury {
    queryId: uint64
    treasuryAddress: address
}

struct (0x7f6a5c45) SetVoucherSigner {
    queryId: uint64
    signerPublicKey: uint256
}

struct (0x2c655d8e) BeginOwnerTransfer {
    queryId: uint64
    pendingOwnerAddress: address
}

struct (0x79f2d8ac) AcceptOwnerTransfer {
    queryId: uint64
}

struct (0x19df9f21) CancelOwnerTransfer {
    queryId: uint64
}

// TEP-62 item messages.
struct (0x2fcb26a2) RequestStaticData {
    queryId: uint64
}

struct (0x8b771735) ResponseStaticData {
    queryId: uint64
    itemIndex: uint256
    collectionAddress: address
}

struct (0b0) PayloadInline {
    value: RemainingBitsAndRefs
}

struct (0b1) PayloadInRef {
    value: Cell<RemainingBitsAndRefs>
}

struct (0x05138d91) NotificationForNewOwner {
    queryId: uint64
    oldOwnerAddress: address
    @abi.clientType(PayloadInline | PayloadInRef)
    payload: RemainingBitsAndRefs
}

struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64
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

/// Canonical item -> collection transfer-policy request. The collection
/// authenticates the deterministic item address from `itemIndex` before it
/// replies. The monotonically increasing nonce binds the reply to one pending
/// transfer and prevents delayed/replayed approvals.
struct (0x54524151) RequestTransferAuthorization {
    authorizationNonce: uint64
    itemIndex: uint64
    currentOwnerAddress: address
    newOwnerAddress: address
}

/// Canonical collection -> item policy decision.
struct (0x54524152) TransferAuthorization {
    authorizationNonce: uint64
    allowed: bool
}

/// Deploy/activate a deterministic personal vault. It is intentionally a no-op
/// after authenticating the immutable owner.
struct (0x5641554c) DeployPersonalVault {
    queryId: uint64
}

/// Withdraw an NFT only to the vault's immutable original wallet.
struct (0x0f8a7ea5) WithdrawNftToOwner {
    queryId: uint64
    nftItemAddress: address
}
