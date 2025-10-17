import "@stdlib/common";
import "./constants";
import "./utils";

// ─────────────────────────────────────────────────────────────────────────────
// Persistent data
// ─────────────────────────────────────────────────────────────────────────────

global adminAddress: address;
global content: cell;
global jettonWalletCode: cell;
global totalSupply: int;
global isMintFrozen: int;      // 0 = mint allowed; 1 = mint frozen
global walletDeployGrams: int; // grams to send when minting to (possibly undeployed) wallet

fun loadData() {
    var ds = contract.getData().beginParse();
    totalSupply = ds.loadCoins();
    adminAddress = ds.loadAddress();
    content = ds.loadRef();
    jettonWalletCode = ds.loadRef();
    isMintFrozen = ds.loadUint(1);
    walletDeployGrams = ds.loadCoins();
}

fun saveData() {
    contract.setData(
        beginCell()
            .storeCoins(totalSupply)
            .storeAddress(adminAddress)
            .storeRef(content)
            .storeRef(jettonWalletCode)
            .storeUint(isMintFrozen, 1)
            .storeCoins(walletDeployGrams)
            .endCell()
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet derivation (StateInit & address)
// ─────────────────────────────────────────────────────────────────────────────

fun calculateJettonWalletStateInit(ownerAddress: address): cell {
    val data = beginCell()
        .storeCoins(0)                       // wallet balance
        .storeAddress(ownerAddress)          // owner
        .storeAddress(contract.getAddress()) // jetton master
        .storeRef(jettonWalletCode)          // wallet code ref (your chosen model)
        .endCell();

    return beginCell()
        .storeUint(0, 1)                            // split_depth: none
        .storeUint(0, 1)                            // special: none
        .storeUint(1, 1).storeRef(jettonWalletCode) // code present
        .storeUint(1, 1).storeRef(data)             // data present
        .storeUint(0, 1)                            // library: none
        .endCell();
}

fun calculateJettonWalletAddress(ownerAddress: address): address {
    val stateInit = calculateJettonWalletStateInit(ownerAddress);
    val stateInitHash = stateInit.hash();
    val wc: int = contract.getAddress().getWorkchain();

    // addr_std$10 anycast? wc:int8 addr:bits256
    return beginCell()
        .storeUint(0b10, 2)
        .storeUint(0, 1)
        .storeInt(wc, 8)
        .storeUint(stateInitHash, 256)
        .endCell()
        .beginParse() as address;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mint (master -> recipient wallet)
// ─────────────────────────────────────────────────────────────────────────────

fun mintTokens(
    toAddress: address,
    amount: int,
    responseAddress: address,
    forwardTonAmount: int,
    forwardPayload: slice
) {
    // Supply & amount checks
    assert(totalSupply + amount <= MAX_SUPPLY, M_ERR_MAX_SUPPLY_EXCEEDED);
    assert(amount > 0, M_ERR_INVALID_AMOUNT);

    // Forwarding safety
    assert(forwardTonAmount <= FORWARD_TON_MAX, M_ERR_FORWARD_TOO_LARGE);

    // Optimistically increase supply, will be rolled back on bounce if credit fails
    totalSupply += amount;

    // Body for recipient wallet (credit)
    val mintBody = beginCell()
        .storeUint(OP_INTERNAL_TRANSFER, 32)
        .storeUint(0, 64)                    // query_id
        .storeCoins(amount)                  // credited jettons
        .storeAddress(contract.getAddress())   // <-- was addrNone()
        .storeAddress(responseAddress)       // response_destination
        .storeCoins(forwardTonAmount)        // forward grams to response (wallet -> response)
        .storeSlice(forwardPayload)          // forward payload
        .endCell();

    // Deploy (if needed) and fund recipient wallet with walletDeployGrams
    val stateInit = calculateJettonWalletStateInit(toAddress);
    val toWalletAddress = calculateJettonWalletAddress(toAddress);

    val info = beginCell()
        .storeUint(0, 1)              // internal
        .storeUint(1, 1)              // ihr_disabled
        .storeUint(1, 1)              // bounce
        .storeUint(0, 1)              // not bounced
        .storeAddress(contract.getAddress())
        .storeAddress(toWalletAddress)
        .storeCoins(walletDeployGrams) // grams out (must be covered by incoming msg to master)
        .storeDict(null)               // other currencies
        .storeCoins(0)                 // ihr_fee
        .storeCoins(0)                 // fwd_fee
        .storeUint(0, 64)              // created_lt
        .storeUint(0, 32)              // created_at
        .endCell();

    val msg = beginCell()
        .storeSlice(info.beginParse())
        .storeUint(1, 1).storeUint(1, 1).storeRef(stateInit) // init present, by-ref
        .storeUint(1, 1).storeRef(mintBody)                  // body by-ref
        .endCell();

    sendRawMessage(msg, SEND_MODE_PAY_FEES_SEPARATELY); // pay fee from contract; works reliably
}

// ─────────────────────────────────────────────────────────────────────────────
// Inbound handler (+ bounce handling)
// ─────────────────────────────────────────────────────────────────────────────

fun onInternalMessage(inMsgValue: int, inMsg: cell, inMsgBody: slice) {
    if (inMsgBody.isEmpty()) {
        return;
    }

    // Envelope parse
    var cs = inMsg.beginParse();
    val flags = cs.loadUint(4);
    val senderAddress = cs.loadAddress();

    // Handle bounces (e.g., wallet credit failed). Revert supply if we detect our mint body.
    if ((flags & 1) != 0) {
        if (!inMsgBody.isEmpty() && inMsgBody.remainingBitsCount() >= 32) {
            // We expect the original mint credit body to start with OP_INTERNAL_TRANSFER
            val opPeek = inMsgBody.preloadUint(32);
            if (opPeek == OP_INTERNAL_TRANSFER) {
                // Parse defensively; throws if truncated
                _ = inMsgBody.loadUint(32);           // op
                val qid = inMsgBody.loadUint(64);     // query_id (we set 0)
                val amount = inMsgBody.loadCoins();   // credited jettons
                val fromAddr = inMsgBody.loadAddress(); // must be this contract
                // We could also read response_destination here if you want to track it:
                // val respAddr = inMsgBody.loadAddress();

                assert(qid == 0, M_ERR_UNKNOWN_OP); // unexpected qid => not our mint credit
                assert(fromAddr == contract.getAddress(), M_ERR_UNKNOWN_OP);

                loadData();
                assert(totalSupply >= amount, M_ERR_SUPPLY_UNDERFLOW);
                totalSupply -= amount;
                saveData();
            }
        }
        return;
    }

    loadData();

    val op = inMsgBody.loadUint(32);
    val queryId = inMsgBody.loadUint(64);

    // --- Admin: mint
    if (op == OP_MINT) {
        assert(isNoneAddress(adminAddress) == 0, M_ERR_NOT_ADMIN);
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        assert(isMintFrozen == 0, M_ERR_MINT_FROZEN);

        // Require enough incoming grams to cover outflow + buffer
        assert(inMsgValue >= walletDeployGrams + MINT_BUFFER, M_ERR_INSUFFICIENT_GAS);

        val toAddress = inMsgBody.loadAddress();
        val tokenAmount = inMsgBody.loadCoins();
        assert(tokenAmount > 0, M_ERR_INVALID_AMOUNT);

        // Use tokenAmount directly (TEP-74: amounts are in elementary units)
        var amount: int = tokenAmount; // Already in elementary units per TEP-74
        var responseAddress = senderAddress;
        var forwardTonAmount: int = DEFAULT_FORWARD_AMOUNT;
        var forwardPayload: slice = createEmptySlice();

        // Parse ref to get real user amount (minter.org compatibility)
        if (inMsgBody.remainingRefsCount() > 0) {
            val ref = inMsgBody.loadRef();
            var refSlice = ref.beginParse();

            if (refSlice.remainingBitsCount() >= 32) {
                val refOp = refSlice.preloadUint(32);

                // Check if ref contains OP_INTERNAL_TRANSFER template with real amount
                if (refOp == OP_INTERNAL_TRANSFER) {
                    _ = refSlice.loadUint(32);  // skip op
                    _ = refSlice.loadUint(64);  // skip query_id
                    val realAmount = refSlice.loadCoins(); // This is the real amount!

                    // Use real amount instead of hardcoded 20M from main body
                    amount = realAmount;
                }
            }
        }

        mintTokens(toAddress, amount, responseAddress, forwardTonAmount, forwardPayload);
        saveData();
        return;
    }

    // --- Admin: transfer admin
    if (op == OP_TRANSFER_ADMIN) {
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        adminAddress = inMsgBody.loadAddress();
        saveData();
        refundExcess(senderAddress, queryId);
        return;
    }

    // --- Admin: revoke admin (irreversible)
    if (op == OP_REVOKE_ADMIN) {
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        val confirmationCode = inMsgBody.loadUint(32);
        assert(confirmationCode == 0xDEADBEEF, M_ERR_NOT_ADMIN); // simple confirmation

        adminAddress = addrNone();
        saveData();
        refundExcess(senderAddress, queryId);
        return;
    }

    // --- Admin: change metadata content
    if (op == OP_CHANGE_CONTENT) {
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        content = inMsgBody.loadRef();
        saveData();
        refundExcess(senderAddress, queryId);
        return;
    }

    // --- Admin: set wallet code (allowed only while totalSupply == 0)
    if (op == OP_SET_WALLET_CODE) {
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        assert(totalSupply == 0, M_ERR_CODE_LOCKED);
        jettonWalletCode = inMsgBody.loadRef();
        saveData();
        refundExcess(senderAddress, queryId);
        return;
    }

    // --- Admin: set wallet deploy grams (clamped to safe range)
    if (op == OP_SET_DEPLOY_GRAMS) {
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        val v = inMsgBody.loadCoins();
        assert(v >= MIN_DEPLOY_GRAMS && v <= MAX_DEPLOY_GRAMS, M_ERR_FORWARD_TOO_LARGE);
        walletDeployGrams = v;
        saveData();
        refundExcess(senderAddress, queryId);
        return;
    }

    // --- Admin: freeze / unfreeze mint
    if (op == OP_FREEZE_MINTING) {
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        isMintFrozen = inMsgBody.loadUint(1);
        saveData();
        refundExcess(senderAddress, queryId);
        return;
    }

    // --- Admin: in-place code upgrade
    if (op == OP_UPGRADE_CODE) {
        assert(senderAddress == adminAddress, M_ERR_NOT_ADMIN);
        val newCode = inMsgBody.loadRef();
        contract.setCodePostponed(newCode);
        // refund any extra grams after scheduling the upgrade
        refundExcess(senderAddress, queryId);
        return;
    }

    // --- Burn from wallet → master
    if (op == OP_BURN) {
        assert(inMsgBody.remainingRefsCount() <= 1, M_ERR_INVALID_BURN_AMOUNT);

        val amount = inMsgBody.loadCoins();
        val owner  = inMsgBody.loadAddress();
        val resp   = inMsgBody.loadAddress();

        assert(amount > 0, M_ERR_INVALID_BURN_AMOUNT);

        val expectedWallet = calculateJettonWalletAddress(owner);
        assert(senderAddress == expectedWallet, M_ERR_UNAUTHORIZED_WALLET);

        assert(totalSupply >= amount, M_ERR_SUPPLY_UNDERFLOW);
        totalSupply -= amount;
        saveData();

        // Notify burn
        val notifBody = beginCell()
            .storeUint(OP_BURN_NOTIFICATION, 32)
            .storeUint(queryId, 64)
            .storeCoins(amount)
            .storeAddress(owner)
            .storeAddress(resp)
            .endCell();

        val info = beginCell()
            .storeUint(0, 1)          // internal
            .storeUint(1, 1)          // ihr_disabled
            .storeUint(1, 1)          // bounce
            .storeUint(0, 1)          // not bounced
            .storeAddress(contract.getAddress())
            .storeAddress(resp)
            .storeCoins(0)            // mode 64 adds remaining inbound value
            .storeDict(null)
            .storeCoins(0)
            .storeCoins(0)
            .storeUint(0, 64)
            .storeUint(0, 32)
            .endCell();

        val msg = beginCell()
            .storeSlice(info.beginParse())
            .storeUint(0, 1)                  // no init
            .storeUint(1, 1).storeRef(notifBody)
            .endCell();

        // Forward entire remaining inbound value to `resp`
        sendRawMessage(msg, SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE); // 65
        return;
    }

    // Unknown op
    throw M_ERR_UNKNOWN_OP;
}

// ─────────────────────────────────────────────────────────────────────────────
// External messages are disabled by default in Tolk
// ─────────────────────────────────────────────────────────────────────────────
fun onExternalMessage(_: slice) {
    throw 0xfffe;
}
// ─────────────────────────────────────────────────────────────────────────────
// Getters (TEP-74)
// ─────────────────────────────────────────────────────────────────────────────

get fun get_jetton_data(): (int, int, address, cell, cell) {
    loadData();
    // Per convention: mintable = -1 (true) / 0 (false)
    var mintable = 0;
    if ((isNoneAddress(adminAddress) == 0) && (isMintFrozen == 0)) {
        mintable = -1;
    }
    return (totalSupply, mintable, adminAddress, content, jettonWalletCode);
}

get fun get_wallet_code_hash(): int {
    loadData();
    return jettonWalletCode.hash();
}

get fun get_wallet_code(): cell {
    loadData();
    return jettonWalletCode;
}

get fun get_wallet_deploy_grams(): int {
    loadData();
    return walletDeployGrams;
}

get fun get_wallet_address(owner_address: address): address {
    loadData();
    return calculateJettonWalletAddress(owner_address);
}

get fun get_max_supply(): int {
    return MAX_SUPPLY;
}

get fun get_remaining_supply(): int {
    loadData();
    return MAX_SUPPLY - totalSupply;
}

get fun get_decimals(): int {
    return DECIMALS;
}

get fun get_version(): (int, int, int, cell) {
    val codeHash = contract.getCode().hash();                 // 256-bit
    val codeHashCell = beginCell().storeUint(codeHash, 256).endCell();
    return (M_VERSION_MAJOR, M_VERSION_MINOR, M_VERSION_PATCH, codeHashCell);
}

get fun get_config(): (int, int, int, int) {
    loadData();
    // returns (walletDeployGrams, mintFrozen, decimals, max_forward_ton)
    return (walletDeployGrams, isMintFrozen, DECIMALS, FORWARD_TON_MAX);
}
