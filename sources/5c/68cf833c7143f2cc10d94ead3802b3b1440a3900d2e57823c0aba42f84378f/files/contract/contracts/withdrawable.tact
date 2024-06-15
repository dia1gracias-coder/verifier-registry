import "@stdlib/ownable";
import "./jetton/jettons_owner.tact";

message Withdraw {
    amount: Int as coins;
    tokenWallet: Address?; // null = TONCOIN
}

trait WithdrawableJettonsOwner with OwnableTransferable, JettonsOwner {
    owner: Address;

    receive(request: Withdraw){
        self.requireOwner();
        if (request.tokenWallet == null) {
            send(SendParameters{
                bounce: false,
                to: self.owner,
                value: request.amount,
                mode: SendRemainingValue | SendIgnoreErrors
            });
            return ;
        }
        self.requireSpecialCondition(request);
        self.sendTokens(request.tokenWallet!!, TokenTransfer{
            queryId: now(),
            amount: request.amount,
            destination: self.owner,
            response_destination: sender(),
            custom_payload: null,
            forward_ton_amount: 0,
            forward_payload: emptySlice()
        });
    }

    virtual fun requireSpecialCondition(request: Withdraw) {
    }
}