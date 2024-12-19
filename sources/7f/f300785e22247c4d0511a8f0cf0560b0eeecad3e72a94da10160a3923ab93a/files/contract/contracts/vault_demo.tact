import "@stdlib/deploy";

contract VaultDemo with Deployable {
    wallet: Address;
    shares: map<Address, Int>;
    init(){
        self.shares = emptyMap();
        self.wallet = newAddress(0, 0);
    }

    receive(msg: WalletSetup){
        self.wallet = msg.wallet;
    }

    receive(msg: TokenNotification){
        let shareBefore: Int = 0;
        if (self.shares.get(msg.from) != null) {
            shareBefore = self.shares.get(msg.from)!!;
        }
        let shareAmount: Int = shareBefore + msg.amount;
        self.shares.set(msg.from, shareAmount);
        send(SendParameters{
                to: msg.from,
                value: 1,
                mode: SendPayGasSeparately,
                bounce: false,
                body: DepositNotification{query_id: msg.query_id, amount: msg.amount, from: myAddress()}.toCell()
            }
        );
    }

    get fun wallet(): Address {
        return self.wallet;
    }

    get fun shares(): map<Address, Int> {
        return self.shares;
    }

    get fun shareOf(who: Address): Int? {
        return self.shares.get(who);
    }
}
message WalletSetup {
    wallet: Address;
}
message(0x7362d09c) TokenNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}
message DepositNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    from: Address;
}