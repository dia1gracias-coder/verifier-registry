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

struct GrowthMigrationConfig {
    migrationWallet1: address
    migrationWallet2: address
}

struct GrowthEngineConfig {
    admin: address
    projectFundWallet: address
    migration: Cell<GrowthMigrationConfig>
}

struct GrowthEngineStorage {
    config: Cell<GrowthEngineConfig>
    counters: Cell<GrowthEngineCounters>
    maps: Cell<GrowthEngineMaps>
    oracle: address
    growthJettonWallet: address?
    migrationTarget: address?
    growthEnabled: bool
    permanentlyClosed: bool
    growthConfirmedLevel: uint8
    nextQueryId: uint64
}

struct GrowthEngineMaps {
    purchasedTon: map<address, coins>
    positions: map<address, PurchasePosition>
    pendingTransfers: map<uint64, PendingSaleTransfer>
    migrationAllowlist: map<address, bool>
}

struct GrowthEngineCounters {
    growthPoolTotalHi: coins
    growthSoldHi: coins
    growthClaimedHi: coins
    growthMissedHi: coins
    growthMigratedHi: coins
}

fun GrowthEngineStorage.load(): GrowthEngineStorage {
    return GrowthEngineStorage.fromCell(contract.getData());
}

fun GrowthEngineStorage.save(self) {
    contract.setData(self.toCell());
}

struct PriceOracleCampaignTargets {
    campaignWinnerVault: address?
}

struct PriceOracleTargets {
    growthEngine: address?
    teamVestingVault: address?
    merkleRewardVault: address?
    campaignTargets: Cell<PriceOracleCampaignTargets>
}

struct PriceOracleGrowthState {
    confirmedLevel: uint8
    candidateLevel: uint8
    levelStartedAt: uint32
    lastPrice: uint64
}

struct PriceOracleTeamState {
    confirmedLevel: uint8
    candidateLevel: uint8
    levelStartedAt: uint32
    lastPrice: uint64
}

struct PriceOracleStorage {
    admin: address
    confirmationDelay: uint32
    targets: Cell<PriceOracleTargets>
    growth: Cell<PriceOracleGrowthState>
    team: Cell<PriceOracleTeamState>
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
    migration: Cell<GrowthMigrationConfig>
}

struct TeamVestingStorage {
    config: Cell<TeamVestingConfig>
    counters: Cell<TeamVestingCounters>
    maps: Cell<TeamVestingMaps>
    oracle: address
    teamJettonWallet: address?
    migrationTarget: address?
    teamConfirmedLevel: uint8
    nextQueryId: uint64
}

struct TeamVestingCounters {
    totalHi: coins
    claimedHi: coins
    migratedHi: coins
}

struct PendingTeamTransfer {
    kind: uint8
    amount: coins
}

struct TeamVestingMaps {
    pendingTransfers: map<uint64, PendingTeamTransfer>
    migrationAllowlist: map<address, bool>
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
    requiredGrowthLevel: uint8
}

struct PendingRewardTransfer {
    kind: uint8
    batchId: uint64
    claimant: address
    amount: coins
}

struct MerkleRewardStorage {
    config: Cell<MerkleRewardConfig>
    counters: Cell<MerkleRewardCounters>
    maps: Cell<MerkleRewardMaps>
    oracle: address
    rewardJettonWallet: address?
    migrationTarget: address?
    growthConfirmedLevel: uint8
    nextQueryId: uint64
}

struct MerkleRewardCounters {
    ecosystemTotalHi: coins
    universalTotalHi: coins
    redPacketTotalHi: coins
    migratedHi: coins
}

struct MerkleRewardMaps {
    batches: map<uint64, MerkleRewardBatch>
    claimed: map<uint256, bool>
    pendingTransfers: map<uint64, PendingRewardTransfer>
    migrationAllowlist: map<address, bool>
}

struct MerkleRewardConfig {
    admin: address
    migration: Cell<GrowthMigrationConfig>
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
    kind: uint8
    winner: address
    amount: coins
}

struct CampaignWinnerConfig {
    admin: address
    migration: Cell<GrowthMigrationConfig>
}

struct CampaignWinnerStorage {
    config: Cell<CampaignWinnerConfig>
    counters: Cell<CampaignWinnerCounters>
    maps: Cell<CampaignWinnerMaps>
    oracle: address
    winnerJettonWallet: address?
    migrationTarget: address?
    growthConfirmedLevel: uint8
    nextQueryId: uint64
}

struct CampaignWinnerCounters {
    winnerCount: uint16
    totalClaimedHi: coins
    migratedHi: coins
}

struct CampaignWinnerMaps {
    winners: map<address, CampaignWinnerPosition>
    pendingTransfers: map<uint64, PendingCampaignWinnerTransfer>
    migrationAllowlist: map<address, bool>
}

fun CampaignWinnerStorage.load(): CampaignWinnerStorage {
    return CampaignWinnerStorage.fromCell(contract.getData());
}

fun CampaignWinnerStorage.save(self) {
    contract.setData(self.toCell());
}
