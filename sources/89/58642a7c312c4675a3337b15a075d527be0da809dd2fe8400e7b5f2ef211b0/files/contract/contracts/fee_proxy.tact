import "@stdlib/deploy";

// Standard proxy: no referrer
message(0x50524F58) ProxyForward {
    fragmentAddress: Address;
    forwardAmount: Int as coins;
    originalPayload: Cell;
}

// Proxy with referral: splits fee with referrer
message(0x50524F59) ProxyForwardRef {
    fragmentAddress: Address;
    forwardAmount: Int as coins;
    originalPayload: Cell;
    referrerAddress: Address;
    referralBps: Int as uint16;  // basis points: 5000 = 50%
}

// Owner withdraws accumulated fees
message(0x57445257) WithdrawFees {
    amount: Int as coins;
    to: Address;
}

contract FeeProxy with Deployable {
    owner: Address;
    totalForwarded: Int as coins;
    totalFees: Int as coins;
    totalReferralPaid: Int as coins;

    init(owner: Address) {
        self.owner = owner;
        self.totalForwarded = 0;
        self.totalFees = 0;
        self.totalReferralPaid = 0;
    }

    // Standard proxy: no referrer
    receive(msg: ProxyForward) {
        let ctx: Context = context();
        require(ctx.value >= msg.forwardAmount, "Insufficient value");

        send(SendParameters{
            to: msg.fragmentAddress,
            value: msg.forwardAmount,
            mode: SendPayGasSeparately,
            body: msg.originalPayload
        });

        let fee: Int = ctx.value - msg.forwardAmount;
        self.totalForwarded = self.totalForwarded + msg.forwardAmount;
        self.totalFees = self.totalFees + fee;
    }

    // Proxy with referral: splits fee with referrer
    receive(msg: ProxyForwardRef) {
        let ctx: Context = context();
        require(ctx.value >= msg.forwardAmount, "Insufficient value");
        require(msg.referralBps <= 10000, "Invalid referral bps");

        // Forward to Fragment
        send(SendParameters{
            to: msg.fragmentAddress,
            value: msg.forwardAmount,
            mode: SendPayGasSeparately,
            body: msg.originalPayload
        });

        // Calculate fee and referral commission
        let fee: Int = ctx.value - msg.forwardAmount;
        let referralAmount: Int = (fee * msg.referralBps) / 10000;

        // Send commission to referrer if meaningful amount
        if (referralAmount > ton("0.001")) {
            send(SendParameters{
                to: msg.referrerAddress,
                value: referralAmount,
                mode: SendPayGasSeparately,
                body: "Referral reward from hoton.tg".asComment()
            });
            self.totalReferralPaid = self.totalReferralPaid + referralAmount;
        }

        self.totalForwarded = self.totalForwarded + msg.forwardAmount;
        self.totalFees = self.totalFees + fee;
    }

    // Owner-only: withdraw accumulated fees
    receive(msg: WithdrawFees) {
        require(sender() == self.owner, "Not owner");

        let withdrawAmount: Int = msg.amount;
        if (withdrawAmount == 0) {
            withdrawAmount = myBalance() - ton("0.01");
        }
        require(withdrawAmount > 0, "Nothing to withdraw");

        send(SendParameters{
            to: msg.to,
            value: withdrawAmount,
            mode: SendPayGasSeparately
        });
    }

    get fun owner(): Address {
        return self.owner;
    }

    get fun totalForwarded(): Int {
        return self.totalForwarded;
    }

    get fun totalFees(): Int {
        return self.totalFees;
    }

    get fun totalReferralPaid(): Int {
        return self.totalReferralPaid;
    }

    get fun balance(): Int {
        return myBalance();
    }
}
