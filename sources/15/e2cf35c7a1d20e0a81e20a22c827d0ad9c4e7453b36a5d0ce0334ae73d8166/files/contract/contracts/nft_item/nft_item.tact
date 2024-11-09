import "./structs";
import "./messages";

contract NftItem {
    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");
    const scalingFactor: Int = 1000; // Scaling factor for fixed-point arithmetic
    const basePointsPerMinute: Int = 1667; // Base points per minute in scaled form (1.667 points)

    // Default earning duration and max points
    const defaultEarningDuration: Int = 3 * 3600; // 3 hours in seconds
    const defaultMaxPointsPerPeriod: Int = 300; // Maximum points per default period

    // Fuel booster durations and costs
    const fuelBooster6hCost: Int = ton("0.2");
    const fuelBooster12hCost: Int = ton("0.35");
    const fuelBooster24hCost: Int = ton("0.6");

    const earningDuration6h: Int = 6 * 3600; // 6 hours in seconds
    const earningDuration12h: Int = 12 * 3600; // 12 hours in seconds
    const earningDuration24h: Int = 24 * 3600; // 24 hours in seconds

    const maxPointsPerPeriod6h: Int = 600; // Max points for 6-hour period
    const maxPointsPerPeriod12h: Int = 1200; // Max points for 12-hour period
    const maxPointsPerPeriod24h: Int = 2400; // Max points for 24-hour period

    collection_address: Address;
    item_index: Int;
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool;

    points: Int = 0; // Total lifetime points accumulated
    last_refuel_time: Int = 0; // Initialize to 0

    // Booster variables
    boosterMultiplier: Int = 1000; // Booster multiplier in scaled form (default 1.0)

    // Variables for fuel booster
    currentEarningDuration: Int = 0; // Initialize to 0
    currentMaxPointsPerPeriod: Int = 0; // Initialize to 0
    fuelBoosterExpirationTime: Int = 0; // Timestamp when fuel booster expires

    init(collection_address: Address, item_index: Int, owner: Address, individual_content: Cell) {
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = collection_address;
        self.individual_content = individual_content;
        self.is_initialized = false;
        self.last_refuel_time = now(); // Set last refuel time to current timestamp on minting

        // Initialize current earning duration and max points per period to default values
        self.currentEarningDuration = self.defaultEarningDuration;
        self.currentMaxPointsPerPeriod = self.defaultMaxPointsPerPeriod;
    }

    receive(msg: Transfer) {
        let ctx: Context = context();

        let msgValue: Int = ctx.value; // Check the gasCost for storage
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);

        // Only Owner of this NFT Item can transfer it.
        require(ctx.sender == self.owner, "not owner");

        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.last_refuel_time = now(); // Set last refuel time to current timestamp on minting
            send(SendParameters{
                to: msg.response_destination,
                value: 0,
                mode: SendIgnoreErrors + SendRemainingValue,
                body: Excesses { query_id: msg.query_id }.toCell() //0xd53276db
            });
        } else {
            self.owner = msg.new_owner; // Change current owner to the new_owner
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

    receive(msg: GetStaticData) {
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

    // --------- Get Function to Fetch NFT Data --------- //
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

        // Check if the earning window has expired
        let currentTime: Int = now();
        let refuelThreshold: Int = self.last_refuel_time + self.currentEarningDuration;

        require(currentTime >= refuelThreshold, "must wait until earning period ends");

        // Reset last refuel time to start a new earning period
        self.last_refuel_time = currentTime;
    }

    // --------- Buy Booster Function --------- //
    receive(msg: BuyBooster) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not owner");

        // Update points before applying booster
        self.update_points();

        // Determine which booster is being purchased based on the amount sent
        let amountSent: Int = ctx.value;

        if (amountSent >= ton("0.25")) {
            // Purchase 25% booster
            self.boosterMultiplier = self.scalingFactor + (self.scalingFactor * 25 / 100); // Multiplier becomes 1.25
        } else if (amountSent >= ton("0.1")) {
            // Purchase 10% booster
            self.boosterMultiplier = self.scalingFactor + (self.scalingFactor * 10 / 100); // Multiplier becomes 1.10
        }

        // Send excess funds back to the sender if any
        let boosterCost: Int = ton("0.1");
        if (amountSent >= ton("0.25")) {
            boosterCost = ton("0.25");
        }
        let change: Int = amountSent - boosterCost;
        if (change > 0) {
            send(SendParameters{
                to: ctx.sender,
                value: change,
                mode: SendIgnoreErrors,
                bounce: false
            });
        }
    }

    // --------- Buy Fuel Booster Function --------- //
    receive(msg: BuyFuelBooster) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "not owner");

        // Update points before applying fuel booster
        self.update_points();

        let amountSent: Int = ctx.value;

        let boosterDuration: Int = 0;
        let boosterMaxPoints: Int = 0;
        let boosterCost: Int = 0;
        let boosterActiveDuration: Int = 0; // Duration for which the booster is active (in seconds)


        if (amountSent >= self.fuelBooster24hCost) {
            // Purchase 24-hour booster
            boosterDuration = self.earningDuration24h;
            boosterMaxPoints = self.maxPointsPerPeriod24h;
            boosterCost = self.fuelBooster24hCost;
            boosterActiveDuration = 24 * 3600;
        } else if (amountSent >= self.fuelBooster12hCost) {
            // Purchase 12-hour booster
            boosterDuration = self.earningDuration12h;
            boosterMaxPoints = self.maxPointsPerPeriod12h;
            boosterCost = self.fuelBooster12hCost;
            boosterActiveDuration = 12 * 3600;
        } else if (amountSent >= self.fuelBooster6hCost) {
            // Purchase 6-hour booster
            boosterDuration = self.earningDuration6h;
            boosterMaxPoints = self.maxPointsPerPeriod6h;
            boosterCost = self.fuelBooster6hCost;
            boosterActiveDuration = 6 * 3600;
        }

        // Update current earning duration and max points per period
        self.currentEarningDuration = boosterDuration;
        self.currentMaxPointsPerPeriod = boosterMaxPoints;

        // Set fuel booster expiration time
        let currentTime: Int = now();
        self.fuelBoosterExpirationTime = currentTime + boosterActiveDuration;

        // Send excess funds back to the sender if any
        let change: Int = amountSent - boosterCost;
        if (change > 0) {
            send(SendParameters{
                to: ctx.sender,
                value: change,
                mode: SendIgnoreErrors,
                bounce: false
            });
        }
    }

    // --------- Get Booster Multiplier Function --------- //
    get fun get_booster_multiplier(): Int {
        return self.boosterMultiplier;
    }

    // --------- Get Fuel Booster Expiration Time Function --------- //
    get fun get_fuel_booster_expiration_time(): Int {
        return self.fuelBoosterExpirationTime;
    }

    // --------- Get Current Earning Duration Function --------- //
    get fun get_current_earning_duration(): Int {
        return self.currentEarningDuration;
    }

    // --------- Get Last Refuel Time Function --------- //
    get fun get_last_refuel_time(): Int {
        return self.last_refuel_time;
    }

    // --------- Get Total Points Function --------- //
    get fun get_points(): Int {
        self.update_points(); // Update points before retrieving
        return self.points;
    }

    // --------- Helper Function to Update Points --------- //
  fun update_points() {
        let currentTime: Int = now();

        // Check if fuel booster has expired
        if (self.fuelBoosterExpirationTime > 0 && currentTime >= self.fuelBoosterExpirationTime) {
            // Fuel booster has expired, reset earning duration and max points per period
            self.currentEarningDuration = self.defaultEarningDuration;
            self.currentMaxPointsPerPeriod = self.defaultMaxPointsPerPeriod;
            self.fuelBoosterExpirationTime = 0;
        }

        // Calculate earned points within the allowed earning duration
        let timeElapsed: Int = currentTime - self.last_refuel_time;
        let cappedElapsedTime: Int = min(timeElapsed, self.currentEarningDuration); // Cap timeElapsed to current earning duration

        // Calculate points based on full minutes elapsed, using scaling factor
        let minutesElapsed: Int = cappedElapsedTime / 60;
        let scaledBasePoints: Int = minutesElapsed * self.basePointsPerMinute; // Base points in scaled form

        // Apply booster multiplier
        let scaledPointsToAdd: Int = (scaledBasePoints * self.boosterMultiplier) / self.scalingFactor; // Adjusted points in scaled form

        // Cap scaled points to currentMaxPointsPerPeriod (scaled)
        let maxPointsPerPeriodScaled: Int = self.currentMaxPointsPerPeriod * self.scalingFactor;
        scaledPointsToAdd = min(scaledPointsToAdd, maxPointsPerPeriodScaled);

        // Convert scaled points to whole points and accumulate
        let pointsToAdd: Int = scaledPointsToAdd / self.scalingFactor; // Adjust back to integer points
        self.points = self.points + pointsToAdd;

        // Reset `last_refuel_time` after the earning duration has passed
        if (timeElapsed >= self.currentEarningDuration) {
            self.last_refuel_time = self.last_refuel_time + self.currentEarningDuration;
        }
    }
}
