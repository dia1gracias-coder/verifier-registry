import "@stdlib/ownable";
import "./messages";
import "./jetton";
import "@stdlib/deploy";

contract FeeContract with Deployable, Ownable {
    owner: Address;
    numerator: Int as uint64 = 0;
    denominator: Int as uint64 = 1;

    init(owner: Address) {
        self.owner = owner;
    }

    receive(msg: TokenTransfer) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: TokenTransferWithFee{
                    query_id: msg.query_id,
                    amount: msg.amount,
                    destination: msg.destination,
                    numerator: self.numerator,
                    denominator: self.denominator,
                    response_destination: msg.response_destination,
                    custom_payload: msg.custom_payload,
                    forward_ton_amount: msg.forward_ton_amount,
                    forward_payload: msg.forward_payload
                }.toCell()
        });
    }
    receive(msg: ChangeFee) {
        self.requireOwner();
        require(100*msg.numerator/msg.denominator<=10, "Too big commission"); // 10% - max //Exit code - 51252
        self.numerator = msg.numerator;
        self.denominator = msg.denominator;
    }


    get fun get_fee(): FeeData {
        return FeeData{
            owner: self.owner,
            numerator: self.numerator,
            denominator: self.denominator
        };
    }
}