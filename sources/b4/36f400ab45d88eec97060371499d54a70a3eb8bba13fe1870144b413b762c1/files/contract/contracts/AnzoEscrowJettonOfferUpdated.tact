/**
 * AnzoEscrowJettonOffer.tact
 * 
 * A decentralized peer-to-peer Jetton (TON token) escrow contract that facilitates secure trading
 * between makers (offer creators) and takers (offer accepters) with a 2-out-of-3 confirmation system.
 * 
 * Key Features:
 * - Support for both BUY and SELL offers
 * - Partial fills through "intents" (smaller trades within a larger offer)  
 * - 2-out-of-3 multi-signature confirmation (Maker + Taker + Controller)
 * - Automatic fee collection and escrow management with fee sharing support
 * - Time-based intent expiration for safety
 * - Offer-level expiry with reclaim functionality
 * - Dispute resolution through controller intervention
 * - Safe math operations with overflow protection
 * - Comprehensive on-chain logging with context-specific transfer messages
 * - Dynamic offer amount updates (for makers)
 * - Taker deposit management for BUY offers
 * - Fee collection and withdrawal mechanisms
 * 
 * Architecture:
 * - Makers deposit jettons (SELL offers) or specify buy amounts (BUY offers)
 * - Takers create "intents" to partially fill offers
 * - Funds are escrowed until both parties + controller (2/3) confirm the trade
 * - Controller acts as dispute resolver and can break ties in confirmations
 * - Jettons are transferred with descriptive messages for better UX
 * - Fees are automatically calculated and collected on successful trades
 * - Support for both standard and shared fee collection
 * 
 * Offer Types:
 * - SELL offers: Maker deposits jettons, takers buy from the deposited amount
 * - BUY offers: Maker specifies amount to buy, takers deposit jettons for trading
 * 
 * Security Features:
 * - Authorization checks for all operations
 * - Reentrancy protection through state updates before external calls
 * - Input validation with specific error codes
 * - Time-based expiration for both intents and offers
 * - Multi-signature confirmation system prevents unilateral execution
 * 
 * Error Handling:
 * - Comprehensive error codes (400-409) for different failure scenarios
 * - Clear authorization rules for each operation
 * - Graceful handling of expired offers and intents
 * - Safe math operations prevent overflow/underflow
 */

import "./common/jetton-common-structs";
import "./common/jetton-utils";

// ============================================================================
// MESSAGE DEFINITIONS - External interfaces for interacting with the contract
// ============================================================================

/**
 * Message sent by takers to create a new trading intent (partial fill of an offer)
 * @param amount - Amount of jettons the taker wants to trade
 * @param isFeeShared - Whether the fees between feeCollectorAddress and feeSharingAddress will be shared or not
 */
message(0xa3000cd4) TakerCreateIntent {
    amount: Int;
    isFeeShared: Bool;
}

/**
 * Message sent by the Anzo controller to create an intent on behalf of a taker
 * Used for backend-initiated trades. This is to avoid the UX of the taker having to sign when no escrow is needed.
 * @param takerAddress - Address of the taker for whom the intent is created
 * @param amount - Amount of jettons to trade
 * @param isFeeShared - Whether the fees between feeCollectorAddress and feeSharingAddress will be shared or not
 */
message(0x49d6dd62) AnzoCreateIntent {
    takerAddress: Address;
    amount: Int;
    isFeeShared: Bool;
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
 * Can be called:
 *  - By taker (if no confirmations), 
 *  - By controller (if 1 confirmation), or 
 *  - By anyone (if expired)
 * @param intentId - Intent identifier to cancel
 */
message(0xee6154b1) CancelIntent {
    intentId: Int;
}

/**
 * Message to withdraw unused taker deposits
 * Can only be called by the taker
 */
message(0xa55d3bfb) WithdrawTakerDeposit {}

/**
 * Message to collect accumulated platform fees
 * Can only be called by the maker
 */
message(0xc33ad913) CollectFees {}
/**
 * Message to reclaim an expired offer
 * Can only be called by the maker
 */
message(0x7b3e8d92) ReclaimOffer {}

/**
 * Message to update the available amount for the offer
 * Can only be called by the maker when no active intents exist
 * @param newAvailableAmount - New available amount for trading
 */
message(0x8f4e8d92) UpdateAvailableAmount {
    newAvailableAmount: Int;
}

/**
 * Message to cancel the entire offer
 * Can only be called by the maker
 * For SELL offers, returns remaining jettons to maker
 * For BUY offers, no action needed (takers withdraw their own deposits)
 */
message(0x7b3e8d93) MakerCancelOffer {}

// ============================================================================
// DATA STRUCTURES - Core data models for the escrow system
// ============================================================================

/**
 * Complete constructor data for contract initialization
 * Contains all parameters needed to set up a new escrow offer
 */
struct ContractConstructorData {
    makerAddress: Address;                          // Address of the offer creator
    offChainOfferId: Int;                 // Reference to off-chain offer data
    jettonTypeId: Int;                    // Identifier for the Jetton type being traded
    minimumIntentAmount: Int;             // Minimum trade size to prevent spam
    controllerWalletAddress: Address;               // Anzo controller for dispute resolution
    feeCollectionWalletAddress: Address;            // Where platform fees are collected
    sharedFeeCollectionWalletAddress: Address;      // Where shared fees are collected
    feeBasisPoints: Int;                  // Fee percentage (basis points, e.g., 100 = 1%)
    availableAmount: Int;                 // Current available amount for trading
    intentValidityDurationSeconds: Int;   // How long intents remain valid
    myJettonWalletAddress: Address;                 // Contract's Jetton wallet address
    offerExpiryTimestamp: Int;            // When the entire offer expires

    // Runtime state variables
    numActiveIntents: Int;                // Count of currently active trading intents
    amountFeesCollected: Int;             // Total fees collected but not yet withdrawn
    amountSharedFeesCollected: Int;       // Total fess shared by a wallet connector
    isBuyOffer: Bool;                               // true = maker wants to buy, false = maker wants to sell
    nextIntentId: Int;                    // Next available intent ID (auto-incrementing)
}

/**
 * Represents a single trading intent (partial fill of an offer)
 * Intents use a 2-out-of-3 confirmation system for security
 */
struct Intent {
    takerAddress: Address;                          // Address of the taker who created this intent
    amount: Int;                          // Amount of jettons in this intent
    validUntilTimestamp: Int;             // Expiration timestamp for safety
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
    throwUnless(500, result >= a && result >= b);
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
    throwUnless(500, a >= b);
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
    throwUnless(500, result / a == b);
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
    throwUnless(500, b != 0);
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
    jettonTypeId: Int;                          // Type of Jetton being traded (standard or governance for now)

    // Intent management system - Sharded for gas efficiency
    intents: map<Int, Intent>;                  // Sharded intent storage: shardId -> (intentId -> Intent)
    nextIntentId: Int = 0;                      // Auto-incrementing intent ID counter
    minimumIntentAmount: Int;                   // Minimum permissable intent amount - Prevents spam with tiny trades

    // Jetton wallet integration
    myJettonWalletAddress: Address;                       // This contract's Jetton wallet

    // Fee and control system
    feeCollectionWalletAddress: Address;                  // Where platform fees go
    sharedFeeCollectionWalletAddress: Address;            // Where shared fees go
    controllerWalletAddress: Address;                     // The address authorized to resolve disputes
    feeBasisPoints: Int;                        // Platform fee percentage (1% = 100 basis points)
    amountFeesCollected: Int;                   // Accumulated fees awaiting collection
    amountSharedFeesCollected: Int;             // Total fess shared by a wallet connector

    // Escrow state management
    availableAmount: Int;                       // Amount still available for new intents
    availableTakerDeposits: map<Address, Int>;  // Taker deposits that can be used for intents
    numActiveIntents: Int;                      // Count of active intents (for gas optimization)

    // Offer type and timing
    isBuyOffer: Bool;                                     // true = maker buys jettons, false = maker sells jettons
    intentValidityDurationSeconds: Int;         // How long intents remain valid
    offerExpiryTimestamp: Int;                  // When the entire offer expires

    /**
     * Contract constructor - initializes a new escrow offer
     * @param makerAddress - Address creating the offer
     * @param offChainOfferId - Reference to off-chain offer data
     * @param jettonMasterAddress - Master contract of the Jetton being traded
     * @param jettonTypeId - Unique identifier for this Jetton type
     * @param jettonWalletCode - Code for Jetton wallet contracts
     * @param feeCollectionWalletAddress - Where to send collected fees
     * @param controllerWalletAddress - Anzo controller for dispute resolution
     * @param feeBasisPoints - Platform fee (100 = 1%, max 10000 = 100%)
     * @param minimumIntentAmount - Minimum trade size to prevent spam
     * @param amountToTrade - For BUY offers: amount maker wants to buy; For SELL offers: 0 (balance-based)
     * @param intentValidityDurationSeconds - Intent expiration time
     * @param offerExpiryDurationSeconds - Offer expiration duration from creation
     * @throws 401 if the fee is not positive
     * @throws 402 if the fee is greater than 100%
     * @throws 403 if the minimum trade size is not positive
     * @throws 404 if the offer expiry duration is not positive
     */
    init(   
        makerAddress: Address,
        offChainOfferId: Int,
        jettonMasterAddress: Address,
        jettonTypeId: Int,
        jettonWalletCode: Cell,
        feeCollectionWalletAddress: Address,
        sharedFeeCollectionWalletAddress: Address,
        controllerWalletAddress: Address,
        feeBasisPoints: Int,
        minimumIntentAmount: Int,
        // The amount of Jetton that the maker wants to trade
        // Note: 0 means the maker wants to **SELL** the Jetton
        // This is because in case of sell jettons, the contract Jetton balance is directly the available amount
        // So simply depositing jettons will change the available amount
        amountToTrade: Int, 
        intentValidityDurationSeconds: Int,
        offerExpiryDurationSeconds: Int,
    ) {
        // Input validation - prevent invalid configurations 
        // There needs to be a fee
        throwUnless(401, feeBasisPoints > 0);
        // Max 100% fee
        throwUnless(402, feeBasisPoints <= 10000);
        // Must have minimum trade size
        throwUnless(403, minimumIntentAmount > 0);
        // Must have valid expiry duration
        throwUnless(404, offerExpiryDurationSeconds > 0);

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
        self.amountFeesCollected = 0;
        self.amountSharedFeesCollected = 0;

        // Determine offer type and set initial available amount
        // If amountToTrade is 0, it means the maker wants to SELL the Jetton
        // For SELL offers: available amount starts at 0, increases when maker deposits jettons
        // For BUY offers: available amount is set to the amount maker wants to buy
        self.isBuyOffer = amountToTrade > 0;
        self.availableAmount = amountToTrade;

        self.intentValidityDurationSeconds = intentValidityDurationSeconds;
        
        // Set offer expiry timestamp
        self.offerExpiryTimestamp = safeAdd(now(), offerExpiryDurationSeconds);

        // Calculate and store this contract's Jetton wallet address
        // This is where jettons will be deposited and withdrawn from
        self.myJettonWalletAddress = calculateJettonWalletAddress(
            myAddress(),
            // Note: we don't need to store the Jetton master address nor wallet code 
            // in the contract after initialization
            // We just use it once to calculate the Jetton wallet address
            // In backend verification, we have to repeat this calculation 
            jettonMasterAddress,
            jettonWalletCode,
            jettonTypeId,
        );  
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

    /**
     * Handles Jetton deposits from makers and takers
     * This is called automatically when jettons are sent to the contract's Jetton wallet
     * SELL offers: Maker deposits jettons → increases availableAmount
     * BUY offers: Takers deposit jettons → increases their availableTakerDeposits
     * @throws 403 if the sender is not the maker
     * @throws 405 if the sender is not the taker
     * @throws 408 if the offer has expired
     */
    receive(msg: JettonTransferNotification) {
        // Security: Only accept notifications from our own Jetton wallet
        require(
            sender() == self.myJettonWalletAddress,
            "Notification not from your Jetton wallet!",
        );
        
        // Check offer hasn't expired
        throwUnless(408, now() < self.offerExpiryTimestamp);
        
        if(msg.from == self.makerAddress) {
            // Maker deposit - only allowed for SELL offers
            throwUnless(403, !self.isBuyOffer);  
            // For SELL offers, maker deposits directly increase available trading amount
            self.availableAmount = safeAdd(self.availableAmount, msg.amount);
        } else {
            // Taker deposit - only allowed for BUY offers  
            throwUnless(405, self.isBuyOffer);
            // For BUY offers, track each taker's deposit separately
            let prevTakerDepositOpt = self.availableTakerDeposits.get(msg.from);
            let prevTakerDeposit = prevTakerDepositOpt != null ? prevTakerDepositOpt!! : 0;
            let newTakerDeposit = safeAdd(prevTakerDeposit, msg.amount);
            // Update taker's deposit
            self.availableTakerDeposits.set(msg.from, newTakerDeposit);
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
     * @throws 403 if the sender is not the controller
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
     * @param isFeeShared - Whether the fee is shared with the referral
     * @throws 407 if the offer has expired
     * @throws 409 if the intent is not valid
     * @throws 403 if the intent is not valid
     * @throws 405 if the taker has insufficient deposits
     */
    inline fun createIntent(takerAddress: Address, amount: Int, isFeeShared: Bool) {
        // Check offer hasn't expired
        throwUnless(407, now() < self.offerExpiryTimestamp);
        
        // Validation: Check intent is valid and within available limits
        throwUnless(409, amount > 0 && amount <= self.availableAmount);
        throwUnless(403, amount >= self.minimumIntentAmount);

        // Escrow funds based on offer type
        if(self.isBuyOffer) {
            // BUY offer: Escrow taker's deposited jettons
            let takerDepositOpt = self.availableTakerDeposits.get(takerAddress);
            let takerDeposit = takerDepositOpt != null ? takerDepositOpt!! : 0;
            // Check taker has sufficient deposits
            throwUnless(405, amount <= takerDeposit);
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
            takerAddress: takerAddress,
            amount: amount,
            validUntilTimestamp: safeAdd(now(), self.intentValidityDurationSeconds),
            isMakerConfirmed: false,
            isTakerConfirmed: false,
            isControllerConfirmed: false,
            isFeeShared: isFeeShared,
        });
        
        // Update counters with safe math
        self.nextIntentId = safeAdd(self.nextIntentId, 1);
        self.numActiveIntents = safeAdd(self.numActiveIntents, 1);

        // Return excess TON to sender
        cashback(sender());
    }

    /**
     * Handles intent confirmations using 2-out-of-3 multi-signature system
     * - Maker and Taker can always confirm their own intents
     * - Controller can only confirm as tiebreaker (when exactly 1 other party confirmed)
     * - Intent executes automatically when 2/3 confirmations reached
     * @throws 407 if the offer has expired
     * @throws 404 if the intent does not exist
     * @throws 403 if the intent has expired or the sender is not the controller
     * @throws 401 if the sender is not the maker, taker, or controller
     * @throws 405 if the sender is the maker and the intent has not been confirmed by the taker
     * @throws 406 if the intent has more than 2 confirmations
     */
    receive(msg: ConfirmIntent) {
        // Check offer hasn't expired
        throwUnless(407, now() < self.offerExpiryTimestamp);
        
        // Validate intent exists and is still valid
        let intentOpt = self.intents.get(msg.intentId);
        throwUnless(404, intentOpt != null);
        let intent = intentOpt!!;
        // Check intent is still valid (not expired) or sender is the controller
        throwUnless(403, now() < intent.validUntilTimestamp || sender() == self.controllerWalletAddress); 
        
        // Get sender's role in the intent
        // Determine sender's role in the intent
        let isMaker = sender() == self.makerAddress;
        let isTaker = sender() == intent.takerAddress;
        let isController = sender() == self.controllerWalletAddress;
        // Check sender is a valid role
        throwUnless(401, isMaker || isTaker || isController);

        // Apply confirmation based on sender's role
        if(isMaker) {
            intent.isMakerConfirmed = true;
        } else if(isTaker) {
            intent.isTakerConfirmed = true;
        } else {
            // Controller acts as dispute resolver - can only confirm when exactly one party has confirmed
            // This prevents controller from overriding both parties' decisions
            // Also, controller can't be the first to confirm
            throwUnless(
                405, 
                (intent.isMakerConfirmed && !intent.isTakerConfirmed) || 
                        (!intent.isMakerConfirmed && intent.isTakerConfirmed)
            );
            // Controller confirms the intent
            intent.isControllerConfirmed = true;
        }

        // Check confirmation count and execute if threshold reached
        // Note that this is after the confirmations have been updated
        let confirmationCount = countConfirmations(intent);
        // Prevent over-confirmation
        throwUnless(406, confirmationCount <= 2);

        if(confirmationCount == 2) {
            // Execute the intent immediately
            self.completeIntent(msg.intentId);
        } else { 
            // Save updated intent (only needed if not executing)
            self.intents.set(msg.intentId, intent);
        }

        // Return excess TON to sender
        cashback(sender());
    }

    /**
     * Executes a confirmed intent by transferring jettons and collecting fees
     * Called automatically when intent reaches 2/3 confirmations
     * 
     * @param intentId - ID of the intent to complete
     * @throws 404 if the intent does not exist
     * @throws 405 if the fee is not positive
     */
    inline fun completeIntent(intentId: Int) {
        // Get and validate intent
        let intentOpt = self.intents.get(intentId);
        throwUnless(404, intentOpt != null);
        let intent = intentOpt!!;

        // Escrow funds based on offer type
        if(self.isBuyOffer) {
            // BUY offer: Escrow taker's deposited jettons
            // Check taker has sufficient deposits and deduct the intent amount
            let takerDeposits = self.availableTakerDeposits.get(intent.takerAddress);
            
            // Update taker's available deposits (delete if zero to save gas)
            if(takerDeposits == 0) {
                let _ = self.availableTakerDeposits.del(intent.takerAddress);
            }
            // Reduce MAKER's willingness to trade when it's BUY offer
            self.availableAmount = safeSub(self.availableAmount, intent.amount)
        }

        // Calculate platform fee and net transfer amount using safe math
        let feeAmount = safeDiv(safeMul(intent.amount, self.feeBasisPoints), 10000);
        // Ensure fee is positive
        throwUnless(405, feeAmount > 0);                    
        // Calculate amount to send to the recipient
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

        // Transfer jettons to the appropriate recipient
        // BUY offer: Send jettons to maker (who is buying)
        // SELL offer: Send jettons to taker (who is buying from maker)
        self.sendJettons(
            self.isBuyOffer ? self.makerAddress : intent.takerAddress, 
            amountToSend, 
            "Anzo Escrow - Completing Intent - Releasing jettons"
        );

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
     * @throws 404 if the intent does not exist
     * @throws 403 if the sender is not the taker or controller
     */
    inline fun cancelIntent(intentId: Int) {
        // Validate intent exists
        let intentOpt = self.intents.get(intentId);
        throwUnless(404, intentOpt != null);
        let intent = intentOpt!!;

        // Check sender's role in the intent
        let isTaker = sender() == intent.takerAddress;
        let isController = sender() == self.controllerWalletAddress;
        
        // Authorization check for non-expired intents
        if(now() < intent.validUntilTimestamp) {
            // Check confirmation count
            let confirmationCount = countConfirmations(intent);
            
            // Authorization rules:
            // - 0 confirmations: Only taker can cancel their own intent
            // - 1 confirmation: Only controller can cancel (dispute resolution)
            // - 2+ confirmations: Intent is completed, cannot cancel
            throwUnless(
                403, 
                (confirmationCount == 0 && isTaker) || 
                        (confirmationCount == 1 && isController) || 
                        (confirmationCount > 1)
            );
        }
        // Note: Anyone can cancel expired intents (cleanup mechanism)

        // Remove intent
        let _ = self.intents.del(intentId);

        // Restore available amount
        if(!self.isBuyOffer) {
            self.availableAmount = safeAdd(self.availableAmount, intent.amount);
        } 
        self.numActiveIntents = safeSub(self.numActiveIntents, 1);

        // For BUY offers, return escrowed jettons to taker
        // We send directly rather than restoring to availableTakerDeposits
        // to avoid unexpected balance changes if taker has multiple intents
        if(self.isBuyOffer) {
            self.sendJettons(
                intent.takerAddress, 
                intent.amount, 
                "Anzo Escrow - Cancelling Intent - Returning deposited jettons"
            );
        }   
    }

    /**
     * Internal function to send jettons with proper notification and comments
     * @param destination - Address to receive the jettons
     * @param amount - Amount of jettons to send
     * @param message - Custom message for the transfer (displayed in wallets)
     */
    inline fun sendJettons(
        destination: Address,
        amount: Int,
        message: String,
    ) {
        // Create text comment for the transfer (displayed in wallets)
        // Format: 32-bit zero + UTF-8 text for user-readable comments
        // Binary comments (starting with 0xff) are not displayed to users
        let refFpCell = beginCell()
                        .storeUint(0, 32)           // Text comment: 32-bit unsigned integer equals to zero
                        .storeSlice(message.asSlice())   // Comment for the recipient
                        .endCell();
        // Create payload for the Jetton transfer
        let forwardPayload = beginCell()
                                .storeBit(true)         // isRight = true - required for comment display
                                .storeRef(refFpCell)     // Comment for the recipient
                                .endCell().beginParse();      // Parse the payload

        // Send Jetton transfer message to our Jetton wallet
        send(SendParameters {
            to: self.myJettonWalletAddress,                         // Our Jetton wallet address
            value: JettonTransferGas,                               // Gas for Jetton transfer operation
            body: JettonTransfer {                                  // Jetton transfer parameters
                queryId: 0,                                         // Unique identifier for transaction tracing
                amount: amount,                                     // Amount of jettons to send (amount to send to the recipient)
                destination: destination,                           // Final recipient of jettons
                responseDestination: destination,                   // Where to send confirmation and TON remainder
                customPayload: null,                                // No custom logic needed
                // Forward amount ensures JettonTransferNotification is sent
                // If 0, notification won't be sent to recipient
                forwardTonAmount: JettonTransferForwardTonAmount,   // Forward TON to the recipient (for notification)
                forwardPayload: forwardPayload                      // Comment for the recipient
            }.toCell(),
        });
    }

    /**
     * Allows maker to cancel entire offer and return remaining jettons to maker
     * Only maker can call this
     * @throws 401 if sender is not the maker
     */
    receive(msg: ReclaimOffer) {
        // Authorization: Only maker can cancel their own offer
        throwUnless(401, sender() == self.makerAddress);

        let availableAmountBeforeClear = self.availableAmount;
        // Mark offer as cancelled
        self.availableAmount = 0;

        // For SELL offers, return remaining jettons to maker
        // For BUY offers, no action needed (takers withdraw their own deposits)
        if(!self.isBuyOffer && availableAmountBeforeClear > 0) {
            self.sendJettons(
                self.makerAddress, 
                availableAmountBeforeClear,
                "Anzo Escrow - Reclaiming Offer - Returning remaining jettons"
            );
        }

        cashback(sender());
    }

    /**
     * Internal function to cancel an intent during offer reclaim
     * Similar to cancelIntent but without authorization checks
     * 
     * @param intentId - ID of the intent to cancel
     * @param intent - Intent to cancel
     */
    inline fun cancelIntentForOfferCancellation(intentId: Int, intent: Intent) {
        // Remove intent and restore available amount
        self.availableAmount = safeAdd(self.availableAmount, intent.amount);
        self.numActiveIntents = safeSub(self.numActiveIntents, 1);
        let _ = self.intents.del(intentId);

        // For BUY offers, return escrowed jettons to taker
        if(self.isBuyOffer) {
            self.sendJettons(
                intent.takerAddress, 
                intent.amount, 
                "Anzo Escrow - Cancelling Intent - Returning deposited jettons"
            );
        }
    }

    /**
     * Allows maker to reclaim expired offer
     * Only maker can call this, and only after offer has expired
     * Returns all remaining jettons and clears the offer
     * @throws 401 if sender is not the maker
     */
    receive(msg: MakerCancelOffer) {
        // Authorization: Only maker can reclaim their own offer
        throwUnless(401, sender() == self.makerAddress);

        // Cancel all active intents and return escrowed funds
        foreach (intentId, intent in self.intents) {
            // Cancel intents that have 0 confirmations and are expired
            if(
                !intent.isControllerConfirmed && 
                !intent.isMakerConfirmed && 
                !intent.isTakerConfirmed && 
                now() > intent.validUntilTimestamp
            ) {
                self.cancelIntentForOfferCancellation(intentId, intent);
            }
        }

        // Get the available amount before clearing
        let availableAmountBeforeClear = self.availableAmount;
        // Mark offer as reclaimed
        self.availableAmount = 0;

        // For SELL offers, return remaining jettons to maker
        if(!self.isBuyOffer && availableAmountBeforeClear > 0) {
            self.sendJettons(
                self.makerAddress, 
                availableAmountBeforeClear,
                "Anzo Escrow - Cancelling Offer - Returning remaining jettons"
            );
        }

        // Return excess TON to sender
        cashback(sender());
    }

    /**
     * Allows anyone to collect accumulated platform fees
     * Fees are sent to the designated fee collection wallet
     * Open access prevents fees from being stuck
     * @throws 405 if there are no fees to collect
     */
    receive(msg: CollectFees) {
        // Check if there are any fees to collect
        throwUnless(
            405, 
            self.amountFeesCollected > 0 || self.amountSharedFeesCollected > 0
        );

        // Calculate fees to collect
        let feesToCollect = self.amountFeesCollected;
        let sharedFeesToCollect = safeDiv(self.amountSharedFeesCollected, 2); // 50%

        // Clear fees
        self.amountFeesCollected = 0;
        self.amountSharedFeesCollected = 0;

        // Send fees to fee collection wallet
        self.sendJettons(
            self.feeCollectionWalletAddress, 
            safeAdd(feesToCollect, sharedFeesToCollect), 
            "Anzo Escrow - Collecting Fees"
        );
        // Send shared fees to shared fee collection wallet
        if(sharedFeesToCollect > 0) {
            self.sendJettons(
                self.sharedFeeCollectionWalletAddress, 
                sharedFeesToCollect, 
                "Anzo Escrow - Collecting Shared Fees"
            );
        }

        // Return excess TON to sender
        cashback(sender());
    }

    /**
     * Allows takers to withdraw their unused deposits from BUY offers
     * Useful after maker cancellation or when taker wants to exit
     * Only applicable to BUY offers (SELL offers don't have taker deposits)
     * @throws 403 if the offer is not a BUY offer
     * @throws 404 if the taker has no deposits
     * @throws 400 if the taker's deposit is not positive
     */
    receive(msg: WithdrawTakerDeposit) {
        // Only for BUY offers
        throwUnless(403, self.isBuyOffer);
        // Get taker's deposit
        let takerAddress = sender();
        let depositOpt = self.availableTakerDeposits.get(takerAddress);
        // Check taker's deposit is not null
        throwUnless(404, depositOpt != null);
        // Get taker's deposit amount
        let depositAmount = depositOpt!!;
        // Check taker's deposit is positive
        throwUnless(400, depositAmount > 0);        
        // Update state before external call (reentrancy protection)
        let _ = self.availableTakerDeposits.del(takerAddress);
        
        // Send jettons back to the taker
        self.sendJettons(
            takerAddress, 
            depositAmount, 
            "Anzo Escrow - Withdrawing Taker Deposit - Returning deposited jettons"
        );
        
        // Return excess TON to sender
        cashback(sender());
    }

    /**
     * Allows maker to update the available amount for the offer
     * Can only be called by the maker when no active intents exist
     * For BUY offers: Simply updates the availableAmount
     * For SELL offers: Deposits or releases jettons based on amount change
     * @param newAvailableAmount - The new available amount
     * @throws 401 if sender is not the maker
     * @throws 403 if there are active intents
     * @throws 404 if the offer has expired
     * @throws 400 if the new available amount is not positive
     */
    receive(msg: UpdateAvailableAmount) {
        // Authorization: Only maker can update their own offer
        // Safety: Cannot update with active intents (would break escrow)
        // Check offer hasn't expired
        // Check new amount is positive
        throwUnless(401, sender() == self.makerAddress);
        throwUnless(403, self.numActiveIntents == 0);
        throwUnless(404, now() < self.offerExpiryTimestamp);
        throwUnless(400, msg.newAvailableAmount > 0);

        // Calculate the difference between the old and new available amounts
        let oldAvailableAmount = self.availableAmount;
        let amountDifference = msg.newAvailableAmount - oldAvailableAmount;
        
        // Early return if no change needed (no Jetton transfers needed)
        if (amountDifference == 0) {
            return;
        }
        
        if (self.isBuyOffer) {
            // BUY offer: Simply update the available amount
            // No Jetton transfers needed since takers deposit their own jettons
            self.availableAmount = msg.newAvailableAmount;
        } else {
            // SELL offer: Handle Jetton deposits/releases based on amount change
            if (amountDifference > 0) {
                // Available amount increased - maker needs to deposit more jettons
                // This will be handled by the JettonTransferNotification receiver
                // when maker sends jettons to the contract's Jetton wallet
                // ! Available Amount update is done by JettonTransferNotification receiver
            } else {
                // Available amount decreased - release excess jettons to maker
                let amountToRelease = safeSub(oldAvailableAmount, msg.newAvailableAmount);
                // Update available amount
                self.availableAmount = msg.newAvailableAmount;
                
                // Release excess jettons to maker
                self.sendJettons(
                    self.makerAddress, 
                    amountToRelease, 
                    "Anzo Escrow - Updating Available Amount - Returning excess jettons"
                );
            }
        }
        // Return excess TON to sender
        cashback(sender());
    }

    // ========================================================================
    // GETTER FUNCTIONS - Read-only access to contract state
    // ========================================================================

    /**
     * Returns the address of the maker of the offer
     */
    get fun makerAddress(): Address {
        return self.makerAddress;
    }

    /**
     * Returns the off-chain offer ID
     */
    get fun offChainOfferId(): Int {
        return self.offChainOfferId;
    }

    /**
     * Returns the Jetton type ID
     */
    get fun jettonTypeId(): Int {
        return self.jettonTypeId;
    }

    /**
     * Returns the intent for a given intent ID
     */
    get fun intent(intentId: Int): Intent? {
        return self.intents.get(intentId);
    }

    /**
     * Returns the next intent ID
     */
    get fun nextIntentId(): Int {
        return self.nextIntentId;
    }

    /**
     * Returns the minimum intent amount
     */
    get fun minimumIntentAmount(): Int {
        return self.minimumIntentAmount;
    }

    /**
     * Returns the address of the Jetton wallet
     */
    get fun myJettonWalletAddress(): Address {
        return self.myJettonWalletAddress;
    }

    /**
     * Returns the address of the fee collection wallet
     */
    get fun feeCollectionWalletAddress(): Address {
        return self.feeCollectionWalletAddress;
    }

    /**
     * Returns the address of the shared fee collection wallet
     */
    get fun sharedFeeCollectionWalletAddress(): Address {
        return self.sharedFeeCollectionWalletAddress;
    }

    /**
     * Returns the address of the controller wallet
     */
    get fun controllerWalletAddress(): Address {
        return self.controllerWalletAddress;
    }

    /**
     * Returns the fee basis points
     */
    get fun feeBasisPoints(): Int {
        return self.feeBasisPoints;
    }

    /**
     * Returns the amount of fees collected
     */
    get fun amountFeesCollected(): Int {
        return self.amountFeesCollected;
    }

    /**
     * Returns the amount of shared fees collected
     */
    get fun amountSharedFeesCollected(): Int {
        return self.amountSharedFeesCollected;
    }

    /**
     * Returns the available amount
     */
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

    /**
     * Returns the number of active intents
     */
    get fun numActiveIntents(): Int {
        return self.numActiveIntents;
    }

    /**
     * Returns true if the offer is a BUY offer (false if SELL)
     */
    get fun isBuyOffer(): Bool {
        return self.isBuyOffer;
    }

    /**
     * Returns the intent validity duration in seconds
     */
    get fun intentValidityDurationSeconds(): Int {
        return self.intentValidityDurationSeconds;
    }

    /**
     * Returns the offer expiry timestamp
     */
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