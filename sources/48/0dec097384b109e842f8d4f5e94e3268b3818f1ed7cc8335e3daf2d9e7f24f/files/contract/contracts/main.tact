import "@stdlib/deploy";
import "./messages.tact";

contract Main with Deployable {
    // Empty init() function is present by default in all Tact contracts
    // since v1.3.0, so the following may be omitted:
    //

    jettonToken: Address;
    init(_jettonToken: Address) {
        self.jettonToken = _jettonToken;
    }

    receive("sendToken") {
        send(SendParameters{
                to: self.jettonToken,
                value: 0,
                mode: (SendRemainingValue + SendIgnoreErrors),
                bounce: false,
                body: TokenTransfer{
                    query_id: 0,
                    amount: 10,
                    sender:myAddress(),
                    response_destination:  context().sender,
                    custom_payload: null,
                    forward_ton_amount: ton("0.01"),
                    forward_payload: emptySlice()
                }.toCell()
            }
        );
    }
}
