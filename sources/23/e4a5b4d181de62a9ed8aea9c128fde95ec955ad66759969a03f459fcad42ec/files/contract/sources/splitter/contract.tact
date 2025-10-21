// SPDX-License-Identifier: MIT
import "@stdlib/deploy";

const MIN_AMOUNT: Int = ton("1");   // 1 TON
const MIN_FEE_BP: Int = 500;             // 5%
const GAS_OVERHEAD: Int = ton("0.02");

message(0x50415931) Pay1 {
    beneficiary: Address;
    payment_id: Int as int64;
    amount: Int as uint128;
    fee_bp: Int as uint16;
    comment: String;
}

contract PaymentRouter with Deployable {
    owner: Address;
    fee_wallet: Address;

    init(owner: Address, fee_wallet: Address) {
        self.owner = owner;
        self.fee_wallet = fee_wallet;
    }

    receive(msg: Pay1) {
        let ctx = context();
        throwUnless(9400, ctx.value >= msg.amount + GAS_OVERHEAD);
        throwUnless(49357, msg.amount >= MIN_AMOUNT);
        throwUnless(57649, msg.fee_bp >= MIN_FEE_BP);
        throwUnless(57649, msg.fee_bp >= MIN_FEE_BP);
        throwUnless(57649, msg.fee_bp >= MIN_FEE_BP);
        throwUnless(57649, msg.fee_bp >= MIN_FEE_BP);

        let fee = (msg.amount * msg.fee_bp) / 10_000;
        let net = msg.amount - fee;
        throwUnless(32622, net > 0);
        let commissionComment = beginComment();

        commissionComment.append("999:commission_by_");
        commissionComment.append(msg.comment);

        message(MessageParameters{
            to: self.fee_wallet,
            value: fee,
            bounce: true,
            body: commissionComment.toCell(),
            mode: SendBounceIfActionFail,
        });

        message(MessageParameters{
            to: msg.beneficiary,
            value: net,
            bounce: true,
            body: msg.comment.asComment(),
            mode: SendBounceIfActionFail
        });
    }
}