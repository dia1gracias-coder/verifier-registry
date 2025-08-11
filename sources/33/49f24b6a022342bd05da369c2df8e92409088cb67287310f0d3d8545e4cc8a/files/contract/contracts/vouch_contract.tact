import "@stdlib/deploy";

// Messages for the contract
message(0x01) VouchProfile {
    profileOwner: Address;
}

message(0x02) SetTreasuryAddress {
    treasuryAddress: Address;
}

message(0x03) WithdrawFunds {
    amount: Int;
}

message(0x04) WithdrawAll {
    
}

// Structs
struct VouchRecord {
    voucher: Address;
    amount: Int;
    timestamp: Int;
}

struct ProfileStats {
    totalVouches: Int;
    totalAmount: Int;
    lastVouchTime: Int;
}

struct VouchHistoryEntry {
    records: map<Int, VouchRecord>;
}

contract VouchContract {
    owner: Address;
    treasuryAddress: Address;
    salt: Int;
    
    // Contract parameters for bonding curve
    basePrice: Int = ton("0.1"); // 0.1 TON base price
    step: Int = ton("0.01"); // 0.01 TON step increase
    
    // Revenue split percentages (out of 1000 for precision)
    profileOwnerShare: Int = 400; // 40%
    vouchersShare: Int = 300; // 30%
    treasuryShare: Int = 200; // 20%
    burnShare: Int = 100; // 10%
    
    // Storage maps
    profileStats: map<Address, ProfileStats>;
    vouchHistory: map<Address, VouchHistoryEntry>; // profileOwner -> VouchHistoryEntry
    
    init(owner: Address, treasuryAddress: Address, salt: Int) {
        self.owner = owner;
        self.treasuryAddress = treasuryAddress;
        self.salt = salt;
    }
    
    // Deploy receiver with cashback
    receive() {
        // Empty receiver for deployment with cashback
    }
    
    // Calculate vouch price based on current vouch count
    fun calculateVouchPrice(vouchCount: Int): Int {
        // Formula: basePrice + (n^2 * step)
        return self.basePrice + (vouchCount * vouchCount * self.step);
    }
    
    // Get profile statistics
    get fun getProfileStats(profileOwner: Address): ProfileStats? {
        return self.profileStats.get(profileOwner);
    }
    
    // Get vouch history for a profile
    get fun getVouchHistory(profileOwner: Address, index: Int): VouchRecord? {
        let profileHistoryEntry: VouchHistoryEntry? = self.vouchHistory.get(profileOwner);
        if (profileHistoryEntry != null) {
            return profileHistoryEntry!!.records.get(index);
        }
        return null;
    }
    
    // Get next vouch price for a profile
    get fun getNextVouchPrice(profileOwner: Address): Int {
        let stats: ProfileStats? = self.profileStats.get(profileOwner);
        if (stats != null) {
            return self.calculateVouchPrice(stats!!.totalVouches);
        }
        return self.basePrice; // First vouch
    }
    
    // Get contract balance
    get fun getBalance(): Int {
        return myBalance();
    }
    
    // Main vouch function
    receive(msg: VouchProfile) {
        let voucher: Address = sender();
        let profileOwner: Address = msg.profileOwner;
        
        // Prevent self-vouching
        require(voucher != profileOwner, "Cannot vouch for yourself");
        
        // Get current stats
        let currentStats: ProfileStats? = self.profileStats.get(profileOwner);
        let vouchCount: Int = 0;
        let totalAmount: Int = 0;
        
        if (currentStats != null) {
            vouchCount = currentStats!!.totalVouches;
            totalAmount = currentStats!!.totalAmount;
        }
        
        // Calculate required payment
        let requiredPayment: Int = self.calculateVouchPrice(vouchCount);
        
        // Check if enough TON was sent
        let ctx: Context = context();
        require(ctx.value >= requiredPayment, "Insufficient payment for vouch");
        
        // Update profile stats
        let newStats: ProfileStats = ProfileStats{
            totalVouches: vouchCount + 1,
            totalAmount: totalAmount + requiredPayment,
            lastVouchTime: now()
        };
        self.profileStats.set(profileOwner, newStats);
        
        // Add vouch record to history
        let vouchRecord: VouchRecord = VouchRecord{
            voucher: voucher,
            amount: requiredPayment,
            timestamp: now()
        };
        
        let profileHistory: map<Int, VouchRecord> = emptyMap();
        let existingHistoryEntry: VouchHistoryEntry? = self.vouchHistory.get(profileOwner);
        if (existingHistoryEntry != null) {
            profileHistory = existingHistoryEntry!!.records;
        }
        profileHistory.set(vouchCount, vouchRecord);
        
        let newHistoryEntry: VouchHistoryEntry = VouchHistoryEntry{
            records: profileHistory
        };
        self.vouchHistory.set(profileOwner, newHistoryEntry);
        
        // Calculate and distribute payments
        self.distributePayments(profileOwner, requiredPayment, vouchCount);
        
        // Refund excess payment if any
        let excess: Int = ctx.value - requiredPayment;
        if (excess > 0) {
            send(SendParameters{
                to: voucher,
                value: excess,
                mode: SendIgnoreErrors,
                body: "Excess payment refund".asComment()
            });
        }
    }
    
    // Distribute payments according to revenue split
    inline fun distributePayments(profileOwner: Address, amount: Int, vouchCount: Int) {
        let profileOwnerAmount: Int = (amount * self.profileOwnerShare) / 1000;
        let vouchersAmount: Int = (amount * self.vouchersShare) / 1000;
        let treasuryAmount: Int = (amount * self.treasuryShare) / 1000;
        // burnAmount is kept in contract (effectively burned)
        
        // Send to profile owner
        if (profileOwnerAmount > 0) {
            send(SendParameters{
                to: profileOwner,
                value: profileOwnerAmount,
                mode: SendIgnoreErrors,
                body: "Vouch reward".asComment()
            });
        }
        
        // Send to treasury
        if (treasuryAmount > 0) {
            send(SendParameters{
                to: self.treasuryAddress,
                value: treasuryAmount,
                mode: SendIgnoreErrors,
                body: "Treasury share".asComment()
            });
        }
        
        // Distribute to previous vouchers
        if (vouchersAmount > 0 && vouchCount > 0) {
            let amountPerVoucher: Int = vouchersAmount / vouchCount;
            let remainder: Int = vouchersAmount % vouchCount;
            
            let i: Int = 0;
            while (i < vouchCount) {
                let vouchRecord: VouchRecord? = self.getVouchHistory(profileOwner, i);
                if (vouchRecord != null) {
                    let paymentAmount: Int = amountPerVoucher;
                    if (i == 0) { // Give remainder to first voucher
                        paymentAmount = paymentAmount + remainder;
                    }
                    
                    if (paymentAmount > 0) {
                        send(SendParameters{
                            to: vouchRecord!!.voucher,
                            value: paymentAmount,
                            mode: SendIgnoreErrors,
                            body: "Voucher reward".asComment()
                        });
                    }
                }
                i = i + 1;
            }
        }
    }
    
    // Owner functions
    receive(msg: SetTreasuryAddress) {
        require(sender() == self.owner, "Only owner can set treasury address");
        self.treasuryAddress = msg.treasuryAddress;
    }
    
    receive(msg: WithdrawFunds) {
        require(sender() == self.owner, "Only owner can withdraw funds");
        require(msg.amount <= myBalance(), "Insufficient contract balance");
        
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendIgnoreErrors,
            body: "Owner withdrawal".asComment()
        });
    }
    
    // Emergency withdraw all funds (owner only)
    receive(msg: WithdrawAll) {
        require(sender() == self.owner, "Only owner can withdraw all funds");
        
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
            body: "Emergency withdrawal".asComment()
        });
    }
    
    // Get contract configuration
    get fun getBasePrice(): Int {
        return self.basePrice;
    }
    
    get fun getStep(): Int {
        return self.step;
    }
    
    get fun getRevenueSplit(): Int {
        return self.profileOwnerShare; // Returns profile owner share as example
    }
}