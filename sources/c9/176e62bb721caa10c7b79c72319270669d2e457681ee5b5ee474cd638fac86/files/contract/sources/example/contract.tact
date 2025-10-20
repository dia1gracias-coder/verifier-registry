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
        let value = ctx.value;
        send(SendParameters{
            to: msg.beneficiary,
            bounce: true,
            value: 0,
            mode: SendIgnoreErrors
        });
    }
}