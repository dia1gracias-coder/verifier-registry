import "./sample_jetton.tact";

message DeployJetton {
    owner: Address;
    content: Cell;
    max_supply: Int;
}

contract JettonFactory with Deployable, Ownable {

    owner: Address;

    init(owner: Address) {
        self.owner = owner;
    }

    receive(msg: DeployJetton) {
        let ctx: Context = context();
        let creator: Address = ctx.sender;
        self.deployJetton(msg.owner, msg.content, msg.max_supply);
    }

    fun deployJetton(owner: Address, content: Cell, max_supply: Int) {
        let jettonInit: StateInit = initOf SampleJetton(owner, content, max_supply);
        send(SendParameters{
            to: contractAddress(jettonInit),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: Mint{
                amount: 100000000000000000,
                receiver: owner
            }.toCell(),
            code: jettonInit.code,
            data: jettonInit.data
        });
    }
}
