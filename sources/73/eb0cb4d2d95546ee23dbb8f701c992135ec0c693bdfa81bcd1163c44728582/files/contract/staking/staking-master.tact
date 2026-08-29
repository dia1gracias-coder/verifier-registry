// SPDX-License-Identifier: MIT
// Staking Master — Jetton stake via TEP-74 notification; Unstake / Claim; emission tick (Phase 1 linear).

import "../jetton/burn-jetton-wallet";
import "../governance/governance-messages";
import "../vp-math";
import "./staking-messages";
import "./staking-lock";

message(0x5a020002) UnstakeJetton {
    queryId: Int as uint64;
    tier: Int as uint8;
    amount: Int as coins;
}

message(0x5a020003) ClaimRewards {
    queryId: Int as uint64;
    tier: Int as uint8;
}

/// Called once by bootstrap after deploy: `wallet = jetton_master.get_wallet_address(staking_master)`.
message(0x5a020004) SetMasterJettonWallet {
    queryId: Int as uint64;
    wallet: Address;
}

/// Called once by bootstrap after the Governor contract is deployed: re-points `governorAddr`
/// from the bootstrap placeholder (deployer) to the real Governor. Without this the
/// `GovernorVoteRelay` "Only governor" guard rejects every relayed vote.
message(0x5a020005) SetGovernor {
    queryId: Int as uint64;
    governor: Address;
}


struct StakeInfoView {
    amount: Int as coins;
    tier: Int as uint8;
    startTime: Int;
    lastClaimTime: Int;
    unlockTime: Int;
}

contract StakingMaster(
    pool: Address,
    jettonMaster: Address,
    stakingLock: Address,
    bootstrapOwner: Address,
    governorAddr: Address,
    stakingJettonWallet: Address,
    jwConfigured: Bool,
    stakesT0: map<Address, StakeInfoView>,
    stakesT1: map<Address, StakeInfoView>,
    stakesT2: map<Address, StakeInfoView>,
    stakesT3: map<Address, StakeInfoView>,
    rewardPerShare: map<Int as uint8, Int>,
    debtT0: map<Address, Int>,
    debtT1: map<Address, Int>,
    debtT2: map<Address, Int>,
    debtT3: map<Address, Int>,
    totalStakeByTier: map<Int as uint8, Int as coins>,
    emissionStartTime: Int as uint64,
    lastEmitTime: Int as uint64,
    emittedSoFar: Int as coins,
    /// Reward jettons actually provisioned to the pool to back linear emission.
    /// Emission can never accrue into `rewardPerShare` beyond this funded reserve, so the
    /// pool never promises emission rewards it cannot pay. Raised ONLY via
    /// `EmissionReserveFunded` relayed by the pool after reward jettons physically arrive at
    /// the pool jetton wallet with an `EmissionFundForward` payload (IMP-MNAUD-F01).
    emissionFunded: Int as coins,
    /// Runtime tier table — synced from StakingLock (push model, IMP-AUDIT-03).
    tierConfigs: map<Int, TierConfig>,
) {
    const MinTier: Int = 0;
    const MaxTier: Int = 3;

    /// Scales accruing multiplier before dividing by tier total stake (~MasterChef precision).
    const RewardScale: Int = 1000000000000000000; // 1e18

    /// 300 BURN (nano) linear emission over 3 years (Phase 1).
    const TotalEmissionNano: Int = 300000000000;
    const EmissionDurationSec: Int = 94608000;
    /// floor(300e9 / emissionDuration) nano per second
    const EmissionNanoPerSec: Int = 3170;
    const EmitMinIntervalSec: Int = 60;

    /// Minimum stake 0.01 BURN (anti-dust).
    const MinStakeNano: Int = 10000000;

    const GasToPool: Int = ton("0.06");
    /// Must satisfy BurnJettonWallet JettonTransfer gate (forward + `minTonFeePath` from
    /// the wallet's feeConfig snapshot — governance default 1.0 TON after IMP-MNAUD-F17/F22 —
    /// plus forward fees). 3.5 keeps ample headroom even if governance raises the gate.
    const GasForwardStakeJetton: Int = ton("3.5");
    const GasPayRewards: Int = ton("3.5");

    inline fun assertTier(tier: Int) {
        require(tier >= self.MinTier && tier <= self.MaxTier, "Bad tier");
    }

    inline fun tierCfg(tier: Int): TierConfig {
        self.assertTier(tier);
        require(self.tierConfigs.get(tier) != null, "Missing tier cfg");
        return self.tierConfigs.get(tier)!!;
    }

    inline fun tierRewardSharePercent(tier: Int): Int {
        return self.tierCfg(tier).rewardShare;
    }

    inline fun tierUnlockDurationSeconds(tier: Int): Int {
        return self.tierCfg(tier).durationSeconds;
    }

    inline fun tierVpMultiplier(tier: Int): Int {
        return self.tierCfg(tier).multiplier;
    }

    inline fun rewardPerShareForTier(tier: Int): Int {
        let v = self.rewardPerShare.get(tier);
        if (v == null) {
            return 0;
        }
        return v!!;
    }

    inline fun tierTotalStake(tier: Int): Int {
        let v = self.totalStakeByTier.get(tier);
        if (v == null) {
            return 0;
        }
        return v!!;
    }

    inline fun masterJettonWalletAddr(): Address {
        return self.stakingJettonWallet;
    }

    fun stakesMapGet(tier: Int, who: Address): StakeInfoView? {
        self.assertTier(tier);
        if (tier == 0) {
            return self.stakesT0.get(who);
        }
        if (tier == 1) {
            return self.stakesT1.get(who);
        }
        if (tier == 2) {
            return self.stakesT2.get(who);
        }
        return self.stakesT3.get(who);
    }

    fun stakesMapSet(tier: Int, who: Address, info: StakeInfoView) {
        self.assertTier(tier);
        if (tier == 0) {
            self.stakesT0.set(who, info);
            return;
        }
        if (tier == 1) {
            self.stakesT1.set(who, info);
            return;
        }
        if (tier == 2) {
            self.stakesT2.set(who, info);
            return;
        }
        self.stakesT3.set(who, info);
    }

    fun stakesMapDel(tier: Int, who: Address) {
        self.assertTier(tier);
        if (tier == 0) {
            self.stakesT0.replace(who, null);
            return;
        }
        if (tier == 1) {
            self.stakesT1.replace(who, null);
            return;
        }
        if (tier == 2) {
            self.stakesT2.replace(who, null);
            return;
        }
        self.stakesT3.replace(who, null);
    }

    fun debtMapGet(tier: Int, who: Address): Int {
        self.assertTier(tier);
        let opt: Int? = null;
        if (tier == 0) {
            opt = self.debtT0.get(who);
        } else if (tier == 1) {
            opt = self.debtT1.get(who);
        } else if (tier == 2) {
            opt = self.debtT2.get(who);
        } else {
            opt = self.debtT3.get(who);
        }
        if (opt == null) {
            return 0;
        }
        return opt!!;
    }

    fun debtMapSet(tier: Int, who: Address, debt: Int) {
        self.assertTier(tier);
        if (tier == 0) {
            self.debtT0.set(who, debt);
            return;
        }
        if (tier == 1) {
            self.debtT1.set(who, debt);
            return;
        }
        if (tier == 2) {
            self.debtT2.set(who, debt);
            return;
        }
        self.debtT3.set(who, debt);
    }

    fun debtMapDel(tier: Int, who: Address) {
        self.assertTier(tier);
        if (tier == 0) {
            self.debtT0.replace(who, null);
            return;
        }
        if (tier == 1) {
            self.debtT1.replace(who, null);
            return;
        }
        if (tier == 2) {
            self.debtT2.replace(who, null);
            return;
        }
        self.debtT3.replace(who, null);
    }

    fun addTierTotalStake(tier: Int, delta: Int) {
        self.assertTier(tier);
        require(delta > 0, "Bad delta");
        let prev = self.tierTotalStake(tier);
        let next = prev + delta;
        require(next >= prev, "Stake overflow");
        self.totalStakeByTier.set(tier, next);
    }

    fun subTierTotalStake(tier: Int, delta: Int) {
        self.assertTier(tier);
        require(delta > 0, "Bad delta");
        let prev = self.tierTotalStake(tier);
        require(prev >= delta, "Tier underflow");
        self.totalStakeByTier.set(tier, prev - delta);
    }

    /// Accrues `tierFeeSliceNano` into the tier's rewardPerShare when the tier has stake.
    /// Returns the amount actually applied (0 if the slice is zero or the tier is empty) —
    /// empty-tier slices are forfeited so callers can credit/consume only distributed nano
    /// (IMP-FAUDIT-F03 / F-1 variant a).
    fun accumulateTierRewardFromStakeFeeSlice(tier: Int, tierFeeSliceNano: Int): Int {
        if (tierFeeSliceNano == 0) {
            return 0;
        }
        let tot = self.tierTotalStake(tier);
        if (tot == 0) {
            return 0;
        }
        let deltaRps = tierFeeSliceNano * self.RewardScale / tot;
        let prev = self.rewardPerShareForTier(tier);
        self.rewardPerShare.set(tier, prev + deltaRps);
        return tierFeeSliceNano;
    }

    /// Distributes staking-fee / emission `feeAmount` across tiers by TOKENOMICS shares.
    /// Returns the sum of slices that landed in non-empty tiers (empty-tier slices forfeited).
    fun applyStakeFeeSlices(feeAmount: Int): Int {
        require(feeAmount > 0, "Bad fee");
        let distributed: Int = 0;
        let t: Int = 0;
        while (t <= self.MaxTier) {
            let slice = feeAmount * self.tierRewardSharePercent(t) / 100;
            distributed = distributed + self.accumulateTierRewardFromStakeFeeSlice(t, slice);
            t = t + 1;
        }
        return distributed;
    }

    fun initUserRewardDebt(ownerAddr: Address, tier: Int, stakeAmount: Int) {
        self.assertTier(tier);
        let rps = self.rewardPerShareForTier(tier);
        let debt = stakeAmount * rps / self.RewardScale;
        self.debtMapSet(tier, ownerAddr, debt);
    }

    fun totalStakedAllTiers(): Int {
        let s = 0;
        let t = 0;
        while (t <= self.MaxTier) {
            s = s + self.tierTotalStake(t);
            t = t + 1;
        }
        return s;
    }

    /// Phase 1 linear emission. Emission only accrues into `rewardPerShare` (and credits the
    /// pool) up to the funded reserve (`emissionFunded`) AND only while there are stakers to
    /// receive it. With no stakers the window is forfeited but neither the budget nor the
    /// funding is consumed. Empty-tier slices of a non-zero pending are likewise forfeited
    /// (IMP-FAUDIT-F03): only the sum of slices that land in non-empty tiers is credited to
    /// the pool and added to `emittedSoFar` — keeping `emittedSoFar == Σ distributed`.
    fun tickEmission() {
        let nowTs = now();

        if (self.emissionStartTime == 0) {
            self.emissionStartTime = nowTs;
            self.lastEmitTime = nowTs;
            return;
        }

        let elapsed = nowTs - self.lastEmitTime;
        if (elapsed < self.EmitMinIntervalSec) {
            return;
        }

        // No stakers: nothing to distribute. Advance the clock but do NOT consume budget,
        // funding, or credit the pool — otherwise emittedSoFar desyncs from rewardPerShare.
        let totalStaked = self.totalStakedAllTiers();
        if (totalStaked <= 0) {
            self.lastEmitTime = nowTs;
            return;
        }

        let pending = elapsed * self.EmissionNanoPerSec;
        let budgetCap = self.TotalEmissionNano - self.emittedSoFar;
        if (pending > budgetCap) {
            pending = budgetCap;
        }
        // Solvency gate: never accrue emission beyond reward jettons actually funded.
        let fundedCap = self.emissionFunded - self.emittedSoFar;
        if (pending > fundedCap) {
            pending = fundedCap;
        }

        if (pending <= 0) {
            self.lastEmitTime = nowTs;
            return;
        }

        // Only credit / consume slices that actually accrued into non-empty tiers.
        // Empty-tier slices are forfeited as an unused window (IMP-FAUDIT-F03): keeps
        // emittedSoFar == Σ distributed and avoids orphaning budget into pool_balance.
        let distributed = self.applyStakeFeeSlices(pending);
        if (distributed > 0) {
            message(MessageParameters {
                to: self.pool,
                value: self.GasToPool,
                bounce: true,
                mode: SendPayGasSeparately,
                body: CreditPoolBalance {
                    queryId: 0,
                    delta: distributed,
                }.toCell(),
            });
            self.emittedSoFar = self.emittedSoFar + distributed;
        }
        self.lastEmitTime = nowTs;
    }

    /// Minimum TON on JettonNotification (forward from user JW). Mirrors UnstakeJetton guard pattern.
    inline fun minStakeNotifyTon(staker: Address, tier: Int): Int {
        let minNotify = self.GasForwardStakeJetton + self.GasToPool * 2 + ton("0.08");
        let oldOpt = self.stakesMapGet(tier, staker);
        if (oldOpt != null) {
            let pendingOld = self.calculatePendingRewardFor(staker, tier);
            if (pendingOld > 0) {
                minNotify = minNotify + self.GasPayRewards;
            }
        }
        return minNotify;
    }

    /// True when forward_payload carries a `StakeForward` ref (user stake intent), not mint/refill dust.
    inline fun hasStakeForwardPayload(forwardPayload: Slice): Bool {
        if (forwardPayload.preloadUint(1) != 1) {
            return false;
        }
        let br = calculateSliceBitsAndRefs(forwardPayload);
        if (br.refs != 1 || br.bits != 1) {
            return false;
        }
        let inner = forwardPayload.preloadRef().beginParse();
        return inner.preloadUint(32) == StakeForward.opcode();
    }

    /// Extract `StakeForward.tier` from a payload already verified by `hasStakeForwardPayload`.
    inline fun stakeForwardTier(forwardPayload: Slice): Int {
        let inner = forwardPayload.loadRef().beginParse();
        let sf = StakeForward.fromSlice(inner);
        return sf.tier;
    }

    /// Return rejected-stake jettons to the depositor (IMP-STKFEE-04 sub-min / IMP-MNAUD-F09 underfunded & bad payload).
    /// Requires `context().value >= GasForwardStakeJetton` for the outbound JettonTransfer; below that the
    /// refund itself cannot be funded (residual stranding — see decision log).
    fun returnSubMinStakeJettons(amount: Int, recipient: Address, queryId: Int) {
        require(context().value >= self.GasForwardStakeJetton, "Low TON return");
        message(MessageParameters {
            to: self.masterJettonWalletAddr(),
            value: self.GasForwardStakeJetton,
            bounce: true,
            mode: SendPayGasSeparately,
            body: JettonTransferOut {
                queryId: queryId,
                amount: amount,
                destination: recipient,
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
        cashback(sender());
    }

    fun forwardStakeJettonsToPool(amount: Int, queryId: Int) {
        message(MessageParameters {
            to: self.masterJettonWalletAddr(),
            value: self.GasForwardStakeJetton,
            bounce: true,
            mode: SendPayGasSeparately,
            body: JettonTransferOut {
                queryId: queryId,
                amount: amount,
                destination: self.pool,
                responseDestination: myAddress(),
                customPayload: null,
                forwardTonAmount: 0,
                forwardPayload: beginCell().storeUint(0, 1).asSlice(),
            }.toCell(),
        });
    }

    fun sendPayRewards(recipient: Address, amount: Int, queryId: Int) {
        require(amount > 0, "Bad payout");
        message(MessageParameters {
            to: self.pool,
            value: self.GasPayRewards,
            bounce: true,
            mode: SendPayGasSeparately,
            body: PayRewards {
                queryId: queryId,
                recipient: recipient,
                amount: amount,
            }.toCell(),
        });
    }

    /// Unstake payout: principal (always backed) + reward (capped to funding by the pool).
    fun sendPayUnstake(recipient: Address, principal: Int, reward: Int, queryId: Int) {
        require(principal > 0, "Bad principal");
        message(MessageParameters {
            to: self.pool,
            value: self.GasPayRewards,
            bounce: true,
            mode: SendPayGasSeparately,
            body: PayUnstake {
                queryId: queryId,
                recipient: recipient,
                principal: principal,
                reward: reward,
            }.toCell(),
        });
    }

    /// Plain TON from Governor (e.g. vote-relay remainder) or StakingLock (TierConfigSync cashback)
    /// must not bounce back — that caused cashback loops (IMP-GOVOTE-02 / IMP-RELAY-03).
    receive() {
        if (sender() != self.governorAddr && sender() != self.stakingLock) {
            cashback(sender());
        }
    }

    receive(msg: JettonExcesses) {
        cashback(sender());
    }

    receive(msg: SetMasterJettonWallet) {
        require(sender() == self.bootstrapOwner, "Only bootstrap");
        require(!self.jwConfigured, "JW already set");
        forceBasechain(msg.wallet);
        self.stakingJettonWallet = msg.wallet;
        self.jwConfigured = true;
        cashback(sender());
    }

    /// One-shot governor wiring. At deploy `governorAddr == bootstrapOwner` (placeholder); this
    /// re-points it to the real Governor. Once set (`governorAddr != bootstrapOwner`) it can never
    /// be changed again, preserving the trust assumption of `GovernorVoteRelay`.
    receive(msg: SetGovernor) {
        require(sender() == self.bootstrapOwner, "Only bootstrap");
        require(self.governorAddr == self.bootstrapOwner, "Governor already set");
        forceBasechain(msg.governor);
        self.governorAddr = msg.governor;
        cashback(sender());
    }

    /// Raises the emission funding ceiling after reward jettons PHYSICALLY arrived at the pool
    /// jetton wallet (IMP-MNAUD-F01 mint-to-pool). Only the pool may send this, and the pool
    /// only sends it from its jetton-wallet notification handler — so `emissionFunded` can never
    /// grow without real backing. Funding beyond the Phase-1 budget is clamped (excess jettons
    /// stay in the pool wallet as a donation) rather than thrown, so an over-funding transfer
    /// cannot break the notification chain. Remaining TON is absorbed (no cashback) to avoid
    /// ping-pong with Pool's generic receive().
    receive(msg: EmissionReserveFunded) {
        require(sender() == self.pool, "Only pool");
        require(msg.amount > 0, "Bad amount");
        let next = self.emissionFunded + msg.amount;
        if (next > self.TotalEmissionNano) {
            next = self.TotalEmissionNano;
        }
        self.emissionFunded = next;
    }

    /// Jetton wallet notifies Master after incoming transfer; forward_payload carries `StakeForward`.
    receive(msg: JettonNotification) {
        require(self.jwConfigured, "JW not configured");
        require(sender() == self.stakingJettonWallet, "Only master JW");

        // Sub-minimum net: mint/refill dust (no StakeForward) is ignored; user stake attempts are refunded.
        if (msg.amount < self.MinStakeNano) {
            if (self.hasStakeForwardPayload(msg.forwardPayload)) {
                self.returnSubMinStakeJettons(msg.amount, msg.sender, msg.queryId);
            } else {
                cashback(sender());
            }
            return;
        }

        // Full-amount stake: JettonNotification arrives bounce:false — throwing strands tokens.
        // Fail-closed acceptance checks refund principal instead of require (IMP-MNAUD-F09).
        if (!self.hasStakeForwardPayload(msg.forwardPayload)) {
            self.returnSubMinStakeJettons(msg.amount, msg.sender, msg.queryId);
            return;
        }

        let tierAsInt = self.stakeForwardTier(msg.forwardPayload);
        let staker = msg.sender;
        if (tierAsInt < self.MinTier || tierAsInt > self.MaxTier || self.tierConfigs.get(tierAsInt) == null) {
            self.returnSubMinStakeJettons(msg.amount, msg.sender, msg.queryId);
            return;
        }
        if (context().value < self.minStakeNotifyTon(staker, tierAsInt)) {
            self.returnSubMinStakeJettons(msg.amount, msg.sender, msg.queryId);
            return;
        }

        self.tickEmission();

        let oldOpt = self.stakesMapGet(tierAsInt, staker);
        let start = now();
        let unlockTime = start + self.tierUnlockDurationSeconds(tierAsInt);

        if (oldOpt != null) {
            let old = oldOpt!!;
            let pendingOld = self.calculatePendingRewardFor(staker, tierAsInt);
            if (pendingOld > 0) {
                self.sendPayRewards(staker, pendingOld, msg.queryId);
            }

            let mergedAmt = old.amount + msg.amount;
            let merged = StakeInfoView {
                amount: mergedAmt,
                tier: tierAsInt,
                startTime: old.startTime,
                lastClaimTime: start,
                unlockTime,
            };
            self.stakesMapSet(tierAsInt, staker, merged);
            self.addTierTotalStake(tierAsInt, msg.amount);
            self.initUserRewardDebt(staker, tierAsInt, mergedAmt);
        } else {
            let info = StakeInfoView {
                amount: msg.amount,
                tier: tierAsInt,
                startTime: start,
                lastClaimTime: start,
                unlockTime,
            };
            self.stakesMapSet(tierAsInt, staker, info);
            self.addTierTotalStake(tierAsInt, msg.amount);
            self.initUserRewardDebt(staker, tierAsInt, msg.amount);
        }

        message(MessageParameters {
            to: self.pool,
            value: self.GasToPool,
            bounce: true,
            mode: SendPayGasSeparately,
            body: IncrementTotalStake {
                queryId: msg.queryId,
                tier: tierAsInt,
                delta: msg.amount,
            }.toCell(),
        });

        message(MessageParameters {
            to: self.pool,
            value: self.GasToPool,
            bounce: true,
            mode: SendPayGasSeparately,
            body: CreditPoolBalance {
                queryId: msg.queryId,
                delta: msg.amount,
            }.toCell(),
        });

        self.forwardStakeJettonsToPool(msg.amount, msg.queryId);
    }

    receive(msg: UnstakeJetton) {
        require(context().value >= self.GasPayRewards + self.GasToPool + ton("0.08"), "Low TON unstake");
        self.tickEmission();

        let who = sender();
        let tierAsInt = msg.tier;
        self.assertTier(tierAsInt);
        require(msg.amount > 0, "Bad amount");

        let curOpt = self.stakesMapGet(tierAsInt, who);
        require(curOpt != null, "No stake");
        let cur = curOpt!!;
        require(cur.amount > 0, "Empty stake");
        require(msg.amount <= cur.amount, "Too much");

        let t = now();
        require(cur.unlockTime <= t, "Still locked");

        // Principal is always returned in full; reward is capped to real funding by the pool.
        // This keeps the stake body from ever being trapped behind a reward shortfall.
        let pending = self.calculatePendingRewardFor(who, tierAsInt);
        self.sendPayUnstake(who, msg.amount, pending, msg.queryId);

        let newAmt = cur.amount - msg.amount;
        if (newAmt == 0) {
            self.stakesMapDel(tierAsInt, who);
            self.debtMapDel(tierAsInt, who);
        } else {
            let upd = StakeInfoView {
                amount: newAmt,
                tier: cur.tier,
                startTime: cur.startTime,
                lastClaimTime: cur.lastClaimTime,
                unlockTime: cur.unlockTime,
            };
            self.stakesMapSet(tierAsInt, who, upd);
            self.initUserRewardDebt(who, tierAsInt, newAmt);
        }

        self.subTierTotalStake(tierAsInt, msg.amount);

        message(MessageParameters {
            to: self.pool,
            value: self.GasToPool,
            bounce: true,
            mode: SendPayGasSeparately,
            body: DecrementTotalStake {
                queryId: msg.queryId,
                tier: tierAsInt,
                delta: msg.amount,
            }.toCell(),
        });
    }

    receive(msg: ClaimRewards) {
        require(context().value >= self.GasPayRewards + ton("0.06"), "Low TON claim");
        self.tickEmission();

        let who = sender();
        let tierAsInt = msg.tier;
        self.assertTier(tierAsInt);

        let curOpt = self.stakesMapGet(tierAsInt, who);
        require(curOpt != null, "No stake");
        let cur = curOpt!!;
        require(cur.amount > 0, "Empty stake");

        let pending = self.calculatePendingRewardFor(who, tierAsInt);
        require(pending > 0, "Nothing to claim");
        self.sendPayRewards(who, pending, msg.queryId);

        self.initUserRewardDebt(who, tierAsInt, cur.amount);

        let claimTime = now();
        let upd = StakeInfoView {
            amount: cur.amount,
            tier: cur.tier,
            startTime: cur.startTime,
            lastClaimTime: claimTime,
            unlockTime: cur.unlockTime,
        };
        self.stakesMapSet(tierAsInt, who, upd);
    }

    /// Trusted callback from staking pool (`sender()==pool`): accrues staking fee into rewardPerShare.
    /// Remaining TON is absorbed (no cashback) to avoid ping-pong with Pool's generic receive().
    receive(msg: StakeFeeRewardsAccrue) {
        require(sender() == self.pool, "Only pool");
        self.applyStakeFeeSlices(msg.feeAmount);
    }

    fun computeOwnerVotingPower(ownerAddr: Address): Int {
        let sum: Int = 0;
        let t = self.MinTier;
        while (t <= self.MaxTier) {
            let stOpt = self.stakesMapGet(t, ownerAddr);
            if (stOpt != null) {
                let stake = stOpt!!;
                if (stake.amount > 0) {
                    sum =
                        sum +
                        tierVotingPowerFromAmount(stake.amount, self.tierVpMultiplier(stake.tier));
                }
            }
            t = t + 1;
        }
        return sum;
    }

    /// Vote-weight for governance: only stakes locked past `voteEndTime` count
    /// (IMP-FAUDIT-F01 / F-2). Flexible-tier (`unlockTime == startTime`) never
    /// satisfies `unlockTime > voteEndTime` once voting has opened, so the
    /// post-snapshot flash-stake path cannot inflate `forVotes`.
    fun computeOwnerVotingPowerLockedBeyond(ownerAddr: Address, voteEndTime: Int): Int {
        let sum: Int = 0;
        let t = self.MinTier;
        while (t <= self.MaxTier) {
            let stOpt = self.stakesMapGet(t, ownerAddr);
            if (stOpt != null) {
                let stake = stOpt!!;
                if (stake.amount > 0 && stake.unlockTime > voteEndTime) {
                    sum =
                        sum +
                        tierVotingPowerFromAmount(stake.amount, self.tierVpMultiplier(stake.tier));
                }
            }
            t = t + 1;
        }
        return sum;
    }

    fun computeTotalVotingPower(): Int {
        let sum: Int = 0;
        let t = self.MinTier;
        while (t <= self.MaxTier) {
            let tot = self.tierTotalStake(t);
            if (tot > 0) {
                sum = sum + tierVotingPowerFromAmount(tot, self.tierVpMultiplier(t));
            }
            t = t + 1;
        }
        return sum;
    }

    receive(msg: GovernorVoteRelay) {
        require(sender() == self.governorAddr, "Only governor");
        require(msg.claimedVp > 0, "Zero claimed vp");

        /// Lock-gated VP (IMP-FAUDIT-F01): live stake alone is not enough — the
        /// capital must remain locked past the proposal's voting window.
        let onChainVp = self.computeOwnerVotingPowerLockedBeyond(msg.voter, msg.voteEndTime);
        let vpEff = onChainVp;
        if (msg.claimedVp < vpEff) {
            vpEff = msg.claimedVp;
        }
        require(vpEff > 0, "Zero effective vp");

        message(MessageParameters {
            to: msg.proposal,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: ProposalVoteRelay {
                voter: msg.voter,
                support: msg.support,
                vp: vpEff,
            }.toCell(),
        });
    }

    /// IMP-GOVOTE-03 / AD-1 — Proposal rejected `ProposalVoteRelay` (Not started, Already voted, …).
    /// Bounce returns the forwarded vote value. `voter` does not fit the ~224-bit bounce prefix
    /// (Address after opcode) — value stays on StakingMaster; see decision log. No cashback to
    /// Governor (IMP-GOVOTE-02 / RC-2).
    bounced(msg: bounced<ProposalVoteRelay>) {
        /// Absorb bounce value; terminal voter refund happens only on successful ProposalVoteRelay.
    }

    /// IMP-AUDIT-03 — trusted push sync from StakingLock (Timelock-governed tier table).
    /// Remaining TON is absorbed (no cashback) to avoid ping-pong with Lock's generic receive().
    receive(msg: TierConfigSync) {
        require(sender() == self.stakingLock, "Only staking lock");
        let t = msg.tier;
        self.assertTier(t);
        require(msg.multiplier > 0, "Bad multiplier");
        require(msg.rewardShare >= 0 && msg.rewardShare <= 100, "Bad share");
        self.tierConfigs.set(
            t,
            TierConfig {
                durationSeconds: msg.durationSeconds,
                multiplier: msg.multiplier,
                rewardShare: msg.rewardShare,
            },
        );
    }

    /// IMP-AUDIT-02 — authoritative total-VP snapshot for governance quorum.
    /// Only the wired Governor may request it. Computes on-chain Σ VP and the proposer's
    /// eligibility VP, then echoes the pending proposal so phase 2 can deploy with an
    /// un-spoofable quorum denominator and minProposalVp gate (IMP-MNAUD-F07).
    /// The remaining value is forwarded back so phase 2 can fund the deploy.
    receive(msg: RequestTotalVpSnapshot) {
        require(sender() == self.governorAddr, "Only governor");

        let totalVp = self.computeTotalVotingPower();
        let proposerVp = self.computeOwnerVotingPower(msg.proposer);

        message(MessageParameters {
            to: self.governorAddr,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: TotalVpSnapshotReply {
                queryId: msg.queryId,
                proposalId: msg.proposalId,
                proposer: msg.proposer,
                proposalType: msg.proposalType,
                payload: msg.payload,
                period: msg.period,
                quorumPercent: msg.quorumPercent,
                thresholdBps: msg.thresholdBps,
                timelockDelay: msg.timelockDelay,
                totalVp: totalVp,
                proposerVp: proposerVp,
            }.toCell(),
        });
    }

    fun calculatePendingRewardFor(ownerAddr: Address, tierAsInt: Int): Int {
        let stakeOpt = self.stakesMapGet(tierAsInt, ownerAddr);
        if (stakeOpt == null) {
            return 0;
        }
        let stake = stakeOpt!!;
        if (stake.amount == 0) {
            return 0;
        }
        let accrued = stake.amount * self.rewardPerShareForTier(tierAsInt) / self.RewardScale;
        let debt = self.debtMapGet(tierAsInt, ownerAddr);
        let pend = accrued - debt;
        if (pend < 0) {
            return 0;
        }
        return pend;
    }

    get fun get_voting_power(ownerAddr: Address): Int {
        return self.computeOwnerVotingPower(ownerAddr);
    }

    /// Lock-gated VP used by `GovernorVoteRelay` (IMP-FAUDIT-F01). Tooling / frontend
    /// can preview whether a stake will count for a given proposal end time.
    get fun get_voting_power_locked_beyond(ownerAddr: Address, voteEndTime: Int): Int {
        return self.computeOwnerVotingPowerLockedBeyond(ownerAddr, voteEndTime);
    }

    /// Sum of VP over all tiers (Σ tierTotalStake × runtime multiplier / 100).
    get fun get_total_voting_power(): Int {
        return self.computeTotalVotingPower();
    }

    get fun get_governor_addr(): Address {
        return self.governorAddr;
    }

    get fun calculatePendingReward(ownerAddr: Address, tier: Int): Int {
        self.assertTier(tier);
        return self.calculatePendingRewardFor(ownerAddr, tier);
    }

    get fun get_pending_reward(ownerAddr: Address, tier: Int): Int {
        return self.calculatePendingReward(ownerAddr, tier);
    }

    get fun get_reward_scale(): Int {
        return self.RewardScale;
    }

    get fun get_reward_per_share(tier: Int): Int {
        self.assertTier(tier);
        return self.rewardPerShareForTier(tier);
    }

    get fun get_user_reward_debt(ownerAddr: Address, tier: Int): Int {
        self.assertTier(tier);
        return self.debtMapGet(tier, ownerAddr);
    }

    get fun get_master_total_stake(tier: Int): Int {
        self.assertTier(tier);
        return self.tierTotalStake(tier);
    }

    get fun get_pool(): Address {
        return self.pool;
    }

    get fun get_jetton_master(): Address {
        return self.jettonMaster;
    }

    get fun get_staking_lock(): Address {
        return self.stakingLock;
    }

    get fun get_staking_jetton_wallet(): Address {
        return self.stakingJettonWallet;
    }

    get fun get_stake(ownerAddr: Address, tier: Int): StakeInfoView? {
        self.assertTier(tier);
        return self.stakesMapGet(tier, ownerAddr);
    }

    get fun get_emission_start_time(): Int {
        return self.emissionStartTime;
    }

    get fun get_last_emit_time(): Int {
        return self.lastEmitTime;
    }

    get fun get_emitted_so_far(): Int {
        return self.emittedSoFar;
    }

    get fun get_total_emission_budget(): Int {
        return self.TotalEmissionNano;
    }

    get fun get_emission_funded(): Int {
        return self.emissionFunded;
    }

    get fun get_tier_config(tier: Int): TierConfig {
        return self.tierCfg(tier);
    }
}
