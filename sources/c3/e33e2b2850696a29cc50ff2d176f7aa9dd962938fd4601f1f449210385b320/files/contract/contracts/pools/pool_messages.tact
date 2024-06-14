// https://docs.ston.fi/docs/developer-section/api-reference/pool#get_expected_outputs

// message(0xed4d8b67) AssessSwapRequest {
//     queryId: Int as uint64;
//     inputAmount: Int as coins;
//     inputTokenWallet: Address;
// }

// message(0xed4d8b67) AssessSwapResponse {
//     queryId: Int as uint64;
//     output: Int as coins;
//     protocolFee: Int as coins;
//     refFee: Int as coins;
// }

// message(0x43c034e6) PoolDataRequest {
//     queryId: Int as uint64;
// }

// message(0x43c034e6) PoolDataResponse {
//     queryId: Int as uint64;
//     reserve0: Int as coins;
//     reserve1: Int as coins;
//     token0: Address;
//     token1: Address;
//     fees: Fees;
// }

// struct Fees {
//     lpFee: Int as uint8;
//     protocolFee: Int as uint8;
//     refFee: Int as uint8;
//     protocolFeeReceiver: Address;
//     collectedProtocolFeeToken0: Int as coins;
//     collectedProtocolFeeToken1: Int as coins;
// }