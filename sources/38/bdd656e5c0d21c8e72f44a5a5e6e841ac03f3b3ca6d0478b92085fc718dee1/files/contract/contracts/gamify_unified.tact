import "@stdlib/deploy";
import "@stdlib/ownable";


const PRICE_PER_DAY: Int = ton("0.2"); // Full revenue per subscription day
const ONE_DAY: Int = 86400;
const NIGERIA_UTC_OFFSET: Int = 3600; // +1 hour in seconds (WAT - UTC+1)
const REWARD_PERCENTAGE: Int = 80; // Pool is 80% of revenue
const BACKEND_PERCENTAGE: Int = 20; // Backend is 20% of revenue
const MIN_GAS_RESERVE: Int = ton("0.05");
const GAS_PER_SEND: Int = ton("0.005");
const MAX_DISTRIBUTION_USERS: Int = 1000;
const MIN_REWARD_PER_USER: Int = ton("0.001");
const MAX_SUBSCRIPTION_DAYS: Int = 3650; // Maximum 10 years
const MAX_DISTRIBUTION_DAY_AGE: Int = 365; // Cannot distribute days older than 1 year

// =========================
// Admin & Backend Messages
// =========================

message AddAdmin {
    admin: Address;
}

message RemoveAdmin {
    admin: Address;
}

message AddBackendSigner {
    signer: Address;
}

message RemoveBackendSigner {
    signer: Address;
}

// =========================
// Distribution Messages - DAY-SPECIFIC with VALIDATION
// =========================

message DistributeLeaderboard {
    day: Int as uint64;
    recipients: map<Address, Int as coins>;
}


// =========================
// Subscription Messages
// =========================

message PurchaseSubscription {}

message GrantSubscription {
    user: Address;
    days: Int as uint32;
}

message RevokeSubscription {
    user: Address;
}

// =========================
// Management Messages
// =========================

message TransferOwnership {
    newOwner: Address;
}

message Withdraw {
    to: Address;
    amount: Int as coins;
}

message WithdrawAll {}

message WithdrawSafe {}

message WithdrawFromVault {
    amount: Int as coins;
    recipient: Address?;
}

message SetTreasuryWallet {
    treasury: Address;
}

message Pause {}

message Unpause {}

// =========================
// Event Messages
// =========================

message AdminAddedEvent {
    admin: Address;
}

message AdminRemovedEvent {
    admin: Address;
}

message BackendSignerAddedEvent {
    signer: Address;
}

message BackendSignerRemovedEvent {
    signer: Address;
}

message SubscriptionPurchasedEvent {
    user: Address;
    days: Int as uint32;
    amount: Int as coins;
    poolAllocated: Int as coins; // Pool amount (80% of revenue) allocated to daily pools
}

message SubscriptionGrantedEvent {
    user: Address;
    days: Int as uint32;
}

message SubscriptionRevokedEvent {
    user: Address;
    daysRevoked: Int as uint32;
    poolReclaimed: Int as coins; // Pool amount (80% of revenue) reclaimed from daily pools
}

message DistributionLeaderboardEvent {
    day: Int as uint64;
    recipientCount: Int as uint16;
    totalDistributed: Int as coins;
    backendFee: Int as coins;
    remainderToTreasury: Int as coins;
    poolBalance: Int as coins;
    balanceBefore: Int as coins;
    balanceAfter: Int as coins;
}


message WithdrawEvent {
    to: Address;
    amount: Int as coins;
    balanceBefore: Int as coins;
    balanceAfter: Int as coins;
}

message OwnershipTransferredEvent {
    oldOwner: Address;
    newOwner: Address;
}

message TreasuryWalletSetEvent {
    treasury: Address;
}

message PausedEvent {}
message UnpausedEvent {}

message DistributionErrorEvent {
    day: Int as uint64;
    error: String;
    reason: String;
    balanceBefore: Int as coins;
    requiredBalance: Int as coins;
    poolBalance: Int as coins;
    recipientCount: Int as uint16;
    totalAmount: Int as coins;
}

message ContractInitializedEvent {
    owner: Address;
    timestamp: Int as uint64;
}

// =========================
// Storage Structures
// =========================

struct SubscriptionData {
    startDay: Int as uint64;          // Day (Nigerian time) when subscription started - for pool allocation
    startTimestamp: Int as uint64;     // Exact timestamp when subscription started - for precise expiry
    totalDays: Int as uint32;
    remainingDays: Int as uint32;
}

struct DistributionInfo {
    totalPool: Int as coins;
    leaderboardPool: Int as coins;
    backendPool: Int as coins;
    userCount: Int as uint16;
    timestamp: Int as uint64;
}

struct SubscriptionSummary {
    active: Bool;
    startDay: Int as uint64;
    startTimestamp: Int as uint64;
    expiryTimestamp: Int as uint64;
    totalDays: Int as uint32;
    remainingDays: Int as uint32;
}

struct PricingInfo {
    pricePerDay: Int as coins;
}

struct DistributionInfoResult {
    totalPool: Int as coins;
    leaderboardPool: Int as coins;
    backendPool: Int as coins;
    userCount: Int as uint16;
    timestamp: Int as uint64;
}

struct RewardsInfo {
    totalRewardsDistributed: Int as coins;
    totalBackendFees: Int as coins;
}

struct Statistics {
    totalSubscriptionsGranted: Int as uint64;
    totalSubscriptionRevenue: Int as coins;
    totalRewardsDistributed: Int as coins;
    totalBackendFees: Int as coins;
    activeSubscriptionsCount: Int as uint32;
}

struct AvailablePool {
    availablePool: Int as coins;
    safeGasReserve: Int as coins;
    totalGasReserve: Int as coins;
}

struct DayInfo {
    day: Int as uint64;
    poolBalance: Int as coins;
    isDistributed: Bool;
    activeCount: Int as uint32;
    distributionInfo: DistributionInfoResult;
    treasuryAddress: Address?;
}

struct ActiveSubscribersListResult {
    totalCount: Int as uint32;
    addresses: map<Int as uint32, Address>;
}

contract GamifyUnified with Deployable, Ownable {
    owner: Address;
    isPaused: Bool;
    
    admins: map<Address, Bool>;
    backendSigners: map<Address, Bool>;
    
    subscriptions: map<Address, SubscriptionData>;
    activeSubscriptionsCount: Int as uint32;
    totalSubscriptionsGranted: Int as uint64;
    totalSubscriptionRevenue: Int as coins;
    
    activeSubscribersList: map<Int as uint32, Address>;
    activeSubscribersListLength: Int as uint32;
    activeSubscriberIndex: map<Address, Int as uint32>;
    
    distributedDays: map<Int as uint64, Bool>;
    dailyActiveCounts: map<Int as uint64, Int as uint32>;
    dailyPoolBalances: map<Int as uint64, Int as coins>;
    distributionInfo: map<Int as uint64, DistributionInfo>;
    
    totalRewardsDistributed: Int as coins;
    totalBackendFees: Int as coins;
    vaultBalance: Int as coins;
    treasuryWallet: Address?;

    init(timestamp: Int as uint64) {
        self.owner = sender();
        self.isPaused = false;
        
        self.admins.set(sender(), true);
        self.treasuryWallet = sender();
        
        self.activeSubscriptionsCount = 0;
        self.totalSubscriptionsGranted = 0;
        self.totalSubscriptionRevenue = 0;
        self.totalRewardsDistributed = 0;
        self.totalBackendFees = 0;
        self.vaultBalance = 0;
        self.activeSubscribersListLength = 0;
        
        emit(ContractInitializedEvent{
            owner: self.owner,
            timestamp: timestamp
        }.toCell());
    }

    // =========================
    // Authorization Helpers
    // =========================

    inline fun requireAdmin() {
        let isOwner = sender() == self.owner;
        let isAdmin = self.admins.exists(sender()) && self.admins.get(sender())!!;
        require(isOwner || isAdmin, "Unauthorized: admin required");
    }

    inline fun requireBackendSigner() {
        let isSigner = self.backendSigners.exists(sender()) && self.backendSigners.get(sender())!!;
        require(isSigner, "Unauthorized: backend signer required");
    }

    inline fun requireAdminOrBackend() {
        let isOwner = sender() == self.owner;
        let isAdmin = self.admins.exists(sender()) && self.admins.get(sender())!!;
        let isBackend = self.backendSigners.exists(sender()) && self.backendSigners.get(sender())!!;
        require(isOwner || isAdmin || isBackend, "Unauthorized: admin or backend required");
    }

    // =========================
    // Validation Helpers
    // =========================

    inline fun requireValidAddress(addr: Address) {
    }

    inline fun requireValidDay(day: Int) {
        // Validates day for distribution
        // - Cannot distribute future days
        // - Cannot distribute days older than MAX_DISTRIBUTION_DAY_AGE (1 year)
        // 
        // EDGE CASE HANDLING:
        // - Day rollover at midnight Nigerian time is handled correctly
        // - Distribution window is limited to prevent stale data distribution
        let currentDay = self.getCurrentDay();
        require(day <= currentDay, "Cannot distribute future days");
        require(day > currentDay - MAX_DISTRIBUTION_DAY_AGE, "Day too old - cannot distribute days older than 1 year");
    }

    // =========================
    // Helper Functions
    // =========================

    // =========================
    // Time Helper Functions
    // =========================
    // 
    // TIME HANDLING NOTES:
    // - Tact now() returns UTC timestamp in seconds (no milliseconds)
    // - Day calculation uses Nigerian timezone offset (UTC+1)
    // - Day rollover happens at midnight Nigerian time
    // - Edge case: Subscriptions near midnight may have fractional day appearance
    // - Precision: Second-level only (no sub-second accuracy)
    // 
    // TIMEZONE WARNING:
    // - All timestamps are stored as UTC seconds
    // - Frontend must convert to user's local timezone for display
    // - Day-based logic uses Nigerian timezone for consistency
    // =========================

    get fun getCurrentDay(): Int {
        // Returns current day number based on Nigerian timezone (UTC+1)
        // Day changes at midnight Nigerian time
        // Edge case: Transactions at 23:59:59 UTC (00:59:59 Nigerian) may appear
        // to have a "short" day, but this is expected behavior
        return (now() + NIGERIA_UTC_OFFSET) / ONE_DAY;
    }

    get fun getCurrentTimestamp(): Int {
        // Returns current UTC timestamp in seconds
        // Use this for precise time calculations
        // Note: No millisecond precision available
        return now();
    }

    inline fun calculateDailyRevenue(): Int {
        return PRICE_PER_DAY;
    }

    inline fun calculateDailyPool(): Int {
        return (self.calculateDailyRevenue() * REWARD_PERCENTAGE) / 100;
    }

    inline fun calculateDailyBackendFee(): Int {
        return (self.calculateDailyRevenue() * BACKEND_PERCENTAGE) / 100;
    }

    inline fun getRecipient(msgRecipient: Address?): Address {
        if (msgRecipient != null) {
            return msgRecipient!!;
        } else if (self.treasuryWallet != null) {
            return self.treasuryWallet!!;
        }
        return self.owner;
    }

    inline fun calculateExpiryDay(sub: SubscriptionData): Int {
        return sub.startDay + sub.remainingDays - 1;
    }

    inline fun calculateExpiryTimestamp(sub: SubscriptionData): Int {
        return sub.startTimestamp + (sub.remainingDays * ONE_DAY);
    }

    inline fun isSubscriptionActive(sub: SubscriptionData, currentDay: Int): Bool {
        // Checks if subscription is currently active
        // Uses both day-based and timestamp-based checks for accuracy
        // 
        // LOGIC:
        // - Must not have expired by day (for pool allocation purposes)
        // - Must not have expired by timestamp (for precise expiry)
        // - Both conditions must be true for subscription to be active
        // 
        // EDGE CASE: Subscriptions expiring at midnight are handled correctly
        // by checking both day and timestamp boundaries
        let expiryDay = self.calculateExpiryDay(sub);
        let expiryTimestamp = self.calculateExpiryTimestamp(sub);
        let currentTimestamp = now();
        return expiryDay >= currentDay && expiryTimestamp > currentTimestamp;
    }

    inline fun allocatePoolToDays(startDay: Int, endDay: Int) {
        let poolPerDay = self.calculateDailyPool();
        let day = startDay;
        
        while (day <= endDay) {
            let current = 0;
            if (self.dailyPoolBalances.exists(day)) {
                current = self.dailyPoolBalances.get(day)!!;
            }
            self.dailyPoolBalances.set(day, current + poolPerDay);
            day += 1;
        }
    }

    inline fun deallocatePoolFromDays(startDay: Int, endDay: Int) {
        let poolPerDay = self.calculateDailyPool();
        let day = startDay;
        
        while (day <= endDay) {
            if (self.dailyPoolBalances.exists(day)) {
                let current = self.dailyPoolBalances.get(day)!!;
                let newBalance = current - poolPerDay;
                require(newBalance >= 0, "Cannot deallocate more pool than allocated");
                self.dailyPoolBalances.set(day, newBalance);
            }
            day += 1;
        }
    }

    inline fun updateDailyCounts(startDay: Int, endDay: Int, delta: Int) {
        let day = startDay;
        while (day <= endDay) {
            let current = 0;
            if (self.dailyActiveCounts.exists(day)) {
                current = self.dailyActiveCounts.get(day)!!;
            }
            let newCount = current + delta;
            if (newCount < 0) {
                newCount = 0;
            }
            self.dailyActiveCounts.set(day, newCount);
            day += 1;
        }
    }

    inline fun addToActiveSubscribersList(user: Address) {
        if (!self.activeSubscriberIndex.exists(user)) {
            let index = self.activeSubscribersListLength;
            self.activeSubscribersList.set(index, user);
            self.activeSubscriberIndex.set(user, index);
            self.activeSubscribersListLength += 1;
        }
    }

    inline fun removeFromActiveSubscribersList(user: Address) {
        if (self.activeSubscriberIndex.exists(user)) {
            let indexToRemove = self.activeSubscriberIndex.get(user)!!;
            let lastIndex = self.activeSubscribersListLength - 1;
            
            if (lastIndex >= 0) {
                if (self.activeSubscribersList.exists(lastIndex)) {
                    let lastAddress = self.activeSubscribersList.get(lastIndex)!!;
                    
                    if (indexToRemove != lastIndex) {
                        self.activeSubscribersList.set(indexToRemove, lastAddress);
                        self.activeSubscriberIndex.set(lastAddress, indexToRemove);
                    }
                    
                    self.activeSubscribersList.set(lastIndex, null);
                }
                
                self.activeSubscriberIndex.set(user, null);
                self.activeSubscribersListLength -= 1;
            }
        }
    }

    // =========================
    // Subscription Logic
    // =========================

    receive() {
    }

    receive(msg: String) {
    }

    receive(msg: PurchaseSubscription) {
        require(!self.isPaused, "Contract is paused");
        
        let msgValue = context().value;
        require(msgValue >= PRICE_PER_DAY, "Insufficient payment - minimum is 0.2 TON per day");
        
        let daysGranted = msgValue / PRICE_PER_DAY;
        require(daysGranted >= 1, "Insufficient payment for at least 1 day");
        
        let actualPayment = daysGranted * PRICE_PER_DAY;
        self.totalSubscriptionRevenue += actualPayment;
        
        let poolAllocated = daysGranted * self.calculateDailyPool();
        
        self.applySubscription(context().sender, daysGranted, true);
        
        emit(SubscriptionPurchasedEvent{
            user: context().sender,
            days: daysGranted,
            amount: actualPayment,
            poolAllocated: poolAllocated
        }.toCell());
        
        let excess = msgValue - actualPayment;
        // Only refund if excess is significant enough to cover gas
        // User pays gas for refund (not SendPayGasSeparately) so contract keeps full payment
        if (excess > GAS_PER_SEND * 2) {
            send(SendParameters{
                to: context().sender,
                value: excess,
                bounce: false
            });
        }
    }

    receive(msg: GrantSubscription) {
        self.requireAdmin();
        require(!self.isPaused, "Contract is paused");
        require(msg.days > 0, "Days must be greater than zero");
        require(msg.days <= MAX_SUBSCRIPTION_DAYS, "Days cannot exceed maximum (3650 days)");
        self.requireValidAddress(msg.user);
        
        self.applySubscription(msg.user, msg.days, false);
        
        emit(SubscriptionGrantedEvent{
            user: msg.user,
            days: msg.days
        }.toCell());
    }

    receive(msg: RevokeSubscription) {
        self.requireAdmin();
        self.requireValidAddress(msg.user);
        
        if (self.subscriptions.exists(msg.user)) {
            let sub = self.subscriptions.get(msg.user)!!;
            let currentDay = self.getCurrentDay();
            let endDay = self.calculateExpiryDay(sub);
            
            let daysRevoked = 0;
            let poolReclaimed = 0;
            
            if (sub.remainingDays > 0 && self.isSubscriptionActive(sub, currentDay)) {
                if (self.activeSubscriptionsCount > 0) {
                self.activeSubscriptionsCount = self.activeSubscriptionsCount - 1;
                }
                self.removeFromActiveSubscribersList(msg.user);
                self.updateDailyCounts(currentDay, endDay, -1);
                
                if (endDay >= currentDay) {
                daysRevoked = endDay - currentDay + 1;
                poolReclaimed = daysRevoked * self.calculateDailyPool();
                self.deallocatePoolFromDays(currentDay, endDay);
                } else {
                    daysRevoked = 0;
                    poolReclaimed = 0;
                }
            }
            
            self.subscriptions.set(msg.user, null);
            
            emit(SubscriptionRevokedEvent{
                user: msg.user,
                daysRevoked: daysRevoked,
                poolReclaimed: poolReclaimed
            }.toCell());
        }
    }

    fun applySubscription(user: Address, daysGranted: Int, isPaid: Bool) {
        require(daysGranted > 0, "Invalid days");
        require(daysGranted <= MAX_SUBSCRIPTION_DAYS, "Days cannot exceed maximum (3650 days)");
        
        let currentDay = self.getCurrentDay();
        let currentTimestamp = now();
        let wasActive = false;
        let startDay = currentDay;
        let startTimestamp = currentTimestamp;
        let totalDays = daysGranted;
        let remainingDays = daysGranted;
        let oldEndDay = 0;
        
        if (self.subscriptions.exists(user)) {
            let oldSub = self.subscriptions.get(user)!!;
            oldEndDay = self.calculateExpiryDay(oldSub);
            
            if (oldSub.remainingDays > 0 && self.isSubscriptionActive(oldSub, currentDay)) {
                wasActive = true;
                startDay = oldSub.startDay;
                startTimestamp = oldSub.startTimestamp;
                totalDays = oldSub.totalDays + daysGranted;
                remainingDays = oldSub.remainingDays + daysGranted;
            } else {
                self.totalSubscriptionsGranted += 1;
            }
        } else {
            self.totalSubscriptionsGranted += 1;
        }
        
        let newEndDay = startDay + remainingDays - 1;
        
        self.subscriptions.set(user, SubscriptionData{
            startDay: startDay,
            startTimestamp: startTimestamp,
            totalDays: totalDays,
            remainingDays: remainingDays
        });
        
        if (!wasActive) {
            self.activeSubscriptionsCount += 1;
            self.addToActiveSubscribersList(user);
            self.updateDailyCounts(startDay, newEndDay, 1);
            
            if (isPaid) {
                self.allocatePoolToDays(startDay, newEndDay);
            }
        } else {
            if (newEndDay > oldEndDay) {
                self.updateDailyCounts(oldEndDay + 1, newEndDay, 1);
                
                if (isPaid) {
                    self.allocatePoolToDays(oldEndDay + 1, newEndDay);
                }
            }
        }
    }

    receive(msg: DistributeLeaderboard) {
        let balanceBefore = myBalance();
        let day = msg.day;
        
        // Authorization check with error event
        let isOwner = sender() == self.owner;
        let isAdmin = self.admins.exists(sender()) && self.admins.get(sender())!!;
        let isBackend = self.backendSigners.exists(sender()) && self.backendSigners.get(sender())!!;
        if (!(isOwner || isAdmin || isBackend)) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Authorization failed",
                reason: "Unauthorized: admin or backend required",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: 0,
                recipientCount: 0,
                totalAmount: 0
            }.toCell());
            require(false, "Unauthorized: admin or backend required");
        }
        
        // Paused check with error event
        if (self.isPaused) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Contract paused",
                reason: "Contract is paused",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: 0,
                recipientCount: 0,
                totalAmount: 0
            }.toCell());
            require(false, "Contract is paused");
        }
        
        // Day validation with error event
        let currentDay = self.getCurrentDay();
        if (day > currentDay) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Invalid day",
                reason: "Cannot distribute future days",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: 0,
                recipientCount: 0,
                totalAmount: 0
            }.toCell());
            require(false, "Cannot distribute future days");
        }
        if (day <= currentDay - MAX_DISTRIBUTION_DAY_AGE) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Invalid day",
                reason: "Day too old - cannot distribute days older than 1 year",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: 0,
                recipientCount: 0,
                totalAmount: 0
            }.toCell());
            require(false, "Day too old - cannot distribute days older than 1 year");
        }
        
        // Already distributed check with error event
        if (self.distributedDays.exists(day)) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Already distributed",
                reason: "Day already distributed",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: 0,
                recipientCount: 0,
                totalAmount: 0
            }.toCell());
            require(false, "Day already distributed");
        }
        
        let dailyPoolBalance = self.getDailyPoolBalanceForDay(day);
        if (dailyPoolBalance <= 0) {
            emit(DistributionErrorEvent{
                day: day,
                error: "No pool balance",
                reason: "No pool balance for this day",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: dailyPoolBalance,
                recipientCount: 0,
                totalAmount: 0
            }.toCell());
            require(false, "No pool balance for this day");
        }
        
        // Count recipients and calculate total
        let count: Int = 0;
        let totalAmount: Int = 0;
        foreach (addr, amount in msg.recipients) {
            if (amount <= 0) {
                emit(DistributionErrorEvent{
                    day: day,
                    error: "Invalid amount",
                    reason: "Distribution amount must be greater than zero",
                    balanceBefore: balanceBefore,
                    requiredBalance: 0,
                    poolBalance: dailyPoolBalance,
                    recipientCount: count,
                    totalAmount: totalAmount
                }.toCell());
                require(false, "Distribution amount must be greater than zero");
            }
            if (amount >= MIN_REWARD_PER_USER) {
                count += 1;
                totalAmount += amount;
            }
        }
        
        if (count == 0) {
            emit(DistributionErrorEvent{
                day: day,
                error: "No recipients",
                reason: "No recipients",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: dailyPoolBalance,
                recipientCount: 0,
                totalAmount: totalAmount
            }.toCell());
            require(false, "No recipients");
        }
        
        if (count > MAX_DISTRIBUTION_USERS) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Too many recipients",
                reason: "Too many recipients",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: dailyPoolBalance,
                recipientCount: count,
                totalAmount: totalAmount
            }.toCell());
            require(false, "Too many recipients");
        }
        
        if (totalAmount <= 0) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Invalid total amount",
                reason: "Total amount must be positive",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: dailyPoolBalance,
                recipientCount: count,
                totalAmount: totalAmount
            }.toCell());
            require(false, "Total amount must be positive");
        }
        
        // CRITICAL: Check total amount BEFORE any calculations or sends
        // This must happen immediately to prevent any state changes
        if (totalAmount > dailyPoolBalance) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Amount exceeds pool",
                reason: "Total distribution cannot exceed pool balance",
                balanceBefore: balanceBefore,
                requiredBalance: 0,
                poolBalance: dailyPoolBalance,
                recipientCount: count,
                totalAmount: totalAmount
            }.toCell());
            require(false, "Total distribution cannot exceed pool balance");
        }
        
        let dailyRevenue = (dailyPoolBalance * 100) / REWARD_PERCENTAGE;
        let backendFee = (dailyRevenue * BACKEND_PERCENTAGE) / 100;
        let remainder = dailyPoolBalance - totalAmount;
        
        // Add remainder to backend fee (backend recipient is treasury if set, or deployer)
        // This ensures remainder goes to backend and we only need one call
        let totalBackendFee = backendFee + remainder;
        
        // Gas calculation with refund mechanism
        // Recipients and backend use SendPayGasSeparately (they pay their own gas)
        // Contract needs gas reserve for internal operations (computation, storage updates)
        // Larger distributions (more recipients, larger amounts) need more gas
        
        // Calculate dynamic gas reserve based on distribution size
        // Base gas for contract execution: 0.015 TON
        // Per recipient processing: 0.001 TON
        // Safety buffer: 0.015 TON
        let baseGas = ton("0.015");
        let perRecipientGas = ton("0.001");
        let safetyBuffer = ton("0.015");
        let dynamicGasReserve = baseGas + (perRecipientGas * count) + safetyBuffer;
        
        // Minimum gas reserve
        let minGasBuffer = ton("0.005");
        let gasReserve = dynamicGasReserve > minGasBuffer ? dynamicGasReserve : minGasBuffer;
        
        // If balance is very low, use higher reserve
        if (balanceBefore < ton("0.1")) {
            gasReserve = MIN_GAS_RESERVE;
        }
        
        // Contract needs: totalAmount + totalBackendFee + gas reserve for execution
        // Recipients and backend pay their own gas via SendPayGasSeparately
        let minRequired = totalAmount + totalBackendFee + gasReserve;
        
        if (balanceBefore < minRequired) {
            emit(DistributionErrorEvent{
                day: day,
                error: "Insufficient balance",
                reason: "Insufficient contract balance for distribution (including gas)",
                balanceBefore: balanceBefore,
                requiredBalance: minRequired,
                poolBalance: dailyPoolBalance,
                recipientCount: count,
                totalAmount: totalAmount
            }.toCell());
            require(false, "Insufficient contract balance for distribution (including gas)");
        }
        
        // Get message value for gas refund calculation
        let messageValue = context().value;
        let estimatedGasUsed = ton("0.01") + (perRecipientGas * count); // Actual gas used is less than reserve
        let gasRefund = 0;
        
        // Calculate refund: if message value > estimated gas used, refund the excess
        if (messageValue > estimatedGasUsed) {
            gasRefund = messageValue - estimatedGasUsed;
            // Only refund if significant (more than 0.001 TON to cover refund gas)
            if (gasRefund > ton("0.001")) {
                send(SendParameters{
                    to: sender(),
                    value: gasRefund,
                    mode: SendPayGasSeparately,
                    bounce: false
                });
            } else {
                gasRefund = 0;
            }
        }
        
        // Update statistics
        self.totalRewardsDistributed += totalAmount;
        self.totalBackendFees += backendFee; // Track base backend fee (20% of revenue)
        
        // Distribute to recipients
        foreach (addr, amount in msg.recipients) {
            if (amount >= MIN_REWARD_PER_USER) {
                send(SendParameters{
                    to: addr,
                    value: amount,
                    mode: SendPayGasSeparately,
                    bounce: false
                });
            }
        }
        
        // Send backend fee + remainder (one call to backend recipient)
        // Backend recipient is treasury if set, or deployer
        // Backend pays their own gas (SendPayGasSeparately) so they receive full amount
        if (totalBackendFee > 0) {
            let backendRecipient = self.getRecipient(null);
            send(SendParameters{
                to: backendRecipient,
                value: totalBackendFee,
                mode: SendPayGasSeparately,
                bounce: false
            });
        }
        
        let balanceAfter = myBalance();
        
        // Mark day as distributed
        self.distributedDays.set(day, true);
        self.distributionInfo.set(day, DistributionInfo{
            totalPool: dailyPoolBalance,
            leaderboardPool: totalAmount,
            backendPool: totalBackendFee, // Includes remainder
            userCount: count,
            timestamp: now()
        });
        
        emit(DistributionLeaderboardEvent{
            day: day,
            recipientCount: count,
            totalDistributed: totalAmount,
            backendFee: totalBackendFee, // Includes remainder
            remainderToTreasury: remainder,
            poolBalance: dailyPoolBalance,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter
        }.toCell());
    }


    // =========================
    // Admin Management
    // =========================

    receive(msg: AddAdmin) {
        self.requireOwner();
        self.requireValidAddress(msg.admin);
        self.admins.set(msg.admin, true);
        
        emit(AdminAddedEvent{
            admin: msg.admin
        }.toCell());
    }

    receive(msg: RemoveAdmin) {
        self.requireOwner();
        self.requireValidAddress(msg.admin);
        self.admins.set(msg.admin, null);
        
        emit(AdminRemovedEvent{
            admin: msg.admin
        }.toCell());
    }

    receive(msg: AddBackendSigner) {
        self.requireAdmin();
        self.requireValidAddress(msg.signer);
        self.backendSigners.set(msg.signer, true);
        
        emit(BackendSignerAddedEvent{
            signer: msg.signer
        }.toCell());
    }

    receive(msg: RemoveBackendSigner) {
        self.requireAdmin();
        self.requireValidAddress(msg.signer);
        self.backendSigners.set(msg.signer, null);
        
        emit(BackendSignerRemovedEvent{
            signer: msg.signer
        }.toCell());
    }

    // =========================
    // Owner Functions
    // =========================

    receive(msg: TransferOwnership) {
        self.requireOwner();
        self.requireValidAddress(msg.newOwner);
        require(msg.newOwner != self.owner, "New owner must be different from current owner");
        let oldOwner = self.owner;
        self.owner = msg.newOwner;
        
        emit(OwnershipTransferredEvent{
            oldOwner: oldOwner,
            newOwner: msg.newOwner
        }.toCell());
    }

    receive(msg: Withdraw) {
        self.requireOwner();
        self.requireValidAddress(msg.to);
        
        let amount = msg.amount;
        require(amount > 0, "Invalid amount");
        
        let availableBalance = myBalance() - context().value;
        let maxWithdrawable = availableBalance - MIN_GAS_RESERVE;
        let actualAmount = min(amount, maxWithdrawable);
        require(actualAmount > 0, "Insufficient balance");
        
        let balanceBefore = myBalance();
        
        send(SendParameters{
            to: msg.to,
            value: actualAmount,
            mode: SendPayGasSeparately,
            bounce: false
        });
        
        let balanceAfter = myBalance();
        emit(WithdrawEvent{
            to: msg.to,
            amount: actualAmount,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter
        }.toCell());
    }

    receive(msg: WithdrawAll) {
        self.requireOwner();
        
        let balanceBefore = myBalance();
        let availableBalance = balanceBefore - context().value;
        require(availableBalance > MIN_GAS_RESERVE, "Insufficient balance");
        
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    receive(msg: WithdrawSafe) {
        self.requireOwner();
        
        let balanceBefore = myBalance();
        let availableBalance = balanceBefore - context().value;
        let withdrawable = availableBalance - MIN_GAS_RESERVE;
        require(withdrawable > 0, "Insufficient balance");
        
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: withdrawable,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }

    receive(msg: WithdrawFromVault) {
        self.requireOwner();
        require(!self.isPaused, "Contract is paused");
        
        let amount = msg.amount;
        require(amount > 0, "Invalid amount");
        require(self.vaultBalance >= amount, "Insufficient vault balance");
        
        let recipient = self.getRecipient(msg.recipient);
        self.requireValidAddress(recipient);
        
        let availableBalance = myBalance() - context().value;
        let maxWithdrawable = availableBalance - MIN_GAS_RESERVE;
        let actualAmount = min(amount, maxWithdrawable);
        require(actualAmount > 0, "Insufficient balance");
        
        self.vaultBalance = self.vaultBalance - actualAmount;
        
        send(SendParameters{
            to: recipient,
            value: actualAmount,
            mode: SendPayGasSeparately,
            bounce: false
        });
    }

    receive(msg: SetTreasuryWallet) {
        self.requireOwner();
        self.requireValidAddress(msg.treasury);
        self.treasuryWallet = msg.treasury;
        
        emit(TreasuryWalletSetEvent{
            treasury: msg.treasury
        }.toCell());
    }

    receive(msg: Pause) {
        self.requireOwner();
        self.isPaused = true;
        emit(PausedEvent{}.toCell());
    }

    receive(msg: Unpause) {
        self.requireOwner();
        self.isPaused = false;
        emit(UnpausedEvent{}.toCell());
    }

    // =========================
    // Getters
    // =========================

    // =========================
    // WARNING: This getter may return corrupted uint64 values due to Tact ABI bug
    // 
    // RECOMMENDED: Use individual getters instead:
    // - getStartDay(user) for startDay
    // - getStartTimestamp(user) for startTimestamp  
    // - getExpiryTimestamp(user) for expiryTimestamp
    // - getTotalDays(user) for totalDays
    // - getRemainingDays(user) for remainingDays
    // - isSubscribed(user) for active status
    // 
    // The uint64 fields (startDay, startTimestamp, expiryTimestamp) in this struct
    // may be corrupted during ABI serialization. Use individual getters for reliability.
    // =========================
    get fun getSubscriptionSummary(user: Address): SubscriptionSummary {
        if (!self.subscriptions.exists(user)) {
            return SubscriptionSummary{
                active: false,
                startDay: 0,
                startTimestamp: 0,
                expiryTimestamp: 0,
                totalDays: 0,
                remainingDays: 0
            };
        }
        
        let sub = self.subscriptions.get(user)!!;
        let currentDay = self.getCurrentDay();
        let expiryDay = self.calculateExpiryDay(sub);
        let active = self.isSubscriptionActive(sub, currentDay);
        let expiryTimestamp = self.calculateExpiryTimestamp(sub);
        
        let actualRemaining = 0;
        if (active) {
            let currentTimestamp = now();
            let secondsRemaining = expiryTimestamp - currentTimestamp;
            actualRemaining = (secondsRemaining + ONE_DAY - 1) / ONE_DAY;
            if (actualRemaining > sub.remainingDays) {
                actualRemaining = sub.remainingDays;
            }
        }
        
        return SubscriptionSummary{
            active: active,
            startDay: sub.startDay,
            startTimestamp: sub.startTimestamp,
            expiryTimestamp: expiryTimestamp,
            totalDays: sub.totalDays,
            remainingDays: actualRemaining
        };
    }

    get fun isSubscribed(user: Address): Bool {
        if (!self.subscriptions.exists(user)) {
            return false;
        }
        
        let sub = self.subscriptions.get(user)!!;
        let currentDay = self.getCurrentDay();
        return self.isSubscriptionActive(sub, currentDay);
    }

    // =========================
    // Separate getters to work around Tact uint64 struct serialization bug
    // These return values individually (not in structs) to avoid ABI issues
    // 
    // KNOWN ISSUE: Tact compiler has a bug where uint64 fields in structs
    // returned from get methods can be corrupted during ABI serialization.
    // 
    // WORKAROUND: Use these individual getters instead of getSubscriptionSummary()
    // for reliable uint64 values. The struct getter may return corrupted timestamps.
    // 
    // AFFECTED FIELDS:
    // - startTimestamp (uint64) - use getStartTimestamp() instead
    // - expiryTimestamp (uint64) - use getExpiryTimestamp() instead
    // - startDay (uint64) - use getStartDay() instead
    // 
    // SAFE FIELDS (can use struct):
    // - totalDays (uint32) - safe
    // - remainingDays (uint32) - safe
    // - active (bool) - safe
    // =========================

    get fun getStartDay(user: Address): Int {
        if (!self.subscriptions.exists(user)) {
            return 0;
        }
        let sub = self.subscriptions.get(user)!!;
        return sub.startDay;
    }

    get fun getStartTimestamp(user: Address): Int {
        if (!self.subscriptions.exists(user)) {
            return 0;
        }
        let sub = self.subscriptions.get(user)!!;
        return sub.startTimestamp;
    }

    get fun getExpiryTimestamp(user: Address): Int {
        if (!self.subscriptions.exists(user)) {
            return 0;
        }
        let sub = self.subscriptions.get(user)!!;
        return self.calculateExpiryTimestamp(sub);
    }

    get fun getTotalDays(user: Address): Int {
        if (!self.subscriptions.exists(user)) {
            return 0;
        }
        let sub = self.subscriptions.get(user)!!;
        return sub.totalDays;
    }

    get fun getRemainingDays(user: Address): Int {
        if (!self.subscriptions.exists(user)) {
            return 0;
        }
        let sub = self.subscriptions.get(user)!!;
        let currentDay = self.getCurrentDay();
        let active = self.isSubscriptionActive(sub, currentDay);
        
        if (!active) {
            return 0;
        }
        
        let expiryTimestamp = self.calculateExpiryTimestamp(sub);
        let currentTimestamp = now();
        let secondsRemaining = expiryTimestamp - currentTimestamp;
        let actualRemaining = (secondsRemaining + ONE_DAY - 1) / ONE_DAY;
        if (actualRemaining > sub.remainingDays) {
            actualRemaining = sub.remainingDays;
        }
        return actualRemaining;
    }

    // =========================
    // Additional getters for problematic struct fields
    // Use these instead of struct getters for uint64 fields
    // =========================

    get fun getTotalSubscriptionsGrantedRaw(): Int {
        return self.totalSubscriptionsGranted;
    }

    get fun getDistributionTimestamp(day: Int): Int {
        if (!self.distributionInfo.exists(day)) {
            return 0;
        }
        let info = self.distributionInfo.get(day)!!;
        return info.timestamp;
    }

    get fun isAdmin(address: Address): Bool {
        return self.admins.exists(address) && self.admins.get(address)!!;
    }

    get fun isBackendSigner(address: Address): Bool {
        return self.backendSigners.exists(address) && self.backendSigners.get(address)!!;
    }

    get fun getPricingInfo(): PricingInfo {
        return PricingInfo{
            pricePerDay: PRICE_PER_DAY
        };
    }

    get fun getTotalRevenue(): Int {
        return self.totalSubscriptionRevenue;
    }

    get fun getTotalSubscriptionsGranted(): Int {
        return self.totalSubscriptionsGranted;
    }

    get fun getIsPaused(): Bool {
        return self.isPaused;
    }

    get fun getActiveSubscriptionsCount(): Int {
        return self.activeSubscriptionsCount;
    }

    get fun getActiveSubscribersList(offset: Int, limit: Int): ActiveSubscribersListResult {
        let totalCount = self.activeSubscribersListLength;
        let resultIndex = 0;
        let currentIndex = offset;
        let maxIndex = min(offset + limit, totalCount);
        
        let result: map<Int as uint32, Address> = self.activeSubscribersList;
        
        let clearIndex = 0;
        while (clearIndex < self.activeSubscribersListLength) {
            if (result.exists(clearIndex)) {
                result.set(clearIndex, null);
            }
            clearIndex += 1;
        }
        while (currentIndex < maxIndex) {
            if (self.activeSubscribersList.exists(currentIndex)) {
                let address = self.activeSubscribersList.get(currentIndex)!!;
                result.set(resultIndex, address);
                resultIndex += 1;
            }
            currentIndex += 1;
        }
        
        return ActiveSubscribersListResult{
            totalCount: totalCount,
            addresses: result
        };
    }

    get fun getActiveCountForDay(day: Int): Int {
        if (self.dailyActiveCounts.exists(day)) {
            return self.dailyActiveCounts.get(day)!!;
        }
        return 0;
    }

    get fun getDailyPoolBalanceForDay(day: Int): Int {
        if (self.dailyPoolBalances.exists(day)) {
            return self.dailyPoolBalances.get(day)!!;
        }
        return 0;
    }

    get fun isDayDistributed(day: Int): Bool {
        return self.distributedDays.exists(day);
    }

    // =========================
    // WARNING: This struct contains uint64 field (timestamp)
    // which may be corrupted due to Tact ABI bug.
    // 
    // RECOMMENDED: Use getDistributionTimestamp(day) for reliable uint64 timestamp value
    // Other fields (coins, uint16) are safe to use from struct
    // =========================
    get fun getDistributionInfo(day: Int): DistributionInfoResult {
        if (!self.distributionInfo.exists(day)) {
            return DistributionInfoResult{
                totalPool: 0,
                leaderboardPool: 0,
                backendPool: 0,
                userCount: 0,
                timestamp: 0
            };
        }
        
        let info = self.distributionInfo.get(day)!!;
        return DistributionInfoResult{
            totalPool: info.totalPool,
            leaderboardPool: info.leaderboardPool,
            backendPool: info.backendPool,
            userCount: info.userCount,
            timestamp: info.timestamp
        };
    }

    get fun getTreasuryWallet(): Address? {
        return self.treasuryWallet;
    }

    // =========================
    // WARNING: This struct contains nested DistributionInfoResult with uint64 timestamp
    // which may be corrupted due to Tact ABI bug.
    // 
    // RECOMMENDED: Use individual getters:
    // - getDailyPoolBalanceForDay(day) for poolBalance
    // - isDayDistributed(day) for isDistributed
    // - getActiveCountForDay(day) for activeCount
    // - getDistributionTimestamp(day) for timestamp (instead of distributionInfo.timestamp)
    // - getTreasuryWallet() for treasuryAddress
    // =========================
    get fun getDayInfo(day: Int): DayInfo {
        let poolBalance = self.getDailyPoolBalanceForDay(day);
        let isDistributed = self.isDayDistributed(day);
        let activeCount = self.getActiveCountForDay(day);
        let distributionInfo = self.getDistributionInfo(day);
        let treasuryAddress = self.treasuryWallet;
        
        return DayInfo{
            day: day,
            poolBalance: poolBalance,
            isDistributed: isDistributed,
            activeCount: activeCount,
            distributionInfo: distributionInfo,
            treasuryAddress: treasuryAddress
        };
    }

    get fun getTotalRewardsInfo(): RewardsInfo {
        return RewardsInfo{
            totalRewardsDistributed: self.totalRewardsDistributed,
            totalBackendFees: self.totalBackendFees
        };
    }

    get fun getVaultBalance(): Int {
        return self.vaultBalance;
    }

    get fun getOwner(): Address {
        return self.owner;
    }

    // =========================
    // WARNING: This struct contains uint64 field (totalSubscriptionsGranted)
    // which may be corrupted due to Tact ABI bug.
    // 
    // RECOMMENDED: Use getTotalSubscriptionsGrantedRaw() for reliable uint64 value
    // Other fields (coins, uint32) are safe to use from struct
    // =========================
    get fun getStatistics(): Statistics {
        return Statistics{
            totalSubscriptionsGranted: self.totalSubscriptionsGranted,
            totalSubscriptionRevenue: self.totalSubscriptionRevenue,
            totalRewardsDistributed: self.totalRewardsDistributed,
            totalBackendFees: self.totalBackendFees,
            activeSubscriptionsCount: self.activeSubscriptionsCount
        };
    }

    get fun getContractBalance(): Int {
        return myBalance();
    }

    get fun hasSufficientGas(): Bool {
        return myBalance() >= MIN_GAS_RESERVE;
    }

    get fun getAvailablePool(userCount: Int): AvailablePool {
        let balance = myBalance();
        let totalSends = userCount;
        let totalGasNeeded = MIN_GAS_RESERVE + (totalSends * GAS_PER_SEND);
        let gasBuffer = ton("0.002");
        let totalGasReserve = totalGasNeeded + gasBuffer;
        let safeGasReserve = totalGasReserve + (totalGasReserve / 5);
        
        let availablePool = 0;
        if (balance > safeGasReserve) {
            availablePool = balance - safeGasReserve;
        }
        
        return AvailablePool{
            availablePool: availablePool,
            safeGasReserve: safeGasReserve,
            totalGasReserve: totalGasReserve
        };
    }
}
