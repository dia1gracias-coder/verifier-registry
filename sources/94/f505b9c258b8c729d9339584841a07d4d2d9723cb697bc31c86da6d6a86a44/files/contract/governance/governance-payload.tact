// SPDX-License-Identifier: MIT
// Payload layouts per ProposalType — must mirror docs/specs/TOKENOMICS.md.

inline fun govAssertTrailingEmpty(s: Slice) {
    require(s.bits() == 0 && s.refs() == 0, "Payload trailing data");
}

/// ParameterChange: Address target, uint32 method id, Cell args (may be empty), no trailing refs.
inline fun validateParameterChangePayload(payload: Cell) {
    let s = payload.beginParse();
    s.loadAddress();
    s.loadUint(32);
    s.loadRef();
    govAssertTrailingEmpty(s);
}

/// FeaturePriority: Cell description + Cell cid (cid may be empty).
inline fun validateFeaturePriorityPayload(payload: Cell) {
    let s = payload.beginParse();
    let descCell = s.loadRef();
    s.loadRef();
    govAssertTrailingEmpty(s);
    let ds = descCell.beginParse();
    require(ds.bits() > 0, "Feature description required");
}

/// TreasurySpend: Treasury contract, recipient, Coins amount, Cell reason ref (non-empty).
/// `expectedTreasury` must match the Governor's canonical treasury (immutable init).
inline fun validateTreasurySpendPayload(payload: Cell, expectedTreasury: Address) {
    let s = payload.beginParse();
    let treasury = s.loadAddress();
    require(treasury == expectedTreasury, "Treasury address mismatch");
    s.loadAddress();
    let _amt = s.loadCoins();
    let reasonCell = s.loadRef();
    govAssertTrailingEmpty(s);
    let rs = reasonCell.beginParse();
    require(rs.bits() > 0, "Spend reason required");
}

/// Emergency: Parameter-like head + mandatory non-empty reason ref.
inline fun validateEmergencyPayload(payload: Cell) {
    let s = payload.beginParse();
    s.loadAddress();
    s.loadUint(32);
    s.loadRef();
    let reasonCell = s.loadRef();
    govAssertTrailingEmpty(s);
    let rs = reasonCell.beginParse();
    require(rs.bits() > 0, "Emergency reason required");
}

inline fun validateProposalPayloadShape(proposalType: Int, payload: Cell, expectedTreasury: Address) {
    /// ProposalType constants match TASK_CARD ProposalType enum
    let t = proposalType;
    require(t >= 0 && t <= 3, "Bad proposal type");

    if (t == 0) {
        validateParameterChangePayload(payload);
        return;
    }
    if (t == 1) {
        validateFeaturePriorityPayload(payload);
        return;
    }
    if (t == 2) {
        validateTreasurySpendPayload(payload, expectedTreasury);
        return;
    }
    validateEmergencyPayload(payload);
}
