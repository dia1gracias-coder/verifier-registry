// Import standard library functions and types for TON blockchain development
import "types"

// ============================================================================
// Contract
// ============================================================================

// Define the Stellar contract that wraps all the functionality
contract Stellar {
    author: "Prgnstctr"
    version: "1.0.0"
    description: "Append-only XLM investment calculation storage with owner-controlled updates"
    // Declare that this contract handles IncomingMessages type (which is aliased to StakingMessage)
    // This tells the TON runtime to route incoming messages to the onInternalMessage handler
    incomingMessages: StakingMessage
}

// ============================================================================
// Type Aliases
// ============================================================================

// Define a type alias that maps IncomingMessages to StakingMessage
// This tells the contract that all incoming messages should be of type StakingMessage
type IncomingMessages = StakingMessage

//

// ===== CONSTANTS =====// "XLM" in hex is 584C4D
const TOKEN_NAME: slice = "584C4D".hexToSlice()

//const TOKEN_NAME: slice = "XLM".literalSlice()

// ============================================================================
// Error Codes
// ============================================================================

// Error code 100: Thrown when a non-owner attempts to call restricted functions
// Error code 101: Thrown when an incoming message doesn't match expected structure
// Error code 102: Thrown when the principal amount is invalid (e.g., zero or negative)
// Error code 103: Thrown when the staking period is invalid (e.g., zero or too short)
//enum Errors {
//  NotAuthorized = 100
//  InvalidMessage = 101
//  InvalidPrincipal = 102
//  InvalidPeriod = 103
//}

// ============================================================================
// Data Structures
// ============================================================================

// Define the structure for incoming staking messages with opcode 0x12345678
struct StakingMessage {
    // The initial amount being staked (in smallest units, e.g., nanotons)
    principal: uint64
    // Annual Percentage Yield expressed in basis points (e.g., 3300 = 33%)
    apyBasisPoints: uint32
    // Daily rate of price appreciation expressed in basis points (e.g., 47 = 47%)
    dailyRate: uint32
    // Duration of the staking period in seconds (e.g., 1728000 = 20 days)
    periodSeconds: uint32
}

// Define the structure for storing calculation results as a historical record
struct CalculationRecord {
    // Unix timestamp when this calculation was performed (captured via blockchain.now())
    timestamp: uint64
    // Name of the token being staked (e.g., "XLM", "GRAM")
    // The principal amount used in this calculation
    principal: uint64
    // The APY used in this calculation (stored for historical reference)
    apyBasisPoints: uint32
    // The daily rate used in this calculation (stored for historical reference)
    dailyRate: uint32
    // The staking period used in this calculation (stored for historical reference)
    periodSeconds: uint32
    // Gains calculated from the APY formula (interest earned from annual percentage)
    stakingGains: uint64
    // Gains calculated from daily compounding of the daily rate
    priceAppreciation: uint64
    // Sum of staking_gains and price_appreciation (total profit)
    totalGain: uint64
    // Final value = principal + total_gain (total amount after staking period)
    finalValue: uint64
    // Net gain expressed in basis points: (total_gain * 10000) / principal
    netGainBps: uint32
    // Reference to the previous calculation record in the linked list (for history tracking)
    prevHead: cell
}

// Define the structure for persistent contract storage on the blockchain
struct Storage {
    // The owner's address; only the owner can send staking messages to this contract
    owner: address
    // A array (dynamic array) that stores all historical CalculationRecord entries
    calculations: array<CalculationRecord>
}

fun Storage.load(): Storage {
    return Storage.fromCell(contract.getData());
}

fun Storage.save(mutate self) {
    contract.setData(self.toCell());
}

// ============================================================================
// Calculation Functions
// ============================================================================
fun getTokenName(): slice {
    return TOKEN_NAME;
}

// Function: Calculate staking gains based on APY and investment period
// Formula: Staking Gain = Principal × (APY / 365) × Days
fun calculateStakingGains(
    principal: uint64,
    apyBasisPoints: uint32,
    periodSeconds: uint32,
): uint64 {
    // Convert period from seconds to days by dividing by 86400 (seconds per day)
    val days = periodSeconds / 86400;

    // Convert APY from basis points to decimal: divide by 10000
    // Example: 3300 basis points = 3300 / 10000 = 0.33 = 33%
    val _apyDecimal = (apyBasisPoints as int) / 10000; //uint64

    // Calculate staking gains: principal × apy_decimal × days / 365
    // Example: 95 × 0.33 × 20 / 365 = 1.71780822
    //val gains = (principal * apyDecimal * days) / 365;
    val gains = (principal * (apyBasisPoints as uint64) * days) / 3650000;
    // = (95 * 3300 * 20) / 3650000
    // = 6,270,000 / 3650000
    // = 1 (in uint64, this is correct!)

    // Return the calculated staking gains
    return gains;
}

//maximum dailyRate where the multiplication in the while loop doesn't overflow uint64
// Function: Calculate price appreciation from daily compounding
// Formula: Price Appreciation = Principal × ((1 + Daily Rate)^Days - 1)
fun calculatePriceAppreciation(
    principal: uint64,
    dailyRate: uint32, //Input: 47
    periodSeconds: uint32,
): int {
    //uint64 gets handle overflow
    // Convert period from seconds to days by dividing by 86400
    val days = periodSeconds / 86400;

    // daily_rate is expressed as a percentage (e.g., 47 for 47%)
    val rateDecimal = (dailyRate as int); //instead of uint64,rateDecimal = 47 (still 47, not 0.47)

    // Base multiplier: 10^18 for fixed-point precision arithmetic
    // This allows us to handle decimal multiplications accurately
    val base = 100;                       // as uint64;
    var multiplier = 1000000000000000000; // as uint64; 10^18 in int

    // Loop counter for daily compounding
    var i = 0; // as uint64;

    // Apply daily compounding for each day in the investment period
    // Each iteration: multiplier = multiplier × (100 + daily_rate) / 100
    // This simulates: (1 + rate/100) raised to the power of days
    // Example: for 47% daily over 20 days: (1.47)^20
    while (i < days) {
        // This line uses rateDecimal as 47:        
        // multiplier = multiplier × (100 + 47) / 100        
        // multiplier = multiplier × 147 / 100
        // Multiply by (100 + rate) and divide by 100 to maintain precision
        // Example iteration 1: multiplier = multiplier × 147 / 100
        multiplier = (multiplier * (base + rateDecimal)) / base;

        // Increment loop counter
        i = i + 1;
    }

    // After loop, multiplier = (1 + daily_rate/100)^days × 10^18
    // Now calculate appreciation: principal × (multiplier/10^18 - 1)
    // Subtract 10^18 to remove the "1" part: (1 + rate)^days - 1
    // Then multiply by principal and divide by 10^18 to scale back down
    val appreciation = (principal as int * (multiplier - 1000000000000000000)) /
    1000000000000000000;

    // Return the calculated price appreciation
    return appreciation;
}

// Store a new calculation record by computing all derived values
fun storeCalculation(
    principal: uint64,
    apyBasisPoints: uint32,
    dailyRate: uint32,
    periodSeconds: uint32,
    _sender: address,
): CalculationRecord {
    // Calculate the staking gains component using the APY-based formula
    val stakingGains = calculateStakingGains(principal, apyBasisPoints, periodSeconds);

    // Calculate the price appreciation component using daily compounding
    val priceAppreciation = calculatePriceAppreciation(principal, dailyRate, periodSeconds);

    // Calculate total gain by summing both components
    val totalGain = (stakingGains as int) + priceAppreciation;

    // Calculate the final value: what the principal grows to after the period
    val finalValue = (principal as int) + totalGain;

    // Calculate net gain in basis points: what percentage the principal grew
    // (total_gain * 10000) / principal converts to basis points (1 basis point = 0.01%)
    val netGainBps = (((totalGain as int) * 10000) /
    (principal as int)) as uint32;                                                  //(totalGain * 10000) / principal;

    // Construct and return a new CalculationRecord with all computed values
    return CalculationRecord {
        // Set timestamp to current blockchain time (seconds since Unix epoch)
        timestamp: blockchain.now(),
        // Set token name to "XLM" (hardcoded for this contract)
        // Store the principal for historical reference
        principal,
        // Store the APY for historical reference
        apyBasisPoints,
        // Store the daily rate for historical reference
        dailyRate,
        // Store the period for historical reference
        periodSeconds,
        // Store the calculated staking gains
        stakingGains,
        // Store the calculated price appreciation
        priceAppreciation,
        // Store the sum of both gain components
        totalGain,
        // Store the final value after the period
        finalValue,
        // Store the net gain expressed in basis points
        netGainBps,
        // Set prev_head to an empty cell (no linked list chain yet)
        prevHead: beginCell().endCell(),
    };
}

// ============================================================================
// Message Handler
// ============================================================================

// Handle incoming internal messages (transactions) sent to this contract
fun onInternalMessage(in: InMessage) {
    // Parse the message body lazily as a StakingMessage struct
    // Lazy evaluation defers parsing until the value is actually used
    val msg = lazy StakingMessage.fromSlice(in.body);

    // Match the parsed message against possible message types
    match (msg) {
        // If the message successfully parses as a StakingMessage, execute this block
        StakingMessage => {
            // Extract the principal amount from the message
            val principal = msg.principal;
            // Extract the APY basis points from the message
            val apyBasisPoints = msg.apyBasisPoints;
            // Extract the daily rate from the message
            val dailyRate = msg.dailyRate;
            // Extract the staking period from the message
            val periodSeconds = msg.periodSeconds;

            // Load the current contract storage state from the blockchain
            // Using lazy evaluation to defer loading until needed
            var storage = lazy Storage.load();

            // Verify that the sender is the contract owner (authorization check)
            // If not, throw NotAuthorized error and halt execution
            assert (storage.owner == in.senderAddress) throw Errors.NotAuthorized;

            // Create a new CalculationRecord with the extracted parameters
            // This computes all the staking gains and price appreciation
            val calculationRecord = storeCalculation(
                principal,
                apyBasisPoints,
                dailyRate,
                periodSeconds,
                in.senderAddress,
            );

            // Add the newly created calculation record to the storage array
            // This appends it to the end of the calculations list
            storage.calculations.push(calculationRecord);

            // Persist the updated storage back to the blockchain
            // This saves the new calculation record permanently
            storage.save();
        }
        // If the message does not match StakingMessage type, execute this block
        else => {
            // Verify that the message body is empty (reject non-empty invalid messages)
            // If not empty, throw InvalidMessage error and halt execution
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

// ============================================================================
// Getter Functions
// ============================================================================
get fun getOwner(): address {
    val storage = lazy Storage.load();
    return storage.owner;
}

// Retrieve all calculation records from storage
get fun getCalculations(): array<CalculationRecord> {
    val storage = Storage.load();
    return storage.calculations;
}

// Retrieve the latest calculation record
get fun getLatestCalculation(): CalculationRecord {
    val storage = Storage.load();
    return storage.calculations.get(storage.calculations.size() - 1);
}
// ============================================================================
// Contract
// ============================================================================
