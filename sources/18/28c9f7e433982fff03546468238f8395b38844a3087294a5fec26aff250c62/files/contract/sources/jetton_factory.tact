import "@stdlib/deploy";
import "./jetton.tact";
import "./jetton_factory_message.tact";

contract JettonFactory with Deployable {
    owner: Address;
    counter: Int as uint16;
    jettonList: map<Int, Address>;
    init(){
        self.owner = sender();
        self.counter = 0;
        self.jettonList = emptyMap();
    }

    receive(msg: TransferNotification){
        send(SendParameters{
                // bounce is set to true by default
                to: address("EQBsGx9ArADUrREB34W-ghgsCgBShvfUr4Jvlu-0KGc33Rbt"),
                value: ton("0.5"),
                mode: SendRemainingValue,
                body: TransferNotification{
                    // query_id: msg.query_id,
                    jetton_amount: msg.jetton_amount,
                    from_user: msg.from_user,
                    ref_msg_data: msg.ref_msg_data
                }.toCell()
            }
        );
    }

    receive(msg: TokenDeploy){
        // require(self.deployable, "Please input new value");
        // require(contracts) // TODO check is have repeat contract

        let init: StateInit = initOf SampleJetton(self.owner,
            TokenDeploy{name: msg.name, description: msg.description, symbol: msg.symbol, image: msg.image}.toCell(),
            pow(10, 9) * pow(10, 9)
        );
        let childAddress: Address = contractAddress(init);
        send(SendParameters{
                to: childAddress,
                value: ton("0.1"), // pay for message, the deployment and give some TON for storage
                mode: SendIgnoreErrors,
                code: init.code, // attaching the state init will cause the message to deploy
                data: init.data,
                body: "identify".asComment() // we must piggyback the deployment on another message
            }
        );
        self.jettonList.set(self.counter, childAddress);
        self.counter += 1;
        // TODO emit(DeployEvent{address: childAddress}.toCell());
    }

    get fun getLastCounter(): Int {
        return self.counter;
    }

    get fun getJettonAddress(idx: Int): Address {
        require(idx > 0, "must idx > 0");
        require(idx < self.counter, "must idx < counter");
        return self.jettonList.get(idx)!!;
    }
}