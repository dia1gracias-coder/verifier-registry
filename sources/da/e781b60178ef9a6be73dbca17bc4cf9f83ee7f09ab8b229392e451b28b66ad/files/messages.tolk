import "storage"

const MIN_COLLECTION_MESSAGE_VALUE = ton("0.01")
const MIN_ITEM_DEPLOY_VALUE = ton("0.02")
const MIN_TONS_FOR_ITEM_STORAGE = ton("0.02")

struct ItemInitAtDeployment {
    ownerAddress: address
    postData: Cell<PostData>
}

struct (0x6d696e74) MintPost {
    queryId: uint64
    attachTonAmount: coins
    postData: Cell<PostData>
}

struct (0x63686164) ChangeAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0x2fcb26a2) RequestStaticData {
    queryId: uint64
}

struct (0x8b771735) ResponseStaticData {
    queryId: uint64
    itemIndex: uint256
    collectionAddress: address
}

struct (0x05138d91) NotificationForNewOwner {
    queryId: uint64
    oldOwnerAddress: address
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
    forwardPayload: RemainingBitsAndRefs
}

struct (0x75706474) UpdatePostData {
    queryId: uint64
    postData: Cell<PostData>
}
