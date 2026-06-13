// Storage + messages for the per-job escrow / HTLC settlement contract.
// See BLOCKCHAIN_ECONOMICS §4 (earning function), §6.2 (who gets paid), and the
// "HTLC-style escrow release keyed on the quorum result-hash" recommendation
// in §13. Non-custodial: the arbiter can only DIRECT payouts bounded by the
// locked escrow B and gated on the agreed result hash; it can never seize funds,
// and any leftover always refunds to the requester.
//
// Touched by PAID jobs only. Free jobs never open an escrow (§8.2).

import "common"

const OP_ESCROW_SETTLE = 0x4553_4302
const OP_ESCROW_REFUND = 0x4553_4303
const OP_ESCROW_TOPUP = 0x4553_4300

struct EscrowTerms {
    treasury: address     // platform-fee recipient
    expectedHash: uint256 // HTLC lock: settle must present this quorum result hash
}

struct EscrowStorage {
    requester: address  // who funded B and receives refunds
    arbiter: address    // quorum oracle / coordinator authorized to settle
    escrowAmount: coins // B — the requester's max bid, locked up front
    deadline: uint32    // refund-on-timeout deadline (unix secs)
    settled: bool
    terms: Cell<EscrowTerms>
}

fun EscrowStorage.load(): EscrowStorage {
    return EscrowStorage.fromCell(contract.getData());
}

fun EscrowStorage.save(self) {
    contract.setData(self.toCell());
}

// Settle after the quorum verdict. `participants` maps each agreeing non-winner
// to its fixed participation commission (§6.2). `winnerAmount` is base + perf
// bonus. Any escrow not paid out refunds to the requester.
struct (0x4553_4302) EscrowSettle {
    queryId: uint64
    resultHash: uint256 // the agreed quorum hash — must equal terms.expectedHash
    winner: address
    winnerAmount: coins
    platformFee: coins
    participants: map<address, coins>
}

struct (0x4553_4303) EscrowRefund {
    queryId: uint64
}

struct (0x4553_4300) EscrowTopUp {
    queryId: uint64
}

struct EscrowState {
    escrowAmount: coins
    deadline: uint32
    settled: bool
}
