import "@stdlib/deploy";
import "@stdlib/ownable";

message SetWinFeeParams {
    winFee: Int;
}

message SetAllowParams {
    allowSize: Int;
    allows: map<Int, Int>;
}

contract CoinFlip with OwnableTransferable {
    owner: Address;
    winFee: Int = 7;
    
    allowSize: Int;
    allows: map<Int, Int>;
    
    init(owner_: Address, winFee_: Int) {
        self.owner = owner_;
        self.winFee = winFee_;
        
        self.allowSize = 5;
        self.allows.set(0, 1000000000);
        self.allows.set(1, 3000000000);
        self.allows.set(2, 5000000000);
        self.allows.set(3, 7000000000);
        self.allows.set(4, 9000000000);
    }   
    
    receive("flip") {
        let ctx: Context = context();
        let amount: Int = ctx.value;
        let sender: Address = ctx.sender;
    
    
        let hasAllow: Bool = false;
        let i: Int = 0;
        do {
            let allowAmount: Int = self.allows.get(i)!!;
            if amount == allowAmount {
                hasAllow = true;
            }
            i += 1;
        } until (i != self.allowSize || hasAllow);
            
        // require(hasAllow, "Flip: value is not in allow list");
        
        
        let win:Int = random(0,2);
        if (win == 0) {
            let value:Int = amount * (100 - self.winFee) / 100 + amount;
            send(SendParameters{
                value: value,
                to: sender,
                mode: SendIgnoreErrors
            });
        }
    }
    
    receive("withdraw") {
        self.requireOwner();
        send(SendParameters{value: 0, to: self.owner, mode: SendRemainingBalance });
    }
    
    receive(msg: SetWinFeeParams) {
        self.requireOwner();
        self.winFee = msg.winFee;
    }
    
    receive(msg: SetAllowParams) {
        self.requireOwner();
        self.allowSize = msg.allowSize;
        self.allows = msg.allows;
    }
}