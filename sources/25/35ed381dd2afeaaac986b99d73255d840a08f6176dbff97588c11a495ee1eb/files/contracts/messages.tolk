import "types"

struct (0x4e4d0002) InitializeNameNft {
    queryId: uint64
    nameHash: uint256
    ownerAddress: address
    category: uint2
    mintPrice: coins
    mintedAt: uint64
    name: string
    content: Cell<SnakeString>
}

struct (0x4e4d0003) MintAcknowledged {
    queryId: uint64
    nameHash: uint256
}

struct (0x4e4d0006) MintReservedName {
    queryId: uint64
    recipientAddress: address
    name: string
}

struct (0x4e4d0007) MintPublicName {
    queryId: uint64
    pricingVersion: uint32
    maxPrice: coins
    recipientAddress: address
    name: string
}

struct (0x4e4d0009) RetryFinalizeMint {
    queryId: uint64
    name: string
}

struct (0x4e4d000a) RequestMintAcknowledgement {
    queryId: uint64
    nameHash: uint256
    retryCaller: address
}

struct (0x4e4d000b) ClaimFailedMintRefund {
    queryId: uint64
    name: string
}

struct (0x4e4d0010) ProposeConfigUpdate {
    queryId: uint64
    action: cell
}

struct (0x4e4d0011) ExecuteConfigUpdate {
    queryId: uint64
    proposalId: uint256
}

struct (0x4e4d0012) CancelConfigUpdate {
    queryId: uint64
    proposalId: uint256
}

struct (0x4e4d0013) SetMintPaused {
    queryId: uint64
    paused: bool
}

struct (0x4e4d0014) ProposeCollectionAdmin {
    queryId: uint64
    newAdminAddress: address
}

struct (0x4e4d0015) AcceptCollectionAdmin {
    queryId: uint64
}

struct (0x4e4d0016) CancelCollectionAdmin {
    queryId: uint64
}

struct (0x4e4d0030) LoadInitialCatalogEntry {
    queryId: uint64
    index: uint32
    status: uint2
    price: coins
    reservedFor: address?
    name: string
}

struct (0x4e4d0031) FinalizeInitialCatalog {
    queryId: uint64
}

struct (0x4e4d0101) UpdateCatalogEntryAction {
    status: uint2
    price: coins
    reservedFor: address?
    name: string
}

struct (0x4e4d0102) UpdateBasePricesAction {
    prices: Cell<NamePrices>
}

struct (0x4e4d0103) UpdateTreasuryAction {
    treasuryAddress: address
}

struct (0x4e4d0104) UpdateItemDeployValueAction {
    itemDeployValue: coins
}

struct (0x4e4d0105) UpdateRoyaltyAction {
    royaltyParams: Cell<RoyaltyParams>
}

type AllowedTimelockAction =
    | UpdateCatalogEntryAction
    | UpdateBasePricesAction
    | UpdateTreasuryAction
    | UpdateItemDeployValueAction
    | UpdateRoyaltyAction

struct (0x4e4d0020) MintProceeds {
    queryId: uint64
    nameHash: uint256
}

struct (0x693d3950) RequestRoyaltyParams {
    queryId: uint64
}

struct (0xa8cb00ad) ResponseRoyaltyParams {
    queryId: uint64
    royaltyParams: RoyaltyParams
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
