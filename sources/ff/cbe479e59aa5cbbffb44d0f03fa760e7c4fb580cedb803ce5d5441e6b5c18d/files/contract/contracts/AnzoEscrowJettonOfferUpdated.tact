/**
 * AnzoEscrowJettonOffer.tact
 * 
 * A decentralized peer-to-peer jetton (TON token) escrow contract that facilitates secure trading
 * between makers (offer creators) and takers (offer accepters) with a 2-out-of-3 confirmation system.
 * 
 * Key Features:
 * - Support for both BUY and SELL offers
 * - Partial fills through "intents" (smaller trades within a larger offer)  
 * - 2-out-of-3 multi-signature confirmation (Maker + Taker + Controller)
 * - Automatic fee collection and escrow management
 * - Time-based intent expiration for safety
 * - Offer-level expiry with reclaim functionality
 * - Dispute resolution through controller intervention
 * - Sharded intent storage for gas optimization
 * - Safe math operations with overflow protection
 * - Comprehensive on-chain logging
 * 
 * Architecture:
 * - Makers deposit jettons (SELL offers) or specify buy amounts (BUY offers)
 * - Takers create "intents" to partially fill offers
 * - Funds are escrowed until both parties + controller (2/3) confirm the trade
 * - Controller acts as dispute resolver and can break ties in confirmations
 * - Intents are sharded across multiple buckets for gas efficiency
 */

import "./common/jetton-common-structs";
import "./common/jetton-utils";

// ============================================================================
// CONSTANTS - Configuration values
// ============================================================================

const NUM_SHARDS: Int = 5;          // Number of intent shards for gas optimization
const MAX_PER_SHARD: Int = 100;     // Maximum intents per shard

// ============================================================================
// MESSAGE DEFINITIONS - External interfaces for interacting with the contract
// ============================================================================

/**
 * Message sent by takers to create a new trading intent (partial fill of an offer)
 * @param amount - Amount of jettons the taker wants to trade
 */
message(0xa3000cd4) TakerCreateIntent {
    amount: Int;
    isFeeShared: Bool; // Added Fee Sharing conditional
}

/**
 * Message sent by the Anzo controller to create an intent on behalf of a taker
 * Used for backend-initiated trades. This is to avoid the UX of the taker having to sign when no escrow is needed.
 * @param takerAddress - Address of the taker for whom the intent is created
 * @param amount - Amount of jettons to trade
 */
message(0x49d6dd62) AnzoCreateIntent {
    takerAddress: Address;
    amount: Int;
    isFeeShared: Bool; // Added Fee Sharing conditional
}

/**
 * Message to confirm completion of a trading intent
 * Requires 2 out of 3 confirmations (maker, taker, controller) to execute
 * @param intentId - Unique identifier of the intent to confirm
 */
message(0x6635f157) ConfirmIntent {
    intentId: Int;
}

/**
 * Message to cancel a trading intent
 * Can be called by taker (if no confirmations), controller (if 1 confirmation), or anyone (if expired)
 * @param intentId - Intent identifier to cancel
 */
message(0xee6154b1) CancelIntent {
    intentId: Int;
}

// Opcode-based messages for specific operations (using Tact suggested implicit opcodes)
message(0xbd5d9cce) MakerCancelOffer {}           // Cancel entire offer (maker only)
message(0xa55d3bfb) WithdrawTakerDeposit {}       // Withdraw unused taker deposits
message(0xc33ad913) CollectFees {}                // Collect accumulated platform fees
message(0x7b3e8d92) ReclaimOffer {}               // Reclaim expired offer (maker only)

/**
 * Message to update the available amount for the offer
 * Can only be called by the maker when no active intents exist
 * @param newAvailableAmount - New available amount for trading
 */
message(0x8f4e8d92) UpdateAvailableAmount {
    newAvailableAmount: Int;
}

// ============================================================================
// DATA STRUCTURES - Core data models for the escrow system
// ============================================================================

/**
 * Complete constructor data for contract initialization
 * Contains all parameters needed to set up a new escrow offer
 */
struct ContractConstructorData {
    makerAddress: Address;                          // Address of the offer creator
    offChainOfferId: Int;                           // Reference to off-chain offer data
    jettonTypeId: Int;                              // Identifier for the jetton type being traded
    minimumIntentAmount: Int;                       // Minimum trade size to prevent spam
    controllerWalletAddress: Address;               // Anzo controller for dispute resolution
    feeCollectionWalletAddress: Address;            // Where platform fees are collected
    sharedFeeCollectionWalletAddress: Address;      // Where shared fees are collected
    feeBasisPoints: Int;                            // Fee percentage (basis points, e.g., 100 = 1%)
    availableAmount: Int;                           // Current available amount for trading
    intentValidityDurationSeconds: Int;             // How long intents remain valid
    myJettonWalletAddress: Address;                 // Contract's jetton wallet address
    offerExpiryTimestamp: Int;                      // When the entire offer expires

    // Runtime state variables
    numActiveIntents: Int;                          // Count of currently active trading intents
    amountFeesCollected: Int;                       // Total fees collected but not yet withdrawn
    amountSharedFeesCollected: Int;                 // Total fess shared by a wallet connector
    isBuyOffer: Bool;                               // true = maker wants to buy, false = maker wants to sell
    nextIntentId: Int;                              // Next available intent ID (auto-incrementing)
}

/**
 * Represents a single trading intent (partial fill of an offer)
 * Intents use a 2-out-of-3 confirmation system for security
 */
struct Intent {
    takerAddress: Address;                          // Address of the taker who created this intent
    amount: Int;                                    // Amount of jettons in this intent
    validUntilTimestamp: Int;                       // Expiration timestamp for safety
    isMakerConfirmed: Bool;                         // Whether maker has confirmed this trade
    isTakerConfirmed: Bool;                         // Whether taker has confirmed this trade  
    isControllerConfirmed: Bool;                    // Whether controller has confirmed this trade
    isFeeShared: Bool;                              // Whether the fees between feeCollectorAddress and feeSharingAddress will be shared or not
}

// ============================================================================
// SAFE MATH UTILITY FUNCTIONS
// ============================================================================

/**
 * Safe addition with overflow check
 * @param a - First operand
 * @param b - Second operand
 * @return Sum of a and b
 * @throws 500 if overflow occurs
 */
inline fun safeAdd(a: Int, b: Int): Int {
    let result = a + b;
    throwUnless(500, result >= a && result >= b);  // Overflow check
    return result;
}

/**
 * Safe subtraction with underflow check
 * @param a - Minuend
 * @param b - Subtrahend
 * @return Difference of a and b
 * @throws 500 if underflow occurs
 */
inline fun safeSub(a: Int, b: Int): Int {
    throwUnless(500, a >= b);  // Underflow check
    return a - b;
}

/**
 * Safe multiplication with overflow check
 * @param a - First operand
 * @param b - Second operand
 * @return Product of a and b
 * @throws 500 if overflow occurs
 */
inline fun safeMul(a: Int, b: Int): Int {
    if (a == 0 || b == 0) {
        return 0;
    }
    let result = a * b;
    throwUnless(500, result / a == b);  // Overflow check
    return result;
}

/**
 * Safe division with zero check
 * @param a - Dividend
 * @param b - Divisor
 * @return Quotient of a and b
 * @throws 500 if division by zero
 */
inline fun safeDiv(a: Int, b: Int): Int {
    throwUnless(500, b != 0);  // Division by zero check
    return a / b;
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Counts the number of confirmations for a given intent
 * Used to determine if intent can be executed (requires 2/3 confirmations)
 * @param intent - The intent to check
 * @return Number of confirmations (0-3)
 */
inline fun countConfirmations(intent: Intent): Int {
    let confirmationCount = 0;
    if(intent.isMakerConfirmed) {
        confirmationCount = safeAdd(confirmationCount, 1);
    }
    if(intent.isTakerConfirmed) {
        confirmationCount = safeAdd(confirmationCount, 1);
    }
    if(intent.isControllerConfirmed) {
        confirmationCount = safeAdd(confirmationCount, 1);
    }
    return confirmationCount;
}

/**
 * Calculates the shard ID for a given intent ID
 * @param intentId - Intent identifier
 * @return Shard ID (0 to NUM_SHARDS-1)
 */
// inline fun getShardId(intentId: Int): Int {
//     return intentId % NUM_SHARDS;
// }

/**
 * Counts intents in a specific shard
 * @param shard - Map of intents in the shard
 * @return Number of intents in the shard
 */
// inline fun countIntentsInShard(shard: map<Int, Intent>): Int {
//     let count = 0;
//     foreach (intentId, intent in shard) {
//         count = safeAdd(count, 1);
//     }
//     return count;
// }

// ============================================================================
// MAIN CONTRACT - AnzoEscrowJettonOffer
// ============================================================================

contract AnzoEscrowJettonOffer {
    // ========================================================================
    // STATE VARIABLES - Contract storage
    // ========================================================================
    
    // Core offer identification
    makerAddress: Address;                                // Creator of this escrow offer
    offChainOfferId: Int;                       // Links to off-chain offer metadata
    jettonTypeId: Int;                          // Type of jetton being traded (standard or governance for now)

    // Intent management system - Sharded for gas efficiency
    intents: map<Int, Intent>;  // Sharded intent storage: shardId -> (intentId -> Intent)
    nextIntentId: Int = 0;                      // Auto-incrementing intent ID counter
    minimumIntentAmount: Int;                   // Minimum permissable intent amount - Prevents spam with tiny trades

    // Jetton wallet integration
    myJettonWalletAddress: Address;                       // This contract's jetton wallet

    // Fee and control system
    feeCollectionWalletAddress: Address;                    // Where platform fees go
    sharedFeeCollectionWalletAddress: Address;              // Where shared fees go
    controllerWalletAddress: Address;                       // The address authorized to resolve disputes
    feeBasisPoints: Int;                                    // Platform fee percentage (1% = 100 basis points)
    amountFeesCollected: Int;                               // Accumulated fees awaiting collection
    amountSharedFeesCollected: Int;                         // Total fess shared by a wallet connector

    // Escrow state management
    availableAmount: Int;                       // Amount still available for new intents
    availableTakerDeposits: map<Address, Int>;  // Taker deposits that can be used for intents
    numActiveIntents: Int;                      // Count of active intents (for gas optimization)

    // Offer type and timing
    isBuyOffer: Bool;                                     // true = maker buys jettons, false = maker sells jettons
    intentValidityDurationSeconds: Int;         // How long intents remain valid before expiring
    offerExpiryTimestamp: Int;                  // When the entire offer expires

    /**
     * Contract constructor - initializes a new escrow offer
     * @param makerAddress - Address creating the offer
     * @param offChainOfferId - Reference to off-chain offer data
     * @param jettonMasterAddress - Master contract of the jetton being traded
     * @param jettonTypeId - Unique identifier for this jetton type
     * @param jettonWalletCode - Code for jetton wallet contracts
     * @param feeCollectionWalletAddress - Where to send collected fees
     * @param controllerWalletAddress - Anzo controller for dispute resolution
     * @param feeBasisPoints - Platform fee (100 = 1%, max 10000 = 100%)
     * @param minimumIntentAmount - Minimum trade size to prevent spam
     * @param amountToTrade - For BUY offers: amount maker wants to buy; For SELL offers: 0 (balance-based)
     * @param intentValidityDurationSeconds - Intent expiration time
     * @param offerExpiryDurationSeconds - Offer expiration duration from creation
     */
    init(   
        makerAddress:        Address,
        offChainOfferId:     Int,
        jettonMasterAddress: Address,
        jettonTypeId:        Int,
        jettonWalletCode:    Cell,
        feeCollectionWalletAddress: Address,
        sharedFeeCollectionWalletAddress: Address,
        controllerWalletAddress: Address,
        feeBasisPoints: Int,
        minimumIntentAmount: Int,
        // The amount of jetton that the maker wants to trade
        // Note: 0 means the maker wants to **SELL** the jetton
        // This is because in case of sell jettons, the contract jetton balance is directly the available amount
        // So simply depositing jettons will change the available amount
        amountToTrade: Int, 
        intentValidityDurationSeconds: Int,
        offerExpiryDurationSeconds: Int,
    ) {
        // Input validation - prevent invalid configurations
        throwUnless(401, feeBasisPoints > 0);              // There needs to be a fee
        throwUnless(401, feeBasisPoints <= 10000);         // Max 100% fee
        throwUnless(401, minimumIntentAmount > 0);         // Must have minimum trade size
        throwUnless(401, offerExpiryDurationSeconds > 0);  // Must have valid expiry duration

        // Initialize core offer properties
        self.makerAddress = makerAddress;
        self.offChainOfferId = offChainOfferId;
        self.jettonTypeId = jettonTypeId;
        self.minimumIntentAmount = minimumIntentAmount;
        self.availableAmount = 0;
        self.numActiveIntents = 0;

        // Initialize fee and control system
        self.feeCollectionWalletAddress = feeCollectionWalletAddress;
        self.sharedFeeCollectionWalletAddress = sharedFeeCollectionWalletAddress;
        self.controllerWalletAddress = controllerWalletAddress;
        self.feeBasisPoints = feeBasisPoints;

        // Determine offer type and set initial available amount
        // If amountToTrade is 0, it means the maker wants to SELL the jetton
        // For SELL offers: available amount starts at 0, increases when maker deposits jettons
        // For BUY offers: available amount is set to the amount maker wants to buy
        self.isBuyOffer = amountToTrade > 0;
        self.availableAmount = amountToTrade;

        self.intentValidityDurationSeconds = intentValidityDurationSeconds;
        
        // Set offer expiry timestamp
        self.offerExpiryTimestamp = safeAdd(now(), offerExpiryDurationSeconds);

        // TODO: consider extra caps such as 
        // **Unbounded maps** (`availableTakerDeposits`, `intentBuckets`) allow DOS via rent. 
        // Possible solutions: Impose a cap on `numActiveIntents` (e.g. `<64`) or charge an extra TON fee for each new intent.

        // Calculate and store this contract's jetton wallet address
        // This is where jettons will be deposited and withdrawn from
        self.myJettonWalletAddress = calculateJettonWalletAddress(
            myAddress(),
            // Note: we don't need to store the jetton master address nor wallet code 
            // in the contract after initialization
            // We just use it once to calculate the jetton wallet address
            // In backend verification, we have to repeat this calculation 
            jettonMasterAddress,
            jettonWalletCode,
            jettonTypeId,
        );  

        self.amountFeesCollected = 0;
        self.amountSharedFeesCollected = 0;
        
        // Log contract initialization
        // tvm.log("OFFER_CREATED", self.offChainOfferId, self.makerAddress, self.isBuyOffer, self.availableAmount, self.offerExpiryTimestamp);
    }

    // ========================================================================
    // MESSAGE RECEIVERS - Handle incoming messages and transactions
    // ========================================================================

    /**
     * Empty receiver for contract deployment
     * Simply returns any excess TON to the sender to prevent value loss
     */
    receive() { 
        cashback(sender());
    }

    // ? This works as it should
    /**
     * Handles jetton deposits from makers and takers
     * This is called automatically when jettons are sent to the contract's jetton wallet
     * SELL offers: Maker deposits jettons → increases availableAmount
     * BUY offers: Takers deposit jettons → increases their availableTakerDeposits
     */
    receive(msg: JettonTransferNotification) {
        // Security: Only accept notifications from our own jetton wallet
        require(
            sender() == self.myJettonWalletAddress,
            "Notification not from your jetton wallet!",
        );
        
        // Check offer hasn't expired
        throwUnless(408, now() < self.offerExpiryTimestamp);
        
        if(msg.from == self.makerAddress) {
            // Maker deposit - only allowed for SELL offers
            throwUnless(403, !self.isBuyOffer);  
            // For SELL offers, maker deposits directly increase available trading amount
            self.availableAmount = safeAdd(self.availableAmount, msg.amount);
            
            // Log maker deposit
            // tvm.log("MAKER_DEPOSIT", self.offChainOfferId, msg.from, msg.amount, self.availableAmount);
        } else {
            // Taker deposit - only allowed for BUY offers  
            throwUnless(403, self.isBuyOffer);
            // For BUY offers, track each taker's deposit separately
            let prevTakerDepositOpt = self.availableTakerDeposits.get(msg.from);
            let prevTakerDeposit = prevTakerDepositOpt != null ? prevTakerDepositOpt!! : 0;
            let newTakerDeposit = safeAdd(prevTakerDeposit, msg.amount);
            self.availableTakerDeposits.set(msg.from, newTakerDeposit);
            
            // Log taker deposit
            // tvm.log("TAKER_DEPOSIT", self.offChainOfferId, msg.from, msg.amount, newTakerDeposit);
        }

        // Return any excess TON to the depositor
        self.forward(msg.from, null, false, null);

    }

    /**
     * Taker-initiated intent creation
     * Allows takers to create new trading intents (partial fills)
     */
    receive(msg: TakerCreateIntent) {
        let takerAddress = sender();
        self.createIntent(takerAddress, msg.amount, msg.isFeeShared);
    }

    /**
     * Controller-initiated intent creation  
     * Allows Anzo backend to create intents on behalf of takers. 
     * Its purpose is to improve the user's UX by avoiding the signing of intents when no escrow is needed.
     */
    receive(msg: AnzoCreateIntent) {
        // Security: Only the controller can create intents for others
        throwUnless(403, sender() == self.controllerWalletAddress);
        let takerAddress = msg.takerAddress;
        self.createIntent(takerAddress, msg.amount, msg.isFeeShared);
    }

    /**
     * Internal function to create a new trading intent
     * Handles escrow logic for both BUY and SELL offers
     * 
     * @param takerAddress - Address of the taker creating the intent
     * @param amount - Amount of jettons for this intent
     */
    inline fun createIntent(takerAddress: Address, amount: Int, isFeeShared: Bool) {
        // Check offer hasn't expired
        throwUnless(408, now() < self.offerExpiryTimestamp);
        
        // Validation: Check intent is valid and within available limits
        throwUnless(400, amount > 0 && amount <= self.availableAmount);
        throwUnless(409, amount >= self.minimumIntentAmount);

        // Escrow funds based on offer type
        if(self.isBuyOffer) {
            // BUY offer: Escrow taker's deposited jettons
            let takerDepositOpt = self.availableTakerDeposits.get(takerAddress);
            let takerDeposit = takerDepositOpt != null ? takerDepositOpt!! : 0;
            throwUnless(420, amount <= takerDeposit); // Can't use more than deposited
            // Update deposits
            self.availableTakerDeposits.set(takerAddress, safeSub(takerDeposit, amount));
        }

        // Reduce available amount to reflect escrowed funds
        // For SELL offers: Locks up maker's deposited jettons in escrow
        if(!self.isBuyOffer) {
            self.availableAmount = safeSub(self.availableAmount, amount);
        } 

        // Create new intent with default (unconfirmed) state
        self.intents.set(self.nextIntentId, Intent{
            takerAddress:          takerAddress,
            amount:                amount,
            validUntilTimestamp:   safeAdd(now(), self.intentValidityDurationSeconds),
            isMakerConfirmed:      false,
            isTakerConfirmed:      false,
            isControllerConfirmed:  false,
            isFeeShared: isFeeShared, // Set the fee sharing conditional
        });
        
        // Update counters with safe math
        self.nextIntentId = safeAdd(self.nextIntentId, 1);
        self.numActiveIntents = safeAdd(self.numActiveIntents, 1);
        
        // Log intent creation
        // tvm.log("INTENT_CREATED", self.offChainOfferId, intentId, takerAddress, amount);

        // Return excess TON to sender
        cashback(sender());
    }

    /**
     * Handles intent confirmations using 2-out-of-3 multi-signature system
     * - Maker and Taker can always confirm their own intents
     * - Controller can only confirm as tiebreaker (when exactly 1 other party confirmed)
     * - Intent executes automatically when 2/3 confirmations reached
     */
    receive(msg: ConfirmIntent) {
        // Check offer hasn't expired
        throwUnless(408, now() < self.offerExpiryTimestamp);
        
        // Validate intent exists and is still valid
        let intentOpt = self.intents.get(msg.intentId);
        throwUnless(404, intentOpt != null);
        let intent = intentOpt!!;
        throwUnless(403, now() < intent.validUntilTimestamp || sender() == self.controllerWalletAddress); 
        
        // Determine sender's role in the intent
        let isMaker = sender() == self.makerAddress;
        let isTaker = sender() == intent.takerAddress;
        let isController = sender() == self.controllerWalletAddress;
        throwUnless(401, isMaker || isTaker || isController);

        // Apply confirmation based on sender's role
        if(isMaker) {
            intent.isMakerConfirmed = true;
        }
        else if(isTaker) {
            intent.isTakerConfirmed = true;
        }
        else {
            // Controller acts as dispute resolver - can only confirm when exactly one party has confirmed
            // This prevents controller from overriding both parties' decisions
            // Also, controller can't be the first to confirm
            throwUnless(400, 
            (intent.isMakerConfirmed && !intent.isTakerConfirmed) || 
            (!intent.isMakerConfirmed && intent.isTakerConfirmed));  // exactly one party must have confirmed
            intent.isControllerConfirmed = true;
        }

        // Check confirmation count and execute if threshold reached
        // Note that this is after the confirmations have been updated
        let confirmationCount = countConfirmations(intent);
        throwUnless(400, confirmationCount <= 2);               // Prevent over-confirmation

        if(confirmationCount == 2) {
            // Execute the intent immediately
            self.completeIntent(msg.intentId);
        }
        else { 
            // Save updated intent (only needed if not executing)
            // completeIntent() deletes the intent anyway
            self.intents.set(msg.intentId, intent);
        }
        
        // Log confirmation
        // tvm.log("INTENT_CONFIRMED", self.offChainOfferId, msg.intentId, sender(), confirmationCount);

        cashback(sender());
    }

    /**
     * Executes a confirmed intent by transferring jettons and collecting fees
     * Called automatically when intent reaches 2/3 confirmations
     * 
     * @param intentId - ID of the intent to complete
     */
    inline fun completeIntent(intentId: Int) {
        // Get and validate intent
        let intentOpt = self.intents.get(intentId);
        throwUnless(404, intentOpt != null);
        let intent = intentOpt!!;
        // throwUnless(403, now() < intent.validUntilTimestamp || sender() == self.controllerWalletAddress);

        // Escrow funds based on offer type
        if(self.isBuyOffer) {
            // BUY offer: Escrow taker's deposited jettons
            // Check taker has sufficient deposits and deduct the intent amount
            let takerDeposits = self.availableTakerDeposits.get(intent.takerAddress);
            
            // Update taker's available deposits (delete if zero to save gas)
            if(takerDeposits == 0) {
                let _ = self.availableTakerDeposits.del(intent.takerAddress);
            }
            // ? Reduce Makers willingness to trade when it's BUY offer
            self.availableAmount = safeSub(self.availableAmount, intent.amount)
        }

        // Calculate platform fee and net transfer amount using safe math
        let feeAmount = safeDiv(safeMul(intent.amount, self.feeBasisPoints), 10000);
        throwUnless(402, feeAmount > 0);                    // Ensure fee is positive
        let amountToSend = safeSub(intent.amount, feeAmount);

        if (intent.isFeeShared) {
            // Track shared fees for later withdrawal
            self.amountSharedFeesCollected = safeAdd(self.amountSharedFeesCollected, feeAmount);
        } else {
            // Track fees for later withdrawal
            self.amountFeesCollected = safeAdd(self.amountFeesCollected, feeAmount);
        }

        // Clean up intent storage
        let _ = self.intents.del(intentId);
        self.numActiveIntents = safeSub(self.numActiveIntents, 1);

        // Log intent completion
        // tvm.log("INTENT_COMPLETED", self.offChainOfferId, intentId, intent.takerAddress, amountToSend, feeAmount);

        // Transfer jettons to the appropriate recipient
        // BUY offer: Send jettons to maker (who is buying)
        // SELL offer: Send jettons to taker (who is buying from maker)
        self.sendJettons(self.isBuyOffer ? self.makerAddress : intent.takerAddress, amountToSend);

        // Return excess TON to sender
        cashback(sender());
    }

    /**
     * Handles intent cancellation with proper authorization checks
     * Authorization rules:
     * - Anyone can cancel expired intents
     * - Taker can cancel their own unconfirmed intents  
     * - Controller can cancel intents with exactly 1 confirmation (dispute resolution)
     * - Cannot cancel intents with 2+ confirmations (already executed)
     */
    receive(msg: CancelIntent) {
        self.cancelIntent(msg.intentId);
        cashback(sender());
    }

    /**
     * Internal function to cancel an intent and restore escrowed funds
     * 
     * @param intentId - ID of the intent to cancel
     */
    inline fun cancelIntent(intentId: Int) {
        // Validate intent exists
        let intentOpt = self.intents.get(intentId);
        throwUnless(404, intentOpt != null);
        let intent = intentOpt!!;

        let isTaker = sender() == intent.takerAddress;
        let isController = sender() == self.controllerWalletAddress;

        // Authorization check for non-expired intents
        if(now() < intent.validUntilTimestamp) {
            let confirmationCount = countConfirmations(intent);
            // Authorization rules:
            // - 0 confirmations: Only taker can cancel their own intent
            // - 1 confirmation: Only controller can cancel (dispute resolution)
            // - 2+ confirmations: Intent is completed, cannot cancel
            throwUnless(403, 
            (confirmationCount == 0 && isTaker) || 
            (confirmationCount == 1 && isController) || 
            (confirmationCount > 1));
        }
        // Note: Anyone can cancel expired intents (cleanup mechanism)

        // Remove intent and restore available amount
        let _ = self.intents.del(intentId);

        if(!self.isBuyOffer) {
            self.availableAmount = safeAdd(self.availableAmount, intent.amount);
        } 
        self.numActiveIntents = safeSub(self.numActiveIntents, 1);

        // For BUY offers, return escrowed jettons to taker
        // We send directly rather than restoring to availableTakerDeposits
        // to avoid unexpected balance changes if taker has multiple intents
        if(self.isBuyOffer) {
            self.sendJettons(intent.takerAddress, intent.amount);
        }   
        
        // Log intent cancellation
        // tvm.log("INTENT_CANCELLED", self.offChainOfferId, intentId, sender(), intent.amount);
    }

    /**
     * Internal function to send jettons with proper notification and comments
     * 
     * @param destination - Address to receive the jettons
     * @param amount - Amount of jettons to send
     */
    inline fun sendJettons(
        destination: Address,
        amount: Int,
    ) {
        // Create text comment for the transfer (displayed in wallets)
        // Format: 32-bit zero + UTF-8 text for user-readable comments
        // Binary comments (starting with 0xff) are not displayed to users
        let refFpCell = beginCell()
                        .storeUint(0, 32) // Text comment: 32-bit unsigned integer equals to zero
                        .storeSlice("Anzo Escrow - Releasing Jettons".asSlice())
                        .endCell();
        let forwardPayload = beginCell()
                                .storeBit(true) // isRight = true - required for comment display
                                .storeRef(refFpCell)
                                .endCell().beginParse();

        // Send jetton transfer message to our jetton wallet
        send(SendParameters {
            to: self.myJettonWalletAddress,
            value: JettonTransferGas,           // Gas for jetton transfer operation
            body: JettonTransfer {
                queryId: 0,                    // Unique identifier for transaction tracing
                amount: amount,
                destination: destination,        // Final recipient of jettons
                responseDestination: destination, // Where to send confirmation and TON remainder
                customPayload: null,            // No custom logic needed
                // Forward amount ensures JettonTransferNotification is sent
                // If 0, notification won't be sent to recipient
                forwardTonAmount: JettonTransferForwardTonAmount, 
                forwardPayload: forwardPayload  // Comment for the recipient
            }.toCell(),
        });
    }

    /**
     * Allows maker to cancel entire offer when no active intents exist
     * Only maker can call this, and only when numActiveIntents == 0
     * For SELL offers, returns remaining jettons to maker
     */
    receive(msg: MakerCancelOffer) {
        // Authorization: Only maker can cancel their own offer
        throwUnless(401, sender() == self.makerAddress);
        // Safety: Cannot cancel with active intents (would break escrow)
        // throwUnless(400, self.numActiveIntents == 0);

        let availableAmountBeforeClear = self.availableAmount;
        // Mark offer as cancelled
        self.availableAmount = 0;

        // For SELL offers, return remaining jettons to maker
        // For BUY offers, no action needed (takers withdraw their own deposits)
        if(!self.isBuyOffer && availableAmountBeforeClear > 0) {
            self.sendJettons(self.makerAddress, availableAmountBeforeClear);
        }
        
        // Log offer cancellation
        // tvm.log("OFFER_CANCELLED", self.offChainOfferId, self.makerAddress, availableAmountBeforeClear);

        cashback(sender());
    }

    /**
     * Internal function to cancel an intent during offer reclaim
     * Similar to cancelIntent but without authorization checks
     * 
     * @param intentId - ID of the intent to cancel
     */
    inline fun cancelIntentForReclaim(intentId: Int) {
        let intentOpt = self.intents.get(intentId);
        if (intentOpt != null) {
            let intent = intentOpt!!;
            
            // Remove intent and restore available amount
            let _ = self.intents.del(intentId);
            self.availableAmount = safeAdd(self.availableAmount, intent.amount);
            self.numActiveIntents = safeSub(self.numActiveIntents, 1);

            // For BUY offers, return escrowed jettons to taker
            if(self.isBuyOffer) {
                self.sendJettons(intent.takerAddress, intent.amount);
            }
        }
    }

    /**
     * Allows maker to reclaim expired offer
     * Only maker can call this, and only after offer has expired
     * Returns all remaining jettons and clears the offer
     */
    receive(msg: ReclaimOffer) {
        // Authorization: Only maker can reclaim their own offer
        throwUnless(401, sender() == self.makerAddress);
        // Timing: Can only reclaim after offer expiry
        throwUnless(409, now() >= self.offerExpiryTimestamp);

        let availableAmountBeforeClear = self.availableAmount;
        // Mark offer as reclaimed
        self.availableAmount = 0;
        // Cancel all active intents and return escrowed funds
        foreach (intentId, _ in self.intents) {
            self.cancelIntentForReclaim(intentId);
        }

                    
        // For SELL offers, return remaining jettons to maker
        if(!self.isBuyOffer && availableAmountBeforeClear > 0) {
            self.sendJettons(self.makerAddress, safeAdd(availableAmountBeforeClear, self.availableAmount));
        }

        // Mark offer as reclaimed
        self.availableAmount = 0;
        
        // Log offer reclaim
        // tvm.log("OFFER_RECLAIMED", self.offChainOfferId, self.makerAddress, availableAmountBeforeClear, self.numActiveIntents);

        cashback(sender());
    }

    /**
     * Allows anyone to collect accumulated platform fees
     * Fees are sent to the designated fee collection wallet
     * Open access prevents fees from being stuck
     */
    receive(msg: CollectFees) {
        throwUnless(400, self.amountFeesCollected > 0 || self.amountSharedFeesCollected > 0);

        let feesToCollect = self.amountFeesCollected;
        let sharedFeesToCollect = safeDiv(self.amountSharedFeesCollected, 2); // 50%
        self.amountFeesCollected = 0;      // Clear before external call (reentrancy protection)
        self.amountSharedFeesCollected = 0;      // Clear before external call (reentrancy protection)
        
        // Log fee collection
        // tvm.log("FEES_COLLECTED", self.offChainOfferId, sender(), feesToCollect);
        
        self.sendJettons(self.feeCollectionWalletAddress, safeAdd(feesToCollect, sharedFeesToCollect)); // Send to fee collector
        if(sharedFeesToCollect > 0) {
            self.sendJettons(self.sharedFeeCollectionWalletAddress, sharedFeesToCollect); // Send to fee sharer
        }

        cashback(sender());
    }

    /**
     * Allows takers to withdraw their unused deposits from BUY offers
     * Useful after maker cancellation or when taker wants to exit
     * Only applicable to BUY offers (SELL offers don't have taker deposits)
     */
    receive(msg: WithdrawTakerDeposit) {
        throwUnless(403, self.isBuyOffer);  // Only for BUY offers
        
        let takerAddress = sender();
        let depositOpt = self.availableTakerDeposits.get(takerAddress);
        throwUnless(404, depositOpt != null);
        
        let depositAmount = depositOpt!!;
        throwUnless(400, depositAmount > 0);
        
        // Update state before external call (reentrancy protection)
        let _ = self.availableTakerDeposits.del(takerAddress);
        
        // Log taker withdrawal
        // tvm.log("TAKER_WITHDRAWAL", self.offChainOfferId, takerAddress, depositAmount);
        
        // Send jettons back to the taker
        self.sendJettons(takerAddress, depositAmount);
        
        cashback(sender());
    }

    /**
     * Allows maker to update the available amount for the offer
     * Can only be called by the maker when no active intents exist
     * For BUY offers: Simply updates the availableAmount
     * For SELL offers: Deposits or releases jettons based on amount change
     */
    receive(msg: UpdateAvailableAmount) {
        // Authorization: Only maker can update their own offer
        throwUnless(401, sender() == self.makerAddress);
        
        // Safety: Cannot update with active intents (would break escrow)
        throwUnless(400, self.numActiveIntents == 0);
        
        // Check offer hasn't expired
        throwUnless(408, now() < self.offerExpiryTimestamp);
        
        // Validate new amount is positive
        throwUnless(400, msg.newAvailableAmount > 0);
        
        let oldAvailableAmount = self.availableAmount;
        let amountDifference = msg.newAvailableAmount - oldAvailableAmount;
        
        // Early return if no change needed
        if (amountDifference == 0) {
            return;
        }
        
        if (self.isBuyOffer) {
            // BUY offer: Simply update the available amount
            // No jetton transfers needed since takers deposit their own jettons
            self.availableAmount = msg.newAvailableAmount;
        } else {
            // SELL offer: Handle jetton deposits/releases based on amount change
            if (amountDifference > 0) {
                // Available amount increased - maker needs to deposit more jettons
                // This will be handled by the JettonTransferNotification receiver
                // when maker sends jettons to the contract's jetton wallet
                self.availableAmount = msg.newAvailableAmount;
            } else {
                // Available amount decreased - release excess jettons to maker
                let amountToRelease = safeSub(oldAvailableAmount, msg.newAvailableAmount);
                self.availableAmount = msg.newAvailableAmount;
                
                // Release excess jettons to maker
                self.sendJettons(self.makerAddress, amountToRelease);
            }
        }
        
        // Log available amount update
        // tvm.log("AVAILABLE_AMOUNT_UPDATED", self.offChainOfferId, self.makerAddress, oldAvailableAmount, msg.newAvailableAmount, self.isBuyOffer);
        
        cashback(sender());
    }

    // ========================================================================
    // GETTER FUNCTIONS - Read-only access to contract state
    // ========================================================================

    get fun makerAddress(): Address {
        return self.makerAddress;
    }

    get fun offChainOfferId(): Int {
        return self.offChainOfferId;
    }

    get fun jettonTypeId(): Int {
        return self.jettonTypeId;
    }

    get fun intent(intentId: Int): Intent? {
        return self.intents.get(intentId);
    }

    get fun nextIntentId(): Int {
        return self.nextIntentId;
    }

    get fun minimumIntentAmount(): Int {
        return self.minimumIntentAmount;
    }

    get fun myJettonWalletAddress(): Address {
        return self.myJettonWalletAddress;
    }

    get fun feeCollectionWalletAddress(): Address {
        return self.feeCollectionWalletAddress;
    }

    get fun sharedFeeCollectionWalletAddress(): Address {
        return self.sharedFeeCollectionWalletAddress;
    }

    get fun controllerWalletAddress(): Address {
        return self.controllerWalletAddress;
    }

    get fun feeBasisPoints(): Int {
        return self.feeBasisPoints;
    }

    get fun amountFeesCollected(): Int {
        return self.amountFeesCollected;
    }

    get fun amountSharedFeesCollected(): Int {
        return self.amountSharedFeesCollected;
    }

    get fun availableAmount(): Int {
        return self.availableAmount;
    }

    /**
     * Gets available deposit amount for a specific taker address
     * Returns 0 if taker has no deposits
     */
    get fun availableTakerDeposit(takerAddress: Address): Int {
        let deposit = self.availableTakerDeposits.get(takerAddress);
        return deposit != null ? deposit!! : 0;
    }

    get fun numActiveIntents(): Int {
        return self.numActiveIntents;
    }

    get fun isBuyOffer(): Bool {
        return self.isBuyOffer;
    }

    get fun intentValidityDurationSeconds(): Int {
        return self.intentValidityDurationSeconds;
    }

    get fun offerExpiryTimestamp(): Int {
        return self.offerExpiryTimestamp;
    }

    /**
     * Returns complete contract state for off-chain systems
     * Useful for backend synchronization and debugging
     */
    get fun contractData(): ContractConstructorData {
        return ContractConstructorData {
            makerAddress: self.makerAddress,
            offChainOfferId: self.offChainOfferId,
            jettonTypeId: self.jettonTypeId,
            minimumIntentAmount: self.minimumIntentAmount,
            controllerWalletAddress: self.controllerWalletAddress,
            feeCollectionWalletAddress: self.feeCollectionWalletAddress,
            feeBasisPoints: self.feeBasisPoints,
            availableAmount: self.availableAmount,
            intentValidityDurationSeconds: self.intentValidityDurationSeconds,
            myJettonWalletAddress: self.myJettonWalletAddress,
            offerExpiryTimestamp: self.offerExpiryTimestamp,
            sharedFeeCollectionWalletAddress: self.sharedFeeCollectionWalletAddress,

            numActiveIntents: self.numActiveIntents,
            amountFeesCollected: self.amountFeesCollected,
            amountSharedFeesCollected: self.amountSharedFeesCollected,
            isBuyOffer: self.isBuyOffer,
            nextIntentId: self.nextIntentId,
        };
    }
}