import "./constant";
import "./organization";

message(0x2a732d61) OrgInitRequest {
    content: Cell;
    wallet: Address;
}

contract OrganizationFactory {
    receive(msg: OrgInitRequest) {
        throwUnless(TOO_FEW_COINS, context().value >= MIN_COINS);
        
        deploy(DeployParameters {
            init:  initOf Organization(msg.content, sender()),
            value: DEPLOY_COINS,
        });

        message(MessageParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: Excesses {}.toCell(),
        });
    }

    receive() { cashback(sender()) }
}
