import "@stdlib/ownable";
import "./impl/message.tact";

struct TactJettonWalletStateInit {
    balance: Int as coins = 0;
    owner: Address;
    minter: Address;
}

struct SendJettonsParams {
    queryId: Int;
    forwardedTonAmount: Int as coins;
    tonValue: Int as coins;
    receiver: Address;
    amount: Int;
    forwardPayload: Slice;
    customPayload: Cell?;
}

/**
 * Maximum allowed size for custom payload cell in bits
 */
const MAX_CUSTOM_PAYLOAD_BITS: Int = 1024; // 128 bytes

/**
 * Verify that the custom payload cell size is within acceptable limits - PRODUCTION VERSION
 * @param payload The custom payload cell to verify
 * @return Bool indicating if the payload is valid
 */
inline fun verifyCustomPayloadSize(payload: Cell?): Bool {
    if (payload == null) {
        return true;
    }
    
    // SECURITY IMPLEMENTATION: Full payload validation
    let maxDepth: Int = 10; // Reasonable depth limit for security
    let computedSize = payload.computeDataSize(maxDepth);
    
    // Validate data size (bits)
    require(computedSize.bits <= MAX_CUSTOM_PAYLOAD_BITS, "Payload data size exceeds limit");
    
    // Validate number of cell references (prevent cell bomb attacks)
    require(computedSize.cells <= 16, "Payload cell count exceeds limit");
    
    return true;
}


// Contract for distributing jettons in batches
contract BatchDistribute with Ownable {
    myJettonAmount: Int as coins = 0;
    jettonMasterAddress: Address;
    jettonWalletCode: Cell;
    owner: Address;
    myJettonWalletAddress: Address; // Cached for gas efficiency
    maxBatchSize: Int = 100; // Dynamic batch size limit

    distributors: map<Address, Bool> = emptyMap();
    emergencyOperators: map<Address, Bool> = emptyMap();

    init(jettonMasterAddress: Address, jettonWalletCode: Cell) {
        self.owner = sender();
        self.jettonMasterAddress = jettonMasterAddress;
        self.jettonWalletCode = jettonWalletCode;
        // Cache Jetton wallet address for gas efficiency
        let initData = TactJettonWalletStateInit { owner: myAddress(), minter: jettonMasterAddress }.toCell();
        self.myJettonWalletAddress = contractAddress(StateInit { code: jettonWalletCode, data: initData });
    }

    inline fun getTactJettonWalletStateInit(owner: Address): Cell {
        return TactJettonWalletStateInit {
            owner,
            minter: self.jettonMasterAddress,
        }.toCell();
    }

    inline fun calculateJettonWalletAddress(owner: Address): Address {
        let initData = self.getTactJettonWalletStateInit(owner);
        return contractAddress(StateInit { code: self.jettonWalletCode, data: initData });
    }

    // Empty receiver for the deployment,
    // which expects the `null` message body
    receive() {
        // Forward the remaining value in the
        // incoming message back to the sender
        cashback(sender());
    }

    /**
     * Helper function to safely get boolean from map
     */
    inline fun getBoolFromMap(sourceMap: map<Address, Bool>, key: Address): Bool {
        let maybeValue: Bool? = sourceMap.get(key);
        return (maybeValue != null) ? maybeValue!! : false;
    }

    /**
     * Validate that caller is a distributor
     */
    inline fun requireDistributor() {
        let isDistributor: Bool = self.getBoolFromMap(self.distributors, sender());
        require(isDistributor, "Not authorized as distributor");
    }

    /**
     * Validate that caller is an emergency operator
     */
    inline fun requireEmergencyOperator() {
        let isOperator: Bool = self.getBoolFromMap(self.emergencyOperators, sender());
        require(isOperator, "Not authorized as emergency operator");
    }

    // ======= HANDLE RECEIVE JETTONS ======
    receive(msg: JettonNotification) {
        // Use cached address for gas efficiency
        require(
            sender() == self.myJettonWalletAddress,
            "Incorrect sender",
        );

        // Overflow protection for incoming jettons
        let maxSafeBalance: Int = pow(2, 120) - 1;
        require(
            self.myJettonAmount <= (maxSafeBalance - msg.amount),
            "Balance overflow protection"
        );

        self.myJettonAmount += msg.amount;

        // Forward excesses
        self.forward(msg.sender, null, false, null);
    }

    // ====== SEND JETTONS ======
    fun sendJettonsExtended(params: SendJettonsParams) {
        // Validate custom payload size if present
        require(verifyCustomPayloadSize(params.customPayload), "Custom payload size exceeds maximum limit");
        
        // Use cached address for gas efficiency
        message(MessageParameters {
            to: self.myJettonWalletAddress,
            value: params.tonValue,
            body: JettonTransfer {
                queryId: params.queryId,
                amount: params.amount,
                destination: params.receiver,
                responseDestination: myAddress(),
                customPayload: params.customPayload,
                forwardTonAmount: params.forwardedTonAmount,
                forwardPayload: params.forwardPayload,
            }.toCell(),
            mode: SendDefaultMode,
        });
    }

    get fun balance(): Int {
        return self.myJettonAmount;
    }

    inline fun safeSubBalance(amount: Int) {
        require(amount > 0, "Subtraction amount must be positive");
        require(self.myJettonAmount >= amount, "Insufficient balance");
        self.myJettonAmount -= amount;
    }

    receive(msg: BatchJettonTransfer) {
        self.requireDistributor();
        let recipients = msg.recipients;

        let recipientsLength: Int = 0;
        let totalAmount: Int = 0;
        let maxSafeAmount: Int = pow(2, 120) - 1;

        // Validate recipients and calculate totals with overflow protection
        foreach (key, value in recipients) {
            recipientsLength += 1;
            
            // Validate individual transfer parameters
            require(value.amount > 0, "Transfer amount must be positive");
            require(value.forwardTonAmount >= ton("0.001"), "Forward TON amount must be at least 0.001 TON");
            require(value.tonValue > 0, "TON value must be positive");
            require(verifyCustomPayloadSize(value.customPayload), "Custom payload size exceeds limit");
            
            // Overflow protection for total amount
            require(totalAmount <= (maxSafeAmount - value.amount), "Total amount overflow protection");
            totalAmount += value.amount;
        }

        // Dynamic batch size validation
        require(
            recipientsLength <= self.maxBatchSize,
            "Batch size exceeds maximum limit",
        );
        require(
            totalAmount <= self.myJettonAmount,
            "Not enough funds to withdraw",
        );

        // Minimum gas check for security
        let minRequiredGas: Int = recipientsLength * ton("0.05"); // 0.05 TON per transfer minimum
        require(
            context().value >= minRequiredGas,
            "Insufficient TON for gas fees",
        );

        let forwardPayload = beginCell().storeMaybeRef(null).asSlice();

        // Send individual transfers using cached address
        let transferIndex: Int = 0;
        foreach (key, value in recipients) {
            transferIndex += 1;
            let isLastTransfer: Bool = (transferIndex == recipientsLength);
            
            message(MessageParameters {
                to: self.myJettonWalletAddress,
                value: isLastTransfer ? 0 : value.tonValue,
                mode: isLastTransfer ? (SendRemainingValue | SendIgnoreErrors) : SendDefaultMode,
                body: JettonTransfer {
                    queryId: key,
                    amount: value.amount,
                    destination: value.destination,
                    responseDestination: sender(), // Return excesses to original sender
                    customPayload: value.customPayload,
                    forwardTonAmount: value.forwardTonAmount,
                    forwardPayload,
                }.toCell(),
            });
        }
        self.safeSubBalance(totalAmount);
    }
    // ====== END SEND JETTONS ======

    // ====== HANDLE EMERGENCY JETTON WITHDRAWAL ======
    receive(msg: EmergencyJettonWithdraw) {
        self.requireEmergencyOperator();

        require(
            msg.amount <= self.myJettonAmount,
            "Not enough funds to withdraw",
        );

        // Minimum gas check
        require(
            context().value >= ton("0.1"),
            "Insufficient TON for gas fees",
        );

        self.safeSubBalance(msg.amount);

        let jettonTransferPayload = beginCell().storeUint(239, 32).storeUint(0, 32).asSlice();

        // Use remaining value for emergency withdrawal
        message(MessageParameters {
            to: self.myJettonWalletAddress,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: JettonTransfer {
                queryId: msg.queryId,
                amount: msg.amount,
                destination: msg.to,
                responseDestination: sender(), // Return excesses to original sender
                customPayload: msg.customPayload,
                forwardTonAmount: msg.forwardTonAmount,
                forwardPayload: jettonTransferPayload,
            }.toCell(),
        });
    }
    // ====== END HANDLE EMERGENCY JETTON WITHDRAWAL ======

    // Add or remove distributor
    receive(msg: AddDistributor) {
        self.requireOwner();
        let distributor: Address = msg.distributor;
        self.distributors.set(distributor, true);

        cashback(sender());
    }

    /**
     * Remove distributor
     */
    receive(msg: RemoveDistributor) {
        self.requireOwner();
        let distributor: Address = msg.distributor;
        self.distributors.set(distributor, false);

        cashback(sender());
    }

    /**
     * Add emergency operator
     */
    receive(msg: AddEmergencyOperator) {
        self.requireOwner();
        let operator: Address = msg.operator;
        self.emergencyOperators.set(operator, true);

        cashback(sender());
    }

    /**
     * Remove emergency operator
     */
    receive(msg: RemoveEmergencyOperator) {
        self.requireOwner();
        let operator: Address = msg.operator;
        self.emergencyOperators.set(operator, false);

        cashback(sender());
    }

    /**
     * Update max batch size (Owner only)
     */
    receive(msg: UpdateMaxBatchSize) {
        self.requireOwner();
        require(msg.newMaxBatchSize > 0 && msg.newMaxBatchSize <= 1000, "Invalid batch size");
        self.maxBatchSize = msg.newMaxBatchSize;

        cashback(sender());
    }

    /**
     * Sync internal Jetton balance with actual value (Owner only)
     */
    receive(msg: SyncJettonBalance) {
        self.requireOwner();
        require(msg.newBalance >= 0, "Balance cannot be negative");
        self.myJettonAmount = msg.newBalance;

        cashback(sender());
    }

    get fun isDistributor(address: Address): Bool {
        return self.getBoolFromMap(self.distributors, address);
    }

    get fun isEmergencyOperator(address: Address): Bool {
        return self.getBoolFromMap(self.emergencyOperators, address);
    }

    get fun getMaxBatchSize(): Int {
        return self.maxBatchSize;
    }

    get fun getMyJettonWalletAddress(): Address {
        return self.myJettonWalletAddress;
    }







    // ====== HANDLE BOUNCED MESSAGES ======
    /**
     * Handle bounced Jetton transfer messages with enhanced security validation
     * Restores the contract's balance when Jetton transfers fail
     * 
     * SECURITY NOTE: In TON, bounced messages come from the original destination
     * that failed to process the message, not from our Jetton wallet.
     * We need to validate that this is indeed a bounce of our own transfer.
     */
    bounced(msg: bounced<JettonTransferInternal>) {
        // SECURITY FIX: Verify this is a bounce from a legitimate Jetton wallet
        // The bounced message sender should be a Jetton wallet we sent to
        // We can validate this by checking if it matches our Jetton wallet address
        // or by maintaining a mapping of expected bounce sources
        
        // For maximum security, we only accept bounces from our own Jetton wallet
        // since BatchDistribute only sends to its own Jetton wallet for redistribution
        require(sender() == self.myJettonWalletAddress, "Invalid bounce source");
        
        // Additional security: Verify the message structure is valid
        require(msg.amount > 0, "Invalid bounced amount");
        
        // Overflow protection: Check balance won't exceed safe limits
        let maxSafeBalance: Int = pow(2, 120) - 1;
        require(
            self.myJettonAmount <= (maxSafeBalance - msg.amount), 
            "Balance overflow protection"
        );
        
        // Restore the balance only for legitimate bounced transfers
        self.myJettonAmount += msg.amount;
        
        // Log the bounce for monitoring (in production, emit an event)
        // This helps track failed transfers for debugging
    }
}
