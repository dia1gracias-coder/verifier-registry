struct BridgeBoilerplate {
    amount:                 Int;
    payload:                Cell;
}

/// @dev Sent by LP to the wallet
message InternalWithdrawDeposit {
    amount:                 Int;        // User requested amount
    global_fee_growth:      Int;        // Accumulated fee
    total_supply:           Int;        // The global LP token supply
}

message InternalWithdrawFee {
    lastFeeGrowth:          Int;
    owner:                  Address;
    balance:                Int;
}

struct LPData {
    apy:                    Int;            // APY % with 4 decimals, ex.: 1000 = 10.00%
    available_underlying:   Int;            // Total amount of the staked underlying jetton/TON
    decimals:               Int;            // Underlying asset's decimal points
    fee_growth_global:      Int;            // Global fee counter
    fee_decimals:           Int;            // 10.000 = 100.00%
    protocol_fee:           Int;            // Protocol share of the fee
    protocol_fee_amount:    Int;            // Protocol fee storage slot
    token_fee:              Int;            // Underlying token usage fee
    total_supply:           Int;            // The total number of issued jettons
}

// Bridge role transfers `amount` -> `to`
message ReleaseTokens {
    to:                     Address;
    amount:                 Int;
    body:                   Cell?;
}

// Type
struct PoolPayload {
    mode:                   Int;
}

// Storage type State of a stake
struct Position {
    balance:                Int;    // Staker's LP token balance
    last_fee_growth:        Int;    // Last global fee growth snapshot
    rewards:                Int;    // Last calculated rewards
}

// Global fee growth request
message CollectWithdrawData {
    amount:                 Int;
    wallet:                 Address;
}

// Return type
struct RewardSplit {
    protocolFeeShare:       Int;
    lpProvidersShare:       Int;
}

message SetAdmin {
    newAdmin:               Address;
}

message SetBridge {
    newBridge:               Address;
}

message SetCFO {
    newCFO:                 Address;
}

// Assigns an address
message SetWalletAddress {
    token_wallet:           Address;
}

message UpdateFees {
    protocol_fee:           Int;
    token_fee:              Int;
}

message UpdateGasCost {
    newGasCost:             Int;
}

message Withdraw {
    amount:                 Int;        // Amount of tokens to withdraw
}

message WithdrawGas {
    amount:                 Int;        // Amount of tokens to withdraw
}

message WithdrawRewards {
    // amount:                 Int;        // Amount of tokens to withdraw
}

message WithdrawCallback {
    feeGrowthGlobal:        Int;
    rewards:                Int;
}

/// @dev Ures request to withdraw the deposit
message WithdrawStake {
    amount:                 Int;        // Requested amount of stake to withdraw
}