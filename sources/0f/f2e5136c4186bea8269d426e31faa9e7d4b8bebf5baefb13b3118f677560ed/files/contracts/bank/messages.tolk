struct (0x4C424E01) CreatePosition {
    queryId: uint64
    positionId: uint64
    principal: coins
    multiplierBps: uint16
}

struct (0x4C424E02) SetBankPaused {
    queryId: uint64
    paused: bool
}

struct (0x4C424E03) BankFundReserve {
    queryId: uint64
    amount: coins
}

struct (0x4C424E04) BankWithdrawSurplus {
    queryId: uint64
    amount: coins
}

struct (0x4C424E05) BankSetFee {
    queryId: uint64
    feeBps: uint16
}

struct (0x4C424E06) BankSetTreasury {
    queryId: uint64
    treasury: address
}

struct (0x4C424E07) BankSetOwner {
    queryId: uint64
    owner: address
}

struct (0x4C424E11) BankPayout {
    queryId: uint64
    positionId: uint64
    principal: coins
    targetPayout: coins
}

struct (0x4C424E12) BankProtocolFee {
    queryId: uint64
    positionId: uint64
}

struct (0x4C424E13) BankAdminWithdrawal {
    queryId: uint64
    amount: coins
}
