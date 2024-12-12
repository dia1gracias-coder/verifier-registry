import "@stdlib/ownable";

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton 
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

message TokenWithdraw {
    ton_amount: Int as coins;
    forward_ton_amount: Int as coins;
    token_amount: Int as coins;
    user_address: Address;
}

message ChangeJettonWalletAddress {
    queryId: Int as uint64;
    newJettonWalletAddress: Address;
}

message ChangeJettonWalletAddressOK {
    queryId: Int as uint64;
    newJettonWalletAddress: Address;
}

message ChangeBill {
    user_id: Int as uint64;
    amount: Int as uint64;
}

struct UserData {
    amount: Int as uint64;
    settled_amount: Int as uint64;
}

message ChangeBills {
    users: map<Int, Int>;
}

message ChangeBillsOK {
    users: map<Int, Int>;
}

message SettleBill {
    user_id: Int as uint64;
    user_address: Address;
}

contract StakeContract with Ownable, OwnableTransferable {
    owner: Address;
    myJettonWalletAddress: Address?;
    bill_list: map<Int, UserData>; 

    init(owner: Address) {
        self.owner = owner;
    }

    receive(msg: ChangeJettonWalletAddress){
        self.requireOwner();
        self.myJettonWalletAddress = msg.newJettonWalletAddress;
        self.reply(
            ChangeJettonWalletAddressOK{ 
                queryId: msg.queryId, 
                newJettonWalletAddress: msg.newJettonWalletAddress 
            }.toCell()
        );
    }

    receive(msg: TokenNotification) {}

    receive(msg: ChangeBill) {
        self.requireOwner();
        self.addBill(msg.user_id, msg.amount);
        self.reply(
            ChangeBill{
                user_id: msg.user_id,
                amount: msg.amount
            }.toCell()
        );
    }

    receive(msg: ChangeBills) {
        self.requireOwner();
        foreach (uid, amount in msg.users) {
            self.addBill(uid, amount);
        }
        self.reply(
            ChangeBills{
                users: msg.users
            }.toCell()
        );
    }

    receive(msg: SettleBill) {
        self.requireOwner();
        require(self.bill_list.get(msg.user_id) != null, "Invalid user");
        let item: UserData = self.bill_list.get(msg.user_id)!!;
        let settle_amount = item.amount - item.settled_amount;
        require(settle_amount > 0, "Invalid settle amount");
        self.bill_list.set(msg.user_id, UserData{amount: item.amount, settled_amount: item.amount});
        self.sendTokenToUser(0, settle_amount, msg.user_address, 0)
    }

    receive(msg: TokenWithdraw) {
        self.requireOwner();
        self.sendTokenToUser(msg.ton_amount, msg.token_amount, msg.user_address, msg.forward_ton_amount)
    }

    // @to user id
    // @amount The amount of user
    fun addBill(to: Int, amount: Int) {
        if (self.bill_list.get(to) == null) {
            self.bill_list.set(to, UserData{amount: amount, settled_amount: 0});
        }else{
            let item: UserData = self.bill_list.get(to)!!;
            self.bill_list.set(to, UserData{amount: amount + item.amount, settled_amount: item.settled_amount});
        }
    }

    fun sendTokenToUser(ton_amount: Int, token_amount: Int, user_address: Address, forward_ton_amount: Int){
         send(SendParameters{
            to: self.myJettonWalletAddress!!,
            value: ton_amount,
            mode: SendRemainingValue,
            body: TokenTransfer{
                queryId: 0,
                amount: token_amount,
                destination: user_address,
                response_destination: self.owner,
                custom_payload: null,
                forward_ton_amount: forward_ton_amount,
                forward_payload: emptySlice()
            }.toCell()
        });
    }

    // you can return maps from getters
    get fun allBills(): map<Int, UserData> {
        return self.bill_list;
    }

}