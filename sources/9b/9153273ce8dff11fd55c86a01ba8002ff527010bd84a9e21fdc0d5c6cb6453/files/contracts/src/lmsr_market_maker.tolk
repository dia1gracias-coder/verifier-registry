/// LMSR Market Maker Contract
/// Automated market maker implementing the Logarithmic Market Scoring Rule
/// for pricing outcome tokens in the TON Prediction Market protocol.

import "types"
import "fixed_math"

// ─── Op-codes ───────────────────────────────────────────────────────────────

const OP_INIT_MARKET: int = 0x10;
const OP_TRADE: int = 0x11;
const OP_SELL_TRADE: int = 0x12;
const OP_PAUSE: int = 0x13;
const OP_RESUME: int = 0x14;
const OP_CLOSE: int = 0x15;
const OP_CHANGE_FEE: int = 0x16;
const OP_CHANGE_FUNDING: int = 0x17;
const OP_WITHDRAW_FEES: int = 0x18;
const OP_MM_TRANSFER_NOTIFICATION: int = 0x7362d09c;

// ─── Constants ──────────────────────────────────────────────────────────────

/// Fee range denominator: 10^18
const FEE_RANGE: int = 1000000000000000000;

/// Market stages
const STAGE_RUNNING: int = 0;
const STAGE_PAUSED: int = 1;
const STAGE_CLOSED: int = 2;

// ─── Error codes ────────────────────────────────────────────────────────────

enum MarketErrors {
    NotOwner = 300
    InvalidMessage = 0xFFFF
    MarketAlreadyInitialized = 301
    ZeroFunding = 302
    MarketNotRunning = 303
    MarketNotPaused = 304
    MarketClosed = 305
    InvalidTradeAmounts = 306
    CollateralLimitExceeded = 307
    InsufficientCollateral = 308
    ZeroFundingChange = 309
    InsufficientGas = 310
}

// ─── Storage ────────────────────────────────────────────────────────────────

/// Market configuration stored in a separate cell reference
struct MarketConfig {
    conditionRegistry: address
    collateralToken: address
    jettonWallet: address
    conditionIds: cell                      // serialized array of condition_id (uint256)
    outcomeSlotCounts: cell                 // serialized array of uint8 per condition
}

/// Market state data stored in a separate cell reference
struct MarketState {
    positionBalances: map<uint32, int128>   // atomic_index → balance (can be negative for sells)
    positionIds: map<uint32, uint256>       // atomic_index → position_id cache
    accumulatedFees: uint128
}

struct MarketStorage {
    owner: address
    atomicOutcomeSlotCount: uint32
    funding: uint128                        // LMSR b parameter
    fee: uint64                             // fee rate (0 to FEE_RANGE)
    stage: uint8                            // 0=Running, 1=Paused, 2=Closed
    config: Cell<MarketConfig>
    state: Cell<MarketState>
}

fun MarketStorage.load(): MarketStorage {
    return MarketStorage.fromCell(contract.getData());
}

fun MarketStorage.save(self) {
    contract.setData(self.toCell());
}

// ─── Messages ───────────────────────────────────────────────────────────────

struct (0x00000013) Pause {
    queryId: uint64
}

struct (0x00000014) Resume {
    queryId: uint64
}

struct (0x00000015) Close {
    queryId: uint64
}

struct (0x00000016) ChangeFee {
    queryId: uint64
    newFee: uint64
}

struct (0x00000017) ChangeFunding {
    queryId: uint64
    fundingChange: int128
}

struct (0x00000018) WithdrawFees {
    queryId: uint64
}

struct (0x00000012) SellTrade {
    queryId: uint64
    outcomeTokenAmounts: cell
    minCollateralReturn: coins
}

// ─── Contract definition ────────────────────────────────────────────────────

contract LmsrMarketMaker {
    author: "Hossein Boustani"
    version: "0.1.0"
    description: "LMSR Market Maker for TON Prediction Market - automated pricing and trade execution"
    storage: MarketStorage
    incomingMessages: AllowedMarketMessage
}

type AllowedMarketMessage = Pause | Resume | Close | ChangeFee | ChangeFunding | WithdrawFees | SellTrade

// ─── Entry points ───────────────────────────────────────────────────────────

fun onInternalMessage(in: InMessage) {
    // Gas validation - reject if insufficient TON attached
    assert(in.valueCoins >= 200000000) throw MarketErrors.InsufficientGas;  // 0.2 TON = 2*10^8 nanotons

    val msg = lazy AllowedMarketMessage.fromSlice(in.body);

    match (msg) {
        Pause => {
            // ─── Pause Handler ──────────────────────────────────────────────
            var storage = MarketStorage.load();
            assert(in.senderAddress == storage.owner) throw MarketErrors.NotOwner;
            assert(storage.stage == STAGE_RUNNING) throw MarketErrors.MarketNotRunning;
            storage.stage = STAGE_PAUSED;
            storage.save();
        }
        Resume => {
            // ─── Resume Handler ─────────────────────────────────────────────
            var storage = MarketStorage.load();
            assert(in.senderAddress == storage.owner) throw MarketErrors.NotOwner;
            assert(storage.stage == STAGE_PAUSED) throw MarketErrors.MarketNotPaused;
            storage.stage = STAGE_RUNNING;
            storage.save();
        }
        Close => {
            // ─── Close Handler ──────────────────────────────────────────────
            var storage = MarketStorage.load();
            assert(in.senderAddress == storage.owner) throw MarketErrors.NotOwner;
            assert(storage.stage != STAGE_CLOSED) throw MarketErrors.MarketClosed;
            storage.stage = STAGE_CLOSED;
            storage.save();
        }
        ChangeFee => {
            // ─── Change Fee Handler ─────────────────────────────────────────
            var storage = MarketStorage.load();
            assert(in.senderAddress == storage.owner) throw MarketErrors.NotOwner;
            assert(storage.stage != STAGE_CLOSED) throw MarketErrors.MarketClosed;
            storage.fee = msg.newFee;
            storage.save();
        }
        ChangeFunding => {
            // ─── Change Funding Handler ─────────────────────────────────────
            var storage = MarketStorage.load();
            assert(in.senderAddress == storage.owner) throw MarketErrors.NotOwner;
            assert(storage.stage == STAGE_PAUSED) throw MarketErrors.MarketNotPaused;
            assert(msg.fundingChange != 0) throw MarketErrors.ZeroFundingChange;
            storage.funding = ((storage.funding as int) + (msg.fundingChange as int)) as uint128;
            storage.save();
        }
        WithdrawFees => {
            // ─── Withdraw Fees Handler ──────────────────────────────────────
            var storage = MarketStorage.load();
            assert(in.senderAddress == storage.owner) throw MarketErrors.NotOwner;
            assert(storage.stage != STAGE_CLOSED) throw MarketErrors.MarketClosed;
            var state = storage.state.load();
            state.accumulatedFees = 0 as uint128;
            storage.state = state.toCell();
            storage.save();
        }
        SellTrade => {
            // ─── Sell Trade Handler ─────────────────────────────────────────
            var storage = MarketStorage.load();

            // Check market is running
            assert(storage.stage == STAGE_RUNNING) throw MarketErrors.MarketNotRunning;

            // Access sell trade fields from smart-casted msg
            val tradeAmountsCell = msg.outcomeTokenAmounts;
            val _minCollateralReturn = msg.minCollateralReturn;

            // Validate outcomeTokenAmounts length == atomicOutcomeSlotCount
            val outcomeCount = storage.atomicOutcomeSlotCount as int;
            var validateSlice = tradeAmountsCell.beginParse();
            var validateLen = 0;
            while (validateSlice.remainingBitsCount() >= 64) {
                validateSlice.skipBits(64);
                validateLen += 1;
            }
            assert(validateLen == outcomeCount) throw MarketErrors.InvalidTradeAmounts;

            // Load current state
            var state = storage.state.load();

            // Compute net cost using LMSR (will be negative for sells)
            val netCost = calcNetCost(state.positionBalances, tradeAmountsCell, outcomeCount, storage.funding as int);

            // Compute fee: fee = abs(netCost) * fee / FEE_RANGE
            var absNetCost = netCost;
            if (absNetCost < 0) {
                absNetCost = -absNetCost;
            }
            val fee = absNetCost * (storage.fee as int) / FEE_RANGE;

            // Update position balances: for each i, positionBalances[i] += tradeAmounts[i]
            var tradeSlice = tradeAmountsCell.beginParse();
            var idx = 0;
            while (idx < outcomeCount) {
                val tradeAmount = tradeSlice.loadInt(64);
                val currentBalance = getBalanceAt(state.positionBalances, idx);
                val newBalance = currentBalance + tradeAmount;
                state.positionBalances.set(idx as uint32, newBalance as int128);
                idx += 1;
            }

            // Accumulate fees
            state.accumulatedFees = ((state.accumulatedFees as int) + fee) as uint128;

            // Save updated state
            storage.state = state.toCell();
            storage.save();
        }
        else => {
            // Handle transfer_notification for init_market and buy trades (op 0x7362d09c)
            var bodySlice = in.body;
            val op = bodySlice.loadUint(32);

            if (op == OP_MM_TRANSFER_NOTIFICATION) {
                val _queryId = bodySlice.loadUint(64);
                val amount = bodySlice.loadCoins();
                val _sender = bodySlice.loadAddress();
                val forwardPayload = bodySlice.loadRef();

                // Load storage and verify message comes from our Jetton wallet
                var storage = MarketStorage.load();
                val config = storage.config.load();
                assert(in.senderAddress == config.jettonWallet) throw MarketErrors.InvalidMessage;

                // Parse forward_payload to determine sub-operation
                var fpSlice = forwardPayload.beginParse();
                val fpOp = fpSlice.loadUint(32);

                if (fpOp == OP_INIT_MARKET) {
                    // ─── Init Market Handler ────────────────────────────────────
                    // Check stage == 255 (uninitialized)
                    assert(storage.stage == 255) throw MarketErrors.MarketAlreadyInitialized;

                    // Check amount > 0
                    assert(amount > 0) throw MarketErrors.ZeroFunding;

                    // Parse init_market payload
                    val conditionRegistry = fpSlice.loadAddress();
                    val conditionCount = fpSlice.loadUint(8);
                    val conditionIdsCell = fpSlice.loadRef();
                    val outcomeSlotCountsCell = fpSlice.loadRef();

                    // Compute atomic_outcome_slot_count = product of all outcome_slot_counts
                    var outcomeSlice = outcomeSlotCountsCell.beginParse();
                    var atomicOutcomeSlotCount: int = 1;
                    var i: int = 0;
                    while (i < conditionCount) {
                        val slotCount = outcomeSlice.loadUint(8);
                        atomicOutcomeSlotCount *= slotCount;
                        i += 1;
                    }

                    // Update storage: stage = STAGE_RUNNING, funding = amount
                    storage.stage = STAGE_RUNNING;
                    storage.funding = amount as uint128;
                    storage.atomicOutcomeSlotCount = atomicOutcomeSlotCount as uint32;

                    // Update config with condition registry and condition data
                    val newConfig = MarketConfig {
                        conditionRegistry: conditionRegistry,
                        collateralToken: config.collateralToken,
                        jettonWallet: config.jettonWallet,
                        conditionIds: conditionIdsCell,
                        outcomeSlotCounts: outcomeSlotCountsCell,
                    };
                    storage.config = newConfig.toCell();

                    // Save updated storage
                    storage.save();
                } else if (fpOp == OP_TRADE) {
                    // ─── Buy Trade Handler ──────────────────────────────────────
                    // Check market is running
                    assert(storage.stage == STAGE_RUNNING) throw MarketErrors.MarketNotRunning;

                    // Parse trade payload: outcomeTokenAmounts (ref cell of int64), collateralLimit (int128)
                    val tradeAmountsCell = fpSlice.loadRef();
                    val collateralLimit = fpSlice.loadInt(128);

                    // Validate outcomeTokenAmounts length == atomicOutcomeSlotCount
                    val outcomeCount = storage.atomicOutcomeSlotCount as int;
                    var validateSlice = tradeAmountsCell.beginParse();
                    var validateLen = 0;
                    while (validateSlice.remainingBitsCount() >= 64) {
                        validateSlice.skipBits(64);
                        validateLen += 1;
                    }
                    assert(validateLen == outcomeCount) throw MarketErrors.InvalidTradeAmounts;

                    // Load current state
                    var state = storage.state.load();

                    // Compute net cost using LMSR
                    val netCost = calcNetCost(state.positionBalances, tradeAmountsCell, outcomeCount, storage.funding as int);

                    // Compute fee: fee = abs(netCost) * fee / FEE_RANGE
                    var absNetCost = netCost;
                    if (absNetCost < 0) {
                        absNetCost = -absNetCost;
                    }
                    val fee = absNetCost * (storage.fee as int) / FEE_RANGE;

                    // Total cost for trader (for buy: netCost > 0, so totalCost = netCost + fee)
                    val totalCost = netCost + fee;

                    // Check collateral limit (only if limit > 0)
                    if (collateralLimit > 0) {
                        assert(totalCost <= collateralLimit) throw MarketErrors.CollateralLimitExceeded;
                    }

                    // Check sufficient collateral
                    assert(amount as int >= totalCost) throw MarketErrors.InsufficientCollateral;

                    // Update position balances: for each i, positionBalances[i] += tradeAmounts[i]
                    var tradeSlice = tradeAmountsCell.beginParse();
                    var idx = 0;
                    while (idx < outcomeCount) {
                        val tradeAmount = tradeSlice.loadInt(64);
                        val currentBalance = getBalanceAt(state.positionBalances, idx);
                        val newBalance = currentBalance + tradeAmount;
                        state.positionBalances.set(idx as uint32, newBalance as int128);
                        idx += 1;
                    }

                    // Accumulate fees
                    state.accumulatedFees = ((state.accumulatedFees as int) + fee) as uint128;

                    // Save updated state
                    storage.state = state.toCell();
                    storage.save();
                } else {
                    assert(false) throw MarketErrors.InvalidMessage;
                }
            } else {
                assert(in.body.isEmpty()) throw MarketErrors.InvalidMessage;
            }
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    // Parse bounced body - the prefix is already stripped by the framework
    in.bouncedBody.skipBouncedPrefix();
    var body = in.bouncedBody;

    // Read the original op-code from the bounced message
    if (body.remainingBitsCount() >= 32) {
        val bounceOp = body.loadUint(32);

        if (bounceOp == 0x0f8a7ea5) {
            // Jetton transfer bounced - accept silently
            // Parse query_id and amount if enough bits remain
            if (body.remainingBitsCount() >= 64 + 4) {
                val _queryId = body.loadUint(64);
                val _amount = body.loadCoins();
            }
            // State restoration for the full trade flow would require
            // storing pending trade info - for now, accept the bounce silently
        }
    }
    // Default: silently accept other bounces
}

// ─── LMSR Cost Functions ────────────────────────────────────────────────────

/// Helper: get balance from positionBalances map, returns 0 if key not found.
fun getBalanceAt(positionBalances: map<uint32, int128>, index: int): int {
    val result = positionBalances.get(index as uint32);
    if (result.isFound) {
        return result.loadValue() as int;
    }
    return 0;
}

/// Compute the LMSR cost function: C(q) = b * ln(Σ exp(q_i / b))
/// Uses the offset technique in log2 space to prevent overflow.
///
/// positionBalances: map<uint32, uint128> mapping outcome index → balance
/// atomicOutcomeSlotCount: number of atomic outcomes
/// funding: the b parameter (raw integer token units)
///
/// Returns: cost value in Q64.64 fixed-point (for precision in net cost diff)
fun lmsrCost(positionBalances: map<uint32, int128>, atomicOutcomeSlotCount: int, funding: int): int {
    // Step 1 & 2: Compute log2_scaled[i] = q_i * LOG2_E / funding for each outcome
    // and find the maximum for offset calculation.
    // log2_scaled is in Q64.64: (q_i * LOG2_E) / funding
    var maxLog2Scaled = 0 - (1 << 250); // Very negative initial value
    var i = 0;
    while (i < atomicOutcomeSlotCount) {
        val balance = getBalanceAt(positionBalances, i);
        // log2_scaled[i] = balance * LOG2_E / funding (result in Q64.64)
        val log2Scaled = balance * LOG2_E / funding;
        if (log2Scaled > maxLog2Scaled) {
            maxLog2Scaled = log2Scaled;
        }
        i += 1;
    }

    // Step 3: Compute offset. Only apply offset if max exceeds EXP_LIMIT
    var offset = 0;
    if (maxLog2Scaled > EXP_LIMIT) {
        offset = maxLog2Scaled - EXP_LIMIT;
    }

    // Step 4: Compute sum = Σ pow2(log2_scaled[i] - offset)
    var sumExp = 0;
    i = 0;
    while (i < atomicOutcomeSlotCount) {
        val balance = getBalanceAt(positionBalances, i);
        val log2Scaled = balance * LOG2_E / funding;
        val expArg = log2Scaled - offset;
        val expVal = fixed_pow2(expArg);
        sumExp += expVal;
        i += 1;
    }

    // Step 5: Compute C(q) = b * ln(sum) = b * log2(sum) * ln(2)
    // log2(sumExp) is in Q64.64, offset is in Q64.64
    val log2Sum = fixed_log2(sumExp);
    val totalLog2 = log2Sum + offset;

    // ln(sum) in Q64.64 = fixed_mul(totalLog2, LN_2) = (totalLog2 * LN_2) >> 64
    val lnSum = (totalLog2 * LN_2) >> 64;

    // cost in Q64.64 = lnSum * funding (funding is raw integer, lnSum is Q64.64)
    val costFixed = lnSum * funding;

    return costFixed;
}

/// Compute the net cost of a trade: C(q_after) - C(q_before)
/// where q_after[i] = q_before[i] + tradeAmounts[i]
///
/// currentBalances: map<uint32, uint128> mapping outcome index → current balance
/// tradeAmounts: cell containing atomicOutcomeSlotCount int64 values serialized sequentially
/// atomicOutcomeSlotCount: number of atomic outcomes
/// funding: the b parameter (raw integer token units)
///
/// Returns: net cost in raw token units (positive = trader pays, negative = trader receives)
fun calcNetCost(currentBalances: map<uint32, int128>, tradeAmounts: cell, atomicOutcomeSlotCount: int, funding: int): int {
    // Compute C(q_before) in Q64.64
    val costBefore = lmsrCost(currentBalances, atomicOutcomeSlotCount, funding);

    // Build q_after balances by adding trade amounts to current balances
    var afterBalances: map<uint32, int128> = currentBalances;
    var slice = tradeAmounts.beginParse();
    var i = 0;
    while (i < atomicOutcomeSlotCount) {
        val tradeAmount = slice.loadInt(64);
        val currentBalance = getBalanceAt(currentBalances, i);
        val newBalance = currentBalance + tradeAmount;
        afterBalances.set(i as uint32, newBalance as int128);
        i += 1;
    }

    // Compute C(q_after) in Q64.64
    val costAfter = lmsrCost(afterBalances, atomicOutcomeSlotCount, funding);

    // Net cost in Q64.64, convert to raw token units (floor division by ONE)
    val netCostFixed = costAfter - costBefore;
    return netCostFixed / ONE;
}

// ─── Get-methods ────────────────────────────────────────────────────────────

get fun owner(): address {
    val storage = lazy MarketStorage.load();
    return storage.owner;
}

get fun stage(): int {
    val storage = lazy MarketStorage.load();
    return storage.stage;
}

get fun funding(): int {
    val storage = lazy MarketStorage.load();
    return storage.funding;
}

/// Compute the marginal price for a given outcome index.
/// price_i = exp(q_i / b) / sum(exp(q_j / b)) for all j
/// Uses the offset technique in log2 space (same as lmsrCost) to prevent overflow.
/// Returns price in Q64.64 format.
get fun calcMarginalPrice(outcomeIndex: int): int {
    val storage = lazy MarketStorage.load();
    val state = storage.state.load();
    val atomicOutcomeSlotCount = storage.atomicOutcomeSlotCount as int;
    val funding = storage.funding as int;

    // Step 1: Compute log2_scaled[i] = balance_i * LOG2_E / funding for each outcome
    // and find maximum for offset calculation
    var maxLog2Scaled = 0 - (1 << 250);
    var i = 0;
    while (i < atomicOutcomeSlotCount) {
        val balance = getBalanceAt(state.positionBalances, i);
        val log2Scaled = balance * LOG2_E / funding;
        if (log2Scaled > maxLog2Scaled) {
            maxLog2Scaled = log2Scaled;
        }
        i += 1;
    }

    // Step 2: Compute offset
    var offset = 0;
    if (maxLog2Scaled > EXP_LIMIT) {
        offset = maxLog2Scaled - EXP_LIMIT;
    }

    // Step 3: Compute exp values and sum, also capture exp for outcomeIndex
    var sumExp = 0;
    var expOutcome = 0;
    i = 0;
    while (i < atomicOutcomeSlotCount) {
        val balance = getBalanceAt(state.positionBalances, i);
        val log2Scaled = balance * LOG2_E / funding;
        val expArg = log2Scaled - offset;
        val expVal = fixed_pow2(expArg);
        sumExp += expVal;
        if (i == outcomeIndex) {
            expOutcome = expVal;
        }
        i += 1;
    }

    // Step 4: price = expOutcome / sumExp (both in Q64.64)
    // fixed_div: (a << 64) / b
    return fixed_div(expOutcome, sumExp);
}

/// Compute the net cost of a trade without executing it.
/// Takes a trade amounts cell (array of int64 values) and returns net cost in raw token units.
get fun getNetCost(tradeAmounts: cell): int {
    val storage = lazy MarketStorage.load();
    val state = storage.state.load();
    val atomicOutcomeSlotCount = storage.atomicOutcomeSlotCount as int;
    val funding = storage.funding as int;

    return calcNetCost(state.positionBalances, tradeAmounts, atomicOutcomeSlotCount, funding);
}
