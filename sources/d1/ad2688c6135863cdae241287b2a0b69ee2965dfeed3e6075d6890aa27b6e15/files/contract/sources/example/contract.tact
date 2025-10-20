import "@stdlib/deploy";

const OP_PAY1: Int = 0x50415931;

message(OP_PAY1) Pay1 {
    beneficiary: Address;
    amount: Int as uint128;
}

contract Receivers with Deployable {
    init() {}

    receive(msg: Pay1) {
        let ctx = context();
        let send_value = ctx.value - ton("0.01");
        require(!msg.beneficiary.asSlice().empty(), "beneficiary is empty");
        send(SendParameters{
            to: msg.beneficiary,
            bounce: true,
            value: send_value,
            mode: SendBounceIfActionFail
        });
    }
}