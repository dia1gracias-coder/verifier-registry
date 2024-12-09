// NOTE: The wallet supports the following action
//
////////////////// USER ACTIONs /////////////////
// 0. Create Wallet: Init PolymarketUserWallet via Polymarket contract. [Flow 0.1]
//  Use Factory deploy
//
// 1. Initiate bet (BUY oder): User sign, specifying bet details [Flow 1.1]
//
// 2. Withdraw USDT: User can withdraw permissible amount (not staged) [Flow 0.2]
//
// 3. Settle bet (SELL order): User sign, specifying sell details [Flow 2.1]
//
//////////////// EXECUTOR ACTIONs ///////////////
// 0. Create Wallet: Init PolymarketExecutorWallet via SkateGateway -> Polymarket
//
// 1. Fill BUY order: Via Skate Gateway, executor call ExecuteTask to update user wallet status. [Flow 1.2]
//
// 2. Fill SELL order: Via Skate Gateway, executor call ExecuteTask to transfer USDT (winning amount) to ORIGINAL user. [Flow 2.2]
//  WARN: IF SELL ORDER IS NOT SUCCESSFULLY FILLED. USER MUST REQUEST AGAIN.

message(0x44807e69) WithdrawTON {}

/// Master callback
message(0x834638b4) PlaceBuyOrderNotification {
    action_id: Int as uint64;
    token_id: Int; // Must match Polymarket ID
    usd_amount: Int as coins; // Jetton (USDT) amount WARN: must match the coins serialization used in USDT.
    expiration: Int as uint32;
    user: Address;
}

message(0x3e1ee20f) WithdrawBuyOrderNotification {
    action_id: Int as uint64;
    timestamp: Int as uint32;
    user: Address;
}

message(0x2bcfa777) PlaceSellOrderNotification {
    action_id: Int as uint64;
    token_id: Int; // Must match Polymarket ID
    ct_amount: Int as coins; // Condition Token amount, number of bet tokens for this market on PolyMarket
    expiration: Int as uint32;
    user: Address;
}

message(0x3a85da69) ClaimResolvedMarketNotification {
    action_id: Int as uint64;
    token_id: Int; // Must match Polymarket ID
    user: Address;
}
