message PayTo {
    queryId: Int as uint64; // arbitrary request number
    owner: Address; // end user to pay to
    exitCode: Int as uint32; // exit code to indicate the reason of pay
    amount0Out: Int as coins; // amount of token 0
    token0Address: Address; // token 0 address
    amount1Out: Int as coins; // amount of token 1
    token1Address: Address; // token 1 address
}

message SetFees {
    queryId: Int as uint64; // arbitrary request number
    newLpFee: Int as coins; // new lp fee collected by pool
    newProtocolFee: Int as coins; // new protocol fee collected by pool
    newRefFee: Int as coins; // new referral fee
    newProtocolFeeAddress: Address; // new protocol fee payee
    jettonWallet0: Address; // wallet 0 address
    jettonWallet1: Address; // wallet 1 address
}

message CollectFees {
    queryId: Int as uint64; // arbitrary request number
    jettonWallet0: Address; // wallet 0 address
    jettonWallet1: Address; // wallet 1 address
}

message Lock {
    queryId: Int as uint64; // arbitrary request number
}

message Unlock {
    queryId: Int as uint64; // arbitrary request number
}

message RouterResetGas {
    queryId: Int as uint64; // arbitrary request number
}

message ResetPoolGas {
    queryId: Int as uint64; // arbitrary request number
    jettonWallet0: Address; // wallet 0 address
    jettonWallet1: Address; // wallet 1 address
}

message GetterPoolAddress {
    queryId: Int as uint64; // arbitrary request number
    token0: Address; // token 0 address
    token1: Address; // token 0 address
}

message PoolAddress {
    queryId: Int as uint64; // arbitrary request number
    poolAddress: Address; // computed pool address
}

message InitCodeUpgrade {
    queryId: Int as uint64; // arbitrary request number
    code: Cell; // new router code
}

message InitAdminUpgrade {
    queryId: Int as uint64; // arbitrary request number
    admin: Address; // new admin address
}

message CancelAdminUpgrade {
    queryId: Int as uint64; // arbitrary request number
}

message CancelCodeUpgrade {
    queryId: Int as uint64; // arbitrary request number
}

message FinalizeUpgrades {
    queryId: Int as uint64; // arbitrary request number
}
