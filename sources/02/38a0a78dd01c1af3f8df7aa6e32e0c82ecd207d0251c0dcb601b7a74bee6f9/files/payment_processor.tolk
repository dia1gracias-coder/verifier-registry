tolk 1.1

// Payment processor contract that takes 1% commission
// Commission wallet: UQCCtlPfWLDaFCwiywPc5NU87TngOG6M8mTepklWVOu5q1re
struct Storage {
    commissionWallet: address
    owner: address
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(self): cell {
    return Storage.toCell(self);
}

fun onInternalMessage(in: InMessage) {
    val storage = lazy Storage.load();
    val amount = in.valueCoins;

    // Minimum amount check (must cover gas fees)
    if (amount <= 100000000) {
        throw (100); // 0.1 TON minimum - excNo 100 for amount too small
    }

    // Handle deployment (empty body)
    if (in.body.isEmpty()) {
        return;
    }

    // Calculate commission (1% - rounding down)
    val commission = amount / 100;
    val recipientAmount = amount - commission;

    // Get recipient address from message body
    // The message body contains the recipient address
    var mutBody = in.body;
    val recipient = mutBody.loadAddress();

    // Send 1% commission to commission wallet first (with specific amount)
    if (commission > 0) {
        val outMsg2 = createMessage(CreateMessageOptions {
            dest: storage.commissionWallet,
            value: commission,
            bounce: false,
        });
        outMsg2.send(1); // Pay gas separately
    }

    // Send remaining 99% to recipient (remaining value after commission and gas)
    if (recipientAmount > 0) {
        val outMsg = createMessage(CreateMessageOptions {
            dest: recipient,
            value: recipientAmount,
            bounce: false,
        });
        outMsg.send(128); // Send remaining value
    }
}
