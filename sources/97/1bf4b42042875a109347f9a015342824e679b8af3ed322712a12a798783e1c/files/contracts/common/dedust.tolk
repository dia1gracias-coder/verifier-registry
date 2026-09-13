// DeDust v2 native-vault swap, built ON-CHAIN by the contracts that convert TON (Pot, RewardVault).
// The keeper only chooses the pool (whitelisted), the amount and the minimum output; receiver and
// limit are fixed by the contract itself, so a compromised keeper cannot redirect the proceeds
// (security review F-01). TL-B: https://docs.dedust.io/reference/tlb-schemes
//
//   swap#ea06185d query_id:uint64 amount:Coins _:SwapStep swap_params:^SwapParams = InMsgBody;
//   step#_ pool_addr:MsgAddressInt params:SwapStepParams = SwapStep;
//   step_params#_ kind:SwapKind limit:Coins next:(Maybe ^SwapStep) = SwapStepParams;
//   swap_params#_ deadline:Timestamp recipient_addr:MsgAddressInt referral_addr:MsgAddress
//                 fulfill_payload:(Maybe ^Cell) reject_payload:(Maybe ^Cell) = SwapParams;
//   payout#474f86cf query_id:uint64 payload:(Maybe ^Cell) = InMsgBody;

struct DedustSwapParams {
    deadline: uint32
    recipient: address
    /// addr_none: no referral.
    referral: address?
    fulfillPayload: cell?
    rejectPayload: cell?
}

/// Single-hop swap of native TON through `pool`. `kind` = given_in$0.
struct (0xea06185d) DedustNativeSwap {
    queryId: uint64
    amount: coins
    pool: address
    kind: bool
    limit: coins
    next: cell?
    params: Cell<DedustSwapParams>
}

/// TON sent back by the vault: the whole `amount` when the swap is rejected (limit / deadline),
/// or leftover gas after a successful one. Contracts accept it silently and reconcile on value.
struct (0x474f86cf) DedustPayout {
    queryId: uint64
    payload: cell?
}

/// Gas the vault + pool + jetton transfer chain needs on top of the swapped amount (DeDust SDK: 0.25 TON).
const DEDUST_SWAP_GAS = ton("0.25")

/// Seconds a swap message stays valid once sent (protects against a stale message executing on a moved price).
const DEDUST_SWAP_TTL = 300

fun buildDedustNativeSwap(queryId: uint64, amount: coins, pool: address, limit: coins, recipient: address): DedustNativeSwap {
    return {
        queryId,
        amount,
        pool,
        kind: false,
        limit,
        next: null,
        params: DedustSwapParams {
            deadline: (blockchain.now() + DEDUST_SWAP_TTL) as uint32,
            recipient,
            referral: null,
            fulfillPayload: null,
            rejectPayload: null,
        }.toCell(),
    };
}
