// SPDX-License-Identifier: MIT
// Shared VP math — multiplier comes from StakingMaster runtime tier config (IMP-AUDIT-03).

inline fun tierVotingPowerFromAmount(stakeAmount: Int, multiplierX100: Int): Int {
    return stakeAmount * multiplierX100 / 100;
}
