// SPDX-License-Identifier: MIT

const OP_PAY1: Int = 0x50415931;         // 'PAY1'
const MIN_AMOUNT: Int = 1_000_000_000;   // 1 TON
const MIN_FEE_BP: Int = 500;             // 5%
const GAS_OVERHEAD: Int = 100_000_000;   // ~0.10 TON на 2 send

// Описываем бинарное сообщение с тем же опкодом.
// Tact сам сопоставит тело и вызовет соответствующий receive.
message(OP_PAY1) Pay1 {
    beneficiary: Address;
    payment_id: Int as int64;
    amount: Int as uint128;
    fee_bp: Int as uint16;
}

contract PaymentRouter {
    owner: Address;
    fee_wallet: Address;

    init(owner: Address, fee_wallet: Address) {
        self.owner = owner;
        self.fee_wallet = fee_wallet;
    }

    receive("external") { }

    receive(msg: Pay1) {
        let ctx = context();
        // требуем газ-буфер от отправителя
        require(ctx.value >= msg.amount + GAS_OVERHEAD, "add gas buffer");
        require(msg.amount >= MIN_AMOUNT, "declared < 1 TON");
        require(msg.fee_bp >= MIN_FEE_BP, "fee too low");

        let fee = (msg.amount * msg.fee_bp) / 10_000;
        let net = msg.amount - fee;
        require(net > 0, "bad math");

        // тело, которое пойдёт в out_msgs (для воркера)
        let out_body = beginCell()
        .storeUint(OP_PAY1, 32)
        .storeAddress(msg.beneficiary)
        .storeInt(msg.payment_id, 64)
        .storeUint(msg.amount, 128)
        .storeUint(msg.fee_bp, 16)
        .endCell();

        // Донатер платит газ (mode не указываем).
        send(SendParameters{
            to: self.fee_wallet,
            value: fee,
            body: out_body,
        });
        send(SendParameters{
            to: msg.beneficiary,
            value: net,
            body: out_body,
        });
    }

    receive(_: Slice) {
        throw(130); // unknown message
    }
}