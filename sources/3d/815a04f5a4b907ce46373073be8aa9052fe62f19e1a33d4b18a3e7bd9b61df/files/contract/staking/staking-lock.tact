// SPDX-License-Identifier: MIT
// Staking Lock — tier lock durations, VP multipliers, reward share splits (governance-adjustable).
// Authoritative tier table for Timelock; pushes runtime cache updates to StakingMaster (IMP-AUDIT-03).

// Tier ids match StakingMaster: Flexible=0, Silver=1, Gold=2, Diamond=3.

struct TierConfig {
    durationSeconds: Int as uint64;
    multiplier: Int; // 100 = 1.0x (integer basis)
    rewardShare: Int; // percent points, all four tiers must sum to 100
}

/// Push-model sync: StakingLock → StakingMaster after each governance tier change.
message(0x5a030010) TierConfigSync {
    queryId: Int as uint64;
    tier: Int as uint8;
    durationSeconds: Int as uint64;
    multiplier: Int;
    rewardShare: Int;
}

message(0x5a030001) SetLockDuration {
    queryId: Int as uint64;
    tier: Int as uint8;
    duration: Int as uint64;
}

message(0x5a030002) SetTierMultiplier {
    queryId: Int as uint64;
    tier: Int as uint8;
    multiplier: Int;
}

message(0x5a030003) SetTierRewardShare {
    queryId: Int as uint64;
    tier: Int as uint8;
    share: Int;
}

/// One-shot bootstrap wiring: StakingLock may push tier-config updates to StakingMaster.
message(0x5a030004) SetStakingMasterForPush {
    queryId: Int as uint64;
    stakingMaster: Address;
}

/// Bootstrap / recovery: push all four tier rows to StakingMaster (requires push wiring).
message(0x5a030005) PushAllTierConfigs {
    queryId: Int as uint64;
}

/// Batch rebalance of all tier reward shares (must sum to 100). Timelock-only.
message(0x5a030006) SetAllTierRewardShares {
    queryId: Int as uint64;
    share0: Int;
    share1: Int;
    share2: Int;
    share3: Int;
}

contract StakingLock(
    timelock: Address,
    stakingMaster: Address,
    smPushWired: Bool,
    configs: map<Int, TierConfig>,
) {
    const MinTier: Int = 0;
    const MaxTier: Int = 3;
    const GasPushSync: Int = ton("0.04");

    receive() {
        /// Plain TON from StakingMaster (TierConfigSync cashback) must not bounce back — RC-A (IMP-RELAY-03).
        if (sender() != self.stakingMaster) {
            cashback(sender());
        }
    }

    inline fun assertTimelock() {
        require(sender() == self.timelock, "Only timelock");
    }

    inline fun assertTier(tier: Int) {
        require(tier >= self.MinTier && tier <= self.MaxTier, "Bad tier");
    }

    inline fun tierCfg(tier: Int): TierConfig {
        require(self.configs.get(tier) != null, "Missing tier cfg");
        return self.configs.get(tier)!!;
    }

    inline fun pushTierConfigToMaster(tier: Int) {
        if (!self.smPushWired) {
            return;
        }
        let cfg = self.tierCfg(tier);
        message(MessageParameters {
            to: self.stakingMaster,
            value: self.GasPushSync,
            bounce: true,
            body: TierConfigSync {
                queryId: 0,
                tier: tier,
                durationSeconds: cfg.durationSeconds,
                multiplier: cfg.multiplier,
                rewardShare: cfg.rewardShare,
            }.toCell(),
        });
    }

    /// Bootstrap-only: wire StakingMaster as push target (placeholder `stakingMaster` at deploy).
    receive(msg: SetStakingMasterForPush) {
        require(sender() == self.timelock, "Only timelock");
        require(!self.smPushWired, "Push already wired");
        forceBasechain(msg.stakingMaster);
        self.stakingMaster = msg.stakingMaster;
        self.smPushWired = true;
        cashback(sender());
    }

    receive(msg: PushAllTierConfigs) {
        self.assertTimelock();
        require(self.smPushWired, "Push not wired");
        let t: Int = self.MinTier;
        while (t <= self.MaxTier) {
            self.pushTierConfigToMaster(t);
            t = t + 1;
        }
        cashback(sender());
    }

    receive(msg: SetAllTierRewardShares) {
        self.assertTimelock();
        require(
            msg.share0 + msg.share1 + msg.share2 + msg.share3 == 100,
            "Shares must sum to 100",
        );
        require(msg.share0 >= 0 && msg.share0 <= 100, "Bad share");
        require(msg.share1 >= 0 && msg.share1 <= 100, "Bad share");
        require(msg.share2 >= 0 && msg.share2 <= 100, "Bad share");
        require(msg.share3 >= 0 && msg.share3 <= 100, "Bad share");

        let t: Int = self.MinTier;
        while (t <= self.MaxTier) {
            let cur = self.tierCfg(t);
            let share: Int = msg.share0;
            if (t == 1) {
                share = msg.share1;
            } else if (t == 2) {
                share = msg.share2;
            } else if (t == 3) {
                share = msg.share3;
            }
            self.configs.set(
                t,
                TierConfig {
                    durationSeconds: cur.durationSeconds,
                    multiplier: cur.multiplier,
                    rewardShare: share,
                },
            );
            t = t + 1;
        }

        t = self.MinTier;
        while (t <= self.MaxTier) {
            self.pushTierConfigToMaster(t);
            t = t + 1;
        }
        cashback(sender());
    }

    receive(msg: SetLockDuration) {
        self.assertTimelock();
        let t = msg.tier;
        self.assertTier(t);
        let cur = self.tierCfg(t);
        self.configs.set(
            t,
            TierConfig {
                durationSeconds: msg.duration,
                multiplier: cur.multiplier,
                rewardShare: cur.rewardShare,
            },
        );
        self.pushTierConfigToMaster(t);
        cashback(sender());
    }

    receive(msg: SetTierMultiplier) {
        self.assertTimelock();
        let t = msg.tier;
        self.assertTier(t);
        require(msg.multiplier > 0, "Bad multiplier");
        let cur = self.tierCfg(t);
        self.configs.set(
            t,
            TierConfig {
                durationSeconds: cur.durationSeconds,
                multiplier: msg.multiplier,
                rewardShare: cur.rewardShare,
            },
        );
        self.pushTierConfigToMaster(t);
        cashback(sender());
    }

    receive(msg: SetTierRewardShare) {
        self.assertTimelock();
        let t = msg.tier;
        self.assertTier(t);
        require(msg.share >= 0 && msg.share <= 100, "Bad share");

        let other: Int = 0;
        foreach (k, cfg in self.configs) {
            if (k != t) {
                other = other + cfg.rewardShare;
            }
        }
        require(other + msg.share == 100, "Shares must sum to 100");

        let cur = self.tierCfg(t);
        self.configs.set(
            t,
            TierConfig {
                durationSeconds: cur.durationSeconds,
                multiplier: cur.multiplier,
                rewardShare: msg.share,
            },
        );
        self.pushTierConfigToMaster(t);
        cashback(sender());
    }

    get fun get_lock_config(tier: Int): TierConfig {
        return self.tierCfg(tier);
    }

    get fun get_unlock_time(tier: Int, startTime: Int): Int {
        let d = self.tierCfg(tier).durationSeconds;
        return startTime + d;
    }

    get fun is_unlocked(tier: Int, startTime: Int, currentTime: Int): Bool {
        return currentTime >= self.get_unlock_time(tier, startTime);
    }

    /// Full tier map for off-chain tooling (keys 0–3 expected).
    get fun get_all_configs(): map<Int, TierConfig> {
        return self.configs;
    }

    get fun get_tier_multiplier(tier: Int): Int {
        return self.tierCfg(tier).multiplier;
    }

    get fun get_timelock(): Address {
        return self.timelock;
    }

    get fun get_staking_master_push_target(): Address {
        return self.stakingMaster;
    }

    get fun get_sm_push_wired(): Bool {
        return self.smPushWired;
    }
}
