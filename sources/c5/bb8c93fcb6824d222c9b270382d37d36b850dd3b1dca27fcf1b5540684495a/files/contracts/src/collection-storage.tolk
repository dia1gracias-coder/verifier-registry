struct CollectionContent {
    collectionMetadata: cell
    commonContent: string
}

struct RevealState {
    delayedRevealEnabled: bool
    metadataCommitment: uint256
    metadataRevealed: bool
    metadataFrozen: bool
}

struct PremintConfig {
    immutableRecipientAddress: address
}

struct CollectionConfig {
    immutableTreasuryAddress: address
    premint: Cell<PremintConfig>
    networkId: int32
    maximumSupply: uint32
    giveawaySupply: uint16
    treasuryNftSupply: uint16
    whitelistMaxClaims: uint16
    itemDeploymentValue: coins
    collectionExecutionReserve: coins
    outboundMessageReserve: coins
    minimumStorageReserve: coins
}

struct CollectionMaps {
    usedQuoteHashes: map<uint256, bool>
    mintedSerialGuards: map<uint32, bool>
    whitelistClaimedWallets: map<uint256, bool>
}

struct WhitelistState {
    merkleRoot: uint256
    claimsUsed: uint16
    locked: bool
}

struct CollectionAssets {
    nftItemCode: cell
    maps: Cell<CollectionMaps>
    whitelist: Cell<WhitelistState>
}

struct NftCollectionStorage {
    adminAddress: address
    quotePublicKey: uint256
    signerEpoch: uint32
    nextItemIndex: uint32
    mintedCount: uint32
    giveawayPremintedCount: uint16
    treasuryPremintedCount: uint16
    paused: bool
    config: Cell<CollectionConfig>
    content: Cell<CollectionContent>
    reveal: Cell<RevealState>
    assets: Cell<CollectionAssets>
}

fun NftCollectionStorage.load(): NftCollectionStorage {
    return NftCollectionStorage.fromCell(contract.getData());
}

fun NftCollectionStorage.save(self) {
    contract.setData(self.toCell());
}
