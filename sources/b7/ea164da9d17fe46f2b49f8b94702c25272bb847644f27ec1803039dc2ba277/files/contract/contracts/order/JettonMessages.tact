const jetton_transfer_fee: Int = ton("0.04"); // ~ 0.04 TON, medium fee for any amount of Jetton is 0.037 TON - docs

message(0x7362d09c) JettonTransferNotification {
    query_id: Int as uint64;                // arbitrary request number
    amount: Int as coins;                   // amount of jettons to transfer
    sender: Address;                        // address of the sender of the jettons
    forward_payload: Slice as remaining;    // optional custom payload
}

message(0x0f8a7ea5) JettonTransfer {
    query_id: Int as uint64;                // arbitrary request number
    amount: Int as coins;                   // amount of jettons to transfer
    destination: Address;                   // address of the new seller of the jettons
    response_destination: Address;          // address where to send a response with confirmation of a successful transfer and the rest of the incoming message Toncoins.
    custom_payload: Cell?;                  // optional custom payload
    forward_ton_amount: Int as coins;       // the amount of nanotons to be sent to the destination address.
    forward_payload: Slice?;    // optional custom data that should be sent to the destination address.
}

// @notice Build and send Jetton Transfer message to jetton wallet
// @param jetton_wallet - senders jetton wallet
// @param destination - next owner of sent jettons
// @param amount - amount of sent jettons with decimals
// @param forward_ton_amount - amount of ton in Jetton Transfer Notification (may be zero)
// @param mode - mode of transaction
inline fun basicJettonTransfer(jetton_wallet: Address, destination: Address, amount: Int, forward_ton_amount: Int) {
    send(SendParameters{
        to: jetton_wallet,
        value: jetton_transfer_fee,
        bounce: true,
        mode: SendIgnoreErrors,
        body: JettonTransfer {
            query_id: 0,
            amount: amount,
            destination: destination,
            response_destination: destination,
            custom_payload: null,
            forward_payload: null,
            forward_ton_amount: forward_ton_amount
        }.toCell()
    });
}