import "@stdlib/deploy";
import "@stdlib/ownable";

// ============================================================================
// Messages
// ============================================================================

message Deposit {
    referrer: Address;
}

message ClaimDepositRewards {}

message ClaimReferralRewards {}

message WithdrawDeposit {
    depositId: Int as uint32;
}

message Pause {}

message Unpause {}

message SetWalletA {
    walletA: Address;
}

message SetWalletB {
    walletB: Address;
}

message SetClaimMode {
    partialPayoutMode: Bool;
}

message SetParams {
    minDeposit: Int as coins;
    maxDeposit: Int as coins;
    minClaim: Int as coins;
    dailyRoiBps: Int as uint16;
    referralPercents: map<Int, Int>;
}

message EmergencyWithdraw {
    destination: Address;
}

// ============================================================================
// Structs
// ============================================================================

struct User {
    referrer: Address;
    totalDeposited: Int as coins;
    totalWithdrawn: Int as coins;
    referralRewards: Int as coins;
    totalReferralEarned: Int as coins;
    depositDebt: Int as coins;
    activeDepositCount: Int as uint32;
    level0Count: Int as uint32;
    level1Count: Int as uint32;
    level2Count: Int as uint32;
    level3Count: Int as uint32;
    level4Count: Int as uint32;
}

struct DepositInfo {
    owner: Address;
    amount: Int as coins;
    start: Int as uint32;
    lastClaim: Int as uint32;
    expiry: Int as uint32;
}

struct ContractStats {
    totalUsers: Int as uint32;
    totalDeposited: Int as coins;
    totalPaidOut: Int as coins;
    totalReferralPaid: Int as coins;
    availableLiquidity: Int as coins;
    contractBalance: Int as coins;
    partialPayoutMode: Bool;
}

struct UserInfoResponse {
    referrer: Address;
    totalDeposited: Int as coins;
    totalWithdrawn: Int as coins;
    referralRewards: Int as coins;
    totalReferralEarned: Int as coins;
    depositDebt: Int as coins;
    pendingDepositRewards: Int as coins;
    activeDepositCount: Int as uint32;
}

// ============================================================================
// Main Contract
// ============================================================================

contract StakingPool with Deployable, Ownable {
    // Constants
    const ONE_TON: Int = 1000000000;
    const MAX_ROI_BPS: Int = 350; // 3.5% daily
    const FEE_BPS_PER_WALLET: Int = 750; // 7.5%
    const BASIS_POINTS: Int = 10000;
    const REWARD_DURATION_DAYS: Int = 100;
    const SECONDS_PER_DAY: Int = 86400;
    const MAX_REFERRAL_LEVELS: Int = 5;

    // Owner (from Ownable trait)
    owner: Address;
    
    // Configuration
    walletA: Address;
    walletB: Address;
    paused: Bool = false;
    partialPayoutMode: Bool;
    
    minDeposit: Int as coins;
    maxDeposit: Int as coins;
    minClaim: Int as coins;
    dailyRoiBps: Int as uint16;
    rewardDurationSeconds: Int as uint32;
    
    // Referral percentages (basis points)
    referralPercent0: Int as uint16 = 800;  // 8%
    referralPercent1: Int as uint16 = 400;  // 4%
    referralPercent2: Int as uint16 = 200;  // 2%
    referralPercent3: Int as uint16 = 100;  // 1%
    referralPercent4: Int as uint16 = 100;  // 1%
    
    // Statistics
    totalUsers: Int as uint32 = 0;
    totalDeposited: Int as coins = 0;
    totalPaidOut: Int as coins = 0;
    totalReferralPaid: Int as coins = 0;
    totalClaimed: Int as coins = 0;
    
    // Storage
    nextDepositId: Int as uint32 = 1;
    users: map<Address, User>;
    deposits: map<Int, DepositInfo>;

    // ========================================================================
    // Initialization
    // ========================================================================
    
    init(
        owner: Address,
        walletA: Address,
        walletB: Address,
        minDeposit: Int,
        maxDeposit: Int,
        minClaim: Int,
        dailyRoiBps: Int,
        partialPayoutMode: Bool
    ) {
        self.owner = owner;
        self.walletA = walletA;
        self.walletB = walletB;
        self.minDeposit = minDeposit;
        self.maxDeposit = maxDeposit;
        self.minClaim = minClaim;
        self.dailyRoiBps = dailyRoiBps;
        self.partialPayoutMode = partialPayoutMode;
        self.rewardDurationSeconds = self.REWARD_DURATION_DAYS * self.SECONDS_PER_DAY;
        
        require(minDeposit >= self.ONE_TON, "Min deposit must be >= 1 TON");
        require(maxDeposit >= minDeposit, "Max deposit must be >= min deposit");
        require(minClaim >= self.ONE_TON, "Min claim must be >= 1 TON");
        require(dailyRoiBps <= self.MAX_ROI_BPS, "Daily ROI too high");
    }

    // ========================================================================
    // Receive handlers
    // ========================================================================
    
    receive(msg: Deposit) {
        require(!self.paused, "Contract paused");
        
        let amount: Int = context().value;
        require(amount >= self.minDeposit, "Deposit below minimum");
        require(amount <= self.maxDeposit, "Deposit above maximum");
        
        let sender: Address = context().sender;
        
        // Calculate fees
        let feeA: Int = amount * self.FEE_BPS_PER_WALLET / self.BASIS_POINTS;
        let feeB: Int = amount * self.FEE_BPS_PER_WALLET / self.BASIS_POINTS;
        let netDeposit: Int = amount - feeA - feeB;
        
        // Send fees
        send(SendParameters{
            to: self.walletA,
            value: feeA,
            mode: SendIgnoreErrors,
            body: "Fee A".asComment()
        });
        
        send(SendParameters{
            to: self.walletB,
            value: feeB,
            mode: SendIgnoreErrors,
            body: "Fee B".asComment()
        });
        
        // Set referrer if first deposit
        self.setReferrer(sender, msg.referrer);
        
        // Credit referral bonuses
        self.creditReferralBonuses(sender, amount);
        
        // Get or create user
        let user: User = self.getUser(sender);
        
        if (user.totalDeposited == 0) {
            self.totalUsers = self.totalUsers + 1;
        }
        
        // Create deposit
        let nowTs: Int = now();
        let depositId: Int = self.nextDepositId;
        self.nextDepositId = self.nextDepositId + 1;
        
        let expiry: Int = nowTs + self.rewardDurationSeconds;
        
        self.deposits.set(depositId, DepositInfo{
            owner: sender,
            amount: netDeposit,
            start: nowTs,
            lastClaim: nowTs,
            expiry: expiry
        });
        
        // Update user
        user.totalDeposited = user.totalDeposited + netDeposit;
        user.activeDepositCount = user.activeDepositCount + 1;
        self.users.set(sender, user);
        
        self.totalDeposited = self.totalDeposited + netDeposit;
    }
    
    receive(msg: ClaimDepositRewards) {
        require(!self.paused, "Contract paused");
        
        let sender: Address = context().sender;
        let nowTs: Int = now();
        
        let user: User = self.getUser(sender);
        let pending: Int = self.calculatePendingDepositRewards(sender, nowTs) + user.depositDebt;
        
        require(pending >= self.minClaim, "Deposit reward below minimum claim");
        
        let liquidity: Int = self.availableLiquidity();
        require(self.partialPayoutMode || liquidity >= pending, "Insufficient liquidity");
        
        let paid: Int = min(liquidity, pending);
        let remainder: Int = pending - paid;
        
        // Update deposit claims
        self.updateDepositClaims(sender, nowTs);
        
        user.depositDebt = remainder;
        user.totalWithdrawn = user.totalWithdrawn + paid;
        self.users.set(sender, user);
        
        self.totalPaidOut = self.totalPaidOut + paid;
        self.totalClaimed = self.totalClaimed + paid;
        
        send(SendParameters{
            to: sender,
            value: paid,
            mode: SendIgnoreErrors,
            body: "Deposit rewards".asComment()
        });
    }
    
    receive(msg: ClaimReferralRewards) {
        require(!self.paused, "Contract paused");
        
        let sender: Address = context().sender;
        let user: User = self.getUser(sender);
        let pending: Int = user.referralRewards;
        
        require(pending >= self.minClaim, "Referral reward below minimum claim");
        
        let liquidity: Int = self.availableLiquidity();
        require(self.partialPayoutMode || liquidity >= pending, "Insufficient liquidity");
        
        let paid: Int = min(liquidity, pending);
        
        user.referralRewards = pending - paid;
        user.totalWithdrawn = user.totalWithdrawn + paid;
        self.users.set(sender, user);
        
        self.totalPaidOut = self.totalPaidOut + paid;
        self.totalClaimed = self.totalClaimed + paid;
        
        send(SendParameters{
            to: sender,
            value: paid,
            mode: SendIgnoreErrors,
            body: "Referral rewards".asComment()
        });
    }
    
    receive(msg: WithdrawDeposit) {
        require(!self.paused, "Contract paused");
        
        let sender: Address = context().sender;
        let deposit: DepositInfo = self.deposits.get(msg.depositId)!!;
        
        require(deposit.owner == sender, "Not deposit owner");
        require(deposit.amount > 0, "Deposit not found");
        require(now() >= deposit.expiry, "Deposit not matured");
        
        let liquidity: Int = self.availableLiquidity();
        require(self.partialPayoutMode || liquidity >= deposit.amount, "Insufficient liquidity for withdrawal");
        
        let paid: Int = min(liquidity, deposit.amount);
        deposit.amount = deposit.amount - paid;
        self.deposits.set(msg.depositId, deposit);
        
        let user: User = self.getUser(sender);
        user.totalWithdrawn = user.totalWithdrawn + paid;
        self.users.set(sender, user);
        
        self.totalPaidOut = self.totalPaidOut + paid;
        self.totalClaimed = self.totalClaimed + paid;
        
        send(SendParameters{
            to: sender,
            value: paid,
            mode: SendIgnoreErrors,
            body: "Principal withdrawal".asComment()
        });
    }

    // ========================================================================
    // Owner functions
    // ========================================================================
    
    receive(msg: Pause) {
        self.requireOwner();
        self.paused = true;
    }
    
    receive(msg: Unpause) {
        self.requireOwner();
        self.paused = false;
    }
    
    receive(msg: SetWalletA) {
        self.requireOwner();
        self.walletA = msg.walletA;
    }
    
    receive(msg: SetWalletB) {
        self.requireOwner();
        self.walletB = msg.walletB;
    }
    
    receive(msg: SetClaimMode) {
        self.requireOwner();
        self.partialPayoutMode = msg.partialPayoutMode;
    }
    
    receive(msg: EmergencyWithdraw) {
        self.requireOwner();
        let balance: Int = myBalance() - self.ONE_TON;
        send(SendParameters{
            to: msg.destination,
            value: balance,
            mode: SendIgnoreErrors,
            body: "Emergency withdrawal".asComment()
        });
    }

    // ========================================================================
    // Internal functions
    // ========================================================================
    
    fun setReferrer(user: Address, referrer: Address) {
        if (referrer == newAddress(0, 0) || referrer == user) {
            return;
        }
        
        let userState: User = self.getUser(user);
        if (userState.referrer != newAddress(0, 0)) {
            return;
        }
        
        userState.referrer = referrer;
        self.users.set(user, userState);
        
        // Update referral counts up the chain
        let current: Address = referrer;
        let level: Int = 0;
        
        while (level < self.MAX_REFERRAL_LEVELS) {
            if (current == newAddress(0, 0)) {
                return;
            }
            
            let sponsor: User = self.getUser(current);
            
            if (level == 0) { sponsor.level0Count = sponsor.level0Count + 1; }
            else if (level == 1) { sponsor.level1Count = sponsor.level1Count + 1; }
            else if (level == 2) { sponsor.level2Count = sponsor.level2Count + 1; }
            else if (level == 3) { sponsor.level3Count = sponsor.level3Count + 1; }
            else if (level == 4) { sponsor.level4Count = sponsor.level4Count + 1; }
            
            self.users.set(current, sponsor);
            
            current = sponsor.referrer;
            level = level + 1;
        }
    }
    
    fun creditReferralBonuses(user: Address, amount: Int) {
        let userState: User = self.getUser(user);
        let current: Address = userState.referrer;
        let level: Int = 0;
        
        while (level < self.MAX_REFERRAL_LEVELS && current != newAddress(0, 0)) {
            let percent: Int = self.getReferralPercent(level);
            
            if (percent > 0) {
                let bonus: Int = amount * percent / self.BASIS_POINTS;
                let sponsor: User = self.getUser(current);
                sponsor.referralRewards = sponsor.referralRewards + bonus;
                sponsor.totalReferralEarned = sponsor.totalReferralEarned + bonus;
                self.users.set(current, sponsor);
                self.totalReferralPaid = self.totalReferralPaid + bonus;
            }
            
            let currentUser: User = self.getUser(current);
            current = currentUser.referrer;
            level = level + 1;
        }
    }
    
    fun updateDepositClaims(userAddress: Address, nowTs: Int) {
        // Iterate through all deposits and update those belonging to this user
        let depositId: Int = 1;
        
        while (depositId < self.nextDepositId) {
            let deposit: DepositInfo? = self.deposits.get(depositId);
            
            if (deposit != null) {
                let dep: DepositInfo = deposit!!;
                
                if (dep.owner == userAddress && dep.amount > 0 && dep.lastClaim < dep.expiry) {
                    let claimTime: Int = min(nowTs, dep.expiry);
                    dep.lastClaim = claimTime;
                    self.deposits.set(depositId, dep);
                }
            }
            
            depositId = depositId + 1;
        }
    }
    
    fun calculatePendingDepositRewards(account: Address, nowTs: Int): Int {
        let total: Int = 0;
        let depositId: Int = 1;
        
        // Iterate through all deposits
        while (depositId < self.nextDepositId) {
            let deposit: DepositInfo? = self.deposits.get(depositId);
            
            if (deposit != null) {
                let dep: DepositInfo = deposit!!;
                
                if (dep.owner == account && dep.amount > 0 && dep.lastClaim < dep.expiry) {
                    let endTime: Int = min(nowTs, dep.expiry);
                    
                    if (endTime > dep.lastClaim) {
                        let elapsed: Int = endTime - dep.lastClaim;
                        let reward: Int = dep.amount * self.dailyRoiBps / self.BASIS_POINTS * elapsed / self.SECONDS_PER_DAY;
                        total = total + reward;
                    }
                }
            }
            
            depositId = depositId + 1;
        }
        
        return total;
    }
    
    fun getUser(address: Address): User {
        let user: User? = self.users.get(address);
        
        if (user == null) {
            return User{
                referrer: newAddress(0, 0),
                totalDeposited: 0,
                totalWithdrawn: 0,
                referralRewards: 0,
                totalReferralEarned: 0,
                depositDebt: 0,
                activeDepositCount: 0,
                level0Count: 0,
                level1Count: 0,
                level2Count: 0,
                level3Count: 0,
                level4Count: 0
            };
        }
        
        return user!!;
    }
    
    fun getReferralPercent(level: Int): Int {
        if (level == 0) { return self.referralPercent0; }
        if (level == 1) { return self.referralPercent1; }
        if (level == 2) { return self.referralPercent2; }
        if (level == 3) { return self.referralPercent3; }
        if (level == 4) { return self.referralPercent4; }
        return 0;
    }
    
    fun availableLiquidity(): Int {
        let balance: Int = myBalance();
        if (balance <= self.ONE_TON) {
            return 0;
        }
        return balance - self.ONE_TON;
    }

    // ========================================================================
    // Getters
    // ========================================================================
    
    get fun contractStats(): ContractStats {
        return ContractStats{
            totalUsers: self.totalUsers,
            totalDeposited: self.totalDeposited,
            totalPaidOut: self.totalPaidOut,
            totalReferralPaid: self.totalReferralPaid,
            availableLiquidity: self.availableLiquidity(),
            contractBalance: myBalance(),
            partialPayoutMode: self.partialPayoutMode
        };
    }
    
    get fun getUserInfo(account: Address): UserInfoResponse {
        let user: User = self.getUser(account);
        return UserInfoResponse{
            referrer: user.referrer,
            totalDeposited: user.totalDeposited,
            totalWithdrawn: user.totalWithdrawn,
            referralRewards: user.referralRewards,
            totalReferralEarned: user.totalReferralEarned,
            depositDebt: user.depositDebt,
            pendingDepositRewards: self.calculatePendingDepositRewards(account, now()),
            activeDepositCount: user.activeDepositCount
        };
    }
    
    get fun pendingRewards(account: Address): Int {
        let user: User = self.getUser(account);
        return self.calculatePendingDepositRewards(account, now()) + user.depositDebt;
    }
    
    get fun pendingReferralRewards(account: Address): Int {
        let user: User = self.getUser(account);
        return user.referralRewards;
    }
    
    get fun getDepositInfo(depositId: Int): DepositInfo {
        return self.deposits.get(depositId)!!;
    }
}
