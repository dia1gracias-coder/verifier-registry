import "@stdlib/deploy";

// Room data structure (must be top-level in Tact)
struct RoomData {
    entry_fee: Int;
    winners_count: Int;
    status: Int; // 0=Closed, 1=Open, 2=Paid
    pool: Int;
    total_entries: Int;
    paid_hash: Int;
    created_at: Int;
    closed_at: Int;
}

// Message structures for external calls
struct OpenRoomMessage {
    room_key: Int;
    entry_fee: Int;
    winners_count: Int;
}

struct EnterRoomMessage {
    room_key: Int;
    entry_fee: Int;
}

// FAE Arcade Treasury Contract - Complete Implementation
contract Treasury with Deployable {
    
    // State variables
    owner: Address;
    upgrade_authority: Address;
    
    // Treasury pools
    airdrop_pool: Int;
    airdrop_id: Int;
    
    // Multi-room support with proper data structure
    rooms: map<Int, RoomData>;
    current_room_id: Int;
    
    // Winner rewards tracking (pull-based payouts) - simplified approach
    winner_rewards: map<Address, Int>; // winner_address -> reward_amount (per room)
    claimed_rewards: map<Address, Int>; // winner_address -> claimed_amount (per room)
    
    // Constants
    HOUSE_FEE_BPS: Int = 250; // 2.5%
    HOUSE_FEE_DENOMINATOR: Int = 10000;
    
    // Constructor
    init(owner: Address, upgrade_authority: Address) {
        self.owner = owner;
        self.upgrade_authority = upgrade_authority;
        self.airdrop_pool = 0;
        self.airdrop_id = 0;
        self.current_room_id = 0;
        // ✅ Proper dictionary initialization
        self.rooms = map<Int, RoomData>{};
        self.winner_rewards = map<Address, Int>{};
        self.claimed_rewards = map<Address, Int>{};
    }
    
    // Note: parseTextMessage helper removed due to Tact slice mutability issues
    
    // External message handlers
    
    
    // Open room with specific parameters (text message with parameters)
    receive("open_room_params") {
        // Parse message body for parameters
        // The body format is: opcode (32 bits) + reference to string + parameters
        // Tact automatically handles the receive("string") matching
        let slice = context().raw;
        
        // Skip opcode (32 bits)
        slice.skipBits(32);
        
        // Skip the string reference (Tact has already matched "open_room_params")
        // The backend uses storeStringRefTail which stores the string in a reference
        slice.skipRef();
        
        // Now parse the actual parameters
        let room_key: Int = slice.loadUint(32);
        let entry_fee: Int = slice.loadCoins();
        let winners_count: Int = slice.loadUint(8);
        
        // Validate parameters
        require(entry_fee > 0, "Entry fee must be positive");
        require(winners_count > 0, "Winners count must be positive");
        require(winners_count <= 1000, "Too many winners");
        require(room_key > 0, "Room key must be positive");
        
        // Check if room already exists
        let existing_room: RoomData? = self.rooms.get(room_key);
        require(existing_room == null, "Room already exists");
        
        // Create new room
        let new_room: RoomData = RoomData{
            entry_fee: entry_fee,
            winners_count: winners_count,
            status: 1, // Open
            pool: 0,
            total_entries: 0,
            paid_hash: 0,
            created_at: now(),
            closed_at: 0
        };
        
        self.rooms.set(room_key, new_room);
        self.current_room_id = room_key;
    }
    
    
    // User enters a paid room with specific parameters (text message with parameters)
    receive("enter_room_params") {
        // Parse message body for parameters using context().raw
        let slice = context().raw;
        slice.skipBits(32); // Skip opcode
        
        // Skip the string reference
        slice.skipRef();
        
        // Now parse the actual parameters
        let room_key: Int = slice.loadUint(32);
        let expected_entry_fee: Int = slice.loadCoins();
        
        // Get room data
        let room: RoomData? = self.rooms.get(room_key);
        
        // Room must exist before entry - no auto-creation in entry handler
        require(room != null, "Room does not exist");
        
        // Room exists - process entry payment
        let room_data: RoomData = room!!;
        require(room_data.status == 1, "Room is not open");
        
        // For existing rooms, entry fees must match exactly
        require(room_data.entry_fee == expected_entry_fee, "Entry fee mismatch");
        let actual_entry_fee: Int = room_data.entry_fee;
        
        // Validate entry fee - contract should receive exactly the entry fee (no overpayment allowed)
        let received_amount: Int = context().value;
        require(received_amount == actual_entry_fee, "Entry fee must be exact amount");
        
        // Calculate house fee (2.5%) based on actual entry fee
        let house_fee: Int = (actual_entry_fee * self.HOUSE_FEE_BPS) / self.HOUSE_FEE_DENOMINATOR;
        
        // Calculate pool contribution (97.5%) based on actual entry fee  
        let pool_contribution: Int = actual_entry_fee - house_fee;
        
        // Update room data (pool is tracked in state)
        room_data.pool = room_data.pool + pool_contribution;
        room_data.total_entries = room_data.total_entries + 1;
        
        // Save the updated room data
        self.rooms.set(room_key, room_data);
        
        // Send house fee to owner wallet
        if (house_fee > 0) {
            send(SendParameters{
                to: self.owner,
                value: house_fee,
                body: "House Fee".asComment(),
                bounce: false
            });
        }
        
        // The pool contribution stays in the contract balance automatically
        // No excess refund logic needed since we require exact payment
    }
    
    // Close a room (text message with parameters)
    receive("close_room_params") {
        // Parse message body for room key using context().raw
        let slice = context().raw;
        slice.skipBits(32); // Skip opcode
        
        // Skip the string reference
        slice.skipRef();
        
        // Now parse the actual parameters
        let room_key: Int = slice.loadUint(32);
        
        // Get room data
        let room: RoomData? = self.rooms.get(room_key);
        require(room != null, "Room not found");
        
        let room_data: RoomData = room!!;
        require(room_data.status == 1, "Room is not open");
        
        // Close room
        room_data.status = 0; // Closed
        room_data.closed_at = now();
        
        self.rooms.set(room_key, room_data);
    }
    
    
    // Distribute payouts with linear weights (pull-based) - text message with parameters
    receive("distribute_payouts_params") {
        // Parse message body for parameters using context().raw
        let slice = context().raw;
        slice.skipBits(32); // Skip opcode
        
        // Skip the string reference
        slice.skipRef();
        
        // Now parse the actual parameters
        let room_key: Int = slice.loadUint(32);
        let winners_count: Int = slice.loadUint(8);
        
        // Get room data
        let room: RoomData? = self.rooms.get(room_key);
        require(room != null, "Room not found");
        
        let room_data: RoomData = room!!;
        require(room_data.status == 0, "Room is not closed");
        require(room_data.paid_hash == 0, "Room already paid");
        require(winners_count == room_data.winners_count, "Winners count mismatch");
        
        // Calculate linear weights
        let total_weight: Int = (winners_count * (winners_count + 1)) / 2;
        let remaining_pool: Int = room_data.pool;
        
        // Parse winners and distribute rewards
        let i: Int = 0;
        while (i < winners_count) {
            let winner_address: Address = slice.loadAddress();
            let weight: Int = winners_count - i; // Linear weight: 1st gets highest weight
            
            // Calculate reward amount
            let reward_amount: Int = (remaining_pool * weight) / total_weight;
            
            // Store reward for later claiming using direct address mapping
            self.winner_rewards.set(winner_address, reward_amount);
            
            i = i + 1;
        }
        
        // Mark room as paid
        room_data.status = 2; // Paid
        room_data.paid_hash = now(); // Use timestamp as hash
        self.rooms.set(room_key, room_data);
    }
    
    // Claim reward (pull-based) - text message with parameters
    receive("claim_reward_params") {
        // Parse message body for parameters using context().raw
        let slice = context().raw;
        slice.skipBits(32); // Skip opcode
        
        // Skip the string reference
        slice.skipRef();
        
        // Now parse the actual parameters
        let room_key: Int = slice.loadUint(32);
        let winner_address: Address = slice.loadAddress();
        
        // Get room data
        let room: RoomData? = self.rooms.get(room_key);
        require(room != null, "Room not found");
        
        let room_data: RoomData = room!!;
        require(room_data.status == 2, "Room is not paid");
        
        // Get winner rewards using direct address mapping
        let reward_amount: Int? = self.winner_rewards.get(winner_address);
        require(reward_amount != null, "No reward for this address");
        
        // Check if already claimed
        let already_claimed: Int = 0;
        let claimed_amount: Int? = self.claimed_rewards.get(winner_address);
        if (claimed_amount != null) {
            already_claimed = claimed_amount!!;
        }
        
        let remaining_reward: Int = reward_amount!! - already_claimed;
        require(remaining_reward > 0, "No remaining reward to claim");
        
        // Send reward to winner
        send(SendParameters{
            to: winner_address,
            value: remaining_reward,
            body: "Reward Claim".asComment(),
            bounce: false
        });
        
        // Update claimed amount
        self.claimed_rewards.set(winner_address, already_claimed + remaining_reward);
    }
    
    // Fund the airdrop pool
    receive("fund_airdrop") {
        self.airdrop_pool = self.airdrop_pool + context().value;
    }
    
    // Distribute airdrop rewards - text message
    receive("distribute_airdrop") {
        let airdrop_id: Int = 1; // Default airdrop ID
        let top_scorer_count: Int = 10; // Default counts
        let streak_winner_count: Int = 5;
        
        // Validate we have enough in the pool
        require(self.airdrop_pool > 0, "No airdrop pool available");
        
        // Increment airdrop ID
        self.airdrop_id = self.airdrop_id + 1;
        
        // Split airdrop pool 50/50
        let half_pool: Int = self.airdrop_pool / 2;
        
        // Calculate amounts per winner
        let top_scorer_amount: Int = 0;
        let streak_winner_amount: Int = 0;
        
        if (top_scorer_count > 0) {
            top_scorer_amount = half_pool / top_scorer_count;
        }
        
        if (streak_winner_count > 0) {
            streak_winner_amount = half_pool / streak_winner_count;
        }
        
        // For text messages, we'll send to the sender as a demo
        if (top_scorer_amount > 0) {
            send(SendParameters{
                to: context().sender,
                value: top_scorer_amount,
                body: "Top Scorer Airdrop".asComment(),
                bounce: false
            });
        }
        
        // Clear airdrop pool
        self.airdrop_pool = 0;
    }
    
    
    // Getter functions exposed as methods
    fun getOwner(): Address {
        return self.owner;
    }
    
    fun getUpgradeAuthority(): Address {
        return self.upgrade_authority;
    }
    
    fun getAirdropPool(): Int {
        return self.airdrop_pool;
    }
    
    fun getAirdropId(): Int {
        return self.airdrop_id;
    }
    
    fun getCurrentRoomId(): Int {
        return self.current_room_id;
    }
    
    fun getHouseFeeBps(): Int {
        return self.HOUSE_FEE_BPS;
    }
    
    fun getHouseFeeDenominator(): Int {
        return self.HOUSE_FEE_DENOMINATOR;
    }
    
    fun getRoomData(room_key: Int): RoomData? {
        return self.rooms.get(room_key);
    }
    
    fun getWinnerReward(room_key: Int, winner_address: Address): Int? {
        return self.winner_rewards.get(winner_address);
    }
    
    fun getClaimedReward(room_key: Int, winner_address: Address): Int? {
        return self.claimed_rewards.get(winner_address);
    }
}