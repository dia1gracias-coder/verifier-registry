message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; 
}

trait JettonsOwner {
    virtual fun onTokenNotification(notification: TokenNotification) {
        require(false, "Should be overriden");
    }
    
    receive(notification: TokenNotification) {
        self.onTokenNotification(notification);
    }
    
    fun sendTokens(jettonWallet: Address, msg: TokenTransfer) {
        msg = self.fixForwardPayload(msg);
        send(SendParameters{
            to: jettonWallet, 
            value: 0,
            bounce: true,
            mode: SendRemainingValue,
            body: msg.toCell()
        });
    }

    fun sendTokensWithValue(jettonWallet: Address, msg: TokenTransfer, value: Int) {
        msg = self.fixForwardPayload(msg);
        send(SendParameters{
            to: jettonWallet, 
            value: value,
            bounce: true,
            mode: SendPayGasSeparately,
            body: msg.toCell()
        });
    }

    fun fixForwardPayload(msg: TokenTransfer): TokenTransfer {
        if (msg.forward_payload.empty()) {
            // it is expected that payload contains at least 1 bit
            msg.forward_payload = beginCell().storeBool(false).endCell().asSlice();
        }
        return msg;
    }
}
