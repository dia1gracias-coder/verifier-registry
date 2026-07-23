struct RoyaltyParams {
    numerator: uint16
    denominator: uint16
    royaltyAddress: address
}

/// Values that are never modified after StateInit.
struct CollectionImmutableConfig {
    maxSupply: uint64
    voucherDomain: uint256
    royaltyAddress: address
    collectionMetadata: cell
    commonContent: string
    nftItemCode: cell
    personalVaultCode: cell
}

/// Owner-controlled collection settings.
struct CollectionMutableConfig {
    mintPrice: coins
    paused: bool
    transferFrozen: bool
    treasuryAddress: address
    voucherSignerPublicKey: uint256
    pendingOwnerAddress: address?
}

/// A claim that reached asynchronous item deployment but bounced. Retaining the
/// original index permits an exact retry without creating a marketplace index gap.
struct FailedClaimRecord {
    itemIndex: uint64
    nonce: uint256
    recipientAddress: address
}

struct ClaimIndexes {
    claimedSerials: map<uint64, uint64>
    usedNonces: map<uint256, uint64>
    failedClaims: map<uint64, FailedClaimRecord>
}

/// Root is intentionally four references or fewer.
struct ClaimableCollectionStorage {
    ownerAddress: address
    nextItemIndex: uint64
    immutableConfig: Cell<CollectionImmutableConfig>
    mutableConfig: Cell<CollectionMutableConfig>
    claimIndexes: Cell<ClaimIndexes>
}

/// Constant-size storage for Signup Ape. Claim replay protection is provided by the deterministic
/// item address `serial - 1`: an initialized NFT item rejects every later initialization message.
/// Keeping claim dictionaries out of this account is what permits a six-figure collection.
struct ScalableSignupCollectionStorage {
    ownerAddress: address
    immutableConfig: Cell<CollectionImmutableConfig>
    mutableConfig: Cell<CollectionMutableConfig>
}

struct NftItemStorage {
    itemIndex: uint64
    collectionAddress: address
    ownerAddress: address
    individualContent: string
    nextTransferNonce: uint64
    pendingTransfer: Cell<PendingNftTransfer>?
}

/// A standard TEP-62 transfer retained while the canonical collection makes
/// the current, collection-wide transfer-policy decision. The item accepts at
/// most one pending transfer and binds the reply to a monotonic nonce.
struct PendingNftTransfer {
    authorizationNonce: uint64
    originalOwnerAddress: address
    transferBody: cell
}

struct NftItemStorageNotInitialized {
    itemIndex: uint64
    collectionAddress: address
}

struct NftItemStorageLoader {
    itemIndex: uint64
    collectionAddress: address
    private rest: RemainingBitsAndRefs
}

struct PersonalVaultStorage {
    ownerAddress: address
}

struct CollectionDataReply {
    nextItemIndex: int
    collectionMetadata: cell
    ownerAddress: address
}

struct NftDataReply {
    isInitialized: bool
    itemIndex: int
    collectionAddress: address
    ownerAddress: address? = null
    individualContent: string? = null
}

struct ClaimConfigReply {
    ownerAddress: address
    pendingOwnerAddress: address?
    nextItemIndex: uint64
    maxSupply: uint64
    mintPrice: coins
    minimumMintPrice: coins
    paused: bool
    transferFrozen: bool
    treasuryAddress: address
    voucherSignerPublicKey: uint256
    voucherDomain: uint256
    royaltyAddress: address
}

struct ClaimLookupReply {
    claimed: bool
    itemIndex: uint64
}

struct (0x01) OffchainMetadataReply {
    string: string
}

fun ClaimableCollectionStorage.load(): ClaimableCollectionStorage {
    return ClaimableCollectionStorage.fromCell(contract.getData());
}

fun ClaimableCollectionStorage.save(self) {
    contract.setData(self.toCell());
}

fun ScalableSignupCollectionStorage.load(): ScalableSignupCollectionStorage {
    return ScalableSignupCollectionStorage.fromCell(contract.getData());
}

fun ScalableSignupCollectionStorage.save(self) {
    contract.setData(self.toCell());
}

fun ClaimIndexes.empty(): ClaimIndexes {
    return {
        claimedSerials: [],
        usedNonces: [],
        failedClaims: [],
    };
}

fun NftItemStorage.startLoading(): NftItemStorageLoader {
    return NftItemStorageLoader.fromCell(contract.getData());
}

fun NftItemStorage.save(self) {
    contract.setData(self.toCell());
}

fun NftItemStorageLoader.isNotInitialized(self): bool {
    return self.rest.isEmpty();
}

fun NftItemStorageLoader.endLoading(mutate self): NftItemStorage {
    return {
        itemIndex: self.itemIndex,
        collectionAddress: self.collectionAddress,
        ownerAddress: self.rest.loadAny(),
        individualContent: self.rest.loadAny(),
        nextTransferNonce: self.rest.loadAny(),
        pendingTransfer: self.rest.loadAny(),
    };
}

fun calcPersonalVault(ownerAddress: address, personalVaultCode: cell): AutoDeployAddress {
    val initialStorage: PersonalVaultStorage = { ownerAddress };
    return { stateInit: { code: personalVaultCode, data: initialStorage.toCell() } };
}

fun PersonalVaultStorage.load(): PersonalVaultStorage {
    return PersonalVaultStorage.fromCell(contract.getData());
}

fun calcDeployedNftItem(
    itemIndex: uint64,
    collectionAddress: address,
    nftItemCode: cell,
): AutoDeployAddress {
    val initialStorage: NftItemStorageNotInitialized = { itemIndex, collectionAddress };
    return { stateInit: { code: nftItemCode, data: initialStorage.toCell() } };
}
