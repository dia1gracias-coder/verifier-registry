// SPDX-License-Identifier: MIT
import "@stdlib/deploy";

const MIN_AMOUNT: Int = ton("1");   // 1 TON
const MIN_FEE_BP: Int = 500;             // 5%
const SINGLE_TRX_GAS_OVERHEAD: Int = ton("0.01");
const DOUBLE_TRX_GAS_OVERHEAD: Int = ton("0.02");
const MIN_TON_FOR_STORAGE: Int = ton("0.01");

message(0x50415931) Pay1 {
    beneficiary: Address;
    payment_id: Int as int64;
    amount: Int as uint128;
    fee_bp: Int as uint16;
    referer: Address?;
    comment: String;
}

contract PaymentRouter with Deployable {
    owner: Address;

    init(owner: Address) {
        self.owner = owner;
    }

    receive() {}

    receive(msg: Pay1) {
        let ctx = context();
        let gas_overhead = msg.referer != null ? DOUBLE_TRX_GAS_OVERHEAD : SINGLE_TRX_GAS_OVERHEAD;
        throwUnless(9400, ctx.value >= msg.amount + gas_overhead);
        throwUnless(49357, msg.amount >= MIN_AMOUNT);
        throwUnless(57649, msg.fee_bp >= MIN_FEE_BP);

        let fee = (msg.amount * msg.fee_bp) / 10_000;
        let net = msg.amount - fee;
        throwUnless(32622, net > 0);

        if (msg.referer != null) {
            let ref_share = fee / 5;
            let max_ref_share = (msg.amount * 100) / 10_000;
            if (ref_share > max_ref_share) {
                ref_share = max_ref_share;
            }
            message(MessageParameters{
                to: msg.referer!!,
                value: ref_share,
                bounce: true,
                body: msg.comment.asComment(),
                mode: SendBounceIfActionFail
            });
        }

        message(MessageParameters{
            to: msg.beneficiary,
            value: net,
            bounce: true,
            body: msg.comment.asComment(),
            mode: SendBounceIfActionFail
        });
    }

    receive("withdraw") {
        let bal = myBalance();
        throwUnless(403, sender() == self.owner);
        throwUnless(404, bal > MIN_TON_FOR_STORAGE);
        message(MessageParameters{
            to: sender(),
            bounce: true,
            value: bal - context().value - MIN_TON_FOR_STORAGE,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }
}