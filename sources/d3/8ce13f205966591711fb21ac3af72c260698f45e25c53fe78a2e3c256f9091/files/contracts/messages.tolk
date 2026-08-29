// Source: https://github.com/ton-blockchain/acton-contracts/blob/master/nft-v1.1/contracts/messages.tolk
// Delta vs standard: contentHash in NftItemInitAtDeployment. Minter messages are extra.

import "types"

struct NftItemInitAtDeployment {
    ownerAddress: address
    contentHash: uint256
    content: string
}

struct (0x693d3950) RequestRoyaltyParams {
    queryId: uint64
}

struct (0xa8cb00ad) ResponseRoyaltyParams {
    queryId: uint64
    royaltyParams: RoyaltyParams
}

struct (0x00000001) DeployNft {
    queryId: uint64
    itemIndex: uint64
    attachTonAmount: coins
    initParams: Cell<NftItemInitAtDeployment>
}

struct (0x00000002) BatchDeployNfts {
    queryId: uint64
    deployList: map<uint64, BatchDeployDictItem>
}

struct BatchDeployDictItem {
    attachTonAmount: coins
    initParams: Cell<NftItemInitAtDeployment>
}

struct (0x00000003) ChangeCollectionAdmin {
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

// --- Minter user messages ---

struct PermitBind {
    minterAddress: address
    collectionAddress: address
    to: address
}

struct MintPermit {
    domain: uint32
    bind: Cell<PermitBind>
    validUntil: uint32
    seqno: uint64
    itemIndex: uint64
    contentHash: uint256
    individualContent: string
}

struct (0x4D494E54) MintNft {
    queryId: uint64
    permit: Cell<MintPermit>
    signature: bits512
}

// --- Minter admin messages ---

struct (0x00000020) SetMinterAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0x00000021) SetSignerKey {
    queryId: uint64
    newSignerPublicKey: uint256
}

struct (0x00000022) SetGasParams {
    queryId: uint64
    gasParams: GasParams
}

struct (0x00000023) SetPaused {
    queryId: uint64
    paused: bool
}

struct (0x00000024) SetMinterCode {
    queryId: uint64
    newCode: cell
}

struct (0x00000029) ProxyChangeCollectionAdmin {
    queryId: uint64
    newAdminAddress: address
}
