// SPDX-License-Identifier: MIT
// Shared governance structs

struct ProposalConfig {
    quorumPercent: Int;
    thresholdPercent: Int;
    period: Int as uint64;
    timelockDelay: Int as uint64;
}
