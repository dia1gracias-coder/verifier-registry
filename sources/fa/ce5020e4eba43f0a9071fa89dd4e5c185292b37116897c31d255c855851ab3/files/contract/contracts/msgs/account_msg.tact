message AddLiquidity {
    queryId: Int as uint64;//arbitrary request number
    newAmount0:Int;//token0 amount  by token0 address hash >  token1 address hash
    newAmount1:Int;//token1 amount  by token0 address hash >  token1 address hash
    minLPOut:Int;//minimum LP out
}

message LPAccountData {
    queryId: Int as uint64;//arbitrary request number
}

message LPAccountDataResponse {
    queryId: Int as uint64;//arbitrary request number
    userAddress:Address;//user address
    poolAddress:Address;//pool address
    amount0:Int;//token0  by token0 address hash >  token1 address hash
    amount1:Int;//token1  by token0 address hash >  token1 address hash
}

message RefundMe {
    queryId: Int as uint64;//arbitrary request number
}

message DirectAddLiquidity {
    queryId: Int as uint64;//arbitrary request number
    amount0: Int;//token0 amount  by token0 address hash >  token1 address hash
    amount1: Int;//token1 amount  by token0 address hash >  token1 address hash
    minLPOut: Int;//minimum LP out
}

message ResetGas {
    queryId: Int as uint64;//arbitrary request number
}
