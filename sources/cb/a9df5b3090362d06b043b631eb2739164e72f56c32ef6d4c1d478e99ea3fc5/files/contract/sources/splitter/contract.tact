// SPDX-License-Identifier: MIT
import "@stdlib/deploy";

const OP_PAY1: Int = 0x50415931;         // 'PAY1'
const MIN_AMOUNT: Int = ton("1");   // 1 TON
const MIN_FEE_BP: Int = 500;             // 5%
const GAS_OVERHEAD: Int = ton("0.02");

// Описываем бинарное сообщение с тем же опкодом.
// Tact сам сопоставит тело и вызовет соответствующий receive.
message(OP_PAY1) Pay1 {
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
        // требуем газ-буфер от отправителя
        require(ctx.value >= msg.amount + GAS_OVERHEAD, "add gas buffer");
        require(msg.amount >= MIN_AMOUNT, "declared < 1 TON");
        require(msg.fee_bp >= MIN_FEE_BP, "fee too low");

        let fee = (msg.amount * msg.fee_bp) / 10_000;
        let net = msg.amount - fee;
        require(net > 0, "bad math");


        send(SendParameters{
            to: self.fee_wallet,
            value: fee,
            bounce: true,
            body: "123".asComment(),
            mode: SendBounceIfActionFail,
        });

        send(SendParameters{
            to: msg.beneficiary,
            value: net,
            bounce: true,
            body: "123".asComment(),
            mode: SendBounceIfActionFail
        });
    }
}