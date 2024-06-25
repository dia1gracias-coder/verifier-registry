import "@stdlib/deploy";
import "@stdlib/ownable";
import "./jetton";

message AddToWhitelist {
    addressList: map<Int, Address>;
    amountList: map<Int, Int>;
    length: Int;
}

message SingleAddToWhitelist {
    user: Address;
    amount:  Int;
}

message ClaimEvent {
    user: Address;
    amount: Int;
}

message UserAddedEvent {
    user: Address;
    amount: Int;
}

contract IDOContract with Deployable, Jetton {
    owner: Address;
    white_list: map<Address, Int>;

    max_supply: Int as coins;
    total_supply: Int as coins;
    mintable: Bool;
    content: Cell;

    init(owner: Address, content: Cell, max_supply: Int) {
        self.owner = owner;
        self.white_list = emptyMap();
        self.total_supply = 0;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
    }
    
    receive(msg: AddToWhitelist) {
        self.requireOwner();
        let i: Int = 0;
        while(i < msg.length) {
            let addr: Address = msg.addressList.get(i)!!;
            let amount: Int = msg.amountList.get(i)!!;
            self.white_list.set(addr, amount);
        }
    }

    receive(msg: SingleAddToWhitelist) {
       require(msg.amount>0, "Invalid amount");

       self.white_list.set(msg.user, msg.amount);
       emit(UserAddedEvent{amount: msg.amount, user: msg.user}.toCell());
    }

    receive("claim") {
        let ctx: Context = context();
        let sender: Address = ctx.sender;
        let amount: Int = self.white_list.get(sender)!!;

        // mint token to user
        self.mint(sender, amount, self.owner);
        require(self.total_supply + amount <= self.max_supply, "Max supply exceeded");

        // after claim, set white_list to null
        self.white_list.set(ctx.sender, null);
        emit(ClaimEvent{amount: amount, user: ctx.sender}.toCell());
    }

    get fun getWhiteList(): map<Address, Int> {
        return self.white_list;
    }
}

