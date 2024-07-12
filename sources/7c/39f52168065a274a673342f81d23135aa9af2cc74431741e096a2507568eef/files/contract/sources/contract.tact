import "./jetton";

message Mint {
    amount: Int;
    receiver: Address;
}

message Reward {
    amount: Int;
    receiver: Address;
    transId: String?;
    date: Int?;
}

message MultiReward {
    data: map<Address, Int>;
    totalAmount: Int;
}

message AddToBlacklist {
    address: Address;
}

message RemoveFromBlacklist {
    address: Address;
}

message AuthorizeOperator {
    address: Address;
}

message RevokeOperator {
    address: Address;
}

message AddToWhitelist {
    address: Address;
}

message RemoveFromWhitelist {
    address: Address;
}

message SetUsingWhitelistStatus {
   status: Bool; 
}

contract UXUYJetton with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;
    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.

    _blacklist: map<Address, Bool>;
    _whitelist: map<Address, Bool>;
    isUsingWhitelist: Bool;
    superOperators: map<Address, Bool>;
    _paused: Bool;

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content; 
        self.max_supply = max_supply;

        self.isUsingWhitelist = true;
        self.superOperators.set(owner, true);
        self._paused = false;
    }

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(msg.amount > 0, "amount Cannot be the zero");
        require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive(msg: Reward) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        require(self.mintable, "Not mintable");
        require(msg.amount > 0, "amount Cannot be the zero");
        require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.reward(ctx.sender, msg.receiver, msg.amount, ctx.sender); // (to, amount, response_destination)
    }

    receive("Mint:100") { // Public Minting
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(self.total_supply + 100 <= self.max_supply, "Max supply exceeded");
        self.mint(ctx.sender, 100, self.owner); // 🔴 
    }

    receive("Pause") {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self._requireNotPaused();
        self._paused = true;
    }

    receive("Unpause") {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self._requirePaused();
        self._paused = false;
    }

    receive(msg: AddToBlacklist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._blacklist.get(msg.address);
        require(isIn != true, "User is already on the blacklist.");
        self._blacklist.set(msg.address, true);
    }

    receive(msg: RemoveFromBlacklist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._blacklist.get(msg.address);
        require(isIn == true, "User is not on the blacklist.");
        self._blacklist.set(msg.address, null);
    }

    receive(msg: AuthorizeOperator) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.superOperators.set(msg.address, true);
    }

    receive(msg: RevokeOperator) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.superOperators.set(msg.address, false);
    }

    receive(msg: AddToWhitelist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._whitelist.get(msg.address);
        require(isIn != true, "User is already on the whitelist.");
        self._whitelist.set(msg.address, true);
    }

    receive(msg: RemoveFromWhitelist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._whitelist.get(msg.address);
        require(isIn == true, "User is not on the whitelist.");
        self._whitelist.set(msg.address, false);
    }

    receive(msg: SetUsingWhitelistStatus) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.isUsingWhitelist = msg.status;
    }

} 