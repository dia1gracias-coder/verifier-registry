import "types"

contract TonRouter {
    author: "TonRouter"
    version: "1.0.0"
    description: "Permissionless TON transfer router"
    storage: Storage
    incomingMessages: TransferTon
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    val msg = TransferTon.fromSlice(in.body);

    assert (msg.amount > 0) throw Errors.InvalidAmount;
    assert (in.valueCoins > msg.amount) throw Errors.NotEnoughTon;

    // Preserve all TON that was already held before this call. Only value from
    // this incoming message may fund the transfer and its fees.
    val previousBalance = contract.getOriginalBalance() - in.valueCoins;
    reserveToncoinsOnBalance(previousBalance, RESERVE_MODE_AT_MOST);

    val transfer = createMessage({
        bounce: BounceMode.NoBounce,
        value: msg.amount,
        dest: msg.recipient,
    });
    transfer.send(SEND_MODE_PAY_FEES_SEPARATELY);
}

fun onBouncedMessage(_in: InMessageBounced) {}
