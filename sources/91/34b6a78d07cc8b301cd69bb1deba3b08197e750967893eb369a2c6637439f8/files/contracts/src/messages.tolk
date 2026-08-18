import "quote-types"

struct NftItemInitAtDeployment {
    ownerAddress: address
    content: string
}

struct (0x484f5051) MintWithQuote {
    queryId: uint64
    quote: Cell<HopprQuote>
    signature: bits512
}

struct (0x484f5001) PauseMinting {
    queryId: uint64
}

struct (0x484f5002) UnpauseMinting {
    queryId: uint64
}

struct (0x484f5003) RotateSigner {
    queryId: uint64
    newPublicKey: uint256
}

struct (0x484f5004) RevealMetadata {
    queryId: uint64
    finalBaseUri: string
}

struct (0x484f5005) FreezeMetadata {
    queryId: uint64
}

struct (0x484f5006) PremintGiveaways {
    queryId: uint64
    quantity: uint16
}

struct (0x484f5007) TransferAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0x484f5008) PremintTreasury {
    queryId: uint64
    quantity: uint16
}

struct (0x484f5009) SetMerkleRoot {
    queryId: uint64
    newRoot: uint256
}

/// `proof` is a forward snake. Every cell stores one 256-bit sibling hash and
/// optionally references the next proof cell. Pair hashes are sorted.
struct (0x484f500a) ClaimWhitelist {
    queryId: uint64
    snapshotBalance: uint256
    proof: cell
}

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

struct QuoteConsumedEvent {
    quoteHash: uint256
    firstSerial: uint32
    quantity: uint16
}
