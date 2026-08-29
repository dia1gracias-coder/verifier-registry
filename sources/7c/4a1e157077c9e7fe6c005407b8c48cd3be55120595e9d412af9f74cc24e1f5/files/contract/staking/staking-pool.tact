// SPDX-License-Identifier: MIT
// Staking Pool: per-tier aggregated stake bookkeeping, reward payouts via Jetton wallet (owner = this contract).

import "../jetton/burn-jetton-wallet";
import "./staking-messages";

contract StakingPool(
    bootstrapOwner: Address,
    stakingMaster: Address,
    jettonMinter: Address,
    totals: map<Int as uint8, Int as coins>,
    pool_balance: Int as coins,
    master_wired: Bool,
) {
    const MinTier: Int = 0;
    const MaxTier: Int = 3;
    /// TON attached to payout JettonTransfer (must cover wallet gates, see burn-jetton-wallet JettonTransfer).
    const PayRewardsTon: Int = ton("3.5");

    inline fun jettonRewardsWalletAddr(): Address {
        return contractAddress(
            initOf BurnJettonWallet(myAddress(), self.jettonMinter, 0, jettonWalletEmptyFeeConfig()),
        );
    }

    /// Plain TON from StakingMaster (e.g. leftover after accrual) must not bounce back — that caused Pool↔Master loops.
    receive() {
        if (sender() != self.stakingMaster) {
            cashback(sender());
        }
    }

    /// True when forward_payload carries an `EmissionFundForward` ref (emission-reserve funding
    /// deposit, IMP-MNAUD-F01), not a staking-fee arrival or plain deposit.
    inline fun hasEmissionFundForwardPayload(forwardPayload: Slice): Bool {
        if (forwardPayload.preloadUint(1) != 1) {
            return false;
        }
        let br = calculateSliceBitsAndRefs(forwardPayload);
        if (br.refs != 1 || br.bits != 1) {
            return false;
        }
        let inner = forwardPayload.preloadRef().beginParse();
        return inner.preloadUint(32) == EmissionFundForward.opcode();
    }

    /// Pool jetton wallet notifies Pool after incoming BURN (staking fee 0.3% or other deposits with notification).
    receive(msg: JettonNotification) {
        require(sender() == self.jettonRewardsWalletAddr(), "Only pool JW");
        require(msg.amount > 0, "Bad amount");

        if (self.hasEmissionFundForwardPayload(msg.forwardPayload)) {
            // Emission-reserve funding (IMP-MNAUD-F01 mint-to-pool): jettons physically arrived
            // at the pool wallet — relay the amount so Master raises `emissionFunded`.
            // pool_balance is NOT credited here: tickEmission credits it gradually as emission
            // accrues (keeps `emittedSoFar == Σ CreditPoolBalance` and reward funding gated by
            // the emission schedule instead of unlocking the whole reserve at once).
            require(self.master_wired, "Pool master not wired");
            message(MessageParameters {
                to: self.stakingMaster,
                value: gasPoolToMasterAccrual,
                bounce: true,
                mode: SendPayGasSeparately,
                body: EmissionReserveFunded {
                    queryId: msg.queryId,
                    amount: msg.amount,
                }.toCell(),
            });
            return;
        }

        self.pool_balance = self.pool_balance + msg.amount;

        message(MessageParameters {
            to: self.stakingMaster,
            value: gasPoolToMasterAccrual,
            bounce: true,
            mode: SendPayGasSeparately,
            body: StakeFeeRewardsAccrue {
                queryId: msg.queryId,
                feeAmount: msg.amount,
            }.toCell(),
        });
    }

    inline fun assertMaster() {
        require(self.master_wired, "Pool master not wired");
        require(sender() == self.stakingMaster, "Only staking master");
    }

    inline fun assertTier(tier: Int) {
        require(tier >= self.MinTier && tier <= self.MaxTier, "Bad tier");
    }

    /// Sum of staked principal across all tiers — these jettons were forwarded to the
    /// pool wallet at stake time and must always remain redeemable on unstake.
    fun totalPrincipal(): Int {
        let s: Int = 0;
        let t: Int = self.MinTier;
        while (t <= self.MaxTier) {
            let v = self.totals.get(t);
            if (v != null) {
                s = s + v!!;
            }
            t = t + 1;
        }
        return s;
    }

    /// Reward jettons available for payout = bookkeeping balance minus staked principal.
    /// Caps reward payouts so the pool never pays out staked bodies as rewards and never
    /// promises more rewards than have actually been funded (emission reserve + fees).
    fun rewardFunding(): Int {
        let principal = self.totalPrincipal();
        if (self.pool_balance <= principal) {
            return 0;
        }
        return self.pool_balance - principal;
    }

    receive(msg: WireStakingMaster) {
        require(!self.master_wired, "Already wired");
        require(sender() == self.bootstrapOwner, "Only bootstrap");
        self.stakingMaster = msg.stakingMaster;
        self.master_wired = true;
    }

    /// Pools stake-fee BURN accounted in `CreditPoolBalance` into `rewardPerShare` tiers on Master.
    receive(msg: RelayStakeFeeAccrual) {
        self.assertMaster();
        require(msg.feeAmount > 0, "Bad fee");

        message(MessageParameters {
            to: self.stakingMaster,
            value: gasPoolToMasterAccrual,
            bounce: true,
            mode: SendPayGasSeparately,
            body: StakeFeeRewardsAccrue {
                queryId: msg.queryId,
                feeAmount: msg.feeAmount,
            }.toCell(),
        });
    }

    receive(msg: IncrementTotalStake) {
        self.assertMaster();
        self.assertTier(msg.tier);
        require(msg.delta > 0, "Bad delta");
        let prev: Int = 0;
        if (self.totals.get(msg.tier) != null) {
            prev = self.totals.get(msg.tier)!!;
        }
        let next = prev + msg.delta;
        require(next >= prev, "Stake overflow");
        self.totals.set(msg.tier, next);
    }

    receive(msg: DecrementTotalStake) {
        self.assertMaster();
        self.assertTier(msg.tier);
        require(msg.delta > 0, "Bad delta");
        let prev: Int = 0;
        if (self.totals.get(msg.tier) != null) {
            prev = self.totals.get(msg.tier)!!;
        }
        require(prev >= msg.delta, "Tier underflow");
        self.totals.set(msg.tier, prev - msg.delta);
    }

    receive(msg: CreditPoolBalance) {
        self.assertMaster();
        require(msg.delta > 0, "Bad delta");
        self.pool_balance += msg.delta;
    }

    /// Reward-only payout (claim / stake-merge). Capped to real reward funding so an
    /// underfunded pool degrades gracefully instead of bouncing the whole transfer.
    receive(msg: PayRewards) {
        self.assertMaster();
        require(msg.amount > 0, "Bad amount");
        require(context().value >= self.PayRewardsTon, "Insufficient TON for payout");

        let pay = msg.amount;
        let avail = self.rewardFunding();
        if (pay > avail) {
            pay = avail;
        }
        if (pay <= 0) {
            // Reward funding exhausted — nothing to send. Return surplus TON to master.
            cashback(sender());
            return;
        }

        self.pool_balance -= pay;

        let body = JettonTransferOut {
            queryId: msg.queryId,
            amount: pay,
            destination: msg.recipient,
            responseDestination: self.stakingMaster,
            customPayload: null,
            forwardTonAmount: 1,
            forwardPayload: beginCell().storeUint(0, 1).asSlice(),
        };

        message(MessageParameters {
            to: self.jettonRewardsWalletAddr(),
            value: self.PayRewardsTon,
            bounce: true,
            mode: SendPayGasSeparately,
            body: body.toCell(),
        });
    }

    /// Unstake payout: `principal` is always returned in full (backed by forwarded stake
    /// jettons), `reward` is capped to real reward funding. The two are sent as a single
    /// transfer; the stake body can never be trapped behind a reward shortfall.
    receive(msg: PayUnstake) {
        self.assertMaster();
        require(msg.principal > 0, "Bad principal");
        require(msg.reward >= 0, "Bad reward");
        require(context().value >= self.PayRewardsTon, "Insufficient TON for payout");

        let rewardPay = msg.reward;
        let avail = self.rewardFunding();
        if (rewardPay > avail) {
            rewardPay = avail;
        }
        if (rewardPay < 0) {
            rewardPay = 0;
        }

        let total = msg.principal + rewardPay;
        // Always holds: principal <= totalPrincipal and rewardPay <= (pool_balance - totalPrincipal).
        require(total <= self.pool_balance, "Insufficient accounting balance");

        self.pool_balance -= total;

        let body = JettonTransferOut {
            queryId: msg.queryId,
            amount: total,
            destination: msg.recipient,
            responseDestination: self.stakingMaster,
            customPayload: null,
            forwardTonAmount: 1,
            forwardPayload: beginCell().storeUint(0, 1).asSlice(),
        };

        message(MessageParameters {
            to: self.jettonRewardsWalletAddr(),
            value: self.PayRewardsTon,
            bounce: true,
            mode: SendPayGasSeparately,
            body: body.toCell(),
        });
    }

    /// Jetton wallet bounced payout (e.g. insufficient jetton balance) — restore pool bookkeeping.
    bounced(msg: bounced<JettonTransferOut>) {
        self.pool_balance += msg.amount;
    }

    /// Commit-stage payout failure on the post-F11 resolve path (IMP-MNAUD-F18).
    /// Mirrors bounced<JettonTransferOut>: the payout hops wallet → master → wallet,
    /// and a balance failure at CommitJettonTransfer surfaces as an explicit signal
    /// from the pool jetton wallet instead of a bounce.
    receive(msg: JettonTransferCommitFailed) {
        require(sender() == self.jettonRewardsWalletAddr(), "Only pool JW");
        self.pool_balance += msg.amount;
    }

    get fun get_staking_master(): Address {
        return self.stakingMaster;
    }

    get fun get_master_wired(): Bool {
        return self.master_wired;
    }

    get fun get_jetton_rewards_wallet(): Address {
        return self.jettonRewardsWalletAddr();
    }

    get fun get_total_stake(tier: Int): Int {
        if (tier < self.MinTier || tier > self.MaxTier) {
            return 0;
        }
        if (self.totals.get(tier) == null) {
            return 0;
        }
        return self.totals.get(tier)!!;
    }

    get fun get_pool_balance(): Int {
        return self.pool_balance;
    }

    /// For off-chain tooling (deployment scripts)
    get fun get_jetton_minter(): Address {
        return self.jettonMinter;
    }
}
