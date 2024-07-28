import "@stdlib/deploy";
import "./jetton";

message Mint {
    amount: Int;
    receiver: Address;
}

message Withdraw {
    
}

message WithdrawAmount{
    amount: Int as coins;
}

message UpdateCharge{
    newCharge: Int as uint64;
}

message MinTonMessage{
    newValue: Int as uint64;
}

message UpdateCollector{
    newAddress: Address;
}

message UpdateTonForMint{
    newTonAmount: Int as uint64;
}

contract TemplateForJetton with Jetton, Deployable {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    collector: Address;

    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.

    minTonForStorage: Int as uint64 = ton("0.015"); // can also use 0.015

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.collector = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
    }

    fun updateMinForStorage(data: MinTonMessage){
        self.checkOwner();
        self.minTonForStorage = data.newValue;
    }
    receive(data: MinTonMessage){
        self.updateMinForStorage(data);
    }

    receive("revoke"){
        self.checkOwner();
        //UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ non-bounceable address of zero address
        self.owner = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ"); //UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ
    }

    fun checkOwner(){
        require(sender() == self.owner, "Not owner");
    }

    fun withdrawSafe(){ //withdraw ton balance
        send(SendParameters{
            to: self.collector,
            bounce: true,
            value: myBalance() - context().value - self.minTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }
    receive(msg: Withdraw){
        self.withdrawSafe();
    }

    chargePerMint: Int = ton("0.2");

    receive(msg: UpdateCharge){
        self.checkOwner();
        self.chargePerMint = msg.newCharge;
    }

    //take a particular amount and then send back some amount to sender
    fun sendBack(){
        let tonAmount: Int = context().value; //amount of ton sent in this message
        
        let sendBackAmount: Int = tonAmount/3;

    }

    receive(msg: UpdateCollector){
        self.checkOwner();
        self.collector = msg.newAddress;
    }

    fun withdrawAmount(msg: WithdrawAmount){ //withdraw amount of ton
        let amount: Int = min(msg.amount, myBalance() - context().value - self.minTonForStorage);
        require(amount > 0, "Insufficient balance");
        send(SendParameters{
            to: self.collector,
            bounce: true,
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }
    receive(msg: WithdrawAmount){
        self.withdrawAmount(msg);
    }

    amountTonForMint: Int as uint64 = ton("0.2");

    receive(msg: UpdateTonForMint){
        self.checkOwner();
        self.amountTonForMint = msg.newTonAmount;
    }

    get fun ChargePerMint(): Int{
        return self.amountTonForMint;
    }

    receive(){//receive empty incoming message

    }
    receive(msg: String){//receive incoming message with arbitrary text different from others clearly specified

    }

    /*fun chargeMint(){
        let tonAmountReceived: Int = context().value;
        require(tonAmountReceived >= self.amountTonForMint, "Ton Amount not Enough");
    }*/

    receive("mint"){
        let tonAmount: Int = context().value; //amount of ton from incoming message
        //let tokenAmount: Int = msg.tokenAmount;//amount in single unit eg. 1-1million, 50-50million etc, 4000-4billion
        let unitAfterDiv: Int = tonAmount / self.amountTonForMint; //tonAmount = self.amountTonForMint;
        
        let tokenAmountFinal: Int = unitAfterDiv * ton("1000000");
        require(self.mintable, "Not mintable");
        require(self.total_supply + tokenAmountFinal <= self.max_supply, "Max supply exceeded");
        self.mint(sender(), tokenAmountFinal, self.owner);
        
        send(SendParameters{
            to: self.collector, //myAddress(),//self.collector, //sender(),
            bounce: true,
            value: 0, //myBalance() - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: "Mint Successful".asComment(),
        });
    }

    /*receive("mint2") { // Public Minting 1million unit per mint
        //let ctx: Context = context();
        self.chargeMint();
        require(self.mintable, "Not mintable");
        require(self.total_supply + ton("1000000") <= self.max_supply, "Max supply exceeded");
        self.mint(sender(), ton("1000000"), self.owner);
        
        send(SendParameters{
            to: self.collector, //myAddress(),//self.collector, //sender(),
            bounce: true,
            value: 0, //myBalance() - context().value - self.MinTonForStorage,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: "Mint Successful".asComment(),
        });
    }*/

    receive("mint_close") {
        //let ctx: Context = context();
        require(sender() == self.owner, "Not owner");
        self.mintable = false;
    }
} 