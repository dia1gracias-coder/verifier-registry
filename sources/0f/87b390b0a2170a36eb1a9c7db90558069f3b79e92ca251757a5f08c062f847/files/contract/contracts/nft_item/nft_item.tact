import "./structs";
import "./messages";

contract NftItem {

    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");
    const maxDailyPoints: Int = 100;
    const earningDuration: Int = 3 * 3600; // 3 hours in seconds

    collection_address: Address;
    item_index: Int; 
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool;

    points: Int = 0; // Total lifetime points accumulated
    last_refuel_time: Int; // Last timestamp of refuel or mint
    daily_points_accumulated: Int = 0; // Points accumulated in the current day
    daily_reset_time: Int; // Time at which daily points reset

    init(collection_address: Address, item_index: Int, owner: Address, individual_content: Cell){
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = collection_address;
        self.individual_content = individual_content;
        self.is_initialized = false;
        self.last_refuel_time = now(); // Initialize with current timestamp
        self.daily_reset_time = now(); // Initialize daily reset time
    }

    receive(msg: Transfer){
        let ctx: Context = context();

        let msgValue: Int = ctx.value; // Check the gasCost for storage
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);

        // Only Owner of the this NFT Item can transfer it.
        require(ctx.sender == self.owner, "not owner");

        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.last_refuel_time = now(); // Start the timer on minting
            self.daily_reset_time = now(); // Set daily reset time
            send(SendParameters{
                to: msg.response_destination,
                value: 0,
                mode:  SendIgnoreErrors + SendRemainingValue,
                body: Excesses { query_id: msg.query_id }.toCell() //0xd53276db
            });
        } else {
            self.owner = msg.new_owner; // change current owner to the new_owner
            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode: SendIgnoreErrors, 
                    bounce: false,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: ctx.sender,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }); 
            }
            msgValue = msgValue - ctx.readForwardFee(); 
            if (msg.response_destination != null) { 
                send(SendParameters{ 
                    to: msg.response_destination,
                    value: msgValue - msg.forward_amount,
                    mode: SendPayGasSeparately,
                    body: Excesses { query_id: msg.query_id }.toCell() // 0xd53276db
                });
            } 
        }
    }

    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    // --------- Get Function --------- //
    get fun get_nft_data(): GetNftData {
        self.update_points(); // Update points before returning data

        let b: StringBuilder = beginString();
        let collectionData: String = self.individual_content.asSlice().asString();
        b.append(collectionData);
        b.append(self.item_index.toString());
        b.append(".json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner,
            individual_content: b.toCell()
        };
    }

    // --------- Refuel Function --------- //
    receive(msg: Refuel) {
        require(context().sender == self.owner, "not owner");
        self.update_points();

        // Check if the 3-hour earning window has expired
        let currentTime: Int = now();
        require(currentTime >= self.last_refuel_time + self.earningDuration, "must wait until earning period ends");

        // Reset last refuel time to start a new 3-hour period
        self.last_refuel_time = currentTime;
    }

    // --------- Get Total Points Function --------- //
    get fun get_points(): Int {
        self.update_points(); // Update points before retrieving
        return self.points;
    }

    // --------- Get Today's Points Function --------- //
    get fun get_today_points(): Int {
        self.update_points(); // Ensure points are current
        return self.daily_points_accumulated;
    }

    // --------- Helper Functions --------- //
    fun update_points() {
        let currentTime: Int = now();

        // Reset daily points if a new day has started
        if (currentTime >= self.daily_reset_time + 86400) {
            self.daily_points_accumulated = 0;
            self.daily_reset_time = currentTime;
        }

        // Calculate earned points within the allowed 3-hour earning duration
        let timeElapsed: Int = min(currentTime - self.last_refuel_time, self.earningDuration);
        let pointsEarned: Int = timeElapsed / 60; // Earn 1 point per minute for simplicity

        // Update points without exceeding daily max
        let pointsAvailableToday: Int = self.maxDailyPoints - self.daily_points_accumulated;
        let pointsToAdd: Int = min(pointsEarned, pointsAvailableToday);

        self.points = self.points + pointsToAdd;
        self.daily_points_accumulated = self.daily_points_accumulated + pointsToAdd;

        // Stop earning if the daily cap is reached
        if (self.daily_points_accumulated >= self.maxDailyPoints) {
            self.last_refuel_time = currentTime; // Prevent further earning for the day
        }
    }
}