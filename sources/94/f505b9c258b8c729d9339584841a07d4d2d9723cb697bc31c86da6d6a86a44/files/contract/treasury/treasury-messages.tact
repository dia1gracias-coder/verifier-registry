// SPDX-License-Identifier: MIT
// Treasury spend message layout (timelock-delivered execution). Contract shell in P5-3-2-1.
//
// CANONICAL SCHEMA — must mirror `message(0x5a1c9010) TreasurySpend` in
// `treasury/treasury.tact` byte-for-byte (opcode + field order + types).
// `treasury.tact` is the authoritative receiver; this file is the shared
// builder definition imported by `governance/proposal.tact`. The two are kept
// identical on purpose (see decision IMP-PREMNT-01-treasury-spend-schema).
message(0x5a1c9010) TreasurySpend {
    queryId: Int as uint64;
    recipient: Address;
    amount: Int as coins;
    reason: String;
    proposalId: Int as uint64;
}
