import "@stdlib/deploy";
import "@stdlib/ownable";
import "./traits/skate/ISkateAction.tact"; // implicit

message(0x75a6e8ec) TopUpTON {}
message(0x44807e69) WithdrawTON {}

contract SkateActionBox with Deployable, OwnableTransferable  {
    owner: Address;
    version_id: Int;
    get fun version_id(): Int {
        return self.version_id;
    }
    init(owner: Address, version_id: Int) {
        self.owner = owner;
        self.version_id = version_id;
    }

    /////////////////////////////////////////////////////////
    ////////////////////// GOVERNANCE ///////////////////////
    receive(msg: TopUpTON) {
        // Do nothing, just accept TON.
    }

    receive(msg: WithdrawTON) {
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
        })
    }
    /////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////
    //////////////////// Emission Layer /////////////////////
    action_id: Int = 0;
    get fun action_id(): Int {
        return self.action_id;
    }
    receive(msg: InitiateSkateAction) {
        self.action_id += 1;
        emit(SkateActionCreated{action: msg.action, action_id: self.action_id}.toCell());
        // TODO: Apply processing fees.
        self.forward(msg.excess_receiver, null, true, null);
    }
    /////////////////////////////////////////////////////////
}

