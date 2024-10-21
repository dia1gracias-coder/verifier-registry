// Message with ID 0xe4205fb7 represents a Swap request
message(0xe4205fb7) Swap {
    queryId: Int as uint64;             // Arbitrary request number
    fromUserAddress: Address;           // Address of the user initiating the swap
    tokenWallet: Address;               // Address of the wallet containing the tokens to be swapped
    amount: Int as coins;               // The amount of tokens to be swapped
    minOut: Int as coins;               // Minimum amount of tokens to receive in swap
    fromRealUser: Address;              // Real address of the user
    refAddress: Address?;               // Optional reference address
    refMessageValue: Int as coins;      // Value of the referral, if any
    next: SwapNext?;                    // Optional self-ref object containing details for the next swap in a chain of swaps
}

// Message with ID 0x72210d3a represents a callback for a Swap request
message(0x72210d3a) CbSwap {
    queryId: Int as uint64;             // Arbitrary request number
    fromUserAddress: Address;           // Address of the user initiating the swap, same as in the original Swap
    tokenWallet: Address;               // Address of the token wallet used in the swap, same as in the original Swap
    amount: Int as coins;               // The amount of tokens involved in the swap, same as in the original Swap
    fromRealUser: Address;              // Real address of the user, same as in the original Swap
    refAddress: Address?;               // Optional reference address, same as in the original Swap
    refMessageValue: Int as coins;      // Value of the referral, if any, same as in the original Swap
    next: SwapNext;                     // Self-ref object containing details for the next swap, mandatory in the callback
}

// represents the next swap details in a chain of swaps
struct SwapNext {
    tokenAddress: Address;              // Address of the token for the next swap in the sequence
    minOut: Int as coins;               // Minimum amount of tokens to receive in swap
    next: Cell?;                        // Optional next step in the swap chain, stored as a Cell
}

message ProvideLpOnSingleSide {
    queryId: Int as uint64;
    ownerAddress: Address;
    minLpOut: Int as coins;
    amount0: Int as coins;
    amount1: Int as coins;
}

message SetFeesFromRouter {
    queryId: Int as uint64;
    newLpFee: Int as coins;
    newProtocolFee: Int as coins;
    newRefFee: Int as coins;
    newProtocolFeeAddress: Address;
}

message CollectFeesFromRouter {
    queryId: Int as uint64;
}

message CollectFeesFromAnyone {
    queryId: Int as uint64;
}

message ResetPoolGasFromRouter {
    queryId: Int as uint64;
}

message CbRefundMe {
    queryId: Int as uint64;
    amount0:Int;
    amount1:Int;
    userAddress: Address;
}

message CbAddLiquidity {
    queryId: Int as uint64;
    amount0:Int;
    amount1:Int;
    userAddress: Address;
    minLpOut:Int;
}

message GetterPoolData {
    queryId: Int as uint64;
}

message GetterPoolDataResponse {
    queryId: Int as uint64;
    reserve0: Int;
    reserve1: Int;
    token0Address: Address;
    token1Address: Address;
    lpFee: Int as uint16;
    protocolFee: Int as uint16;
    refFee: Int as uint16;
    protocolFeeAddress: Address?;
    collectedToken0ProtocolFee: Int;
    collectedToken1ProtocolFee: Int;
}

message GetterExpectedOutputs {
    queryId: Int as uint64;
    amount: Int;
    tokenWallet: Address;
}

message GetterExpectedOutputsResponse {
    queryId: Int as uint64;
    amountOut: Int;
    protocolFeeOut: Int;
    refFeeOut: Int;
}

message GetterLpAccountAddress {
    queryId: Int as uint64;
    userAddress: Address;
}

message GetterLpAccountAddressResponse {
    queryId: Int as uint64;
    accountAddress: Address;
}

message GetterExpectedTokens {
    queryId: Int as uint64;
    amount0: Int;
    amount1: Int;
}

message GetterExpectedTokensResponse {
    queryId: Int as uint64;
    liquidity: Int;
}

message GetterExpectedLiquidity {
    queryId: Int as uint64;
    liquidity: Int;
}

message GetterExpectedLiquidityResponse {
    queryId: Int as uint64;
    amount0: Int;
    amount1: Int;
}

message ProvideWalletAddress {
    queryId: Int as uint64;
    owner: Address;
}

message ProvideWalletAddressResponse {
    queryId: Int as uint64;
    wallet: Address;
}
