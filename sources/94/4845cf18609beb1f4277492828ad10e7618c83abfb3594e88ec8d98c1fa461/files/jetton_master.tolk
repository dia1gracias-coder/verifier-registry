// Jetton Master smart contract
// TEP-74 + TEP-89 compliant
// Supports mint, burn callback, and wallet discovery

// ============================================================================
// Storage structure
// ============================================================================
// storage#_ owner:MsgAddress total_supply:Coins jetton_wallet_code:^Cell content:^Cell = Storage;
struct Storage {
    owner: address
    totalSupply: coins
    jettonWalletCode: cell
    content: cell
}

fun Storage.load() {
    return Storage.fromCell(contract.getData())
}

fun Storage.save(self) {
    contract.setData(self.toCell());
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

// Jetton Master opcodes
const MINT_OP: uint32 = 0x642b7d07
const PROVIDE_WALLET_ADDRESS_OP: uint32 = 0x2c76b973
const TAKE_WALLET_ADDRESS_OP: uint32 = 0xd1735400
const CHANGE_METADATA_OP: uint32 = 0xcb862902

// ============================================================================
// Error codes
// ============================================================================
const ERROR_NOT_OWNER: int = 702
const ERROR_NOT_ENOUGH_GAS: int = 703
const ERROR_INVALID_WALLET: int = 704
const ERROR_WRONG_OP: int = 0xFFFF

// ============================================================================
// Constants
// ============================================================================
const ONE_TON: coins = 1000000000
const MIN_DEPLOY_AMOUNT: coins = 50000000 // 0.05 TON minimum for wallet deploy
const MIN_RESPONSE_AMOUNT: coins = 10000000 // 0.01 TON minimum for response
const RESERVE_FOR_FEES: coins = 10000000 // 0.01 TON reserve for fees

// ============================================================================
// Message structures
// ============================================================================
// mint#642b7d07 query_id:uint64 amount:Coins destination:MsgAddress 
//   response_destination:MsgAddress? custom_payload:^Cell? 
//   forward_ton_amount:Coins forward_payload:^Cell? = Mint;
struct(0x642b7d07) Mint { // MINT_OP
    queryId: uint64
    amount: coins
    destination: address
    responseDestination: address?
    customPayload: cell?
    forwardTonAmount: coins
    forwardPayload: cell?
}

// provide_wallet_address#2c76b973 query_id:uint64 owner_address:MsgAddress 
//   include_address:Bool = ProvideWalletAddress;
struct(0x2c76b973) ProvideWalletAddress { // PROVIDE_WALLET_ADDRESS_OP
    queryId: uint64
    ownerAddress: address
    includeAddress: bool // ignored in response per TEP-89
}

// burn_notification#7bdd97de query_id:uint64 amount:Coins owner:MsgAddress 
//   response_address:MsgAddress? = BurnNotification;
struct(0x7bdd97de) BurnNotification { // BURN_NOTIFICATION_OP
    queryId: uint64
    amount: coins
    owner: address
    responseAddress: address?
}

// change_metadata_uri#cb862902 query_id:uint64 new_content:^Cell = ChangeMetadata;
struct(0xcb862902) ChangeMetadata { // CHANGE_METADATA_OP
    queryId: uint64
    newContent: cell
}

type IncomingMsg = Mint | ProvideWalletAddress | BurnNotification | ChangeMetadata

// ============================================================================
// Helper functions
// ============================================================================
// Calculate jetton wallet address deterministically
// Uses StateInit with owner, master, and zero balance
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
// internal_transfer#178d4519 query_id:uint64 amount:Coins from:MsgAddress 
//   response_address:MsgAddress? forward_ton_amount:Coins 
//   forward_payload:(Either ^Cell) = InternalTransfer;
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
        Mint => {
            // Only owner can mint
            assert(sender == storage.owner) throw ERROR_NOT_OWNER;

            // Calculate forward amount (for wallet deployment and notification)
            // Reserve some TON for fees, then use min(forwardTonAmount, available)
            val forwardTon = min(msg.forwardTonAmount, in.valueCoins - RESERVE_FOR_FEES);
            assert(forwardTon >= MIN_DEPLOY_AMOUNT) throw ERROR_NOT_ENOUGH_GAS;

            // Build internal_transfer message body
            val internalTransferBody = buildInternalTransferBody(
                msg.queryId,
                msg.amount,
                storage.owner,
                msg.responseDestination,
                forwardTon,
                msg.forwardPayload
            );

            // Calculate destination wallet address
            val destWallet = calculateWalletAddress(
                msg.destination,
                contract.getAddress(),
                storage.jettonWalletCode
            );

            // Send message to wallet with StateInit for auto-deploy
            val outMsg = createMessage({
                dest: AutoDeployAddress{
                    stateInit: {
                        code: storage.jettonWalletCode,
                        data: beginCell()
                            .storeAddress(msg.destination)
                            .storeAddress(contract.getAddress())
                            .storeCoins(0)
                        .endCell()
                    }
                },
                value: forwardTon,
                bounce: BounceMode.Only256BitsOfBody,
                body: internalTransferBody
            });
            outMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);

            // Update total supply
            storage.totalSupply += msg.amount;
            storage.save();
        }

        ProvideWalletAddress => {
            // TEP-89: provide_wallet_address handler
            // Must have enough TON to respond
            assert(in.valueCoins >= MIN_RESPONSE_AMOUNT) throw ERROR_NOT_ENOUGH_GAS;

            // Calculate wallet address for owner
            val walletAddr = calculateWalletAddress(
                msg.ownerAddress,
                contract.getAddress(),
                storage.jettonWalletCode
            );

            // Build TEP-89 response: take_wallet_address
            // take_wallet_address#d1735400 query_id:uint64 wallet_address:MsgAddress 
            //   owner_address:(Maybe ^Cell) = TakeWalletAddress;
            var respBody = beginCell()
                .storeUint(TAKE_WALLET_ADDRESS_OP, 32)
                .storeUint(msg.queryId, 64)
                .storeAddress(walletAddr);
            
            // Include owner address if requested (per TEP-89 spec)
            if (msg.includeAddress) {
                respBody.storeInt(1, 1)
                    .storeRef(beginCell().storeAddress(msg.ownerAddress).endCell());
            } else {
                respBody.storeInt(0, 1);
            }

            // Send response with remaining TON (but cap at reasonable amount)
            val respMsg = createMessage({
                dest: sender,
                value: min(in.valueCoins - MIN_RESPONSE_AMOUNT, MIN_RESPONSE_AMOUNT),
                bounce: BounceMode.NoBounce,
                body: respBody.endCell()
            });
            respMsg.send(SEND_MODE_IGNORE_ERRORS | SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
        }

        BurnNotification => {
            // Verify that burn notification comes from valid wallet (TEP-74)
            // Wallet address is calculated deterministically from owner address
            val expectedWalletAddr = calculateWalletAddress(
                msg.owner,
                contract.getAddress(),
                storage.jettonWalletCode
            );
            assert(sender == expectedWalletAddr) throw ERROR_INVALID_WALLET;
            
            // Update total supply (decrease)
            storage.totalSupply -= msg.amount;
            storage.save();
            
            // Return excesses if response_address is provided (TEP-74)
            if (msg.responseAddress != null && in.valueCoins > MIN_RESPONSE_AMOUNT) {
                val excess = in.valueCoins - MIN_RESPONSE_AMOUNT;
                val excessMsg = createMessage({
                    dest: msg.responseAddress,
                    value: excess,
                    bounce: BounceMode.NoBounce,
                    body: buildExcessesBody(msg.queryId)
                });
                excessMsg.send(SEND_MODE_IGNORE_ERRORS);
            }
        }

        ChangeMetadata => {
            // Only owner can change metadata
            assert(sender == storage.owner) throw ERROR_NOT_OWNER;
            
            // Update content (metadata)
            storage.content = msg.newContent;
            storage.save();
        }

        else => throw ERROR_WRONG_OP
    }
}

// ============================================================================
// Getter methods
// ============================================================================
// TEP-74: get_jetton_data() returns 
//   (total_supply, mintable, admin_address, jetton_content, jetton_wallet_code)
get fun get_jetton_data(): (coins, bool, address, cell, cell) {
    var s = Storage.load();
    return (s.totalSupply, true, s.owner, s.content, s.jettonWalletCode);
}

// TEP-89: get_wallet_address(owner_address) returns wallet_address
get fun get_wallet_address(owner: address): address {
    var s = Storage.load();
    return calculateWalletAddress(owner, contract.getAddress(), s.jettonWalletCode);
}
