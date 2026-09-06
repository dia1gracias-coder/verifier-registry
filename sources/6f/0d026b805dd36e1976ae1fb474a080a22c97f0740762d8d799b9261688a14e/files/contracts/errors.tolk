enum Errors {
    NotOwner = 100
    NotVault = 101
    NotPool = 102
    NotTstonWallet = 103
    NotMemberAccount = 104
    DepositTooSmall = 110
    NotEnoughGas = 111
    NoFreeSlot = 112
    BadSlots = 113
    TrancheNotActive = 114
    PendingExists = 115
    NoPending = 116
    RetryTooEarly = 117
    BadConfig = 118
    PrincipalUnderflow = 119
    WrongWorkchain = 120
    // коды реального пула Tonstakers (DESIGN §7.2), используются моком
    PoolDepositTooLow = 0xf200
    PoolDepositsClosed = 0xf201
    InvalidMessage = 0xFFFF
}
