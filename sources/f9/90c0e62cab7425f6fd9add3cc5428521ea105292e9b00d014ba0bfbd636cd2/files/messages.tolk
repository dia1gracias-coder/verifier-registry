import "types"

// Body the collection sends to a freshly deployed item to initialize it.
struct NftItemInitAtDeployment {
    ownerAddress: address
    content: string
}

// --- Collection: incoming ---

// Public mint: anyone who attaches >= mintPrice receives the next NFT.
struct (0x4d696e74) Mint {
    queryId: uint64
}

// Admin-only free mint to an arbitrary address (rewards / giveaways).
struct (0x00000007) AdminMint {
    queryId: uint64
    recipient: address
}

struct (0x693d3950) RequestRoyaltyParams {
    queryId: uint64
}

struct (0x00000003) ChangeCollectionAdmin {
    queryId: uint64
    newAdminAddress: address
}

// Update off-chain content URLs (e.g. switch host to bunny.net later).
struct (0x00000004) ChangeCollectionContent {
    queryId: uint64
    newContent: Cell<CollectionContent>
}

struct (0x00000005) ChangeMintPrice {
    queryId: uint64
    newMintPrice: coins
}

// Send accumulated mint revenue to the admin (keeps storage reserve).
struct (0x00000006) WithdrawFunds {
    queryId: uint64
}

// --- Collection: outgoing ---

struct (0xa8cb00ad) ResponseRoyaltyParams {
    queryId: uint64
    royaltyParams: RoyaltyParams
}

// --- Item ---

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
