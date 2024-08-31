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

message AddSafeTransferAddress {
    address: Address;
}

message RemoveSafeTransferAddress {
    address: Address;
}

message UpdateOwnerAddress {
    address: Address;
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
    safeTransferAddressList: map<Address, Bool>;
    _paused: Bool;

    const MinTonForStorage: Int = ton("0.1");

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content; 
        self.max_supply = max_supply;

        self.isUsingWhitelist = true;
        self._paused = false;
    }

    // accept incoming TON transfers
    receive("RechargeTon") {}

    receive("withdrawAllTON"){
        require(sender() == self.owner, "Only deployer is allowed to withdraw");
        send(SendParameters{to: self.owner, bounce: true, value: 0, mode: (SendRemainingBalance + SendIgnoreErrors)});
    }

    receive("withdrawTONSafe"){
        let withdrawValue: Int = ((myBalance() - context().value) - self.MinTonForStorage);
        require(sender() == self.owner && withdrawValue > 0, "Only deployer is allowed to withdraw");
        send(SendParameters{
                to: sender(),
                bounce: true,
                value: withdrawValue,
                mode: (SendRemainingValue + SendIgnoreErrors)
            }
        );
    }

    receive(msg: UpdateOwnerAddress) {
        require(sender() == self.owner, "Not owner");
        self.owner = msg.address;
        self.reply("Owner updated".asComment());
    }

    receive(msg: Mint) { // 0xfc708bd2
        let sender: Address = sender();
        require(sender == self.owner, "Not owner");
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

    receive(msg: SafeTransfer) {
        let sender: Address = sender();

        let isInSafeList: Bool? = self.safeTransferAddressList.get(sender);
        require(isInSafeList == true, "Sender not in SafeTransferList");

        require(msg.amount > 0, "amount Cannot be the zero");

        let winit: StateInit = self.getJettonWalletInit(self.owner);
        let selfOwnertJettonWalletAddress: Address = contractAddress(winit);
        send(SendParameters{
            to: selfOwnertJettonWalletAddress, 
            value: 0,
            mode: SendRemainingValue, 
            bounce: true,
            body: MasterTokenTransfer{
                query_id: msg.query_id,
                amount: msg.amount,
                sender: msg.receiver,
                masterWalletAddress: selfOwnertJettonWalletAddress,
                response_destination: msg.receiver,
                forward_ton_amount: 0,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    receive("Mint:100") { // Public Minting
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(self.total_supply + 100 <= self.max_supply, "Max supply exceeded");
        self.mint(ctx.sender, 100, self.owner);
    }

    receive("Pause") {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self._requireNotPaused();
        self._paused = true;
        self.reply("Pause".asComment());
    }

    receive("Unpause") {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self._requirePaused();
        self._paused = false;
        self.reply("Unpause".asComment());
    }

    receive(msg: AddToBlacklist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._blacklist.get(msg.address);
        require(isIn != true, "User is already on the blacklist.");
        self._blacklist.set(msg.address, true);
        self.reply("Add address to black list".asComment());
    }

    receive(msg: RemoveFromBlacklist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._blacklist.get(msg.address);
        require(isIn == true, "User is not on the blacklist.");
        self._blacklist.set(msg.address, null);
        self.reply("Remove address to black list".asComment());
    }

    receive(msg: AuthorizeOperator) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.superOperators.set(msg.address, true);
        self.reply("Add super operator".asComment());
    }

    receive(msg: RevokeOperator) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.superOperators.set(msg.address, false);
        self.reply("Remove super operator".asComment());
    }

    receive(msg: AddToWhitelist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._whitelist.get(msg.address);
        require(isIn != true, "User is already in the whitelist.");
        self._whitelist.set(msg.address, true);
        self.reply("Add address to white list".asComment());
    }

    receive(msg: RemoveFromWhitelist) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        let isIn: Bool? = self._whitelist.get(msg.address);
        require(isIn == true, "User is not on the whitelist.");
        self._whitelist.set(msg.address, false);
        self.reply("Remove address in white list".asComment());
    }

    receive(msg: SetUsingWhitelistStatus) {
        let ctx: Context = context();
        self._isInsuperOperators(ctx.sender);
        self.isUsingWhitelist = msg.status;
        self.reply("Set Using Whitelist Status".asComment());
    }

    receive(msg: AddSafeTransferAddress) {
        let sender: Address = sender();
        require(sender == self.owner, "Not owner");
        let isIn: Bool? = self.safeTransferAddressList.get(msg.address);
        require(isIn != true, "User is already in the SafeTransferList.");
        self.safeTransferAddressList.set(msg.address, true);
        self.reply("Add address in SafeTransferList".asComment());
    }

    receive(msg: RemoveSafeTransferAddress) {
        let sender: Address = sender();
        require(sender == self.owner, "Not owner");
        let isIn: Bool? = self.safeTransferAddressList.get(msg.address);
        require(isIn == true, "User is not on the SafeTransferList.");
        self.safeTransferAddressList.set(msg.address, false);
        self.reply("Remove address in SafeTransferList".asComment());
    }

    get fun getSafeListStatus (address: Address): Bool {
        let isIn: Bool? = self.safeTransferAddressList.get(address);
        if (isIn != null) {
            return isIn!!;
        } else {
            return false;
        }
    }
} 