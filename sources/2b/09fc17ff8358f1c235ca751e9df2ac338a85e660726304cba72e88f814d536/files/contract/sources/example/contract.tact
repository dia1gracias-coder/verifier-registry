import "@stdlib/deploy";

const OP_PAY1: Int = 0x50415931;

message(OP_PAY1) Pay1 {
    beneficiary: Address;
    amount: Int as uint128;
}

contract Receivers with Deployable {
    init() {
    }

    receive(msg: Pay1) {
        let ctx = context();
        let send_value = ctx.value - 20_000_000; // 0.01 TON на комиссию сети
        send(SendParameters{
            to: msg.beneficiary,
            bounce: true,
            value: send_value,
            mode: SendBounceIfActionFail
        });
    }
}