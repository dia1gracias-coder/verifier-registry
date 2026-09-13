// Gas / value budgets (nanoTON). The chains they fund are measured in tests/gas.test.tolk (real fees × 1.25
// headroom must fit the budget) so a path that gets more expensive, or a lowered constant, fails a test.

/// Minimum TON every contract keeps on its balance for storage rent.
const MIN_STORAGE_RESERVE = ton("0.05")

/// Value attached by a DeskItem to each SweepRequest sent to the Pot.
/// Covers: Pot compute, jetton transfer (incl. possible wallet deploy for the desk), SweepAck.
const SWEEP_REQUEST_VALUE = ton("0.12")

/// Value attached by a DeskItem to WithdrawViaPot (Pot compute + WithdrawOk back).
const WITHDRAW_REQUEST_VALUE = ton("0.05")

/// Value the Pot attaches to a jetton transfer towards a desk (wallet may need to be deployed).
const POT_JETTON_TRANSFER_VALUE = ton("0.07")

/// Value the Collection attaches when deploying a DeskItem.
const DESK_DEPLOY_VALUE = ton("0.05")

/// Value the Collection forwards to the Pot with RegisterDesk (Pot compute + StampsInit to the desk).
const REGISTER_DESK_VALUE = ton("0.04")

/// Minimum forward TON a mint transfer must carry on top of the surcharge.
const MINT_GAS = ton("0.4")

/// Value attached to the jetton burn issued by the Minter. $DESK is a RewardJetton: its burn goes
/// through a settle round trip with the master (RewardWallet.WALLET_BURN_GAS = 0.12 TON).
const BURN_VALUE = ton("0.15")

/// Value attached to jetton transfers returning a rejected deposit.
const RETURN_DEPOSIT_VALUE = ton("0.05")

/// Fixed-point scale for per-desk accounting counters (amount * SCALE / liveDesks).
const COUNTER_SCALE = 1000000000000

/// Bitmask width for slot selection in Sweep.
const MAX_SLOTS = 64

/// TEP-74 forward payload "Either" left branch with no data (inline, empty).
fun emptyForwardPayload(): slice {
    return beginCell().storeUint(0, 1).endCell().beginParse();
}
