struct (0x48490102) BuyGrowth {
    tonAmount: coins
}

struct (0x48490103) SetGrowthEnabled {
    enabled: bool
}

struct (0x48490104) CloseGrowthEngine {}

struct (0x48490105) ClaimGrowth {}

struct (0x48490106) SetGrowthConfirmedLevel {
    growthConfirmedLevel: uint8
}

struct (0x48490107) SweepGrowthProjectFund {}

struct (0x48490108) WithdrawGrowthTons {
    amount: coins
}

struct (0x48490109) SetGrowthJettonWallet {
    growthJettonWallet: address
}

struct (0x4849010a) SetGrowthMigrationTarget {
    targetContract: address
}

struct (0x4849010b) TransferGrowthUncommittedHiToContract {
    amount: coins
}

struct (0x48490201) ReportGrowthPrice {
    price: uint64
}

struct (0x48490202) ConfirmGrowthLevel {}

struct (0x48490203) SetOracleTargets {
    growthEngine: address
    teamVestingVault: address
    merkleRewardVault: address
}

struct (0x48490204) SetCampaignWinnerTarget {
    campaignWinnerVault: address
}

struct (0x48490205) ReportTeamPrice {
    price: uint64
}

struct (0x48490206) ConfirmTeamLevel {}

struct (0x48490301) SyncTeamPriceLevel {
    teamConfirmedLevel: uint8
    confirmedAt: uint32
}

struct (0x48490302) ClaimTeam {}

struct (0x48490303) SetTeamJettonWallet {
    teamJettonWallet: address
}

struct (0x48490304) SetTeamMigrationTarget {
    targetContract: address
}

struct (0x48490305) TransferTeamUncommittedHiToContract {
    amount: coins
}

struct (0x48490401) CreateRewardBatch {
    batchId: uint64
    root: uint256
    totalHi: coins
    metadataHash: uint256
    poolType: uint8
    requiredGrowthLevel: uint8
}

struct (0x48490402) ClaimReward {
    batchId: uint64
    amount: coins
    proof: cell
}

struct (0x48490403) SetRewardJettonWallet {
    rewardJettonWallet: address
}

struct (0x48490404) SetRewardGrowthLevel {
    growthConfirmedLevel: uint8
}

struct (0x48490405) SetRewardMigrationTarget {
    targetContract: address
}

struct (0x48490406) TransferRewardUncommittedHiToContract {
    amount: coins
}

struct (0x48490501) RegisterCampaignWinner {
    winner: address
}

struct (0x48490502) ClaimCampaignWinner {}

struct (0x48490503) SetCampaignWinnerJettonWallet {
    winnerJettonWallet: address
}

struct (0x48490504) SetCampaignMigrationTarget {
    targetContract: address
}

struct (0x48490505) TransferCampaignUncommittedHiToContract {
    amount: coins
}
