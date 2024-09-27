import "@stdlib/ownable";
import "../../jetton/contract";
import "./messages";

trait BridgeBank with Ownable {
    owner: Address;
    operator: Address;
    tokenDeployer: Address;

    bridgeTokenCount: Int;
    bridgeTokenWhitelist: map<Address, Bool>;
    bridgeTokenCreated: map<Int, Bool>;
    symbol2address: map<Int, DeployedJetton>;

    fun mint(masterAddr: Address, receiver: Address, amount: Int, seqNo:Int) {
        self.mintBridgeToken(masterAddr, receiver, amount, seqNo)
    }

    fun deployNewBridgeToken(owner: Address, content: Cell, max_supply: Int, symbol:String) {
        let winit: StateInit = initOf SampleJetton(owner, content, max_supply);
        let masterAddress: Address = contractAddress(winit);
        self.bridgeTokenWhitelist.set(masterAddress, true);

//        let contentInfo: JettonBasicInfo = JettonBasicInfo.fromCell(content);
//        let symbol: Slice = contentInfo.symbol.asSlice();
        let symbolBuilder: StringBuilder = beginString();
        symbolBuilder.append(symbol);
        let symbolHash: Int = symbolBuilder.toCell().hash();
        require(self.bridgeTokenCreated.get(symbolHash) != true, "The same token has been deployed");

        send(SendParameters{
                to: masterAddress,
                value: ton("0.1"),
                mode:  SendIgnoreErrors,
                bounce: true,
                body: "deploy".asComment(),
                code: winit.code,
                data: winit.data
            }
        );

        self.bridgeTokenCreated.set(symbolHash, true);
        let newDeployedJetton: DeployedJetton = DeployedJetton{
            symbol: symbol,
            master: masterAddress,
        };
        self.bridgeTokenCount += 1;

        self.symbol2address.set(self.bridgeTokenCount, newDeployedJetton);
        emit(LogNewBridgeTokenEvent{masterAddr:masterAddress, symbol: symbol}.toCell());
    }

    fun mintBridgeToken(masterAddr:Address, receiver:Address, amount:Int, seqNo:Int) {
        require(self.bridgeTokenWhitelist.get(masterAddr) == true, "No jetton created with the input master address");
        send(SendParameters{
                to: masterAddr,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: Mint{
                    amount: amount,
                    receiver: receiver,
                    seqNo:seqNo,
                }.toCell()
            }
        );
        emit(MintBridgeToken{masterAddr:masterAddr, receiver: receiver, amount:amount}.toCell());
    }
}
