import "@stdlib/gas-payments"

tolk 1.0

@pure
fun exit_low_bid(): int
                asm "1000 PUSHINT";
@pure
fun exit_not_cancel(): int
             asm "1004 PUSHINT";
@pure
fun exit_auction_end(): int
            asm "1005 PUSHINT";
@pure
fun exit_low_amount(): int
             asm "1008 PUSHINT";
@pure
fun exit_cant_cancel_bid(): int
        asm "1009 PUSHINT";
@pure
fun exit_cant_stop_time(): int
         asm "1010 PUSHINT";
@pure
fun exit_bad_mode(): int
               asm "1012 PUSHINT";
@pure
fun exit_last_bid_too_close(): int
     asm "1013 PUSHINT";
@pure
fun exit_its_too_long_auc(): int
        asm "1014 PUSHINT";

const OP_FINISH_AUCTION = 0xf373ace5  // stringCrc32("finish_auction")
const OP_CANCEL_AUCTION = 0xb820e9c2  // stringCrc32("cancel_auction")
const OP_PROCESS_TON_BID = 0x37fe7689 // stringCrc32("process_ton_bid")
const OP_DEPLOY_AUCTION = 0x9af07447  // stringCrc32("deploy_auction")

const TON_FOR_NFT_PROCESS = 100000000 // 0.1 TON
const MIN_BALANCE_FOR_OPERATION = 50000000 // 0.05 TON

global is_end: int           // end auction or not
global mp_addr: address      // the address of the marketplace from which the contract is deployed
global is_created_at: int    // timestamp of created auction
global entity_id: int        // entity id for indexing
global is_canceled: int      // auction was cancelled by owner

global fees_cell: cell
global constant_cell: cell

global min_bid: int          // minimal bid
global max_bid: int          // maximum bid
global min_step: int         // minimum step (can be 0)
global last_member: address  // last member address
global last_bid: int         // last bid amount
global last_bid_at: int      // timestamp of last bid
global last_query_id: int    // last processed query id
global end_time: int         // unix end time
global step_time: int        // by how much the time increases with the new bid (e.g. 30)

global nft_owner: address    // nft owner address (receives money from auction)

@inline
fun math_get_percent(a: int, percent: int, factor: int): int {
    if (factor == 0) {
        return 0;
    } else {
        return mulDivFloor(a, percent, factor);
    }
}

@inline_ref
fun packData() {
    contract.setData(
        beginCell()
            .storeInt(is_end, 1)
            .storeInt(is_canceled, 1)
            .storeAddress(last_member)
            .storeCoins(last_bid)
            .storeUint(last_bid_at, 32)
            .storeUint(end_time, 32)
            .storeAddress(nft_owner)
            .storeUint(last_query_id, 64)
            .storeRef(fees_cell)
            .storeRef(constant_cell)
            .endCell()
    );
}

@inline_ref
fun initData() {
    var ds: slice = contract.getData().beginParse();
    is_end = ds.loadInt(1);
    is_canceled = ds.loadInt(1);
    last_member = ds.loadAddress();
    last_bid = ds.loadCoins();
    last_bid_at = ds.loadUint(32);
    end_time = ds.loadUint(32);
    nft_owner = ds.loadAddress();
    last_query_id = ds.loadUint(64);

    fees_cell = ds.loadRef();
    constant_cell = ds.loadRef();
    var constants: slice = constant_cell.beginParse();
    mp_addr = constants.loadAddress();
    min_bid = constants.loadCoins();
    max_bid = constants.loadCoins();
    min_step = constants.loadUint(7);
    step_time = constants.loadUint(17);
    is_created_at = constants.loadUint(32);
    entity_id = constants.loadUint(64);
}

@inline_ref
fun getFeesAddresses(): (address, address, int, int, int, int) {
    var fees: slice = fees_cell.beginParse();
    var mpFeeAddr: address = fees.loadAddress();
    var royaltyFeeAddr: address = fees.loadAddress();
    var mpFeeFactor: int = fees.loadUint(32);
    var mpFeeBase: int = fees.loadUint(32);
    var royaltyFeeFactor: int = fees.loadUint(32);
    var royaltyFeeBase: int = fees.loadUint(32);
    return (
        mpFeeAddr,
        royaltyFeeAddr,
        mpFeeFactor,
        mpFeeBase,
        royaltyFeeFactor,
        royaltyFeeBase
    );
}

@inline_ref
fun sendRemainder() {
    var msg: builder = beginCell()
        .storeUint(0x10, 6) // nobounce
        .storeAddress(nft_owner)
        .storeCoins(0)
        .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1);
    sendRawMessage(msg.endCell(), 128 + 2); // carry all balance + ignore errors
}

@inline_ref
fun handle_cancel() {
    sendRemainder();
    is_end = -1;
    is_canceled = -1;
    packData();
}

@inline_ref
fun sendFunds(toAddress: address, amount: int) {
    if (amount <= 0) {
        return;
    }
    var transfer: builder = beginCell()
        .storeUint(0x10, 6) // nobounce
        .storeAddress(toAddress)
        .storeCoins(amount)
        .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1);
    sendRawMessage(transfer.endCell(), 2); // pay fees separately
}

@inline
fun checkOkBalance(myBalance: int) {
    assert(!(myBalance < MIN_BALANCE_FOR_OPERATION)) throw exit_low_bid();
    acceptExternalMessage();
}

@inline_ref
fun handle_end_auction(senderAddr: address, fromExternal: int, queryId: int) {
    if (last_bid == 0) {
        if (fromExternal != 0) {
            var [myBalance: int, _] = contract.getOriginalBalanceWithExtraCurrencies();
            checkOkBalance(myBalance);
        }

        handle_cancel();
        return;
    }

    var (
        mpFeeAddr,
        royaltyFeeAddr,
        mpFeeFactor,
        mpFeeBase,
        royaltyFeeFactor,
        royaltyFeeBase
    ) = getFeesAddresses();

    var [myBalance: int, _] = contract.getOriginalBalanceWithExtraCurrencies();
    var lastBidAvailableProfit: int = min(last_bid, myBalance);
    assert(lastBidAvailableProfit > 0) throw exit_low_amount();

    var mpFee: int = math_get_percent(lastBidAvailableProfit, mpFeeFactor, mpFeeBase);
    var royaltyFee: int = math_get_percent(lastBidAvailableProfit, royaltyFeeFactor, royaltyFeeBase);
    var profit: int = lastBidAvailableProfit - mpFee - royaltyFee;

    if (fromExternal != 0) {
        checkOkBalance(profit);
    }

    if (mpFee > 0) {
        sendFunds(mpFeeAddr, mpFee);
    }

    if (royaltyFee > 0) {
        sendFunds(royaltyFeeAddr, royaltyFee);
    }

    sendRemainder();
    is_end = -1;
    is_canceled = 0;
    end_time = blockchain.now();
    packData();
}

@inline_ref
fun returnLastBid(myBalance: int) {
    if (last_bid <= 0) {
        return;
    }
    var magicGasPrice: int = calculateGasFee(0, 11169);
    var returnBidAmount: int = last_bid - magicGasPrice;
    if (returnBidAmount > (myBalance - 10000000)) {
        // - 0.01 TON
        returnBidAmount = myBalance - 10000000;
    }
    if (returnBidAmount > 0) {
        var returnPrevBid: builder = beginCell()
            .storeUint(0x18, 6) // bounce
            .storeAddress(last_member)
            .storeCoins(returnBidAmount)
            .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .storeUint(0, 32)
            .storeSlice("Your bid has been outbid by another user");

        sendRawMessage(returnPrevBid.endCell(), 2);
    }
}

fun getNextMinBid(): int {
    return max(
        last_bid + 100000000, // 0.1 ton
        math_get_percent(last_bid, 100 + min_step, 100)
    );
}

@inline_ref
fun processNewBid(queryId: int, senderAddr: address, bidValue: int, tonValue: int, myBalance: int) {
    // No activation check for offchain - always active

    if ((is_end != 0) | (blockchain.now() >= end_time)) {
        throw exit_auction_end();
        return;
    }

    // auction larger than 20 days not allowed
    var duration: int = end_time - blockchain.now();
    assert(!(duration > 60 * 60 * 24 * 20)) throw exit_its_too_long_auc();

    // max bid buy
    if ((bidValue >= max_bid) & (max_bid > 0)) {
        assert(!(tonValue < max_bid)) throw exit_low_amount();

        returnLastBid(myBalance);
        last_member = senderAddr;
        last_bid = max_bid;
        last_bid_at = blockchain.now();
        last_query_id = queryId;
        handle_end_auction(senderAddr, 0, queryId);
        return;
    }

    // prevent bid at last second
    if ((end_time - step_time) < blockchain.now()) {
        end_time += step_time;
    }

    if (!last_bid) {
        assert(!(bidValue < min_bid)) throw exit_low_bid();
        last_bid = bidValue;
        last_member = senderAddr;
        last_bid_at = blockchain.now();
        last_query_id = queryId;
        packData();
        return;
    }

    var newMinBid: int = getNextMinBid();
    if (bidValue < newMinBid) {
        throw exit_low_bid();
        return;
    }

    returnLastBid(myBalance);

    last_member = senderAddr;
    last_bid = bidValue;
    last_bid_at = blockchain.now();
    last_query_id = queryId;

    packData();
}

fun onInternalMessage(myBalance: int, msgValue: int, inMsgCell: cell, inMsgBody: slice) {
    var cs: slice = inMsgCell.beginParse();
    assert(!(cs.loadUint(4) & 1)) throw 0;

    var senderAddr: address = cs.loadAddress();
    initData();

    var op: int = 0;
    var queryId: int = 0;
    if (inMsgBody.isEmpty() == false) {
        op = inMsgBody.loadUint(32);
        if (op != 0) {
            queryId = inMsgBody.loadUint(64);
        }
    }

    if (op == 555) {
        // Emergency recovery - only when ended or from marketplace
        assert((is_end != 0)) throw exit_not_cancel();
        assert(senderAddr.bitsEqual(mp_addr)) throw 403;
        // way to fix unexpected troubles with auction contract
        var msg = inMsgBody.loadRef().beginParse();
        var mode = msg.loadUint(8);
        assert(!(mode & 32)) throw exit_bad_mode();

        var tenMin: int = 10 * 60;
        assert(!((blockchain.now() > (end_time - tenMin)) & (blockchain.now() < (end_time + tenMin)))) throw exit_last_bid_too_close();
        if (last_bid_at != 0) {
            assert(!((blockchain.now() > (last_bid_at - tenMin)) & (blockchain.now() < (last_bid_at + tenMin)))) throw exit_last_bid_too_close();
        }

        sendRawMessage(msg.loadRef(), mode);
        if (is_end == 0) {
            is_end = -1;
            packData();
        }
        return;
    }

    if (op == OP_CANCEL_AUCTION) {
        // cancel command, return funds if no bid yet
        assert(!(blockchain.now() >= end_time)) throw exit_auction_end(); // after timeout can't cancel
        assert(!(is_end != 0)) throw exit_auction_end(); // already canceled/ended
        assert(!(last_bid > 0)) throw exit_cant_cancel_bid(); // can't cancel if someone already placed a bid
        assert(senderAddr.bitsEqual(nft_owner) | senderAddr.bitsEqual(mp_addr)) throw 403;
        handle_cancel();
        return;
    }

    if (op == OP_FINISH_AUCTION) {
        // stop auction
        assert(!(is_end != 0)) throw exit_auction_end(); // end = true mean this action already executed
        assert(!(msgValue < TON_FOR_NFT_PROCESS)) throw exit_low_amount();
        assert(!(blockchain.now() < end_time)) throw exit_cant_stop_time(); // can't end auction in progress, only after end time
        assert(senderAddr.bitsEqual(nft_owner) | senderAddr.bitsEqual(mp_addr) | senderAddr.bitsEqual(last_member)) throw 403;
        handle_end_auction(senderAddr, 0, queryId);
        return;
    }

    if (op == OP_DEPLOY_AUCTION) {
        // just accept coins
        return;
    }

    // bid process
    if ((op == 0) | (op == OP_PROCESS_TON_BID)) {
        processNewBid(queryId, senderAddr, msgValue, msgValue, myBalance);
        return;
    }

    throw 0xffff;
}

fun onExternalMessage(inMsg: slice) {
    initData();

    var op: int = inMsg.loadUint(32);
    var queryId: int = inMsg.loadUint(64);

    if (op == OP_FINISH_AUCTION) {
        assert(!(is_end != 0)) throw exit_auction_end(); // end = true mean this action already executed
        assert(!(blockchain.now() < end_time)) throw exit_cant_stop_time(); // can't end auction in progress, only after end time
        handle_end_auction(nft_owner, -1, queryId);
        return;
    }

    throw 0xffff;
}

get fun get_auction_data(): (int, int, address, address, int, address, int, address, int, int, address, int, int, int, int, int, int, int, int, int) {
    initData();

    var (
        mpFeeAddr,
        royaltyFeeAddr,
        mpFeeFactor,
        mpFeeBase,
        royaltyFeeFactor,
        royaltyFeeBase
    ) = getFeesAddresses();

    var currentMinBid = min_bid;
    if (last_bid > 0) {
        currentMinBid = getNextMinBid();
    }

    return (
        is_end,
        end_time,
        mp_addr,
        nft_owner,
        last_bid,
        last_member,
        min_step,
        mpFeeAddr,
        mpFeeFactor,
        mpFeeBase,
        royaltyFeeAddr,
        royaltyFeeFactor,
        royaltyFeeBase,
        max_bid,
        currentMinBid,
        is_created_at,
        last_bid_at,
        is_canceled,
        step_time,
        entity_id
    );
}