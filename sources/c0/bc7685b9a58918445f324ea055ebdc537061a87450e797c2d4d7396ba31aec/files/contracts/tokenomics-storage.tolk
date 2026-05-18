struct PurchasePosition {
    totalLockedHi: coins
    claimedHi: coins
    entryLevel: uint8
    missedHi: coins
}

struct PendingSaleTransfer {
    kind: uint8
    owner: address
    hiAmount: coins
    tonAmount: coins
    lockedPurchaseHi: coins
    missedHi: coins
}

struct PublicSaleConfig {
    admin: address
    projectFundWallet: address
}

struct PublicSaleStorage {
    config: Cell<PublicSaleConfig>
    counters: Cell<PublicSaleCounters>
    maps: Cell<PublicSaleMaps>
    oracle: address
    saleJettonWallet: address?
    instantSaleEnabled: bool
    lockedSaleEnabled: bool
    permanentlyClosed: bool
    confirmedLevel: uint8
    nextQueryId: uint64
}

struct PublicSaleMaps {
    purchasedTon: map<address, coins>
    positions: map<address, PurchasePosition>
    pendingTransfers: map<uint64, PendingSaleTransfer>
}

struct PublicSaleCounters {
    instantPoolTotalHi: coins
    lockedPoolTotalHi: coins
    instantSoldHi: coins
    lockedSoldHi: coins
    lockedClaimedHi: coins
    lockedMissedHi: coins
}

fun PublicSaleStorage.load(): PublicSaleStorage {
    return PublicSaleStorage.fromCell(contract.getData());
}

fun PublicSaleStorage.save(self) {
    contract.setData(self.toCell());
}

struct PriceOracleCampaignTargets {
    campaignWinnerVault: address?
}

struct PriceOracleStorage {
    admin: address
    publicSale: address?
    teamVestingVault: address?
    campaignTargets: Cell<PriceOracleCampaignTargets>
    confirmationDelay: uint32
    confirmedLevel: uint8
    candidateLevel: uint8
    levelStartedAt: uint32
    lastPrice: uint64
}

fun PriceOracleStorage.load(): PriceOracleStorage {
    return PriceOracleStorage.fromCell(contract.getData());
}

fun PriceOracleStorage.save(self) {
    contract.setData(self.toCell());
}

struct TeamVestingConfig {
    admin: address
    teamWallet: address
}

struct TeamVestingStorage {
    config: Cell<TeamVestingConfig>
    oracle: address
    teamJettonWallet: address?
    totalHi: coins
    claimedHi: coins
    confirmedLevel: uint8
    nextQueryId: uint64
    pendingTransfers: map<uint64, coins>
}

fun TeamVestingStorage.load(): TeamVestingStorage {
    return TeamVestingStorage.fromCell(contract.getData());
}

fun TeamVestingStorage.save(self) {
    contract.setData(self.toCell());
}

struct MerkleRewardBatch {
    root: uint256
    totalHi: coins
    claimedHi: coins
    metadataHash: uint256
    poolType: uint8
}

struct PendingRewardTransfer {
    batchId: uint64
    claimant: address
    amount: coins
}

struct MerkleRewardStorage {
    config: Cell<MerkleRewardConfig>
    rewardJettonWallet: address?
    ecosystemTotalHi: coins
    universalTotalHi: coins
    redPacketTotalHi: coins
    nextQueryId: uint64
    batches: map<uint64, MerkleRewardBatch>
    claimed: map<uint256, bool>
    pendingTransfers: map<uint64, PendingRewardTransfer>
}

struct MerkleRewardConfig {
    admin: address
}

fun MerkleRewardStorage.load(): MerkleRewardStorage {
    return MerkleRewardStorage.fromCell(contract.getData());
}

fun MerkleRewardStorage.save(self) {
    contract.setData(self.toCell());
}

struct CampaignWinnerPosition {
    entryLevel: uint8
    claimedHi: coins
}

struct PendingCampaignWinnerTransfer {
    winner: address
    amount: coins
}

struct CampaignWinnerConfig {
    admin: address
}

struct CampaignWinnerStorage {
    config: Cell<CampaignWinnerConfig>
    oracle: address
    winnerJettonWallet: address?
    confirmedLevel: uint8
    winnerCount: uint16
    totalClaimedHi: coins
    nextQueryId: uint64
    winners: map<address, CampaignWinnerPosition>
    pendingTransfers: map<uint64, PendingCampaignWinnerTransfer>
}

fun CampaignWinnerStorage.load(): CampaignWinnerStorage {
    return CampaignWinnerStorage.fromCell(contract.getData());
}

fun CampaignWinnerStorage.save(self) {
    contract.setData(self.toCell());
}
