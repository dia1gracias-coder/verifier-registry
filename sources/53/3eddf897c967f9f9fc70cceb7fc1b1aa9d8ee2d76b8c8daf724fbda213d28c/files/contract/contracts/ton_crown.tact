import "@stdlib/deploy";
import "@stdlib/ownable";

//------------------------------------------------------------------
// STRUCTS AND MESSAGES
//------------------------------------------------------------------

struct StakeInfo {
    stakeId: Int as uint16;
    amount: Int as coins;
    startTime: Int as uint32;
    duration: Int as uint32;
    vipClass: Int as uint8;
    autoRestake: Bool;
    lastClaim: Int as uint32;
    totalClaimed: Int as coins;
    isActive: Bool;
    stakedAsset: Int as uint8;
}

struct StakeDetails {
    stakeId: Int as uint16;
    amount: Int as coins;
    startTime: Int as uint32;
    duration: Int as uint32;
    vipClass: Int as uint8;
    autoRestake: Bool;
    lastClaim: Int as uint32;
    totalClaimed: Int as coins;
    isActive: Bool;
    stakedAsset: Int as uint8;
    pendingReward: Int as coins;
}

struct UserReferralInfo {
    referrer: Address?;
    directReferrals: Int as uint16;
    totalReferrals: Int as uint32;
    downlines: map<Int, Address>;
}

struct User {
    referrer: Address?;
    level: Int as uint8;
    vipClass: Int as uint8;
    directReferrals: Int as uint16;
    totalReferrals: Int as uint32;
    otherReferrals: Int as uint32;
    lastCheckIn: Int as uint32;
    levelExpiration: Int as uint32;
    totalEarned: Int as coins;
    isActive: Bool;
    registrationTime: Int as uint32;
    stakeCounter: Int as uint16;
    stakes: map<Int, StakeInfo>;
    downlines: map<Int, Address>;
    spilloverIndex: Int as uint16;

    // Check-in reward tracking
    pendingCheckInRewards: Int as coins;
    totalCheckInEarned: Int as coins;
    totalCheckInClaimed: Int as coins;

    // Earnings breakdown
    totalStakingClaimed: Int as coins;
    totalReferralEarned: Int as coins;
    totalSpilloverEarned: Int as coins;

    // Transaction history
    transactionCounter: Int as uint32;
    transactions: map<Int, UserTransaction>;
}

struct VipConfig {
    dailyRoi: Int as uint16;
    minLevel: Int as uint8;
    maxLevel: Int as uint8;
    stakingRoi: Int as uint16;
}

struct PlatformStats {
    totalUsers: Int as uint32;
    totalStakedTon: Int as coins;
    totalStakedUsdt: Int as coins;
    totalDistributed: Int as coins;
    activeStakes: Int as uint32;
}

// MESSAGES
message UpgradeLevel {
    targetLevel: Int as uint8;
    referrerAddress: Address?;
}

message CheckIn {}

message StakeTON {
    duration: Int as uint32;
    autoRestake: Bool;
    referrerAddress: Address?;
}

message ClaimStakingRewards {
    stakeId: Int as uint16;
}

message UpdateAutoRestake {
    stakeId: Int as uint16;
    autoRestake: Bool;
}

struct StakeUsdtPayload {
    duration: Int as uint32;
    autoRestake: Bool;
    referrerAddress: Address?;
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

message(0x0f8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message DistributeDailyRewards {
    user: Address;
    stakeId: Int as uint16;
}

message UpdateLevelCost {
    level: Int as uint8;
    cost: Int as coins;
}

message SetUsdtJettonWallet {
    wallet: Address;
}

message SetDistributor {
    address: Address;
}

message OwnerDeposit {}

message OwnerWithdraw {
    amount: Int as coins;
}

message ClaimCheckInRewards {}

struct UserTransaction {
    txId: Int as uint32;
    timestamp: Int as uint32;
    txType: Int as uint8;
    amount: Int as coins;
    level: Int as uint8;
    stakeId: Int as uint16;
    assetType: Int as uint8;
    counterparty: Address?;
    description: String;
}

struct UserEarningsInfo {
    totalEarned: Int as coins;
    pendingCheckInRewards: Int as coins;
    totalCheckInEarned: Int as coins;
    totalCheckInClaimed: Int as coins;
    totalStakingClaimed: Int as coins;
    pendingStakingRewards: Int as coins;
    totalReferralEarned: Int as coins;
    totalSpilloverEarned: Int as coins;
    totalClaimable: Int as coins;
}

struct PlatformEarningsInfo {
    totalUsers: Int as uint32;
    totalStakedTon: Int as coins;
    totalStakedUsdt: Int as coins;
    totalDistributed: Int as coins;
    totalCheckInRewardsAccrued: Int as coins;
    totalCheckInRewardsClaimed: Int as coins;
    totalReferralRewardsPaid: Int as coins;
    totalSpilloverRewardsPaid: Int as coins;
    totalCreatorRewardsPaid: Int as coins;
    totalUnclaimedCheckInRewards: Int as coins;
    activeStakes: Int as uint32;
    contractBalance: Int as coins;
}

struct UserStakeSummary {
    totalStakes: Int as uint16;
    activeStakes: Int as uint16;
    inactiveStakes: Int as uint16;
    pendingStakingRewards: Int as coins;
}

//------------------------------------------------------------------
// CONTRACT: TONCROWN
//------------------------------------------------------------------

contract TonCrown with Deployable, OwnableTransferable {
    owner: Address;
    creatorWallet1: Address;
    creatorWallet2: Address;
    creatorWallet3: Address;
    creatorWallet4: Address;
    usdtJettonWalletAddress: Address;
    distributorAddress: Address;

    users: map<Address, User>;
    levelCosts: map<Int, Int>;
    vipConfigs: map<Int, VipConfig>;

    totalUsers: Int as uint32;
    totalStakedTon: Int as coins;
    totalStakedUsdt: Int as coins;
    totalDistributed: Int as coins;
    activeStakes: Int as uint32;
    isPaused: Bool;

    userList: map<Int, Address>;
    spilloverNextIndexByBoughtLevel: map<Int, Int>;

    // Platform-level earnings tracking
    totalCheckInRewardsAccrued: Int as coins;
    totalCheckInRewardsClaimed: Int as coins;
    totalReferralRewardsPaid: Int as coins;
    totalSpilloverRewardsPaid: Int as coins;
    totalCreatorRewardsPaid: Int as coins;

    const DAILY_CHECKIN_REWARD: Int = ton("0.01");
    const LEVEL1_DURATION: Int = 2592000;
    const MIN_STAKE_DURATION: Int = 14;
    const MAX_STAKE_DURATION: Int = 730;
    const MAX_DIRECT_REFERRALS: Int = 6;
    const SECONDS_PER_DAY: Int = 86400;
    const ASSET_TON: Int = 0;
    const ASSET_USDT: Int = 1;

    // Hybrid gas policy:
    // - upgrades keep the original 0.05 TON buffer because distribution performs many internal sends;
    // - simple actions use smaller per-action buffers;
    // - buffers are not counted as business/reward/stake amounts.
    const DISTRIBUTION_GAS_FEE: Int = ton("0.005");
    const MIN_CONTRACT_RESERVE: Int = ton("0.05");
    const UPGRADE_GAS_BUFFER: Int = ton("0.05");
    const CHECKIN_GAS_BUFFER: Int = ton("0.01");
    const CLAIM_GAS_BUFFER: Int = ton("0.02");
    const STAKE_GAS_BUFFER: Int = ton("0.03");

    // Transaction type constants
    const TX_LEVEL_UPGRADE: Int = 1;
    const TX_CHECKIN_ACCRUED: Int = 2;
    const TX_CHECKIN_CLAIMED: Int = 3;
    const TX_STAKE_TON: Int = 4;
    const TX_STAKE_USDT: Int = 5;
    const TX_STAKING_REWARD_CLAIMED: Int = 6;
    const TX_REFERRAL_COMMISSION: Int = 7;
    const TX_SPILLOVER_REWARD: Int = 8;
    const TX_OWNER_WITHDRAW: Int = 9;
    const TX_REFUND: Int = 10;

    init(owner: Address) {
        self.owner = owner;
        self.creatorWallet1 = address("UQCtNZf0MCqmy558C2zgtzK7i69gg0ttOBWmZ-88ScJp40s5");
        self.creatorWallet2 = address("UQDh7i8s3-wUTuEQ5c5umdpYr9ZG5hWs10LwV8ZIMflYezk8");
        self.creatorWallet3 = address("UQBsxkLE-YTsKmBvnJXe3iqiWEcXG2qgHAJO63fIlRgu87dI");
        self.creatorWallet4 = address("UQD8W3W7eQ7b3drJcSfAqwf8DM47W2LNZn_V3UirGI0NpoqQ");

        self.usdtJettonWalletAddress = owner;
        self.distributorAddress = owner;

        self.totalUsers = 0;
        self.totalStakedTon = 0;
        self.totalStakedUsdt = 0;
        self.totalDistributed = 0;
        self.activeStakes = 0;
        self.isPaused = false;

        self.spilloverNextIndexByBoughtLevel = emptyMap();

        self.totalCheckInRewardsAccrued = 0;
        self.totalCheckInRewardsClaimed = 0;
        self.totalReferralRewardsPaid = 0;
        self.totalSpilloverRewardsPaid = 0;
        self.totalCreatorRewardsPaid = 0;

        self.levelCosts.set(1, ton("1.25"));
        self.levelCosts.set(2, ton("2.51"));
        self.levelCosts.set(3, ton("3.77"));
        self.levelCosts.set(4, ton("5.03"));
        self.levelCosts.set(5, ton("6.27"));
        self.levelCosts.set(6, ton("7.53"));
        self.levelCosts.set(7, ton("8.78"));
        self.levelCosts.set(8, ton("10.04"));
        self.levelCosts.set(9, ton("11.29"));
        self.levelCosts.set(10, ton("12.55"));

        self.vipConfigs.set(1, VipConfig{ dailyRoi: 100, minLevel: 4, maxLevel: 6, stakingRoi: 95 });
        self.vipConfigs.set(2, VipConfig{ dailyRoi: 150, minLevel: 7, maxLevel: 8, stakingRoi: 145 });
        self.vipConfigs.set(3, VipConfig{ dailyRoi: 200, minLevel: 9, maxLevel: 10, stakingRoi: 195 });
        self.vipConfigs.set(4, VipConfig{ dailyRoi: 250, minLevel: 10, maxLevel: 10, stakingRoi: 250 });
    }

    receive() {}

    receive(msg: UpgradeLevel) {
        self.requireNotPaused();
        let senderAddress: Address = sender();
        let originalReferrer: Address? = msg.referrerAddress;

        let currentUser: User = self.getOrRegisterUser(senderAddress, originalReferrer);

        require(msg.targetLevel == currentUser.level + 1, "Must upgrade sequentially");
        let levelCost: Int = self.levelCosts.get(msg.targetLevel)!!;
        require(context().value >= levelCost + self.UPGRADE_GAS_BUFFER, "Insufficient payment for level and gas");

        let purchaseTime: Int = now();
        let oldLevel: Int = currentUser.level;
        currentUser.level = msg.targetLevel;
        currentUser.vipClass = self.calculateVipClass(msg.targetLevel);
        currentUser.isActive = true;

        if (msg.targetLevel == 1) {
            currentUser.levelExpiration = purchaseTime + self.LEVEL1_DURATION;
        }

        self.users.set(senderAddress, currentUser);

        // Only levelCost is distributed/recorded. The gas buffer remains available for internal sends/storage.
        self.distributeFunds(levelCost, senderAddress, oldLevel + 1, originalReferrer, purchaseTime);

        self.recordUserTransaction(
            senderAddress,
            self.TX_LEVEL_UPGRADE,
            levelCost,
            msg.targetLevel,
            0,
            self.ASSET_TON,
            null,
            "Level Upgrade"
        );

        self.reply("Level upgrade successful".asComment());
    }

    receive(msg: CheckIn) {
        self.requireNotPaused();
        require(context().value >= self.CHECKIN_GAS_BUFFER, "Insufficient check-in gas");

        let senderAddress: Address = sender();
        let currentUser: User = self.requireUserExists(senderAddress);
        let currentTime: Int = now();

        require(currentUser.level > 0 && currentUser.isActive, "Must have an active level to check in");
        require(currentTime - currentUser.lastCheckIn >= self.SECONDS_PER_DAY, "Already checked in today");

        // Level 1 users lose check-in eligibility after 30 days but keep their level.
        if (currentUser.level == 1) {
            require(currentTime <= currentUser.levelExpiration, "Level 1 check-in period has ended");
        }

        let reward: Int = self.DAILY_CHECKIN_REWARD;

        // Accumulate reward — do NOT send TON here.
        currentUser.pendingCheckInRewards = currentUser.pendingCheckInRewards + reward;
        currentUser.totalCheckInEarned = currentUser.totalCheckInEarned + reward;
        currentUser.totalEarned = currentUser.totalEarned + reward;
        currentUser.lastCheckIn = currentTime;

        self.totalCheckInRewardsAccrued = self.totalCheckInRewardsAccrued + reward;
        self.totalDistributed = self.totalDistributed + reward;

        let txId: Int = currentUser.transactionCounter;
        currentUser.transactions.set(txId, UserTransaction{
            txId: txId,
            timestamp: currentTime,
            txType: self.TX_CHECKIN_ACCRUED,
            amount: reward,
            level: currentUser.level,
            stakeId: 0,
            assetType: self.ASSET_TON,
            counterparty: null,
            description: "Daily Check-in Accrued"
        });
        currentUser.transactionCounter = currentUser.transactionCounter + 1;

        self.users.set(senderAddress, currentUser);
        self.reply("Check-in successful. Reward added to claimable balance.".asComment());
    }

    receive(msg: ClaimCheckInRewards) {
        self.requireNotPaused();
        require(context().value >= self.CLAIM_GAS_BUFFER, "Insufficient claim gas");

        let senderAddress: Address = sender();
        let user: User = self.requireUserExists(senderAddress);

        let claimAmount: Int = user.pendingCheckInRewards;
        require(claimAmount > 0, "No check-in rewards to claim");
        require(myBalance() >= claimAmount + self.MIN_CONTRACT_RESERVE, "Insufficient contract balance");

        // Zero out BEFORE sending — prevents double-claim.
        user.pendingCheckInRewards = 0;
        user.totalCheckInClaimed = user.totalCheckInClaimed + claimAmount;
        self.totalCheckInRewardsClaimed = self.totalCheckInRewardsClaimed + claimAmount;

        let txId: Int = user.transactionCounter;
        user.transactions.set(txId, UserTransaction{
            txId: txId,
            timestamp: now(),
            txType: self.TX_CHECKIN_CLAIMED,
            amount: claimAmount,
            level: user.level,
            stakeId: 0,
            assetType: self.ASSET_TON,
            counterparty: null,
            description: "Check-in Rewards Claimed"
        });
        user.transactionCounter = user.transactionCounter + 1;

        self.users.set(senderAddress, user);

        send(SendParameters{
            to: senderAddress,
            value: claimAmount,
            mode: SendIgnoreErrors,
            body: "Check-in Rewards Claim".asComment()
        });

        self.reply("Check-in rewards claimed successfully.".asComment());
    }

    receive(msg: StakeTON) {
        self.requireNotPaused();
        let senderAddress: Address = sender();
        let user: User = self.getOrRegisterUser(senderAddress, msg.referrerAddress);
        user = self.refreshUserLevelStatus(senderAddress);

        require(user.vipClass > 0, "VIP status required for staking");
        require(msg.duration >= self.MIN_STAKE_DURATION && msg.duration <= self.MAX_STAKE_DURATION, "Invalid staking duration");

        require(context().value > self.STAKE_GAS_BUFFER, "Insufficient value for staking gas");
        let stakeAmount: Int = context().value - self.STAKE_GAS_BUFFER;

        let minStakeTon: Int = self.getMinStakeTon(user.vipClass);
        require(stakeAmount >= minStakeTon, "Stake amount below minimum");

        let stakeId: Int = user.stakeCounter;
        let currentTime: Int = now();
        let newStake: StakeInfo = StakeInfo{
            stakeId: stakeId,
            amount: stakeAmount,
            startTime: currentTime,
            duration: msg.duration * self.SECONDS_PER_DAY,
            vipClass: user.vipClass,
            autoRestake: msg.autoRestake,
            lastClaim: currentTime,
            totalClaimed: 0,
            isActive: true,
            stakedAsset: self.ASSET_TON
        };

        user.stakes.set(stakeId, newStake);
        user.stakeCounter += 1;

        let tonStakeTxId: Int = user.transactionCounter;
        user.transactions.set(tonStakeTxId, UserTransaction{
            txId: tonStakeTxId,
            timestamp: currentTime,
            txType: self.TX_STAKE_TON,
            amount: stakeAmount,
            level: user.level,
            stakeId: stakeId,
            assetType: self.ASSET_TON,
            counterparty: null,
            description: "TON Staking"
        });
        user.transactionCounter = user.transactionCounter + 1;

        self.users.set(senderAddress, user);

        self.totalStakedTon += stakeAmount;
        self.activeStakes += 1;

        // Preserved existing flow: staking capital is forwarded to creatorWallet3/treasury.
        // Production operation must ensure this treasury is funded for future refunds/rewards.
        send(SendParameters{
            to: self.creatorWallet3,
            value: stakeAmount,
            mode: SendIgnoreErrors,
            body: "TON Staking Capital".asComment()
        });
        self.reply("Staking successful".asComment());
    }

    receive(msg: JettonTransferNotification) {
        self.requireNotPaused();
        require(sender() == self.usdtJettonWalletAddress, "Unknown jetton wallet");

        let stakerAddress: Address = msg.sender;
        let usdtReceived: Int = msg.amount;
        let payloadSlice: Slice = msg.forwardPayload;

        let payload: StakeUsdtPayload = StakeUsdtPayload{
            duration: payloadSlice.loadUint(32),
            autoRestake: payloadSlice.loadBool(),
            referrerAddress: payloadSlice.loadAddress()
        };

        let user: User = self.getOrRegisterUser(stakerAddress, payload.referrerAddress);
        user = self.refreshUserLevelStatus(stakerAddress);

        require(user.vipClass > 0, "VIP status required for staking");
        require(payload.duration >= self.MIN_STAKE_DURATION && payload.duration <= self.MAX_STAKE_DURATION, "Invalid duration");

        let minStakeUsd6: Int = self.getMinStakeInUsd6Decimals(user.vipClass);
        require(usdtReceived >= minStakeUsd6, "Stake amount below minimum");

        let stakeId: Int = user.stakeCounter;
        let currentTime: Int = now();
        let newStake: StakeInfo = StakeInfo{
            stakeId: stakeId,
            amount: usdtReceived,
            startTime: currentTime,
            duration: payload.duration * self.SECONDS_PER_DAY,
            vipClass: user.vipClass,
            autoRestake: payload.autoRestake,
            lastClaim: currentTime,
            totalClaimed: 0,
            isActive: true,
            stakedAsset: self.ASSET_USDT
        };

        user.stakes.set(stakeId, newStake);
        user.stakeCounter += 1;

        let usdtStakeTxId: Int = user.transactionCounter;
        user.transactions.set(usdtStakeTxId, UserTransaction{
            txId: usdtStakeTxId,
            timestamp: currentTime,
            txType: self.TX_STAKE_USDT,
            amount: usdtReceived,
            level: user.level,
            stakeId: stakeId,
            assetType: self.ASSET_USDT,
            counterparty: null,
            description: "USDT Staking"
        });
        user.transactionCounter = user.transactionCounter + 1;

        self.users.set(stakerAddress, user);
        self.totalStakedUsdt += usdtReceived;
        self.activeStakes += 1;

        send(SendParameters{
            to: self.usdtJettonWalletAddress,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            body: JettonTransfer{
                queryId: 0,
                amount: usdtReceived,
                destination: self.creatorWallet3,
                response_destination: self.owner,
                custom_payload: null,
                forward_ton_amount: ton("0.005"),
                forward_payload: "USDT Staking Capital".asComment().asSlice()
            }.toCell()
        });
    }

    receive(msg: ClaimStakingRewards) {
        self.requireNotPaused();
        require(context().value >= self.CLAIM_GAS_BUFFER, "Insufficient claim gas");

        let senderAddress: Address = sender();
        self.processRewardPayout(senderAddress, msg.stakeId);
    }

    receive(msg: DistributeDailyRewards) {
        require(sender() == self.distributorAddress, "Not authorized");
        self.requireNotPaused();
        self.processRewardPayout(msg.user, msg.stakeId);
    }

    receive(msg: UpdateAutoRestake) {
        self.requireNotPaused();
        let user: User = self.requireUserExists(sender());
        let stake: StakeInfo? = user.stakes.get(msg.stakeId);
        require(stake != null && stake!!.isActive, "No active stake");

        let mutableStake: StakeInfo = stake!!;
        mutableStake.autoRestake = msg.autoRestake;
        user.stakes.set(msg.stakeId, mutableStake);
        self.users.set(sender(), user);
        self.reply("Auto-restake updated".asComment());
    }

    receive(msg: UpdateLevelCost) {
        self.requireOwner();
        require(msg.level >= 1 && msg.level <= 10, "Invalid level");
        require(msg.cost > 0, "Invalid cost");
        self.levelCosts.set(msg.level, msg.cost);
    }

    receive(msg: SetUsdtJettonWallet) {
        self.requireOwner();
        self.usdtJettonWalletAddress = msg.wallet;
    }

    receive(msg: SetDistributor) {
        self.requireOwner();
        self.distributorAddress = msg.address;
    }

    receive(msg: OwnerDeposit) {
        self.requireOwner();
        send(
            SendParameters{
                to: sender(),
                value: 0,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Deposit successful".asComment()
            }
        )
    }

    receive(msg: OwnerWithdraw) {
        self.requireOwner();
        require(myBalance() >= msg.amount + self.MIN_CONTRACT_RESERVE, "Insufficient balance after reserve");
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendPayGasSeparately,
            body: "Owner Withdrawal".asComment()
        });
        // self.recordUserTransaction(
        //     self.owner,
        //     self.TX_OWNER_WITHDRAW,
        //     msg.amount,
        //     0,
        //     0,
        //     self.ASSET_TON,
        //     null,
        //     "Owner Withdrawal"
        // );
    }

    //------------------------------------------------------------------
    // INTERNAL HELPER FUNCTIONS
    //------------------------------------------------------------------

    fun calculatePendingStakeReward(stake: StakeInfo, currentTime: Int): Int {
        if (!stake.isActive) {
            return 0;
        }

        let effectiveTime: Int = currentTime;
        let endTime: Int = stake.startTime + stake.duration;
        if (effectiveTime > endTime) {
            effectiveTime = endTime;
        }

        if (effectiveTime <= stake.lastClaim) {
            return 0;
        }

        let elapsedDays: Int = (effectiveTime - stake.lastClaim) / self.SECONDS_PER_DAY;

        if (elapsedDays <= 0) {
            return 0;
        }

        let vip: VipConfig = self.vipConfigs.get(stake.vipClass)!!;
        return stake.amount * vip.stakingRoi * elapsedDays / 10000;
    }

    fun requireNotPaused() {
        require(!self.isPaused, "Contract is paused");
    }

    fun requireUserExists(userAddress: Address): User {
        let userData: User? = self.users.get(userAddress);
        require(userData != null, "User not registered");
        return userData!!;
    }

    fun refreshUserLevelStatus(userAddress: Address): User {
        let user: User = self.requireUserExists(userAddress);
        // Level 1 expiration no longer downgrades the user — check-in eligibility is enforced inside CheckIn.
        return user;
    }

    fun calculateVipClass(level: Int): Int {
        if (level >= 4 && level <= 6) {
            return 1;
        } else if (level >= 7 && level <= 8) {
            return 2;
        } else if (level >= 9) {
            return 3;
        }
        return 0;
    }

    fun getMinStakeTon(vipClass: Int): Int {
        if (vipClass == 1) {
            return ton("2");
        }
        if (vipClass == 2) {
            return ton("50");
        }
        if (vipClass >= 3) {
            return ton("100");
        }
        return 0;
    }

    fun getMinStakeInUsd6Decimals(vipClass: Int): Int {
        if (vipClass == 1) {
            return 10000000;
        }
        if (vipClass == 2) {
            return 50000000;
        }
        if (vipClass >= 3) {
            return 300000000;
        }
        return 0;
    }

    fun distributeSpilloverReward(spilloverShare: Int, boughtLevel: Int, payer: Address, purchaseTime: Int) {
        let minEligibleLevel: Int = boughtLevel;

        // Level 1 purchases cannot reward Level 1 users.
        if (boughtLevel == 1) {
            minEligibleLevel = 2;
        }

        let startIndexOpt: Int? = self.spilloverNextIndexByBoughtLevel.get(boughtLevel);
        let startIndex: Int = 0;
        if (startIndexOpt != null) {
            startIndex = startIndexOpt!!;
        }

        let recipientFound: Bool = false;

        if (self.totalUsers > 0) {
            let i: Int = 0;
            while (i < self.totalUsers && !recipientFound) {
                let currentIndex: Int = (startIndex + i) % self.totalUsers;
                let receiver: Address = self.userList.get(currentIndex)!!;

                // Buyer can never receive their own spillover.
                if (receiver != payer) {
                    let receiverUser: User = self.users.get(receiver)!!;

                    let eligible: Bool = receiverUser.isActive && receiverUser.registrationTime < purchaseTime && receiverUser.level >= minEligibleLevel;

                    if (eligible) {
                        send(SendParameters{
                            to: receiver,
                            value: spilloverShare,
                            mode: SendPayGasSeparately,
                            body: "Spillover Pool Reward".asComment()
                        });

                        self.totalSpilloverRewardsPaid = self.totalSpilloverRewardsPaid + spilloverShare;
                        self.creditSpilloverEarning(receiver, spilloverShare, payer, boughtLevel);

                        self.spilloverNextIndexByBoughtLevel.set(boughtLevel, (currentIndex + 1) % self.totalUsers);

                        recipientFound = true;
                    }
                }

                i = i + 1;
            }
        }

        // Fallback if nobody qualifies.
        if (!recipientFound) {
            send(SendParameters{
                to: self.creatorWallet3,
                value: spilloverShare,
                mode: SendPayGasSeparately,
                body: "Unclaimed Spillover".asComment()
            });
            self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + spilloverShare;
        }
    }

    fun getOrRegisterUser(userAddress: Address, referrerAddress: Address?): User {
        let userData: User? = self.users.get(userAddress);
        if (userData != null) {
            return userData!!;
        }

        let newUser: User = User{
            referrer: referrerAddress,
            level: 0,
            vipClass: 0,
            directReferrals: 0,
            totalReferrals: 0,
            otherReferrals: 0,
            lastCheckIn: 0,
            levelExpiration: 0,
            totalEarned: 0,
            isActive: true,
            registrationTime: now(),
            stakeCounter: 0,
            stakes: emptyMap(),
            downlines: emptyMap(),
            spilloverIndex: 0,
            pendingCheckInRewards: 0,
            totalCheckInEarned: 0,
            totalCheckInClaimed: 0,
            totalStakingClaimed: 0,
            totalReferralEarned: 0,
            totalSpilloverEarned: 0,
            transactionCounter: 0,
            transactions: emptyMap()
        };

        self.userList.set(self.totalUsers, userAddress);
        self.users.set(userAddress, newUser);
        self.totalUsers = self.totalUsers + 1;

        if (referrerAddress != null) {
            self.processReferralRegistration(userAddress, referrerAddress!!);
        }

        return self.users.get(userAddress)!!;
    }

    fun processReferralRegistration(newUser: Address, referrer: Address) {
        let referrerUserOpt: User? = self.users.get(referrer);
        if (referrerUserOpt == null || !referrerUserOpt!!.isActive) {
            let user: User = self.users.get(newUser)!!;
            user.referrer = self.creatorWallet3;
            self.users.set(newUser, user);
            return;
        }

        let referrerUser: User = referrerUserOpt!!;
        if (referrerUser.directReferrals < self.MAX_DIRECT_REFERRALS) {
            referrerUser.directReferrals += 1;
            referrerUser.totalReferrals += 1;
            referrerUser.downlines.set(referrerUser.directReferrals, newUser);
            self.users.set(referrer, referrerUser);

            let newUserStruct: User = self.users.get(newUser)!!;
            newUserStruct.referrer = referrer;
            self.users.set(newUser, newUserStruct);
        } else {
            self.findAndAssignSpillover(referrer, newUser);
        }
    }

    fun findAndAssignSpillover(originalReferrer: Address, newUser: Address) {
        let originalReferrerUser: User = self.users.get(originalReferrer)!!;
        let numDirectDownlines: Int = originalReferrerUser.directReferrals;

        if (numDirectDownlines > 0) {
            let i: Int = 0;
            while (i < numDirectDownlines) {
                let downlineNum: Int = (originalReferrerUser.spilloverIndex + i) % numDirectDownlines + 1;
                let downlineAddress: Address = originalReferrerUser.downlines.get(downlineNum)!!;
                let downlineUser: User = self.users.get(downlineAddress)!!;

                if (downlineUser.directReferrals < self.MAX_DIRECT_REFERRALS) {
                    downlineUser.directReferrals += 1;
                    downlineUser.totalReferrals += 1;
                    downlineUser.downlines.set(downlineUser.directReferrals, newUser);
                    self.users.set(downlineAddress, downlineUser);

                    let newUserStruct: User = self.users.get(newUser)!!;
                    newUserStruct.referrer = downlineAddress;
                    self.users.set(newUser, newUserStruct);

                    originalReferrerUser.otherReferrals += 1;
                    originalReferrerUser.totalReferrals += 1;
                    originalReferrerUser.spilloverIndex = downlineNum;
                    self.users.set(originalReferrer, originalReferrerUser);
                    return;
                }
                i += 1;
            }
        }

        let queue: map<Int, Address> = emptyMap();
        let visited: map<Address, Bool> = emptyMap();
        let queueHead: Int = 0;
        let queueTail: Int = 0;

        let k: Int = 1;
        while (k <= originalReferrerUser.directReferrals) {
            let addr: Address = originalReferrerUser.downlines.get(k)!!;
            queue.set(queueTail, addr);
            visited.set(addr, true);
            queueTail += 1;
            k += 1;
        }

        while (queueHead < queueTail) {
            let currentAddress: Address = queue.get(queueHead)!!;
            queueHead += 1;
            let currentUser: User = self.users.get(currentAddress)!!;

            if (currentUser.directReferrals < self.MAX_DIRECT_REFERRALS) {
                currentUser.directReferrals += 1;
                currentUser.totalReferrals += 1;
                currentUser.downlines.set(currentUser.directReferrals, newUser);
                self.users.set(currentAddress, currentUser);

                let newUserStruct: User = self.users.get(newUser)!!;
                newUserStruct.referrer = currentAddress;
                self.users.set(newUser, newUserStruct);

                originalReferrerUser.otherReferrals += 1;
                originalReferrerUser.totalReferrals += 1;
                self.users.set(originalReferrer, originalReferrerUser);
                return;
            }

            let j: Int = 1;
            while (j <= currentUser.directReferrals) {
                let nextAddr: Address = currentUser.downlines.get(j)!!;
                if (visited.get(nextAddr) == null) {
                    visited.set(nextAddr, true);
                    queue.set(queueTail, nextAddr);
                    queueTail += 1;
                }
                j += 1;
            }
        }

        let newUserStruct: User = self.users.get(newUser)!!;
        newUserStruct.referrer = self.creatorWallet3;
        self.users.set(newUser, newUserStruct);
    }

    fun distributeFunds(amount: Int, payer: Address, level: Int, originalReferrer: Address?, purchaseTime: Int) {
        let user: User = self.users.get(payer)!!;
        let actualReferrer: Address? = user.referrer;

        let creator1Share: Int = 0;
        let creator2Share: Int = 0;
        let creator3Share: Int = amount * 10 / 100;
        let spilloverShare: Int = amount * 20 / 100;
        let splitShare: Int = 0;

        if (level == 1) {
            creator1Share = amount * 10 / 100;
            creator2Share = amount * 10 / 100;
            splitShare = amount * 25 / 100;
        } else {
            creator1Share = amount * 20 / 100;
            creator2Share = amount * 20 / 100;
            splitShare = amount * 15 / 100;
        }

        let unallocatedFunds: Int = amount;

        send(SendParameters{ to: self.creatorWallet1, value: creator1Share, mode: SendPayGasSeparately, body: "Creator Share 1".asComment() });
        send(SendParameters{ to: self.creatorWallet2, value: creator2Share, mode: SendPayGasSeparately, body: "Creator Share 2".asComment() });
        send(SendParameters{ to: self.creatorWallet3, value: creator3Share, mode: SendPayGasSeparately, body: "Creator Share 3".asComment() });
        self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + creator1Share + creator2Share + creator3Share;
        unallocatedFunds = unallocatedFunds - creator1Share - creator2Share - creator3Share;

        if (originalReferrer != null && actualReferrer != null && (originalReferrer!! == actualReferrer!!)) {
            let totalCommission: Int = splitShare * 2;
            let origUser: User? = self.users.get(originalReferrer!!);

            if (origUser != null && origUser!!.level >= level) {
                send(SendParameters{
                    to: originalReferrer!!,
                    value: totalCommission,
                    mode: SendPayGasSeparately,
                    body: "Direct Referral Commission".asComment()
                });
                self.totalReferralRewardsPaid = self.totalReferralRewardsPaid + totalCommission;
                self.creditReferralEarning(originalReferrer!!, totalCommission, payer, level);
            } else {
                send(SendParameters{
                    to: self.creatorWallet3,
                    value: totalCommission,
                    mode: SendPayGasSeparately,
                    body: "Missed Direct Commission".asComment()
                });
                self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + totalCommission;
            }

            unallocatedFunds = unallocatedFunds - totalCommission;
        } else {
            if (originalReferrer != null) {
                let origUser: User? = self.users.get(originalReferrer!!);
                if (origUser != null && origUser!!.level >= level) {
                    send(SendParameters{
                        to: originalReferrer!!,
                        value: splitShare,
                        mode: SendPayGasSeparately,
                        body: "Link Referral Commission".asComment()
                    });
                    self.totalReferralRewardsPaid = self.totalReferralRewardsPaid + splitShare;
                    self.creditReferralEarning(originalReferrer!!, splitShare, payer, level);
                } else {
                    send(SendParameters{
                        to: self.creatorWallet3,
                        value: splitShare,
                        mode: SendPayGasSeparately,
                        body: "Missed Link Commission".asComment()
                    });
                    self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + splitShare;
                }
            } else {
                send(SendParameters{
                    to: self.creatorWallet3,
                    value: splitShare,
                    mode: SendPayGasSeparately,
                    body: "System Link Commission".asComment()
                });
                self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + splitShare;
            }

            if (actualReferrer != null) {
                let actUser: User? = self.users.get(actualReferrer!!);
                if (actUser != null && actUser!!.level >= level) {
                    send(SendParameters{
                        to: actualReferrer!!,
                        value: splitShare,
                        mode: SendPayGasSeparately,
                        body: "Slot Referral Commission".asComment()
                    });
                    self.totalReferralRewardsPaid = self.totalReferralRewardsPaid + splitShare;
                    self.creditReferralEarning(actualReferrer!!, splitShare, payer, level);
                } else {
                    send(SendParameters{
                        to: self.creatorWallet3,
                        value: splitShare,
                        mode: SendPayGasSeparately,
                        body: "Missed Slot Commission".asComment()
                    });
                    self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + splitShare;
                }
            } else {
                send(SendParameters{
                    to: self.creatorWallet3,
                    value: splitShare,
                    mode: SendPayGasSeparately,
                    body: "System Slot Commission".asComment()
                });
                self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + splitShare;
            }

            unallocatedFunds = unallocatedFunds - (splitShare * 2);
        }

        if (spilloverShare > 0) {
            self.distributeSpilloverReward(spilloverShare, level, payer, purchaseTime);
            unallocatedFunds = unallocatedFunds - spilloverShare;
        }

        if (unallocatedFunds > 0) {
            send(SendParameters{
                to: self.creatorWallet3,
                value: unallocatedFunds,
                mode: SendPayGasSeparately,
                body: "Unallocated Balance".asComment()
            });
            self.totalCreatorRewardsPaid = self.totalCreatorRewardsPaid + unallocatedFunds;
        }
    }

    fun processRewardPayout(userAddress: Address, stakeId: Int) {
        let user: User = self.requireUserExists(userAddress);
        let stake: StakeInfo? = user.stakes.get(stakeId);
        require(stake != null, "Stake not found");

        let currentStake: StakeInfo = stake!!;
        require(currentStake.isActive, "Stake inactive");

        let currentTime: Int = now();
        let total: Int = self.calculatePendingStakeReward(currentStake, currentTime);
        require(total > 0, "No rewards yet");

        if (currentStake.stakedAsset == self.ASSET_TON) {
            require(total > self.DISTRIBUTION_GAS_FEE, "Reward below distribution fee");
            let net: Int = total - self.DISTRIBUTION_GAS_FEE;
            require(myBalance() >= net + self.MIN_CONTRACT_RESERVE, "Insufficient contract balance");
            send(SendParameters{
                to: userAddress,
                value: net,
                mode: SendIgnoreErrors,
                body: "TON Staking Reward".asComment()
            });
            user.totalStakingClaimed = user.totalStakingClaimed + net;
            user.totalEarned = user.totalEarned + net;
        } else {
            send(SendParameters{
                to: self.usdtJettonWalletAddress,
                value: ton("0.1"),
                mode: SendIgnoreErrors,
                body: JettonTransfer{
                    queryId: 0,
                    amount: total,
                    destination: userAddress,
                    response_destination: userAddress,
                    custom_payload: null,
                    forward_ton_amount: ton("0.005"),
                    forward_payload: "USDT Staking Reward".asComment().asSlice()
                }.toCell()
            });
            user.totalStakingClaimed = user.totalStakingClaimed + total;
            user.totalEarned = user.totalEarned + total;
        }

        let rewardTxId: Int = user.transactionCounter;
        user.transactions.set(rewardTxId, UserTransaction{
            txId: rewardTxId,
            timestamp: currentTime,
            txType: self.TX_STAKING_REWARD_CLAIMED,
            amount: total,
            level: user.level,
            stakeId: stakeId,
            assetType: currentStake.stakedAsset,
            counterparty: null,
            description: "Staking Reward Claimed"
        });
        user.transactionCounter = user.transactionCounter + 1;

        if (currentTime >= currentStake.startTime + currentStake.duration) {
            if (currentStake.autoRestake) {
                currentStake.startTime = currentTime;
                currentStake.lastClaim = currentTime;
            } else {
                if (currentStake.stakedAsset == self.ASSET_TON) {
                    require(myBalance() >= currentStake.amount + self.MIN_CONTRACT_RESERVE, "Insufficient contract balance");
                    send(SendParameters{
                        to: userAddress,
                        value: currentStake.amount,
                        mode: SendIgnoreErrors,
                        body: "TON Stake Refund".asComment()
                    });
                    self.totalStakedTon -= currentStake.amount;
                } else {
                    send(SendParameters{
                        to: self.usdtJettonWalletAddress,
                        value: ton("0.1"),
                        mode: SendIgnoreErrors,
                        body: JettonTransfer{
                            queryId: 0,
                            amount: currentStake.amount,
                            destination: userAddress,
                            response_destination: userAddress,
                            custom_payload: null,
                            forward_ton_amount: ton("0.005"),
                            forward_payload: "USDT Stake Refund".asComment().asSlice()
                        }.toCell()
                    });
                    self.totalStakedUsdt -= currentStake.amount;
                }

                let refundTxId: Int = user.transactionCounter;
                user.transactions.set(refundTxId, UserTransaction{
                    txId: refundTxId,
                    timestamp: currentTime,
                    txType: self.TX_REFUND,
                    amount: currentStake.amount,
                    level: user.level,
                    stakeId: stakeId,
                    assetType: currentStake.stakedAsset,
                    counterparty: null,
                    description: "Stake Capital Refunded"
                });
                user.transactionCounter = user.transactionCounter + 1;

                currentStake.isActive = false;
                self.activeStakes -= 1;
            }
        } else {
            currentStake.lastClaim = currentTime;
        }

        currentStake.totalClaimed += total;
        user.stakes.set(stakeId, currentStake);
        self.users.set(userAddress, user);
        self.totalDistributed += total;
    }

    fun recordUserTransaction(
        userAddress: Address,
        txType: Int,
        amount: Int,
        level: Int,
        stakeId: Int,
        assetType: Int,
        counterparty: Address?,
        description: String
    ) {
        let userData: User? = self.users.get(userAddress);
        if (userData == null) { return; }
        let user: User = userData!!;
        let txId: Int = user.transactionCounter;
        user.transactions.set(txId, UserTransaction{
            txId: txId,
            timestamp: now(),
            txType: txType,
            amount: amount,
            level: level,
            stakeId: stakeId,
            assetType: assetType,
            counterparty: counterparty,
            description: description
        });
        user.transactionCounter = user.transactionCounter + 1;
        self.users.set(userAddress, user);
    }

    fun creditReferralEarning(recipient: Address, amount: Int, payer: Address, level: Int) {
        let userData: User? = self.users.get(recipient);
        if (userData == null) { return; }
        let user: User = userData!!;
        user.totalReferralEarned = user.totalReferralEarned + amount;
        user.totalEarned = user.totalEarned + amount;
        let txId: Int = user.transactionCounter;
        user.transactions.set(txId, UserTransaction{
            txId: txId,
            timestamp: now(),
            txType: self.TX_REFERRAL_COMMISSION,
            amount: amount,
            level: level,
            stakeId: 0,
            assetType: self.ASSET_TON,
            counterparty: payer,
            description: "Referral Commission"
        });
        user.transactionCounter = user.transactionCounter + 1;
        self.users.set(recipient, user);
    }

    fun creditSpilloverEarning(recipient: Address, amount: Int, payer: Address, level: Int) {
        let userData: User? = self.users.get(recipient);
        if (userData == null) { return; }
        let user: User = userData!!;
        user.totalSpilloverEarned = user.totalSpilloverEarned + amount;
        user.totalEarned = user.totalEarned + amount;
        let txId: Int = user.transactionCounter;
        user.transactions.set(txId, UserTransaction{
            txId: txId,
            timestamp: now(),
            txType: self.TX_SPILLOVER_REWARD,
            amount: amount,
            level: level,
            stakeId: 0,
            assetType: self.ASSET_TON,
            counterparty: payer,
            description: "Spillover Pool Reward"
        });
        user.transactionCounter = user.transactionCounter + 1;
        self.users.set(recipient, user);
    }

    //------------------------------------------------------------------
    // GETTER FUNCTIONS
    //------------------------------------------------------------------

    get fun getUserInfo(userAddress: Address): User? {
        return self.users.get(userAddress);
    }

    get fun getPlatformStats(): PlatformStats {
        return PlatformStats{
            totalUsers: self.totalUsers,
            totalStakedTon: self.totalStakedTon,
            totalStakedUsdt: self.totalStakedUsdt,
            totalDistributed: self.totalDistributed,
            activeStakes: self.activeStakes
        };
    }

    get fun getUserAddressByIndex(index: Int): Address? {
        return self.userList.get(index);
    }

    get fun getUserStakeIds(userAddress: Address): map<Int, Bool> {
        let user: User? = self.users.get(userAddress);
        if (user == null) {
            return emptyMap();
        }

        let stakeIds: map<Int, Bool> = emptyMap();
        let i: Int = 0;
        while (i < user!!.stakeCounter) {
            if (user!!.stakes.get(i) != null) {
                stakeIds.set(i, true);
            }
            i += 1;
        }

        return stakeIds;
    }

    get fun getStakeDetails(userAddress: Address, stakeId: Int): StakeDetails? {
        let user: User? = self.users.get(userAddress);
        if (user == null) {
            return null;
        }

        let stake: StakeInfo? = user!!.stakes.get(stakeId);
        if (stake == null) {
            return null;
        }

        let cs: StakeInfo = stake!!;
        let pending: Int = self.calculatePendingStakeReward(cs, now());

        return StakeDetails{
            stakeId: cs.stakeId,
            amount: cs.amount,
            startTime: cs.startTime,
            duration: cs.duration,
            vipClass: cs.vipClass,
            autoRestake: cs.autoRestake,
            lastClaim: cs.lastClaim,
            totalClaimed: cs.totalClaimed,
            isActive: cs.isActive,
            stakedAsset: cs.stakedAsset,
            pendingReward: pending
        };
    }

    get fun getUserReferralInfo(userAddress: Address): UserReferralInfo? {
        let user: User? = self.users.get(userAddress);
        if (user == null) {
            return null;
        }

        return UserReferralInfo{
            referrer: user!!.referrer,
            directReferrals: user!!.directReferrals,
            totalReferrals: user!!.totalReferrals,
            downlines: user!!.downlines
        };
    }

    get fun getUserEarningsInfo(userAddress: Address): UserEarningsInfo? {
        let user: User? = self.users.get(userAddress);
        if (user == null) {
            return null;
        }
        let u: User = user!!;

        let pendingStaking: Int = 0;
        let i: Int = 0;
        let currentTime: Int = now();
        while (i < u.stakeCounter) {
            let stakeOpt: StakeInfo? = u.stakes.get(i);
            if (stakeOpt != null) {
                pendingStaking = pendingStaking + self.calculatePendingStakeReward(stakeOpt!!, currentTime);
            }
            i = i + 1;
        }

        let totalClaimable: Int = u.pendingCheckInRewards + pendingStaking;

        return UserEarningsInfo{
            totalEarned: u.totalEarned,
            pendingCheckInRewards: u.pendingCheckInRewards,
            totalCheckInEarned: u.totalCheckInEarned,
            totalCheckInClaimed: u.totalCheckInClaimed,
            totalStakingClaimed: u.totalStakingClaimed,
            pendingStakingRewards: pendingStaking,
            totalReferralEarned: u.totalReferralEarned,
            totalSpilloverEarned: u.totalSpilloverEarned,
            totalClaimable: totalClaimable
        };
    }

    get fun getUserStakeSummary(userAddress: Address): UserStakeSummary {
        let userOpt: User? = self.users.get(userAddress);

        if (userOpt == null) {
            return UserStakeSummary{
                totalStakes: 0,
                activeStakes: 0,
                inactiveStakes: 0,
                pendingStakingRewards: 0
            };
        }

        let user: User = userOpt!!;
        let total: Int = user.stakeCounter;
        let active: Int = 0;
        let inactive: Int = 0;
        let pending: Int = 0;
        let i: Int = 0;
        let currentTime: Int = now();

        while (i < user.stakeCounter) {
            let stakeOpt: StakeInfo? = user.stakes.get(i);

            if (stakeOpt != null) {
                let stake: StakeInfo = stakeOpt!!;

                if (stake.isActive) {
                    active = active + 1;
                    pending = pending + self.calculatePendingStakeReward(stake, currentTime);
                } else {
                    inactive = inactive + 1;
                }
            }

            i = i + 1;
        }

        return UserStakeSummary{
            totalStakes: total,
            activeStakes: active,
            inactiveStakes: inactive,
            pendingStakingRewards: pending
        };
    }

    get fun getPlatformEarningsInfo(): PlatformEarningsInfo {
        let unclaimed: Int = self.totalCheckInRewardsAccrued - self.totalCheckInRewardsClaimed;
        return PlatformEarningsInfo{
            totalUsers: self.totalUsers,
            totalStakedTon: self.totalStakedTon,
            totalStakedUsdt: self.totalStakedUsdt,
            totalDistributed: self.totalDistributed,
            totalCheckInRewardsAccrued: self.totalCheckInRewardsAccrued,
            totalCheckInRewardsClaimed: self.totalCheckInRewardsClaimed,
            totalReferralRewardsPaid: self.totalReferralRewardsPaid,
            totalSpilloverRewardsPaid: self.totalSpilloverRewardsPaid,
            totalCreatorRewardsPaid: self.totalCreatorRewardsPaid,
            totalUnclaimedCheckInRewards: unclaimed,
            activeStakes: self.activeStakes,
            contractBalance: myBalance()
        };
    }

    get fun getUserTransaction(userAddress: Address, txId: Int): UserTransaction? {
        let user: User? = self.users.get(userAddress);
        if (user == null) { return null; }
        return user!!.transactions.get(txId);
    }

    get fun getUserTransactionCount(userAddress: Address): Int {
        let user: User? = self.users.get(userAddress);
        if (user == null) { return 0; }
        return user!!.transactionCounter;
    }

    get fun getUserTransactionsPaginated(userAddress: Address, start: Int, limit: Int): map<Int, UserTransaction> {
        let result: map<Int, UserTransaction> = emptyMap();
        let user: User? = self.users.get(userAddress);
        if (user == null) { return result; }
        let u: User = user!!;
        let end: Int = start + limit;
        if (end > u.transactionCounter) {
            end = u.transactionCounter;
        }
        let i: Int = start;
        while (i < end) {
            let tx: UserTransaction? = u.transactions.get(i);
            if (tx != null) {
                result.set(i, tx!!);
            }
            i = i + 1;
        }
        return result;
    }
}