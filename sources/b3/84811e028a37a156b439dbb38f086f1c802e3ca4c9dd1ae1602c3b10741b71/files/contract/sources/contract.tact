import "@stdlib/deploy";
import "./messages";

contract MinterProxyContract with Deployable {
    owner: Address;
    superOperator: Address;
    jettonMasterAddress: Address;
    jettonWalletAddress: Address;
    MinTonForStorage: Int = ton("0.1");
    jettonData: JettonData;

    init(owner: Address, jettonMasterAddress: Address, jettonWalletAddress: Address, jettonData: JettonData) {
        self.owner = owner;
        self.superOperator = owner;
        self.jettonMasterAddress = jettonMasterAddress;
        self.jettonWalletAddress = jettonWalletAddress;
        self.jettonData = jettonData;
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
    receive(msg: JettonChangeAdmin) {
        let sender: Address = sender();
        require(sender == self.owner, "Not owner");
        send(SendParameters{
            to: self.jettonMasterAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: UpdateOwnerAddress{
                address: msg.new_admin_address,
            }.toCell(),
        });
    }
    receive(msg: JettonTransfer) {
        let sender: Address = sender();
        require(sender == self.owner, "Not owner");
        send(SendParameters{
            to: self.jettonWalletAddress,
            value: 0,
            mode: SendRemainingValue, 
            bounce: true,
            body: TokenTransfer{
                query_id: msg.query_id,
                amount: msg.amount,
                destination: msg.destination,
                response_destination: msg.response_destination,
                custom_payload: msg.custom_payload,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: msg.forward_payload
            }.toCell(),
        });
    }
    
    receive(msg: TokenExcesses) {
        commit();
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
        self.reply("Jetton wallet address updated".asComment());
    }
    receive(msg: UpdateJettonData) {
        require(sender() == self.superOperator, "Not operator");
        self.jettonData = msg.data;
        self.reply("Jetton data updated".asComment());
    }
    get fun get_contract_data(): ContractData {
        return ContractData{ 
            owner: self.owner,
            superOperator: self.superOperator,
            jettonMasterAddress: self.jettonMasterAddress,
            jettonWalletAddress: self.jettonWalletAddress
        };
    }
    get fun get_jetton_data(): JettonData {
        return self.jettonData;
    }
    get fun get_wallet_address(owner: Address): Address {
        return self.jettonWalletAddress;
    }
}
