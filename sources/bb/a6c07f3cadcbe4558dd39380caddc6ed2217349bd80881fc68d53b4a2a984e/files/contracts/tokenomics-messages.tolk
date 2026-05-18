struct (0x48490101) BuyInstant {
    tonAmount: coins
}

struct (0x48490102) BuyLocked {
    tonAmount: coins
}

struct (0x48490103) SetPoolEnabled {
    instantPool: bool
    enabled: bool
}

struct (0x48490104) CloseSale {}

struct (0x48490105) ClaimLocked {}

struct (0x48490106) SetConfirmedLevel {
    confirmedLevel: uint8
}

struct (0x48490107) SweepProjectFund {}

struct (0x48490108) WithdrawSaleTons {
    amount: coins
}

struct (0x48490109) SetSaleJettonWallet {
    saleJettonWallet: address
}

struct (0x48490201) ReportPrice {
    price: uint64
}

struct (0x48490202) ConfirmLevel {}

struct (0x48490203) SetOracleTargets {
    publicSale: address
    teamVestingVault: address
}

struct (0x48490204) SetCampaignWinnerTarget {
    campaignWinnerVault: address
}

struct (0x48490301) SyncTeamPriceLevel {
    confirmedLevel: uint8
    confirmedAt: uint32
}

struct (0x48490302) ClaimTeam {}

struct (0x48490303) SetTeamJettonWallet {
    teamJettonWallet: address
}

struct (0x48490401) CreateRewardBatch {
    batchId: uint64
    root: uint256
    totalHi: coins
    metadataHash: uint256
    poolType: uint8
}

struct (0x48490402) ClaimReward {
    batchId: uint64
    amount: coins
    proof: cell
}

struct (0x48490403) SetRewardJettonWallet {
    rewardJettonWallet: address
}

struct (0x48490501) RegisterCampaignWinner {
    winner: address
}

struct (0x48490502) ClaimCampaignWinner {}

struct (0x48490503) SetCampaignWinnerJettonWallet {
    winnerJettonWallet: address
}
