// SPDX-License-Identifier: MIT
// Shared opcodes between StakingPool and StakingMaster

// TEP-74 Jetton transfer — opcode MUST match burn-jetton-wallet.tact JettonTransfer
message(0xf8a7ea5) JettonTransferOut {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

/// Forward payload attached to jetton transfer notifying stake intent (TEP-74 forward_payload ref).
message(0x5a020010) StakeForward {
    tier: Int as uint8;
}

/// Forward payload marking a jetton deposit into the pool wallet as emission-reserve funding
/// (TEP-74 forward_payload ref). Distinguishes the Phase-1 reward mint (IMP-MNAUD-F01
/// mint-to-pool design) from ordinary staking-fee arrivals, which accrue immediately.
message(0x5a020011) EmissionFundForward {
    queryId: Int as uint64;
}

/// Pool → Master: `amount` reward jettons physically arrived at the pool jetton wallet with an
/// `EmissionFundForward` payload. This is the ONLY path that raises `emissionFunded` — the
/// notification chain (pool JW → pool → master) guarantees real physical backing
/// (IMP-MNAUD-F01: no assert-based funding).
message(0x5a010018) EmissionReserveFunded {
    queryId: Int as uint64;
    amount: Int as coins;
}

message(0x5a010010) IncrementTotalStake {
    queryId: Int as uint64;
    tier: Int as uint8;
    delta: Int as coins;
}

message(0x5a010011) DecrementTotalStake {
    queryId: Int as uint64;
    tier: Int as uint8;
    delta: Int as coins;
}

message(0x5a010012) PayRewards {
    queryId: Int as uint64;
    recipient: Address;
    amount: Int as coins;
}

/// Unstake payout: `principal` (staked body, always backed) is always returned in full,
/// `reward` is capped to the pool's real reward funding (degrades on underfunding).
/// Separating the two guarantees the stake body is never trapped behind a reward shortfall.
message(0x5a010017) PayUnstake {
    queryId: Int as uint64;
    recipient: Address;
    principal: Int as coins;
    reward: Int as coins;
}

message(0x5a010013) CreditPoolBalance {
    queryId: Int as uint64;
    delta: Int as coins;
}

message(0x5a010014) WireStakingMaster {
    queryId: Int as uint64;
    stakingMaster: Address;
}

/// Staking Master relays to Pool → Pool notifies Master (`StakeFeeRewardsAccrue`) so `sender()==pool`.
message(0x5a010015) RelayStakeFeeAccrual {
    queryId: Int as uint64;
    feeAmount: Int as coins;
}

message(0x5a010016) StakeFeeRewardsAccrue {
    queryId: Int as uint64;
    feeAmount: Int as coins;
}
