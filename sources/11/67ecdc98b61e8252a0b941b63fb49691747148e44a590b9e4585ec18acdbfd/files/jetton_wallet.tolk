// Jetton Wallet smart contract
// TEP-74 + TEP-89 compliant
// Handles individual user token balances and transfers

// ============================================================================
// Storage structure
// ============================================================================
// storage#_ owner:MsgAddress jetton_master:MsgAddress balance:Coins = Storage;
struct Storage {
    owner: address
    jettonMaster: address
    balance: coins
}

fun Storage.load() {
    var ds = contract.getData().beginParse();
    return Storage{
        owner: ds.loadAddress(),
        jettonMaster: ds.loadAddress(),
        balance: ds.loadCoins()
    }
}

fun Storage.save(self) {
    contract.setData(
        beginCell()
            .storeAddress(self.owner)
            .storeAddress(self.jettonMaster)
            .storeCoins(self.balance)
        .endCell()
    );
}

// ============================================================================
// Opcodes
// ============================================================================
// Common opcodes
const TRANSFER_OP: uint32 = 0x0f8a7ea5
const TRANSFER_NOTIFICATION_OP: uint32 = 0x7362d09c
const INTERNAL_TRANSFER_OP: uint32 = 0x178d4519
const EXCESSES_OP: uint32 = 0xd53276db
const BURN_OP: uint32 = 0x595f07bc
const BURN_NOTIFICATION_OP: uint32 = 0x7bdd97de

// ============================================================================
// Error codes
// ============================================================================
const ERROR_INSUFFICIENT_BALANCE: int = 701
const ERROR_NOT_OWNER: int = 702
const ERROR_NOT_ENOUGH_GAS: int = 703
const ERROR_WRONG_OP: int = 0xFFFF

// ============================================================================
// Constants
// ============================================================================
const RESERVE_FOR_FEES: coins = 10000000 // 0.01 TON reserve for fees
const MIN_BURN_GAS: coins = 10000000 // 0.01 TON minimal gas for burn notification

// ============================================================================
// Message structures
// ============================================================================
// transfer#0f8a7ea5 query_id:uint64 amount:Coins destination:MsgAddress 
//   response_destination:MsgAddress? custom_payload:^Cell? 
//   forward_ton_amount:Coins forward_payload:^Cell? = Transfer;
struct(0x0f8a7ea5) Transfer { // TRANSFER_OP
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: cell?
}

// internal_transfer#178d4519 query_id:uint64 amount:Coins from:MsgAddress 
//   response_address:MsgAddress? forward_ton_amount:Coins 
//   forward_payload:(Either ^Cell) = InternalTransfer;
struct(0x178d4519) InternalTransfer { // INTERNAL_TRANSFER_OP
    queryId: uint64
    amount: coins
    from: address
    responseAddress: address?
    forwardTonAmount: coins
    forwardPayload: cell?
}

// burn#595f07bc query_id:uint64 amount:Coins response_destination:MsgAddress? 
//   custom_payload:^Cell? = Burn;
struct(0x595f07bc) Burn { // BURN_OP
    queryId: uint64
    amount: coins
    responseDestination: address?
    customPayload: cell?
}

type IncomingMsg = Transfer | InternalTransfer | Burn

// ============================================================================
// Helper functions
// ============================================================================
// Calculate wallet address deterministically (for auto-deploy)
fun calculateWalletAddress(owner: address, master: address, code: cell): address {
    val data = beginCell()
        .storeAddress(owner)
        .storeAddress(master)
        .storeCoins(0)
    .endCell();
    return AutoDeployAddress{
        stateInit: { code: code, data: data }
    }.calculateAddress();
}

// Build internal_transfer message body (TEP-74 compliant)
fun buildInternalTransferBody(
    queryId: uint64,
    amount: coins,
    from: address,
    responseAddress: address?,
    forwardTonAmount: coins,
    forwardPayload: cell?
): cell {
    var body = beginCell()
        .storeUint(INTERNAL_TRANSFER_OP, 32)
        .storeUint(queryId, 64)
        .storeCoins(amount)
        .storeAddress(from);
    
    if (responseAddress != null) {
        body.storeAddress(responseAddress);
    } else {
        body.storeInt(0, 2); // address_none
    }
    
    body.storeCoins(forwardTonAmount);
    
    if (forwardPayload != null) {
        body.storeInt(1, 1).storeRef(forwardPayload);
    } else {
        body.storeInt(0, 1);
    }
    
    return body.endCell();
}

// Build transfer_notification message body (TEP-74 compliant)
// transfer_notification#7362d09c query_id:uint64 amount:Coins sender:MsgAddress 
//   forward_payload:(Either ^Cell) = TransferNotification;
fun buildTransferNotificationBody(
    queryId: uint64,
    amount: coins,
    sender: address,
    forwardPayload: cell?
): cell {
    var body = beginCell()
        .storeUint(TRANSFER_NOTIFICATION_OP, 32)
        .storeUint(queryId, 64)
        .storeCoins(amount)
        .storeAddress(sender);
    
    if (forwardPayload != null) {
        body.storeInt(1, 1).storeRef(forwardPayload);
    } else {
        body.storeInt(0, 1);
    }
    
    return body.endCell();
}

// Build burn_notification message body (TEP-74 compliant)
// burn_notification#7bdd97de query_id:uint64 amount:Coins owner:MsgAddress 
//   response_address:MsgAddress? = BurnNotification;
fun buildBurnNotificationBody(
    queryId: uint64,
    amount: coins,
    owner: address,
    responseAddress: address?
): cell {
    var body = beginCell()
        .storeUint(BURN_NOTIFICATION_OP, 32)
        .storeUint(queryId, 64)
        .storeCoins(amount)
        .storeAddress(owner);
    
    if (responseAddress != null) {
        body.storeAddress(responseAddress);
    } else {
        body.storeInt(0, 2); // address_none
    }
    
    return body.endCell();
}

// Build excesses message body
// excesses#d53276db query_id:uint64 = Excesses;
fun buildExcessesBody(queryId: uint64): cell {
    return beginCell()
        .storeUint(EXCESSES_OP, 32)
        .storeUint(queryId, 64)
    .endCell();
}

// ============================================================================
// Main message handler
// ============================================================================
fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    var storage = Storage.load();
    val sender = in.senderAddress;
    val msg = lazy IncomingMsg.fromSlice(in.body);

    match (msg) {
        Transfer => {
            // Only owner can transfer
            assert(sender == storage.owner) throw ERROR_NOT_OWNER;
            assert(msg.amount <= storage.balance) throw ERROR_INSUFFICIENT_BALANCE;

            // Update balance (decrease)
            storage.balance -= msg.amount;
            storage.save();

            // Calculate forward amount (for destination wallet and notification)
            // Reserve some TON for fees, then use min(forwardTonAmount, available)
            val forwardTon = min(msg.forwardTonAmount, in.valueCoins - RESERVE_FOR_FEES);
            assert(forwardTon >= 0) throw ERROR_NOT_ENOUGH_GAS;

            // Build internal_transfer message body
            val internalTransferBody = buildInternalTransferBody(
                msg.queryId,
                msg.amount,
                storage.owner,
                msg.responseDestination,
                forwardTon,
                msg.forwardPayload
            );

            // Get wallet code (all wallets share the same code per TEP-74)
            val walletCode = contract.getCode();
            val destWallet = calculateWalletAddress(msg.destination, storage.jettonMaster, walletCode);

            // Send message to destination wallet with StateInit for auto-deploy
            val outMsg = createMessage({
                dest: AutoDeployAddress{
                    stateInit: {
                        code: walletCode,
                        data: beginCell()
                            .storeAddress(msg.destination)
                            .storeAddress(storage.jettonMaster)
                            .storeCoins(0)
                        .endCell()
                    }
                },
                value: forwardTon,
                bounce: BounceMode.Only256BitsOfBody,
                body: internalTransferBody
            });
            outMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

            // Return excess to response_destination if provided
            if (msg.responseDestination != null) {
                val excess = in.valueCoins - forwardTon - RESERVE_FOR_FEES;
                if (excess > 0) {
                    val excessMsg = createMessage({
                        dest: msg.responseDestination,
                        value: excess,
                        bounce: BounceMode.NoBounce,
                        body: buildExcessesBody(msg.queryId)
                    });
                    excessMsg.send(0);
                }
            }
        }

        InternalTransfer => {
            // Update balance (increase)
            storage.balance += msg.amount;
            storage.save();

            // Send transfer_notification to owner if forward_ton_amount > 0 (TEP-74)
            // Use available balance after storage operations, but reserve some for fees
            if (msg.forwardTonAmount > 0) {
                val reserveForFees = RESERVE_FOR_FEES;
                var availableForForward: coins;
                if (in.valueCoins > reserveForFees) {
                    availableForForward = in.valueCoins - reserveForFees;
                } else {
                    availableForForward = 0;
                }
                val forwardTon = min(msg.forwardTonAmount, availableForForward);
                
                if (forwardTon > 0) {
                    val notifyBody = buildTransferNotificationBody(
                        msg.queryId,
                        msg.amount,
                        msg.from,
                        msg.forwardPayload
                    );

                    val notify = createMessage({
                        dest: storage.owner,
                        value: forwardTon,
                        bounce: BounceMode.NoBounce,
                        body: notifyBody
                    });
                    notify.send(SEND_MODE_PAY_FEES_SEPARATELY);
                }
            }
        }

        Burn => {
            // Only owner can burn
            assert(sender == storage.owner) throw ERROR_NOT_OWNER;
            assert(msg.amount <= storage.balance) throw ERROR_INSUFFICIENT_BALANCE;

            // Update balance (decrease)
            storage.balance -= msg.amount;
            storage.save();

            // Build burn_notification message body
            val burnNotifyBody = buildBurnNotificationBody(
                msg.queryId,
                msg.amount,
                storage.owner,
                msg.responseDestination
            );
            
            // Send burn_notification to master (TEP-74)
            val burnNotify = createMessage({
                dest: storage.jettonMaster,
                value: MIN_BURN_GAS,
                bounce: BounceMode.Only256BitsOfBody,
                body: burnNotifyBody
            });
            burnNotify.send(0);

            // Return excess to response_destination if provided
            if (msg.responseDestination != null && in.valueCoins > MIN_BURN_GAS) {
                val excess = in.valueCoins - MIN_BURN_GAS;
                val excessMsg = createMessage({
                    dest: msg.responseDestination,
                    value: excess,
                    bounce: BounceMode.NoBounce,
                    body: buildExcessesBody(msg.queryId)
                });
                excessMsg.send(0);
            }
        }

        else => throw ERROR_WRONG_OP
    }
}

// ============================================================================
// Getter methods
// ============================================================================
// TEP-74: get_wallet_data() returns (balance, owner, jetton_master)
get fun get_wallet_data(): (coins, address, address) {
    var s = Storage.load();
    return (s.balance, s.owner, s.jettonMaster);
}
