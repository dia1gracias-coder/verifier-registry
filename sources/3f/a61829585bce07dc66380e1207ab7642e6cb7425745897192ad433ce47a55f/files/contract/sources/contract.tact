import "@stdlib/deploy";
import "./messages";

contract MinterProxyContract with Deployable {
    owner: Address;
    superOperator: Address;
    jettonMasterAddress: Address;
    jettonWalletAddress: Address;
    const MinTonForStorage: Int = ton("0.1");

    init(owner: Address, jettonMasterAddress: Address, jettonWalletAddress: Address) {
        self.owner = owner;
        self.superOperator = owner;
        self.jettonMasterAddress = jettonMasterAddress;
        self.jettonWalletAddress = jettonWalletAddress;
    }

    receive(msg: JettonMint) {
        let sender: Address = sender();
        require(sender == self.owner, "Not owner");
        let op: Operation = msg.operation;
        send(SendParameters{
            to: self.jettonMasterAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: Mint{
                amount: op.jetton_amount,
                receiver: msg.to_address
            }.toCell(),
        });
    }
    receive(msg: UpdateJettonOwnerAddress) {
        require(sender() == self.superOperator, "Not operator");
        send(SendParameters{
            to: self.jettonMasterAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: UpdateOwnerAddress{
                address: msg.address,
            }.toCell(),
        });
    }

    receive() {}
    receive("withdrawTONSafe"){
        let withdrawValue: Int = ((myBalance() - context().value) - self.MinTonForStorage);
        require(sender() == self.superOperator && withdrawValue > 0, "Not owner");
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: withdrawValue,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }
    receive(msg: UpdateContractOwnerAddress) {
        require(sender() == self.superOperator, "Not operator");
        self.owner = msg.address;
        self.reply("Owner updated".asComment());
    }
    receive(msg: UpdateSuperOperatorAddress) {
        require(sender() == self.superOperator, "Not operator");
        self.superOperator = msg.address;
        self.reply("Super operator address updated".asComment());
    }
    receive(msg: UpdateJettonMasterAddress) {
        require(sender() == self.superOperator, "Not operator");
        self.jettonMasterAddress = msg.address;
        self.reply("Jetton master address updated".asComment());
    }
    receive(msg: UpdateJettonWalletAddress) {
        require(sender() == self.superOperator, "Not operator");
        self.jettonWalletAddress = msg.address;
        self.reply("Jetton master address updated".asComment());
    }
    get fun get_contract_data(): ContractData {
        return ContractData{ 
            owner: self.owner,
            superOperator: self.superOperator,
            jettonMasterAddress: self.jettonMasterAddress,
            jettonWalletAddress: self.jettonWalletAddress
        };
    }
}
