import "@stdlib/ownable";
import "./Messages";

trait RetriveTokenable with Ownable {
    owner: Address;
    
    receive(msg : RetriveToken) {
        require(self.owner == sender(), "Only owner!");
        if(msg.tokenWallet != null) {
            send(SendParameters {
                to: msg.tokenWallet!!, 
                value: msg.amount,
                mode: SendRemainingValue,
                body: TokenTransfer {
                    query_id: 0,
                    amount: msg.amount,
                    destination: msg.to,
                    response_destination: sender(),
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            });
        } else {
            send(SendParameters {
                to: msg.to, 
                value: msg.amount,
                mode: SendRemainingValue
            });
        }
    }
}