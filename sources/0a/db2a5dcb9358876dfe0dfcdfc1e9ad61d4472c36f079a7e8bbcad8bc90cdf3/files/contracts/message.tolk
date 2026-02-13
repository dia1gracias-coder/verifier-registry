import "constant"

// ============================================
// OWNER MANAGEMENT MESSAGES
// ============================================
struct (0x00020001) MessageAddOwner {
    queryId: uint64
    ownerAddress: address
}

struct (0x00020002) MessageRemoveOwner {
    queryId: uint64
    ownerAddress: address
}

struct (0x00020003) MessageDisableOwner {
    queryId: uint64
    ownerAddress: address
}

struct (0x00020004) MessageEnableOwner {
    queryId: uint64
    ownerAddress: address
}

type AllowedOwnerMessages =
    | MessageAddOwner
    | MessageRemoveOwner
    | MessageDisableOwner
    | MessageEnableOwner

// ============================================
// MASTER CONTRACT MESSAGES
// ============================================
struct (0x00060001) MessagePauseMaster {
    queryId: uint64
}

struct (0x00060002) MessageUnpauseMaster {
    queryId: uint64
}

type AllowedMasterMessages = MessagePauseMaster | MessageUnpauseMaster

// ============================================
// NFT COLLECTION MESSAGES
// ============================================
struct (0x00050001) MessageMintNft {
    queryId: uint64
    itemOwnerAddress: address
    itemContent: cell
}

struct (0x00050002) MessageBatchMintNft {
    queryId: uint64
    batchSize: uint32
    items: RemainingBitsAndRefs // Contains array of (itemOwnerAddress, itemContent) pairs
}

struct (0x00050008) MessageBatchPauseNft {
    queryId: uint64
    itemIndices: RemainingBitsAndRefs // Array of uint64 item indices
}

struct (0x00050009) MessageBatchUnpauseNft {
    queryId: uint64
    itemIndices: RemainingBitsAndRefs // Array of uint64 item indices
}

struct (0x0005000A) MessageWithdrawCollection {
    queryId: uint64
    amount: coins  // 0 = withdraw all
}

// Collection-forwarded revoke: owner sends to collection, collection forwards to NFT item
struct (0x0005000C) MessageForwardRevoke {
    queryId: uint64
    itemIndex: uint64
    newOwner: address
}

// Collection-forwarded transfer: owner sends to collection, collection forwards to NFT item
struct (0x0005000D) MessageForwardCollectionTransfer {
    queryId: uint64
    itemIndex: uint64
    newOwner: address
}

// Authorized admin management (temporary for testing, will be replaced by governance)
struct (0x0005000E) MessageAddAuthorizedAdmin {
    queryId: uint64
    adminAddress: address
}

struct (0x0005000F) MessageRemoveAuthorizedAdmin {
    queryId: uint64
    adminAddress: address
}

type AllowedCollectionMessages =
    | MessageMintNft
    | MessageBatchMintNft
    | MessageBatchPauseNft
    | MessageBatchUnpauseNft
    | MessageWithdrawCollection
    | MessageForwardRevoke
    | MessageForwardCollectionTransfer
    | MessageAddAuthorizedAdmin
    | MessageRemoveAuthorizedAdmin

// ============================================
// NFT ITEM MESSAGES
// ============================================
struct (0x00050004) MessagePauseNft {
    queryId: uint64
}

struct (0x00050005) MessageUnpauseNft {
    queryId: uint64
}

struct (0x00050006) MessageRevokeNft {
    queryId: uint64
    newOwner: address
}

struct (0x00050007) MessageCollectionTransfer {
    queryId: uint64
    newOwner: address
}

// TEP-62 Standard Transfer
// Using RemainingBitsAndRefs for forwardPayload - the official Tolk pattern!
struct (0x5fcc3d14) MessageTransfer {
    queryId: uint64
    newOwner: address
    responseDestination: address
    customPayload: cell?
    forwardAmount: coins
    forwardPayload: RemainingBitsAndRefs // Contains all remaining bits/refs!
}

// TEP-62 Burn
struct (0x595f07bc) MessageBurn {
    queryId: uint64
    responseDestination: address
}

// Add to message.tolk
struct (0x0005000B) MessageWithdrawItem {
    queryId: uint64
}


type AllowedNftItemMessages =
    | MessagePauseNft
    | MessageUnpauseNft
    | MessageRevokeNft
    | MessageCollectionTransfer
    | MessageTransfer
    | MessageBurn
    | MessageWithdrawItem
