// this trait has to be imported
import "@stdlib/deploy";

// Mining game contract
contract MiningGame with Deployable {
 
    minerals: Int as uint32;           // Total minerals collected
    max_storage: Int as uint32;        // Maximum storage capacity
    last_mined: Int as uint64;         // Timestamp of last mining update
    mining_rate: Int as uint32;        // Minerals mined per second
    pickaxe_power: Int as uint32;      // Power of manual mining (click)
    mining_cooldown: Int = 120;        // 2 minutes in seconds
    last_manual_mine: Int = 0;         // Timestamp of last manual mining
    miner_level: Int as uint16;        // Current miner level
    miner_name: String;                // Name of the miner
    owner_address: Address;            // Address of the contract owner/deployer
    commission_rate: Int = 10;         // Commission rate in percentage (10%)
 
    init() {
        self.minerals = 0;
        self.max_storage = 10000;      // Default storage capacity
        self.last_mined = now();
        self.mining_rate = 1;          // Default: 1 mineral per second
        self.pickaxe_power = 5;        // Default: 5 minerals per click
        self.miner_level = 1;          // Start at level 1
        self.miner_name = "Unnamed Miner"; // Default name
        self.owner_address = sender(); // Set deployer as owner
    }
 
    // Manual mining (clicking) with cooldown
    receive("mine") {
        // Check if cooldown period has passed
        let time_since_last_mine: Int = now() - self.last_manual_mine;
        require(time_since_last_mine >= self.mining_cooldown, "Mining too soon! Wait for cooldown to finish");
        
        // First, collect idle mining rewards
        self.collectIdleMinerals();
        
        // Then add manual mining with pickaxe
        require(self.minerals + self.pickaxe_power <= self.max_storage, "Storage full! Upgrade storage or sell minerals");
        self.minerals = self.minerals + self.pickaxe_power;
        
        // Update the last mining timestamp
        self.last_manual_mine = now();
        self.last_mined = now();
    }
    
    // Sell minerals to make room
    receive("sell") {
        // First, collect idle mining rewards
        self.collectIdleMinerals();
        
        // Calculate TON to send based on minerals (1000 minerals = 0.1 TON)
        let tonToSend: Int = self.minerals * ton("0.0001");
        
        // Calculate commission
        let commission: Int = (tonToSend * self.commission_rate) / 100;
        let playerAmount: Int = tonToSend - commission;
        
        // Keep minimum balance for storage
        let minBalance: Int = ton("0.05");
        
        // Make sure we have enough balance to send
        if (myBalance() - tonToSend >= minBalance) {
            // Reset minerals to 0 (sold everything)
            let mineralsSold: Int = self.minerals;
            self.minerals = 0;
            self.last_mined = now();
            
            // Send commission to owner if applicable
            if (commission > 0) {
                send(SendParameters{
                    to: self.owner_address,
                    value: commission,
                    bounce: true,
                    mode: SendIgnoreErrors
                });
            }
            
            // Transfer TON to the user
            send(SendParameters{
                to: sender(),
                value: playerAmount,
                bounce: true,
                mode: SendIgnoreErrors
            });
        } else {
            // Not enough TON in contract
            require(false, "Contract doesn't have enough TON to pay for minerals");
        }
    }
    
    // Upgrade storage capacity
    receive("upgrade_storage") {
        // First, collect idle mining rewards
        self.collectIdleMinerals();
        
        // Increase max storage by 5000
        self.max_storage = self.max_storage + 5000;
        
        // In a real game, you would check if the user sent enough TON
        // to pay for this upgrade
    }
    
    // Upgrade mining equipment
    receive("upgrade_miner") {
        // Check current level to determine upgrade cost
        let upgradeCost: Int = self.getUpgradeCost();
        require(context().value >= upgradeCost, "Insufficient payment for upgrade");
        
        // Calculate commission for the owner
        let commission: Int = (upgradeCost * self.commission_rate) / 100;
        
        // Send commission to owner
        if (commission > 0) {
            send(SendParameters{
                to: self.owner_address,
                value: commission,
                bounce: true,
                mode: SendIgnoreErrors
            });
        }
        
        // First, collect idle mining rewards
        self.collectIdleMinerals();
        
        // Apply level-specific benefits
        self.miner_level = self.miner_level + 1;
        
        // Apply level-specific benefits
        if (self.miner_level == 2) {
            // Level 2: Improved mining rate and pickaxe
            self.mining_rate = self.mining_rate + 2;
            self.pickaxe_power = self.pickaxe_power + 10;
        } else if (self.miner_level == 3) {
            // Level 3: Better mining rate and storage
            self.mining_rate = self.mining_rate + 3;
            self.max_storage = self.max_storage + 5000;
        } else if (self.miner_level == 4) {
            // Level 4: Significant mining improvements
            self.mining_rate = self.mining_rate + 5;
            self.pickaxe_power = self.pickaxe_power + 20;
        } else if (self.miner_level == 5) {
            // Level 5: Master level benefits
            self.mining_rate = self.mining_rate + 10;
            self.pickaxe_power = self.pickaxe_power + 50;
            self.max_storage = self.max_storage + 10000;
        } else {
            // Beyond level 5: Smaller incremental improvements
            self.mining_rate = self.mining_rate + 2;
            self.pickaxe_power = self.pickaxe_power + 5;
        }
    }
    
    // Upgrade pickaxe
    receive("upgrade_pickaxe") {
        // First, collect idle mining rewards
        self.collectIdleMinerals();
        
        // Increase pickaxe power by 5
        self.pickaxe_power = self.pickaxe_power + 5;
        
        // In a real game, you would check if the user sent enough TON
        // to pay for this upgrade
    }
    
    // Collect idle mining rewards
    receive("collect") {
        self.collectIdleMinerals();
    }
    
    // Helper function to calculate and collect idle mining rewards
    fun collectIdleMinerals() {
        let current_time: Int = now();
        let time_passed: Int = current_time - self.last_mined;
        
        if (time_passed > 0) {
            let new_minerals: Int = time_passed * self.mining_rate;
            
            // Cap the minerals to avoid exceeding max_storage
            if (self.minerals + new_minerals > self.max_storage) {
                self.minerals = self.max_storage;
            } else {
                self.minerals = self.minerals + new_minerals;
            }
            
            self.last_mined = current_time;
        }
    }
 
    // Get total minerals (including uncollected)
    get fun total_minerals(): Int {
        let current_time: Int = now();
        let time_passed: Int = current_time - self.last_mined;
        let pending_minerals: Int = time_passed * self.mining_rate;
        
        // Cap at max_storage
        if (self.minerals + pending_minerals > self.max_storage) {
            return self.max_storage;
        }
        
        return self.minerals + pending_minerals;
    }
    
    // Get collected minerals only
    get fun collected_minerals(): Int {
        return self.minerals;
    }
    
    // Get storage capacity
    get fun storage_capacity(): Int {
        return self.max_storage;
    }
    
    // Get mining rate
    get fun mining_rate(): Int {
        return self.mining_rate;
    }
    
    // Get pickaxe power
    get fun pickaxe_power(): Int {
        return self.pickaxe_power;
    }
    
    // Get uncollected minerals
    get fun uncollected_minerals(): Int {
        let current_time: Int = now();
        let time_passed: Int = current_time - self.last_mined;
        let pending_minerals: Int = time_passed * self.mining_rate;
        
        // Cap at max_storage
        if (self.minerals + pending_minerals > self.max_storage) {
            return self.max_storage - self.minerals;
        }
        
        return pending_minerals;
    }
    
    // Get storage fullness percentage
    get fun storage_fullness(): Int {
        return (self.total_minerals() * 100) / self.max_storage;
    }
    
    // Get contract TON balance
    get fun contract_balance(): String {
        return myBalance().toCoinsString();
    }
    
    // Get contract TON balance as raw value
    get fun contract_balance_raw(): Int {
        return myBalance();
    }
    
    // Get miner level
    get fun miner_level(): Int {
        return self.miner_level;
    }
    
    // Get miner name
    get fun miner_name(): String {
        return self.miner_name;
    }
    
    // Get miner level title based on current level
    get fun miner_level_title(): String {
        if (self.miner_level == 1) {
            return "Novice Digger";
        } else if (self.miner_level == 2) {
            return "Apprentice Miner";
        } else if (self.miner_level == 3) {
            return "Skilled Excavator";
        } else if (self.miner_level == 4) {
            return "Master Prospector";
        } else if (self.miner_level >= 5) {
            return "Legendary Geologist";
        } else {
            return "Unknown";
        }
    }
    
    // Get miner stats (combined info)
    get fun miner_stats(): MinerStats {
        return MinerStats{
            name: self.miner_name,
            level: self.miner_level,
            level_title: self.miner_level_title(),
            mining_rate: self.mining_rate,
            pickaxe_power: self.pickaxe_power,
            minerals: self.minerals,
            max_storage: self.max_storage
        };
    }

    // Get the cost to upgrade to the next level
    fun getUpgradeCost(): Int {
        if (self.miner_level == 1) {
            return ton("0.2");  // Level 1 -> 2: 0.2 TON
        } else if (self.miner_level == 2) {
            return ton("0.5");  // Level 2 -> 3: 0.5 TON
        } else if (self.miner_level == 3) {
            return ton("1.0");  // Level 3 -> 4: 1.0 TON
        } else if (self.miner_level == 4) {
            return ton("2.0");  // Level 4 -> 5: 2.0 TON
        } else {
            return ton("5.0");  // Level 5+ upgrades: 5.0 TON
        }
    }

    // Get level requirements for next level
    get fun next_level_requirement(): LevelRequirement {
        let nextLevel: Int = self.miner_level + 1;
        let cost: Int = self.getUpgradeCost();
        
        return LevelRequirement{
            next_level: nextLevel,
            cost: cost,
            cost_string: cost.toCoinsString()
        };
    }

    // Owner-only: Update commission rate
    receive("update_commission") {
        require(sender() == self.owner_address, "Only the owner can update commission rate");
        
        let slice: Slice = context().raw;
        slice.skipBits(32); // Skip function selector
        
        let newRate: Int = slice.loadUint(8); // Load new rate (0-100)
        require(newRate >= 0 && newRate <= 30, "Commission rate must be between 0% and 30%");
        
        self.commission_rate = newRate;
    }
    
    // Get owner address
    get fun owner_address(): Address {
        return self.owner_address;
    }
    
    // Get commission rate
    get fun commission_rate(): Int {
        return self.commission_rate;
    }
}

// Structure to return combined miner stats
struct MinerStats {
    name: String;
    level: Int;
    level_title: String;
    mining_rate: Int;
    pickaxe_power: Int;
    minerals: Int;
    max_storage: Int;
}

// Structure to return level requirement info
struct LevelRequirement {
    next_level: Int;
    cost: Int;
    cost_string: String;
}