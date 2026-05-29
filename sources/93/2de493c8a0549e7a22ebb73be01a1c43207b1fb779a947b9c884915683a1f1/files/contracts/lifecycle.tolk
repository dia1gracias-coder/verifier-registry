// Shared market-lifecycle + outcome enum for all Sooth TON contracts.
//
// This is the single source of truth for the cross-contract lifecycle labels and the
// INVALID outcome. The registry is the canonical six-label authority; the launchpad
// (graduation/trial) and the adjudicator (resolve/attest/settle/dispute) drive subsets of
// the same enum and notify the registry. Previously each of those three contracts hand-copied
// these constants — identical today, but a drift would be a settlement-routing bug. Importing
// this file keeps them in lockstep. Helpers are plain (not `get fun`) and tree-shake to zero
// in any contract that doesn't call a given one, so importing the full set is free.
//
// Values are wire-significant (carried in lifecycle messages + getters); do NOT renumber.

fun lifecycleBonding(): uint8 {
    return 0;
}

fun lifecycleLive(): uint8 {
    return 1;
}

fun lifecycleTrialExpired(): uint8 {
    return 2;
}

fun lifecycleResolving(): uint8 {
    return 3;
}

fun lifecycleAttested(): uint8 {
    return 4;
}

fun lifecycleSettled(): uint8 {
    return 5;
}

fun invalidOutcome(): uint8 {
    return 2;
}
