import "@stdlib/deploy";

message Add {
    amount: Int as uint32;
}

struct GameUser {
    count: Int;
    address: Address;
}

contract SampleTactContract with Deployable {

    owner: Address;
    counter: Int as uint32;
    // mainAddress: Address;  //判断调用地址
    userData: map<Int,GameUser>;
    userCount: Int as int64;

    init(owner: Address) {
        self.owner = owner;
        self.counter = 0;
        self.userCount = 0;
        // self.mainAddress = address("0QD7FNDw0SQRNXpn-KP3A6RA-0H9rp1IKnUmzAzSvUsJgbR5");
        self.userData.set(0, GameUser{count:100000,address:address("0QD7FNDw0SQRNXpn-KP3A6RA-0H9rp1IKnUmzAzSvUsJgbR5")});
    }

    // fun dataInit(){
    //     //初始化数据
    //     self.owner = owner;
    //     self.counter = 0;
    //     self.userCount = 0;
    //     self.mainAddress = address("0QD7FNDw0SQRNXpn-KP3A6RA-0H9rp1IKnUmzAzSvUsJgbR5");
    // }

    fun add(v: Int) {
        // Check sender
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");
        
        // Update counter
        self.counter = (self.counter + v);
        // let data:GameUser = GameUser{count:100000,address:address("0QD7FNDw0SQRNXpn-KP3A6RA-0H9rp1IKnUmzAzSvUsJgbR5")};
        // self.userData.set(self.userCount, data); 
    }

    fun settlement(){
        //结算结果
    }

    receive(msg: Add) {
        self.add(msg.amount);
    }

    receive("increment") {
        self.add(1);
        self.reply("incremented".asComment());
    }

    get fun counter(): Int {
        return self.counter;
    }

    get fun gamedata(): map<Int,GameUser> {
        return self.userData;
    }

    
}
