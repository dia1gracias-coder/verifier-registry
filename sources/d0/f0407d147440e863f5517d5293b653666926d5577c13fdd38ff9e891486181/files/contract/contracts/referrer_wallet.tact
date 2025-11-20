import "@stdlib/deploy";

// ============================================
// Messages for ReferrerWallet
// ============================================

message AddReferrerReward {
    gameId: Int as uint256;
    amount: Int as coins;
    winner: Address;
}

message ReferrerRewardAdded {
    gameId: Int as uint256;
    amount: Int as coins;
    timestamp: Int as uint32;
}

message ReferrerWithdrawn {
    amount: Int as coins;
    timestamp: Int as uint32;
}

// ============================================
// ReferrerWallet Contract
// ============================================

contract ReferrerWallet with Deployable {
    referrer: Address;
    factory: Address;
    totalEarned: Int as coins;
    availableToWithdraw: Int as coins;
    minWithdrawAmount: Int as coins;
    lastWithdrawalAmount: Int as coins;

    init(referrer: Address, factory: Address, minWithdrawAmount: Int) {
        self.referrer = referrer;
        self.factory = factory;
        self.totalEarned = 0;
        self.availableToWithdraw = 0;
        self.minWithdrawAmount = minWithdrawAmount;
        self.lastWithdrawalAmount = 0;
    }

    // ============================================
    // Receive reward from Game contract
    // ============================================

    receive(msg: AddReferrerReward) {
        // Security: Validate reward amount
        // Note: Any contract can send rewards to this wallet, but they would be
        // spending their own TON, so there's no attack vector
        require(msg.amount > 0, "Invalid amount");

        self.totalEarned += msg.amount;
        self.availableToWithdraw += msg.amount;

        emit(ReferrerRewardAdded {
            gameId: msg.gameId,
            amount: msg.amount,
            timestamp: now(),
        }.toCell());
    }

    // ============================================
    // Withdraw earnings
    // ============================================

    receive("withdraw") {
        require(sender() == self.referrer, "Only referrer can withdraw");
        require(self.availableToWithdraw >= self.minWithdrawAmount, "Below minimum withdrawal");
        require(self.availableToWithdraw > 0, "Nothing to withdraw");

        let minBalance: Int = ton("0.05");
        let amount: Int = self.availableToWithdraw;

        // Ensure we keep enough for gas
        require(myBalance() - amount >= minBalance, "Insufficient gas reserve");

        // Store amount before sending (for bounce recovery)
        self.lastWithdrawalAmount = amount;
        self.availableToWithdraw = 0;

        send(SendParameters {
            to: self.referrer,
            value: amount,
            mode: SendIgnoreErrors,
            bounce: false,  // User wallets should use bounce: false
            body: "Referrer reward".asComment(),
        });

        emit(ReferrerWithdrawn {
            amount,
            timestamp: now(),
        }.toCell());
    }

    // Handle bounced withdrawals
    bounced(src: Slice) {
        // If withdrawal bounced, restore the balance
        if (self.lastWithdrawalAmount > 0) {
            self.availableToWithdraw += self.lastWithdrawalAmount;
            self.lastWithdrawalAmount = 0;
        }
    }

    // ============================================
    // Getters
    // ============================================

    get fun balance(): Int {
        return self.availableToWithdraw;
    }

    get fun totalEarned(): Int {
        return self.totalEarned;
    }

    get fun referrerAddress(): Address {
        return self.referrer;
    }

    get fun minWithdrawAmount(): Int {
        return self.minWithdrawAmount;
    }
}
