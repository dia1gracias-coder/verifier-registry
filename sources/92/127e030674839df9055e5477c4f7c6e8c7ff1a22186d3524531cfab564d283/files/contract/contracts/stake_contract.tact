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
    amount: Int as coins;
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
    amount: Int as uint64;
}

message ChangeBillOK {
    amount: Int as uint64;
}

contract StakeContract with Ownable, OwnableTransferable {
    owner: Address;
    myJettonWalletAddress: Address?;

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
        emit(ChangeBillOK{
            amount: msg.amount
            }.toCell()
        );
    }

    receive(msg: TokenWithdraw) {
        self.requireOwner();
        send(SendParameters{
            to: self.myJettonWalletAddress!!,
            value: msg.ton_amount,
            mode: SendRemainingValue,
            body: TokenTransfer{
                queryId: 0,
                amount: msg.amount,
                destination: msg.user_address,
                response_destination: self.owner,
                custom_payload: null,
                forward_ton_amount: msg.forward_ton_amount,
                forward_payload: emptySlice()
            }.toCell()
        });
    }

}