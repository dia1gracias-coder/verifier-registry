// SPDX-License-Identifier: MIT
// Universal linear + cliff vesting for BURN allocations (P5-3-3-1).

import "../jetton/burn-jetton-wallet";

message(0x5a060001) VestRelease {
    queryId: Int as uint64;
}

message(0x5a060002) VestEmergencyRevoke {
    queryId: Int as uint64;
}

struct VestingInfo {
    beneficiary: Address;
    treasury: Address;
    timelock: Address;
    jetton_master: Address;
    total_amount: Int as coins;
    released_amount: Int as coins;
    start_time: Int as uint64;
    cliff_duration: Int as uint64;
    vesting_duration: Int as uint64;
}

contract Vesting(
    beneficiary: Address,
    total_amount: Int as coins,
    start_time: Int as uint64,
    cliff_duration: Int as uint64,
    vesting_duration: Int as uint64,
    released_amount: Int as coins,
    timelock: Address,
    jetton_master: Address,
    treasury: Address,
) {
    /// Attached to outbound `JettonTransfer` toward the vesting jetton wallet (must satisfy excluded-transfer gates; same order as staking pool payouts).
    const ReleaseTon: Int = ton("3.5");

    /// Plain TON from Timelock (emergency revoke relay) or the vesting jetton wallet must not
    /// bounce back — RC-A defense (IMP-RELAY-04). External senders still get cashback.
    receive() {
        let s = sender();
        if (s != self.timelock && s != self.jetton_wallet_addr()) {
            cashback(s);
        }
    }

    inline fun jetton_wallet_addr(): Address {
        return contractAddress(
            initOf BurnJettonWallet(myAddress(), self.jetton_master, 0, jettonWalletEmptyFeeConfig()),
        );
    }

    fun vested_amount(currentTime: Int): Int {
        require(self.cliff_duration <= self.vesting_duration, "Bad vesting schedule");
        if (currentTime < self.start_time + self.cliff_duration) {
            return 0;
        }
        if (currentTime >= self.start_time + self.vesting_duration) {
            return self.total_amount;
        }
        let elapsed = currentTime - self.start_time - self.cliff_duration;
        let linear_window = self.vesting_duration - self.cliff_duration;
        /// When `cliff_duration == vesting_duration`, the two branches above cover all times (cliff-only unlock).
        require(linear_window > 0, "Invalid vesting schedule");
        return self.total_amount * elapsed / linear_window;
    }

    fun releasable_amount(currentTime: Int): Int {
        let v = self.vested_amount(currentTime);
        let r = v - self.released_amount;
        return r > 0 ? r : 0;
    }

    receive(msg: VestRelease) {
        require(sender() == self.beneficiary, "Only beneficiary");
        let amount = self.releasable_amount(now());
        require(amount > 0, "Nothing to release");
        self.released_amount += amount;

        message(MessageParameters {
            to: self.jetton_wallet_addr(),
            value: self.ReleaseTon,
            mode: SendPayGasSeparately,
            bounce: true,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount,
                destination: self.beneficiary,
                responseDestination: self.beneficiary,
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
    }

    receive(msg: VestEmergencyRevoke) {
        require(sender() == self.timelock, "Only timelock");
        /// Fail loudly in the COMPUTE phase when the Timelock relay under-funds the
        /// revoke (IMP-MNAUD-F08): the ReleaseTon send below fails in the ACTION
        /// phase on an under-funded call, and TON generates a bounce only for
        /// compute-phase failures — an action-phase failure would leave the
        /// Timelock's re-arm path blind. Mirrors Treasury's MIN_SPEND_FORWARD gate.
        require(context().value >= self.ReleaseTon, "Insufficient gas for revoke");
        let remaining = self.total_amount - self.released_amount;
        require(remaining > 0, "Nothing to revoke");
        self.released_amount = self.total_amount;

        // Forward at the documented treasury floor so the Treasury contract receives
        // `JettonNotification` and `total_received` grows (MNAUD-2/C-2). A 1-nano
        // forward is dropped on-chain (`cskip_no_gas`), leaving revoked jettons
        // unaccounted and unspendable via `TreasurySpend`.
        message(MessageParameters {
            to: self.jetton_wallet_addr(),
            value: self.ReleaseTon,
            mode: SendPayGasSeparately,
            bounce: true,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: remaining,
                destination: self.treasury,
                responseDestination: self.treasury,
                customPayload: null,
                forwardTonAmount: gasTreasuryForwardMin,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
    }

    /// Jetton wallet failed `JettonTransfer` — rollback accounting (same pattern as Treasury).
    bounced(msg: bounced<JettonTransfer>) {
        let amt = msg.amount;
        require(self.released_amount >= amt, "Unexpected bounce");
        self.released_amount -= amt;
    }

    get fun get_beneficiary(): Address {
        return self.beneficiary;
    }

    get fun get_treasury(): Address {
        return self.treasury;
    }

    get fun get_timelock(): Address {
        return self.timelock;
    }

    get fun get_jetton_master(): Address {
        return self.jetton_master;
    }

    get fun get_total_amount(): Int {
        return self.total_amount;
    }

    get fun get_released_amount(): Int {
        return self.released_amount;
    }

    get fun get_schedule(): VestingInfo {
        return VestingInfo {
            beneficiary: self.beneficiary,
            treasury: self.treasury,
            timelock: self.timelock,
            jetton_master: self.jetton_master,
            total_amount: self.total_amount,
            released_amount: self.released_amount,
            start_time: self.start_time,
            cliff_duration: self.cliff_duration,
            vesting_duration: self.vesting_duration,
        };
    }

    get fun get_vested_at(currentTime: Int): Int {
        return self.vested_amount(currentTime);
    }

    get fun get_releasable_at(currentTime: Int): Int {
        return self.releasable_amount(currentTime);
    }
}
