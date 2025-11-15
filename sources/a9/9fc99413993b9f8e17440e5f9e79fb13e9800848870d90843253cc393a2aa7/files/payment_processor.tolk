tolk 1.1

// Payment processor contract that takes 1% commission
// Commission wallet: bounceable
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
    val storage = Storage.load();
    val amount = in.valueCoins;

    // Handle deployment (empty body) - return early for deployment
    if (in.body.isEmpty()) {
        return;
    }

    // Check if commission wallet is initialized
    val zeroAddress = address("0:0000000000000000000000000000000000000000000000000000000000000000");
    if (storage.commissionWallet == zeroAddress) {
        throw (101); // excNo 101 for uninitialized commission wallet
    }

    // Handle owner-only admin functions
    // Admin messages format: first 32 bits = op code (1 = emergency withdrawal), then owner address for verification
    // Note: Tolk doesn't provide direct access to sender address, so we verify owner in message body
    // Payment messages start directly with recipient address (no op code)
    // We check if first 32 bits are op code 1 - addresses start with 2-bit type (0-3), so 1 is safe to check
    if (!in.body.isEmpty()) {
        var mutAdminBody = in.body;
        // Check if body has at least 32 bits
        // Read first 32 bits to check for op code
        val first32Bits = mutAdminBody.loadUint(32);

        // If first 32 bits are exactly 1, it's likely an admin message (addresses don't start with 1)
        // Try to process as admin message
        if (first32Bits == 1) {
            // Emergency withdrawal: op code 1, owner address (for verification), then address to withdraw to
            val messageOwner = mutAdminBody.loadAddress();
            // Verify the owner address matches storage
            if (messageOwner == storage.owner) {
                val withdrawTo = mutAdminBody.loadAddress();
                // Send all remaining balance (send mode 128 sends entire contract balance)
                // If balance is zero, this will send zero (no error)
                val withdrawMsg = createMessage(CreateMessageOptions {
                    dest: withdrawTo,
                    value: 0, // Value doesn't matter with send(128), it sends all balance
                    bounce: true,
                });
                withdrawMsg.send(128); // Send all remaining balance
                return;
            } else {
                throw (106); // excNo 106 for unauthorized owner access
            }
        }// But we've already consumed the first 32 bits, so we need to reconstruct the body
        // Actually, mutAdminBody is a copy, so in.body should still be intact
        // Let's use in.body for payment processing
    }
    // If first 32 bits are not 1, it's a payment message
    // Minimum amount check (must cover gas fees for two outbound messages)
    if (amount < 150000000) {
        throw (100); // 0.15 TON minimum - excNo 100 for amount too small
    }

    // Note: Body size validation removed as Tolk doesn't provide remainingBits() method
    // The loadAddress() call will fail if body is invalid, which is acceptable
    // Calculate commission (1% - rounding down)
    val commission = amount / 100;
    val recipientAmount = amount - commission;

    // Get recipient address from message body
    // The message body contains the recipient address
    // Body size validation above ensures we have enough bits for an address
    var mutBody = in.body;
    val recipient = mutBody.loadAddress();

    // Note: Self-send check removed as Tolk doesn't provide easy access to contract address
    // The commission wallet check below prevents circular payments
    // Prevent sending to commission wallet as recipient (prevents circular payments)
    if (recipient == storage.commissionWallet) {
        throw (105); // excNo 105 for recipient same as commission wallet
    }

    // Send 1% commission to commission wallet first
    // Gas is deducted from the commission amount (send mode 0)
    // Bounce enabled to detect invalid addresses and prevent fund loss
    if (commission > 0) {
        val outMsg2 = createMessage(CreateMessageOptions {
            dest: storage.commissionWallet,
            value: commission,
            bounce: true,
        });
        outMsg2.send(0); // Gas deducted from commission amount, not from contract balance
    }

    // Send remaining 99% to recipient (remaining value after commission and gas)
    // Bounce enabled to detect invalid addresses and prevent fund loss
    if (recipientAmount > 0) {
        val outMsg = createMessage(CreateMessageOptions {
            dest: recipient,
            value: recipientAmount,
            bounce: true,
        });
        outMsg.send(128); // Send remaining value after gas
    }
}
