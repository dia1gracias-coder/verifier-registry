import "@stdlib/deploy";


message Withdraw {
    user: Address;
    amount: Int as coins;
}

message Invest {
    user: Address;
    referrer: Address;    
}

message LevelSetting {
    level: Int;
    amount: Int as coins;
}

message RegistrationEvent {
    id: Int;
    user: Address;
    referrer: Address;
    level: Int;
}
message UpgradeEvent {
    user: Address;
    level: Int;
}
message WithdrawEvent {
    user: Address;
    amount: Int as coins;
}

    struct User {
        id: Int;
        referrer: Address;
        level: Int;
    }

contract SendTon with Deployable {
    const MinTonForStorage: Int = ton("0"); //ton("0.01"); // 1 KB for 2.5 year
    map_level: map<Int, Int as coins>;
    owner: Address;
    lastUserId: Int = 0;
    users: map<Address, User>;
    nodes: map<Int, Address>;
    contractId: Int as uint32; // This is an ID for contract deployment
    fun onlyOwner(){
        require(sender() == self.owner, "invalid owner");
    }
    fun onlyUser(user: Address){
        require(self.users.exists(user), "invalid user");
    }
    fun valid_Balance(amount: Int){
       require(amount>0, "invalid balance");
    }
    fun valid_LevelAmount(level: Int){
        require(context().value == self.map_level.get(level), "invalid amount");
    }
    fun fn_Registration(referrer: Address,user: Address) {
        require(!self.users.exists(user),"User exists");
        self.users.set(user, User{id: (self.lastUserId+1), referrer:  referrer, level: 1});
        self.nodes.set((self.lastUserId+1),user);
        self.lastUserId=self.lastUserId+1;
        emit(RegistrationEvent{id: self.lastUserId, user: user, referrer: referrer, level: 1}.toCell());
    }
    fun fn_UpdateUserLevel(user: Address, level: Int) {
        if(self.users.exists(user))
        { 
           let mustHaveGotOrErrored: User = self.users.get(user)!!;
           self.users.del(user);
           self.users.set(user, User{id: mustHaveGotOrErrored.id, referrer:  mustHaveGotOrErrored.referrer, level: level});
        }
        emit(UpgradeEvent{user: user, level:level}.toCell());
    }
    fun fn_LevelSetting(level: Int, amount: Int) {  
        if(self.map_level.exists(level)){
              self.map_level.del(level); 
        }
        self.map_level.set(level,amount);
    }
    fun fn_IsUserExists(user: Address): Bool{
        return self.users.exists(user);
    }
    init(id: Int) {
        // Init the id assed from the contructor
        self.contractId = id;
        self.users = emptyMap(); 
        self.owner = sender();
        // registering the owner as initial user
        self.fn_Registration(myAddress(), self.owner);
        // setting intial level
        self.fn_LevelSetting(1,ton("1"));
    }

    receive(){
        // accept incoming TON transfers
    }

    receive(msg: LevelSetting){
        self.onlyOwner();
        // setting of level amount
        self.fn_LevelSetting(msg.level, msg.amount);
    }

    receive(msg: Invest){
        self.onlyUser(msg.referrer);
        self.valid_LevelAmount(1);
        // registering the users basis of referral
        self.fn_Registration(msg.referrer, msg.user);
    }

    receive("ReInvest"){
        self.onlyUser(sender());
        self.valid_LevelAmount(self.users.get(sender())!!.level+1);
        // upgrading the users one level ahead.0
        self.fn_UpdateUserLevel(sender(),self.users.get(sender())!!.level+1);     
    }


    receive(msg: Withdraw){
        self.onlyOwner();
        self.onlyUser(msg.user);
        let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
        self.valid_Balance(amount);
        send(SendParameters{
            to: msg.user,
            bounce: true,
            value: amount,
            mode: SendIgnoreErrors + SendRemainingValue
        });
        emit(WithdrawEvent{amount: amount, user: msg.user}.toCell());
    }
    
    get fun balance(): Int{
        return myBalance();
    }
    get fun contractId(): Int{
        return self.contractId();
    }
    get fun isUserExists(key: Address): Bool{
        return self.fn_IsUserExists(key);
    }
    get fun User(key: Address): User{
        return self.users.get(key)!!;
    }
    get fun levelAmount(key: Int): Int{
        return self.map_level.get(key)!!;
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
