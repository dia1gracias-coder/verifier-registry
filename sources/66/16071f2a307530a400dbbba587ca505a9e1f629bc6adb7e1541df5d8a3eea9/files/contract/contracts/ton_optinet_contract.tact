import "@stdlib/deploy";

message Withdraw {
    user: Address;
    amount: Int as coins;
    fee: Int as coins;
}

message Invest {
    user: Address;
    referrer: Address;    
}
message TaxParam {
    percent: Int;
    taxAddress: Address;
}

message LevelSetting {
    level: Int;
    amount: Int as coins;
}

message RegistrationEvent {
    id: Int;
    user: Address;
    referrer: Address;
    amount: Int as coins;
}
message InvestEvent {
    user: Address;
    amount: Int as coins;
}
message WithdrawEvent {
    user: Address;
    amount: Int as coins;
}

struct User {
        id: Int;
        referrer: Address;
       
}
contract TonOptinetContract with Deployable {
    taxAddr: Address; 
    owner: Address;
    lastUserId: Int = 0;
    
    users: map<Address, User>;
    nodes: map<Int, Address>;
    contractId: Int as uint32; // This is an ID for contract deployment
    fun requireOnlyUser(user: Address){
        require(self.fn_IsUserExists(user), "invalid user");
    }
    fun requireOwner(){
        require(self.owner==sender(), "invalid owner");
    }
    fun requireValidAmount(amt: Int){
       require(amt>0, "incorrect amount");
       require(myBalance()>=amt, "insufficient balance");
    }
    fun requireValidInvest(){
       require(context().value>1, "invalid amount");
    }
    /*fun requireValidInvest(level: Int){
        require(context().value == self.map_level.get(level), "invalid invest");
    }*/
    fun fn_Registration(referrer: Address,user: Address,amt: Int) {
        require(!self.users.exists(user),"User exists");
        self.users.set(user, User{id: (self.lastUserId+1), referrer:  referrer});
        self.nodes.set((self.lastUserId+1),user);
        self.lastUserId=self.lastUserId+1;
        emit(RegistrationEvent{id: self.lastUserId, user: user, referrer: referrer, amount: amt}.toCell());
        
    }
    
    fun fn_IsUserExists(user: Address): Bool{
        return self.users.exists(user);
    }
    init(id: Int) {
        self.contractId = id;
        self.users = emptyMap(); 
        self.owner = address("UQBqd8r4VHf_PZtKGftDzUZKXcD5DwfjHexQqmFprtCqe9hF");
        self.taxAddr = address("UQBKwfX0DaWJ8AvOm-LwMa_0XvK35TxODBsTyfzrD3pe8ezg");
        self.fn_Registration(myAddress(), address("UQBsyOII9L9rDhBS3IKfouOK-LvnSFO-nZTZ6KB7ejpZKUY_"), 0);
       
    }

    receive(){
        //self.reply("accepted".asComment());
    }

    receive(msg: Invest){
        let _amount :Int = context().value;
        self.requireValidInvest();
        self.fn_Registration(msg.referrer, msg.user, _amount);    
    }
    receive("ReInvest"){
        let _amount :Int = context().value;
        self.requireValidInvest();
        emit(InvestEvent{user: sender(), amount: _amount}.toCell());
    }
    receive(msg: TaxParam){
        self.requireOwner();
        self.taxAddr = msg.taxAddress;
        self.reply("UpgradeTaxAddr".asComment());
    }


    receive(msg: Withdraw){
        self.requireOwner();
        self.requireValidAmount(msg.amount);
       
        send(SendParameters{
            to: msg.user,
            bounce: false,
            value: msg.amount,
            mode:1
        });
        send(SendParameters{
            to: self.taxAddr,
            bounce: false,
            value: msg.fee,
            mode:1
        });
        emit(WithdrawEvent{amount: msg.amount, user: msg.user}.toCell());
    }
    receive("withdrawAll") {
        self.requireOwner();
        let bal = myBalance();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
         emit(WithdrawEvent{amount: bal, user: self.owner}.toCell());
    }
    get fun balance(): Int{
        return myBalance();
    }
    get fun mycontractId(): Int{
        return self.contractId;
    }
    get fun isUserExists(key: Address): Bool{
        return self.fn_IsUserExists(key);
    }
    get fun User(key: Address): User{
        return self.users.get(key)!!;
    }
    get fun lastId(): Int{
        return self.lastUserId;
    }
    get fun nodes(inx: Int): Address{
        return self.nodes.get(inx)!!;
    }
    get fun owner(): Address{
        return self.owner;
    }
}
