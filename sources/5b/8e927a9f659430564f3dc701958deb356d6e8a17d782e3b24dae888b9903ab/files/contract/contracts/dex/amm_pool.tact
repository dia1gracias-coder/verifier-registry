import "@stdlib/deploy";
import "@stdlib/ownable";

// ============================================================
// TEP-74 Messages (standalone for Pool)
// ============================================================

// Standard TEP-74 transfer_notification
message(0x7362d09c) DexTokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

// Tact auto-generated TokenNotification (from TONX/Tact jetton wallets)
message(0xad2c4ac6) TactTokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining;
}

message(0x0f8a7ea5) DexTokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x595f07bc) DexTokenBurn {
    queryId: Int as uint64;
    amount: Int as coins;
    owner: Address;
    response_destination: Address;
}

message(0xd53276db) DexTokenExcesses {
    queryId: Int as uint64;
}

// ============================================================
// Pool Admin Messages
// ============================================================

message SetOcWallet {
    wallet: Address;
}

message SetUsdtWallet {
    wallet: Address;
}

message SetLpMaster {
    master: Address;
}

// The pool's OWN LP jetton wallet (under the LP master). Set post-deploy so the pool can
// authenticate LP-token deposits by sender, instead of guessing by elimination.
message SetLpWallet {
    wallet: Address;
}

message SetProtocolWallet {
    wallet: Address;
}

message SetOcMaster {
    master: Address;
}

message PoolPause {}
message PoolUnpause {}

message SetMaxSwapBps {
    bps: Int as uint16;
}

// Admin tunes the TON attached to each outgoing jetton transfer (gas per payout).
message SetSendGas {
    gas: Int as coins;
}

message SetMinReserveUsdt {
    amount: Int as coins;
}

message SetTimelockDelay {
    delay: Int as uint64;
}

message SetFeeRates {
    lpFeeBps: Int as uint16;
    protocolFeeBps: Int as uint16;
    burnFeeBps: Int as uint16;
}

message SetBurnEnabled {
    enabled: Bool;
}

// When false (default), only the owner may add liquidity. Owner flips it on to open adds to all.
message SetPublicAddLiquidity {
    enabled: Bool;
}

// Admin overrides/disables the launch-period high sell fee (set endsAt in the past to disable).
message SetLaunchEnd {
    endsAt: Int as uint64;
}

// Backend Ed25519 signer for per-user sell permits. 0 blocks ALL sells (strict mode).
message SetPermitPublicKey {
    pubkey: Int as uint256;
}

// Global per-day sell cap as bps of OC reserve (snapshot at each window start).
message SetDailySellLimitBps {
    bps: Int as uint16;
}

// User cancels pending deposit
message CancelPendingDeposit {}

// User executes scheduled remove liquidity after timelock
message ExecuteRemoveLiquidity {
    queryId: Int as uint64;
}

// User cancels a scheduled removal and gets their LP tokens back
message CancelRemoveLiquidity {}

// Pool -> LP Master: mint
message PoolMintLp {
    queryId: Int as uint64;
    amount: Int as coins;
    to: Address;
    response_destination: Address;
}

// Admin emergency withdraw (stuck tokens)
message AdminWithdrawToken {
    jettonWallet: Address;
    amount: Int as coins;
    to: Address;
}

// Admin withdraw TON from contract balance
message AdminWithdrawTon {
    amount: Int as coins;
    to: Address;
}

// ============================================================
// Structs
// ============================================================

struct PoolReserves {
    reserveOC: Int as coins;
    reserveUSDT: Int as coins;
    totalLpSupply: Int as coins;
}

struct FeeResult {
    totalFee: Int as coins;
    lpFee: Int as coins;
    protocolFee: Int as coins;
    burnFee: Int as coins;
}

struct PendingDepositInfo {
    user: Address;
    ocAmount: Int as coins;
    usdtAmount: Int as coins;
    timestamp: Int as uint64;
}

struct RemovalInfo {
    user: Address;
    lpAmount: Int as coins;
    scheduledAt: Int as uint64;
}

struct LaunchInfo {
    launchEndsAt: Int as uint64;
    launchSellFeeBps: Int as uint16;
    started: Bool;
    active: Bool;
}

struct GlobalDailySold {
    sold: Int as coins;       // OC sold into the pool in the current window
    cap: Int as coins;        // snapshot cap for the window (2% of reserveOC at window start)
    windowStart: Int as uint64;
}

struct PoolConfig {
    owner: Address;
    paused: Bool;
    maxSwapBps: Int as uint16;
    minReserveUSDT: Int as coins;
    timelockDelay: Int as uint64;
    protocolWallet: Address;
    deployedAt: Int as uint64;
    lpFeeBps: Int as uint16;
    protocolFeeBps: Int as uint16;
    burnFeeBps: Int as uint16;
    lpMaster: Address?;
    lpJettonWallet: Address?;
    burnEnabled: Bool;
    publicAddLiquidity: Bool;
}

// ============================================================
// Op codes for forward_payload
// ============================================================
// op = 1: swap (+ min_output as coins)
// op = 2: add_liquidity
// op = 3: remove_liquidity (LP token sent to pool)

// ============================================================
// AMM Pool Contract
// ============================================================

// A standards-compliant EMPTY jetton forward_payload: a single Either bit (0 = inline,
// empty). A governed USDT wallet strictly parses forward_payload:(Either Cell ^Cell), so
// a malformed/absent prefix makes it underflow (exit 9).
fun emptyForwardPayload(): Slice {
    return beginCell().storeUint(0, 1).endCell().asSlice();
}

contract AmmPool with Ownable {

    // Fee config (basis points, denominator = 10000)
    const FEE_DENOMINATOR: Int = 10000;

    // Outgoing-transfer purpose tag;
    const TAG_NOOP: Int = 0;
    const TAG_RESERVE: Int = 1;
    const TAG_REFUND: Int = 2;
 
    const MINT_BOUNCE_WINDOW: Int = 60;
    const LAUNCH_PERIOD: Int = 2592000;   // 30 days: window where selling OC pays the high launch fee
    const DAY: Int = 86400;               // rolling-window length for the global daily sell cap
    const SIG_BITS: Int = 512;            // Ed25519 signature length
    // const MIN_GAS: Int = ton("0.15");
    // const PENDING_TIMEOUT: Int = 3600;  // 1 hour

    owner: Address;

    // TON attached to each outgoing jetton transfer. Governed USDT (jetton_wallet_governed)
    // needs far more than the old hardcoded 0.03 — too little => the transfer is rejected
    // and bounces. Admin-tunable so it can be raised without redeploying.
    sendGas: Int as coins;

    // Jetton wallet addresses (Pool's own wallets)
    ocJettonWallet: Address?;
    usdtJettonWallet: Address?;
    lpMaster: Address?;
    lpJettonWallet: Address?;   // the pool's own LP wallet; LP deposits MUST come from here

    // Reserves
    reserveOC: Int as coins;
    reserveUSDT: Int as coins;
    totalLpSupply: Int as coins;

    // Fee rates (basis points, owner can update)
    lpFeeBps: Int as uint16;             // default 20 = 0.20%
    protocolFeeBps: Int as uint16;       // default 8 = 0.08%
    burnFeeBps: Int as uint16;           // default 2 = 0.02%

    // Launch anti-dump: while now() < launchEndsAt, selling OC (OC->USDT) pays launchSellFeeBps
    // (default 10%) entirely to the protocol wallet instead of the normal 0.3% split.
    launchSellFeeBps: Int as uint16;     // default 1000 = 10%
    launchEndsAt: Int as uint64;         // set to firstLiquidityTs + LAUNCH_PERIOD
    launchStarted: Bool;                  // armed on first liquidity (or by SetLaunchEnd)

    // Sell limits (SELL = OC->USDT only). Per-user 20 USDT/day is enforced OFF-CHAIN via a
    // signed permit (no per-user storage); the global cap is enforced on-chain (O(1)).
    permitPublicKey: Int as uint256;     // backend Ed25519 signer; 0 = ALL sells blocked (strict)
    dailySellLimitBps: Int as uint16;    // default 200 = 2% of reserveOC per day
    globalDaySoldOC: Int as coins;       // OC sold this window
    globalDayStart: Int as uint64;       // window start (rolling 24h)
    globalDayCapOC: Int as coins;        // snapshot 2% of reserveOC at window start

    // Fee destinations
    protocolWallet: Address;
    ocMasterAddress: Address?;

    // Burn toggle
    burnEnabled: Bool;

    // Add-liquidity gate: false = owner-only, true = open to everyone.
    publicAddLiquidity: Bool;

    // Safety
    paused: Bool;
    maxSwapBps: Int as uint16;          // default 200 = 2%
    minReserveUSDT: Int as coins;       // default 10_000 * 10^6
    timelockDelay: Int as uint64;       // default 86400 = 24h

    // Pending deposits: map<user_address_hash, value>
    pendingOC: map<Int as uint256, Int as coins>;
    pendingUSDT: map<Int as uint256, Int as coins>;
    pendingUser: map<Int as uint256, Address>;
    pendingTimestamp: map<Int as uint256, Int as uint64>;

    // Remove liquidity timelock
    removeLpAmount: map<Int as uint256, Int as coins>;
    removeScheduledAt: map<Int as uint256, Int as uint64>;
    removeUser: map<Int as uint256, Address>;

    // In-flight LP mints, keyed by a pool-assigned nonce carried in PoolMintLp.queryId.
    // A bounced mint preserves only the first ~224 bits of the body (no address fields),
    // so we look the deposit up by nonce to reverse reserves/supply and refund the user.
    mintNonce: Int as uint64;
    mintUser: map<Int as uint64, Address>;
    mintOC: map<Int as uint64, Int as coins>;
    mintUSDT: map<Int as uint64, Int as coins>;
    mintTimestamp: map<Int as uint64, Int as uint64>;   // nonce -> created-at, gates safe cleanup
    userMintNonce: map<Int as uint256, Int as uint64>;  // userHash -> last mint nonce (for cleanup)

    // Monotonic sequence woven into the low 62 bits of every DexTokenTransfer queryId. Makes
    // each outgoing transfer uniquely identifiable so a bounced refund can be matched back
    // OFF-CHAIN (bounce preserves queryId) to the original send to find the owed user + amount.
    transferSeq: Int as uint64;

    // Deploy timestamp (makes contract address unique per deploy)
    deployedAt: Int as uint64;

    init(
        owner: Address,
        protocolWallet: Address,
        deployedAt: Int
    ) {
        self.owner = owner;
        self.protocolWallet = protocolWallet;
        self.deployedAt = deployedAt;

        self.ocJettonWallet = null;
        self.usdtJettonWallet = null;
        self.lpMaster = null;
        self.lpJettonWallet = null;
        self.ocMasterAddress = null;

        self.reserveOC = 0;
        self.reserveUSDT = 0;
        self.totalLpSupply = 0;
        self.mintNonce = 0;
        self.transferSeq = 0;

        self.lpFeeBps = 20;                 // 0.2%
        self.protocolFeeBps = 10;            // 0.1%
        self.burnFeeBps = 0;               // 0%

        self.launchSellFeeBps = 1000;       // 10%
        self.launchEndsAt = 0;              // armed on first liquidity (firstLiquidityTs + LAUNCH_PERIOD)
        self.launchStarted = false;

        self.permitPublicKey = 0;           // set via SetPermitPublicKey to enable per-user cap
        self.dailySellLimitBps = 200;       // 2%
        self.globalDaySoldOC = 0;
        self.globalDayStart = 0;
        self.globalDayCapOC = 0;

        self.burnEnabled = false;
        self.publicAddLiquidity = false;    // owner-only adds until opened
        self.paused = false;
        self.maxSwapBps = 200;              // 2%
        self.minReserveUSDT = 10000000000;  // 10K USDT (6 decimals)
        self.timelockDelay = 86400;         // 24h
        self.sendGas = ton("0.1");          // enough for a governed USDT transfer
    }

    // ============================================================
    // Admin Setup
    // ============================================================

    receive(msg: SetOcWallet) {
        self.requireOwner();
        self.ocJettonWallet = msg.wallet;
    }

    receive(msg: SetUsdtWallet) {
        self.requireOwner();
        self.usdtJettonWallet = msg.wallet;
    }

    receive(msg: SetLpMaster) {
        self.requireOwner();
        self.lpMaster = msg.master;
    }

    receive(msg: SetLpWallet) {
        self.requireOwner();
        self.lpJettonWallet = msg.wallet;
    }

    receive(msg: SetProtocolWallet) {
        self.requireOwner();
        self.protocolWallet = msg.wallet;
    }

    receive(msg: SetOcMaster) {
        self.requireOwner();
        self.ocMasterAddress = msg.master;
    }

    receive(msg: PoolPause) {
        self.requireOwner();
        self.paused = true;
    }

    receive(msg: PoolUnpause) {
        self.requireOwner();
        self.paused = false;
    }

    receive(msg: SetMaxSwapBps) {
        self.requireOwner();
        require(msg.bps > 0 && msg.bps <= 10000, "Invalid bps");
        self.maxSwapBps = msg.bps;
    }

    receive(msg: SetSendGas) {
        self.requireOwner();
        require(msg.gas > 0, "Send gas must be positive");
        self.sendGas = msg.gas;
    }

    receive(msg: SetMinReserveUsdt) {
        self.requireOwner();
        self.minReserveUSDT = msg.amount;
    }

    receive(msg: SetTimelockDelay) {
        self.requireOwner();
        self.timelockDelay = msg.delay;
    }

    receive(msg: SetBurnEnabled) {
        self.requireOwner();
        self.burnEnabled = msg.enabled;
    }

    receive(msg: SetPublicAddLiquidity) {
        self.requireOwner();
        self.publicAddLiquidity = msg.enabled;
    }

    receive(msg: SetLaunchEnd) {
        self.requireOwner();
        // Lock the value so a later first-liquidity add can't overwrite an explicit admin setting
        // (e.g. disabling early with endsAt in the past, or pre-arming before seeding).
        self.launchStarted = true;
        self.launchEndsAt = msg.endsAt;
    }

    receive(msg: SetPermitPublicKey) {
        self.requireOwner();
        self.permitPublicKey = msg.pubkey;
    }

    receive(msg: SetDailySellLimitBps) {
        self.requireOwner();
        require(msg.bps > 0 && msg.bps <= 10000, "Invalid bps");
        self.dailySellLimitBps = msg.bps;
    }

    receive(msg: SetFeeRates) {
        self.requireOwner();
        let total: Int = msg.lpFeeBps + msg.protocolFeeBps + msg.burnFeeBps;
        require(total > 0 && total <= 1000, "Total fee must be 0-10%");
        require(msg.lpFeeBps >= 0 && msg.protocolFeeBps >= 0 && msg.burnFeeBps >= 0, "Fee cannot be negative");
        self.lpFeeBps = msg.lpFeeBps;
        self.protocolFeeBps = msg.protocolFeeBps;
        self.burnFeeBps = msg.burnFeeBps;
    }

    // Accept excess TON from burn/transfer callbacks (do nothing, just accept)
    receive(msg: DexTokenExcesses) {}

    // LP mint bounced (e.g. LP master rejected it — max supply / not mintable). The deposit
    // was already folded into the reserves and no LP was minted, so reverse the reserve and
    // supply changes and refund the user their deposited OC + USDT. Only queryId (= our mint
    // nonce) and amount (= lpAmount) survive a bounce, so we recover oc/usdt and the user
    // from the record we stored before sending.
    bounced(msg: bounced<PoolMintLp>) {
        let nonce: Int = msg.queryId;
        let user: Address? = self.mintUser.get(nonce);
        if (user == null) {
            return; // already cleaned up — nothing to reverse
        }

        let oc: Int = self.mintOC.get(nonce)!!;
        let usdt: Int = self.mintUSDT.get(nonce)!!;

        // Reverse the optimistic reserve/supply updates from _executAddLiquidity.
        self.reserveOC = self.reserveOC - oc;
        self.reserveUSDT = self.reserveUSDT - usdt;
        self.totalLpSupply = self.totalLpSupply - msg.amount;

        // Drop the record so it can't be reversed twice. Only clear the user index if it still
        // points at THIS nonce — a newer in-flight mint may have already claimed it.
        self.mintUser.set(nonce, null);
        self.mintOC.set(nonce, null);
        self.mintUSDT.set(nonce, null);
        self.mintTimestamp.set(nonce, null);
        let uHash: Int = self._addressHash(user!!);
        if (self.userMintNonce.get(uHash) == nonce) {
            self.userMintNonce.set(uHash, null);
        }

        // Refund the deposit so funds are never stuck in the pool without LP.
        if (oc > 0) {
            self._sendJetton(self.ocJettonWallet!!, user!!, oc, user!!, 0, self.TAG_REFUND);
        }
        if (usdt > 0) {
            self._sendJetton(self.usdtJettonWallet!!, user!!, usdt, user!!, 0, self.TAG_REFUND);
        }
    }

    // An outgoing jetton transfer bounced (recipient wallet rejected it / out of gas)
    bounced(msg: bounced<DexTokenTransfer>) {
        let tag: Int = msg.queryId >> 62;
        let s: Address = sender();
        if (tag == self.TAG_RESERVE) {
            if (self.ocJettonWallet != null && s == self.ocJettonWallet!!) {
                self.reserveOC = self.reserveOC + msg.amount;
            } else if (self.usdtJettonWallet != null && s == self.usdtJettonWallet!!) {
                self.reserveUSDT = self.reserveUSDT + msg.amount;
            }
        }
    }

    // A burn we initiated bounced (amount survives; sender identifies it).
    // LP wallet: removal burn failed, tokens still exist -> re-credit totalLpSupply.
    // OC wallet: swap burn-fee failed; that OC was never in reserves -> no-op.
    bounced(msg: bounced<DexTokenBurn>) {
        let s: Address = sender();
        if (self.lpJettonWallet != null && s == self.lpJettonWallet!!) {
            self.totalLpSupply = self.totalLpSupply + msg.amount;
        }
    }

    receive(msg: AdminWithdrawToken) {
        self.requireOwner();
        self._sendJetton(msg.jettonWallet, msg.to, msg.amount, self.owner, 0, self.TAG_NOOP);
    }

    receive(msg: AdminWithdrawTon) {
        self.requireOwner();
        require(msg.amount > 0, "Amount must be > 0");
        send(SendParameters{
            to: msg.to,
            value: msg.amount,
            mode: 0,
            bounce: true,
            body: "Admin withdraw".asComment()
        });
    }

    // ============================================================
    // Main Entry Point: TokenNotification from Jetton Wallets
    // Handles both standard TEP-74 (0x7362d09c) and Tact auto (0xad2c4ac6)
    // ============================================================

    receive(msg: TactTokenNotification) {
        self._handleNotification(msg.queryId, msg.amount, msg.from, msg.forward_payload);
    }

    receive(msg: DexTokenNotification) {
        self._handleNotification(msg.queryId, msg.amount, msg.from, msg.forward_payload);
    }

    // Shared notification handler
    fun _handleNotification(queryId: Int, amount: Int, from: Address, forward_payload: Slice) {
        let ctx: Context = context();
        let sender: Address = ctx.sender;

        let isOC: Bool = sender == self.ocJettonWallet!!;
        let isUSDT: Bool = sender == self.usdtJettonWallet!!;
        // LP deposits are authenticated by sender (the pool's own LP wallet) — NOT by
        // elimination. The old "anyone who isn't OC/USDT is the LP wallet" let a forged
        // transfer_notification schedule a removal of arbitrary LP and drain the pool.
        let isLP: Bool = (self.lpJettonWallet != null) && (sender == self.lpJettonWallet!!);

        require(isOC || isUSDT || isLP, "Unknown jetton");

        let op: Int = 0;
        let minOutput: Int = 0;
        let deadline: Int = 0;

        // Parse forward_payload: handle Either encoding (bit 0=inline, bit 1=ref)
        let payload: Slice = forward_payload;
        if (payload.bits() >= 1 && payload.bits() < 32) {
            let isRef: Int = payload.loadUint(1);
            if (isRef == 1 && payload.refs() > 0) {
                payload = payload.loadRef().beginParse();
            }
        }

        if (payload.bits() >= 32) {
            op = payload.loadUint(32);
            if (op == 1 && payload.bits() >= 4) {
                minOutput = payload.loadCoins();
                // Optional deadline: if present, check tx not expired
                if (payload.bits() >= 64) {
                    deadline = payload.loadUint(64);
                }
            }
        }

        if (isLP) {
            require(ctx.value >= self.sendGas, "Insufficient gas for removal scheduling");
            self._scheduleRemoveLiquidity(from, amount, queryId);
            return;
        }

        require(!self.paused, "Pool is paused");

        // Check deadline if set (0 = no deadline)
        if (deadline > 0) {
            require(now() <= deadline, "Transaction expired");
        }

        if (op == 1) {
            // up to 3 sends: output + protocol fee + burn/redirect
            require(ctx.value >= 3 * self.sendGas, "Insufficient gas for swap");
            // SELL (OC->USDT): per-user daily cap enforced off-chain via a signed permit carried
            // in the payload's ref (only when a signer is set). Global cap is enforced in the swap.
            if (isOC) {
                self._verifySellPermit(amount, from, payload);
            }
            self._handleSwap(isOC, amount, from, minOutput, queryId);
        } else if (op == 2) {
            // up to 3 sends: LP mint + up to 2 excess refunds
            require(ctx.value >= 3 * self.sendGas, "Insufficient gas for add liquidity");
            self._handleAddLiquidity(isOC, amount, from, queryId);
        } else {
            require(ctx.value >= self.sendGas, "Insufficient gas for refund");
            if (isOC) {
                self._sendJetton(self.ocJettonWallet!!, from, amount, from, 0, self.TAG_REFUND);
            } else {
                self._sendJetton(self.usdtJettonWallet!!, from, amount, from, 0, self.TAG_REFUND);
            }
        }
    }

    // ============================================================
    // Swap Logic
    // ============================================================
    
    fun _verifySellPermit(inputOC: Int, user: Address, payload: Slice) {
        // Strict: every sell MUST carry a valid permit. Until a signer is configured all sells
        // are blocked, so SetPermitPublicKey is a required launch step before trading opens.
        require(self.permitPublicKey != 0, "Permit signer not set");
        require(payload.refs() > 0, "Missing sell permit");
        let permit: Slice = payload.loadRef().beginParse();
        let maxSell: Int = permit.loadCoins();
        let permitDeadline: Int = permit.loadUint(64);
        let sig: Slice = permit.loadRef().beginParse();
        require(sig.bits() == self.SIG_BITS, "Invalid signature length");
        require(now() <= permitDeadline, "Permit expired");
        require(inputOC <= maxSell, "Exceeds permitted sell");
        let h: Int = beginCell()
            .storeAddress(myAddress())
            .storeAddress(user)
            .storeCoins(maxSell)
            .storeUint(permitDeadline, 64)
            .endCell().hash();
        require(checkSignature(h, sig, self.permitPublicKey), "Bad permit");
    }

    fun _handleSwap(isOC: Bool, inputAmount: Int, user: Address, minOutput: Int, queryId: Int) {
        require(inputAmount > 0, "Zero input");

        if (isOC) {
            self._swapOcToUsdt(inputAmount, user, minOutput, queryId);
        } else {
            self._swapUsdtToOc(inputAmount, user, minOutput, queryId);
        }
    }

    // Swap OC -> USDT: fee on input OC
    fun _swapOcToUsdt(inputOC: Int, user: Address, minOutput: Int, queryId: Int) {
        require(self.reserveOC > 0 && self.reserveUSDT > 0, "No liquidity");

        // Safety: max swap check
        require(inputOC <= self.reserveOC * self.maxSwapBps / self.FEE_DENOMINATOR, "Exceeds max swap");

        // Calculate fees on input OC (high launch fee while in the launch window)
        let fees: FeeResult = self._effectiveSellFee(inputOC);
        let swapAmount: Int = inputOC - fees.totalFee;

        // AMM: x * y = k
        let k: Int = self.reserveOC * self.reserveUSDT;
        let newReserveOC: Int = self.reserveOC + swapAmount + fees.lpFee;
        // Ceil the output reserve so the rounding unit stays in the pool, not the user (keeps k from leaking).
        let newReserveUSDT: Int = (k + newReserveOC - 1) / newReserveOC;
        let outputUSDT: Int = self.reserveUSDT - newReserveUSDT;

        require(outputUSDT > 0, "Zero output");
        require(outputUSDT >= minOutput, "Slippage exceeded");
        require(newReserveUSDT >= self.minReserveUSDT, "Below min reserve");

        // Global daily sell cap (rolling 24h). The ceiling is snapshotted at the window start as
        // 2% of the then-current reserveOC, so it's stable and not gameable by intra-day changes.
        if (self.globalDayStart == 0 || now() - self.globalDayStart >= self.DAY) {
            self.globalDayStart = now();
            self.globalDaySoldOC = 0;
            self.globalDayCapOC = self.reserveOC * self.dailySellLimitBps / self.FEE_DENOMINATOR;
        }
        require(self.globalDaySoldOC + inputOC <= self.globalDayCapOC, "Exceeds global daily sell limit");
        self.globalDaySoldOC = self.globalDaySoldOC + inputOC;

        // Update reserves
        self.reserveOC = newReserveOC;
        self.reserveUSDT = newReserveUSDT;

        // Send output USDT to user
        self._sendJetton(self.usdtJettonWallet!!, user, outputUSDT, user, 0, self.TAG_RESERVE);

        // Send protocol fee OC to protocol wallet
        if (fees.protocolFee > 0) {
            self._sendJetton(self.ocJettonWallet!!, self.protocolWallet, fees.protocolFee, self.protocolWallet, 0, self.TAG_NOOP);
        }

        // Burn fee OC (or redirect to protocol if burn disabled)
        if (fees.burnFee > 0) {
            if (self.burnEnabled) {
                self._burnOc(fees.burnFee, queryId);
            } else {
                self._sendJetton(self.ocJettonWallet!!, self.protocolWallet, fees.burnFee, self.protocolWallet, 0, self.TAG_NOOP);
            }
        }
    }

    // Swap USDT -> OC: fee on input USDT
    fun _swapUsdtToOc(inputUSDT: Int, user: Address, minOutput: Int, queryId: Int) {
        require(self.reserveOC > 0 && self.reserveUSDT > 0, "No liquidity");

        // Safety: max swap check
        require(inputUSDT <= self.reserveUSDT * self.maxSwapBps / self.FEE_DENOMINATOR, "Exceeds max swap");

        // Calculate fees on input USDT
        let fees: FeeResult = self._calculateFees(inputUSDT);
        let swapAmount: Int = inputUSDT - fees.totalFee;

        // AMM: x * y = k
        let k: Int = self.reserveOC * self.reserveUSDT;
        let newReserveUSDT: Int = self.reserveUSDT + swapAmount + fees.lpFee;
        // Ceil the output reserve so the rounding unit stays in the pool, not the user (keeps k from leaking).
        let newReserveOC: Int = (k + newReserveUSDT - 1) / newReserveUSDT;
        let outputOC: Int = self.reserveOC - newReserveOC;

        require(outputOC > 0, "Zero output");
        require(outputOC >= minOutput, "Slippage exceeded");

        // Update reserves (lp fee stays in pool as USDT)
        self.reserveUSDT = newReserveUSDT;
        self.reserveOC = newReserveOC;

        // Send output OC to user
        self._sendJetton(self.ocJettonWallet!!, user, outputOC, user, 0, self.TAG_RESERVE);

        // Send protocol fee USDT to protocol wallet
        if (fees.protocolFee > 0) {
            self._sendJetton(self.usdtJettonWallet!!, self.protocolWallet, fees.protocolFee, self.protocolWallet, 0, self.TAG_NOOP);
        }

        // Burn fee is collected in USDT, which we can't burn (not our token), so it always goes
        // to the protocol wallet — same destination as a disabled burn on the OC->USDT side.
        if (fees.burnFee > 0) {
            self._sendJetton(self.usdtJettonWallet!!, self.protocolWallet, fees.burnFee, self.protocolWallet, 0, self.TAG_NOOP);
        }
    }

    // ============================================================
    // Add Liquidity (Pending Deposit Pattern)
    // ============================================================

    fun _handleAddLiquidity(isOC: Bool, amount: Int, user: Address, queryId: Int) {
        require(amount > 0, "Zero amount");

        // Owner-only mode: refund anyone but the owner (refund, not revert, so the deposited
        // token isn't stranded in the pool's jetton wallet) until the owner opens adds to all.
        if (!self.publicAddLiquidity && user != self.owner) {
            if (isOC) {
                self._sendJetton(self.ocJettonWallet!!, user, amount, user, 0, self.TAG_REFUND);
            } else {
                self._sendJetton(self.usdtJettonWallet!!, user, amount, user, 0, self.TAG_REFUND);
            }
            return;
        }

        // LP master not configured yet: we can't mint LP, so refund instead of booking a
        // pending deposit that would strand the matching token when the mint step later
        // hits `self.lpMaster!!` on null and reverts the whole second-token transaction.
        if (self.lpMaster == null) {
            if (isOC) {
                self._sendJetton(self.ocJettonWallet!!, user, amount, user, 0, self.TAG_REFUND);
            } else {
                self._sendJetton(self.usdtJettonWallet!!, user, amount, user, 0, self.TAG_REFUND);
            }
            return;
        }

        let userHash: Int = self._addressHash(user);

        // Reclaim this user's previous mint record to bound map growth — but ONLY once the
        // bounce window has passed. Reclaiming a still-in-flight mint's record would make its
        // later bounce a no-op (record gone) and strand that deposit (#5). Within the window we
        // leave it intact; the bounce handler still reverses it by nonce.
        let prevNonce: Int? = self.userMintNonce.get(userHash);
        if (prevNonce != null) {
            let ts: Int? = self.mintTimestamp.get(prevNonce!!);
            if (ts == null || now() - ts!! > self.MINT_BOUNCE_WINDOW) {
                self.mintUser.set(prevNonce!!, null);
                self.mintOC.set(prevNonce!!, null);
                self.mintUSDT.set(prevNonce!!, null);
                self.mintTimestamp.set(prevNonce!!, null);
                self.userMintNonce.set(userHash, null);
            }
        }

        if (isOC) {
            // Check if already has pending OC
            let existingOC: Int? = self.pendingOC.get(userHash);
            if (existingOC != null && existingOC!! > 0) {
                // Refund new OC - only one pending per user
                self._sendJetton(self.ocJettonWallet!!, user, amount, user, 0, self.TAG_REFUND);
                return;
            }
            self.pendingOC.set(userHash, amount);
        } else {
            // USDT
            let existingUSDT: Int? = self.pendingUSDT.get(userHash);
            if (existingUSDT != null && existingUSDT!! > 0) {
                // Refund new USDT
                self._sendJetton(self.usdtJettonWallet!!, user, amount, user, 0, self.TAG_REFUND);
                return;
            }
            self.pendingUSDT.set(userHash, amount);
        }

        self.pendingUser.set(userHash, user);
        self.pendingTimestamp.set(userHash, now());

        // Check if both tokens received
        let ocAmount: Int? = self.pendingOC.get(userHash);
        let usdtAmount: Int? = self.pendingUSDT.get(userHash);

        if (ocAmount != null && ocAmount!! > 0 && usdtAmount != null && usdtAmount!! > 0) {
            self._executAddLiquidity(userHash, ocAmount!!, usdtAmount!!, user, queryId);
        }
    }

    fun _executAddLiquidity(userHash: Int, ocAmount: Int, usdtAmount: Int, user: Address, queryId: Int) {
        let lpAmount: Int = 0;
        let actualOC: Int = ocAmount;
        let actualUSDT: Int = usdtAmount;
        let refundOC: Int = 0;
        let refundUSDT: Int = 0;

        if (self.reserveOC == 0 && self.reserveUSDT == 0) {
            // First liquidity
            lpAmount = self._sqrt(ocAmount * usdtAmount);
            require(lpAmount > 0, "Insufficient initial liquidity");
            // Anchor the launch window to when the pool first goes live (arms once; a later
            // full-drain-then-re-add won't reset it, and an explicit SetLaunchEnd locks it).
            if (!self.launchStarted) {
                self.launchStarted = true;
                self.launchEndsAt = now() + self.LAUNCH_PERIOD;
            }
        } else {
            // Calculate correct ratio
            let expectedUSDT: Int = ocAmount * self.reserveUSDT / self.reserveOC;

            if (usdtAmount > expectedUSDT) {
                // Too much USDT, refund excess
                actualUSDT = expectedUSDT;
                refundUSDT = usdtAmount - expectedUSDT;
            } else if (usdtAmount < expectedUSDT) {
                // Too much OC, recalculate
                let expectedOC: Int = usdtAmount * self.reserveOC / self.reserveUSDT;
                actualOC = expectedOC;
                refundOC = ocAmount - expectedOC;
            }

            // LP amount = min of both ratios
            let lpFromOC: Int = actualOC * self.totalLpSupply / self.reserveOC;
            let lpFromUSDT: Int = actualUSDT * self.totalLpSupply / self.reserveUSDT;
            lpAmount = min(lpFromOC, lpFromUSDT);
        }

        require(lpAmount > 0, "Zero LP");

        // Update reserves
        self.reserveOC = self.reserveOC + actualOC;
        self.reserveUSDT = self.reserveUSDT + actualUSDT;
        self.totalLpSupply = self.totalLpSupply + lpAmount;

        // Clear pending
        self._clearPending(userHash);

        // Record this in-flight mint so a bounce (e.g. LP master max-supply) can reverse the
        // reserve/supply changes and refund the user. Keyed by a pool nonce we carry in
        // queryId — the only identifying field that survives a bounce.
        let nonce: Int = self.mintNonce;
        self.mintNonce = self.mintNonce + 1;
        self.mintUser.set(nonce, user);
        self.mintOC.set(nonce, actualOC);
        self.mintUSDT.set(nonce, actualUSDT);
        self.mintTimestamp.set(nonce, now());
        self.userMintNonce.set(userHash, nonce);

        // Mint LP tokens to user
        send(SendParameters{
            to: self.lpMaster!!,
            value: self.sendGas,
            mode: 0,
            bounce: true,
            body: PoolMintLp{
                queryId: nonce,
                amount: lpAmount,
                to: user,
                response_destination: user
            }.toCell()
        });

        // Refund excess tokens
        if (refundOC > 0) {
            self._sendJetton(self.ocJettonWallet!!, user, refundOC, user, 0, self.TAG_REFUND);
        }
        if (refundUSDT > 0) {
            self._sendJetton(self.usdtJettonWallet!!, user, refundUSDT, user, 0, self.TAG_REFUND);
        }
    }

    // Cancel pending deposit (user gets refund)
    receive(msg: CancelPendingDeposit) {
        let user: Address = sender();
        let userHash: Int = self._addressHash(user);

        let ocAmount: Int? = self.pendingOC.get(userHash);
        let usdtAmount: Int? = self.pendingUSDT.get(userHash);

        require(
            (ocAmount != null && ocAmount!! > 0) || (usdtAmount != null && usdtAmount!! > 0),
            "No pending deposit"
        );

        // Refund OC
        if (ocAmount != null && ocAmount!! > 0) {
            self._sendJetton(self.ocJettonWallet!!, user, ocAmount!!, user, 0, self.TAG_REFUND);
        }

        // Refund USDT
        if (usdtAmount != null && usdtAmount!! > 0) {
            self._sendJetton(self.usdtJettonWallet!!, user, usdtAmount!!, user, 0, self.TAG_REFUND);
        }

        self._clearPending(userHash);
    }

    // ============================================================
    // Remove Liquidity (24h Timelock)
    // ============================================================

    fun _scheduleRemoveLiquidity(user: Address, lpAmount: Int, queryId: Int) {
        require(lpAmount > 0, "Zero LP");

        let userHash: Int = self._addressHash(user);

        // Check no existing pending removal
        let existing: Int? = self.removeLpAmount.get(userHash);
        require(existing == null || existing!! == 0, "Already pending removal");

        self.removeLpAmount.set(userHash, lpAmount);
        self.removeScheduledAt.set(userHash, now());
        self.removeUser.set(userHash, user);
    }

    receive(msg: ExecuteRemoveLiquidity) {
        let ctx: Context = context();
        let user: Address = ctx.sender;
        let userHash: Int = self._addressHash(user);

        let lpAmount: Int? = self.removeLpAmount.get(userHash);
        require(lpAmount != null && lpAmount!! > 0, "No pending removal");

        let scheduledAt: Int? = self.removeScheduledAt.get(userHash);
        require(now() >= scheduledAt!! + self.timelockDelay, "Timelock not expired");

        // 3 sends below (burn LP + OC + USDT payout), sendGas each from pool balance.
        require(self.lpJettonWallet != null, "LP wallet not set");
        require(ctx.value >= 3 * self.sendGas, "Insufficient gas for removal");

        let lp: Int = lpAmount!!;

        // Calculate share
        let shareOC: Int = lp * self.reserveOC / self.totalLpSupply;
        let shareUSDT: Int = lp * self.reserveUSDT / self.totalLpSupply;

        // Safety: check min reserve
        require(self.reserveUSDT - shareUSDT >= self.minReserveUSDT || self.totalLpSupply == lp, "Below min reserve");

        // Update reserves
        self.reserveOC = self.reserveOC - shareOC;
        self.reserveUSDT = self.reserveUSDT - shareUSDT;
        self.totalLpSupply = self.totalLpSupply - lp;

        // Clear removal
        self.removeLpAmount.set(userHash, 0);
        self.removeScheduledAt.set(userHash, 0);
        self.removeUser.set(userHash, null);

        // Burn the deposited LP so the master's totalSupply actually drops (record cleared
        // above, so no double-execute). On burn bounce, bounced<DexTokenBurn> re-credits supply.
        self._burnLp(lp, msg.queryId);

        // Send OC to user
        if (shareOC > 0) {
            self._sendJetton(self.ocJettonWallet!!, user, shareOC, user, 0, self.TAG_RESERVE);
        }

        // Send USDT to user
        if (shareUSDT > 0) {
            self._sendJetton(self.usdtJettonWallet!!, user, shareUSDT, user, 0, self.TAG_RESERVE);
        }
    }

    receive(msg: CancelRemoveLiquidity) {
        let ctx: Context = context();
        let user: Address = ctx.sender;
        let userHash: Int = self._addressHash(user);

        let lp: Int? = self.removeLpAmount.get(userHash);
        require(lp != null && lp!! > 0, "No pending removal");
        require(self.lpJettonWallet != null, "LP wallet not set");
        require(ctx.value >= self.sendGas, "Insufficient gas");

        // Clear first so a cancel can't double-spend or race ExecuteRemoveLiquidity.
        self.removeLpAmount.set(userHash, 0);
        self.removeScheduledAt.set(userHash, 0);
        self.removeUser.set(userHash, null);

        // Return the LP the user deposited. Reserves were never touched at schedule time.
        self._sendJetton(self.lpJettonWallet!!, user, lp!!, user, 0, self.TAG_REFUND);
    }

    // ============================================================
    // Fee Calculation
    // ============================================================

    fun _calculateFees(amount: Int): FeeResult {
        let totalBps: Int = self.lpFeeBps + self.protocolFeeBps + self.burnFeeBps;
        let totalFee: Int = amount * totalBps / self.FEE_DENOMINATOR;
        let protocolFee: Int = amount * self.protocolFeeBps / self.FEE_DENOMINATOR;
        let burnFee: Int = amount * self.burnFeeBps / self.FEE_DENOMINATOR;
        let lpFee: Int = totalFee - protocolFee - burnFee;
        return FeeResult{
            totalFee: totalFee,
            lpFee: lpFee,
            protocolFee: protocolFee,
            burnFee: burnFee
        };
    }

    // Sell-side fee. During the launch window the whole launchSellFeeBps goes to the protocol
    // wallet (protocolFee) with no LP/burn share — it's an anti-dump penalty, not an LP reward.
    // After the window, falls back to the normal lp/protocol/burn split.
    fun _effectiveSellFee(amount: Int): FeeResult {
        if (now() < self.launchEndsAt) {
            let fee: Int = amount * self.launchSellFeeBps / self.FEE_DENOMINATOR;
            return FeeResult{
                totalFee: fee,
                lpFee: 0,
                protocolFee: fee,
                burnFee: 0
            };
        }
        return self._calculateFees(amount);
    }

    // ============================================================
    // Helpers
    // ============================================================

    fun _sendJetton(jettonWallet: Address, to: Address, amount: Int, responseDestination: Address, forwardTonAmount: Int, tag: Int) {
        // queryId = [ tag : top 2 bits ][ seq : low 62 bits ]. Lets bounced<DexTokenTransfer>
        // recover the transfer's purpose (only queryId + amount survive a bounce).
        let seq: Int = self.transferSeq % (1 << 62);
        self.transferSeq = self.transferSeq + 1;
        send(SendParameters{
            to: jettonWallet,
            value: self.sendGas,
            mode: 0,
            bounce: true,
            body: DexTokenTransfer{
                queryId: (tag << 62) | seq,
                amount: amount,
                destination: to,
                response_destination: responseDestination,
                custom_payload: null,
                forward_ton_amount: forwardTonAmount,
                // A single Either bit (0 = inline, empty). The OLD `rawSlice("F")` set the
                // leading bit to 1 ("payload in ref") with NO ref, so the governed USDT
                // wallet underflowed (exit code 9) and the transfer bounced.
                forward_payload: emptyForwardPayload()
            }.toCell()
        });
    }

    fun _burnOc(amount: Int, queryId: Int) {
        send(SendParameters{
            to: self.ocJettonWallet!!,
            value: self.sendGas,
            mode: 0,
            bounce: true,
            body: DexTokenBurn{
                queryId: queryId,
                amount: amount,
                owner: myAddress(),
                response_destination: myAddress()
            }.toCell()
        });
    }

    // Burn LP from the pool's own LP wallet (pool == owner, so its sender check passes).
    fun _burnLp(amount: Int, queryId: Int) {
        send(SendParameters{
            to: self.lpJettonWallet!!,
            value: self.sendGas,
            mode: 0,
            bounce: true,
            body: DexTokenBurn{
                queryId: queryId,
                amount: amount,
                owner: myAddress(),
                response_destination: myAddress()
            }.toCell()
        });
    }

    fun _clearPending(userHash: Int) {
        self.pendingOC.set(userHash, null);
        self.pendingUSDT.set(userHash, null);
        self.pendingUser.set(userHash, null);
        self.pendingTimestamp.set(userHash, null);
    }

    fun _addressHash(addr: Address): Int {
        return beginCell().storeAddress(addr).endCell().hash();
    }

    fun _sqrt(x: Int): Int {
        if (x == 0) {
            return 0;
        }
        let z: Int = x;
        let y: Int = (z + 1) / 2;
        while (y < z) {
            z = y;
            y = (x / z + z) / 2;
        }
        return z;
    }

    // ============================================================
    // Getters
    // ============================================================

    // poll the pool's TON float and top up before it runs dry. Floor = 3 * sendGas.
    get fun get_ton_balance(): Int {
        return myBalance();
    }

    get fun get_recommended_ton_floor(): Int {
        return 3 * self.sendGas;
    }

    get fun get_permit_pubkey(): Int {
        return self.permitPublicKey;
    }

    get fun get_global_daily_sold(): GlobalDailySold {
        // Reflect a stale window as already reset (sold 0, fresh cap) so off-chain readers see
        // the live remaining allowance without waiting for the next sell to roll the window.
        if (self.globalDayStart == 0 || now() - self.globalDayStart >= self.DAY) {
            return GlobalDailySold{
                sold: 0,
                cap: self.reserveOC * self.dailySellLimitBps / self.FEE_DENOMINATOR,
                windowStart: now()
            };
        }
        return GlobalDailySold{
            sold: self.globalDaySoldOC,
            cap: self.globalDayCapOC,
            windowStart: self.globalDayStart
        };
    }

    get fun get_reserves(): PoolReserves {
        return PoolReserves{
            reserveOC: self.reserveOC,
            reserveUSDT: self.reserveUSDT,
            totalLpSupply: self.totalLpSupply
        };
    }

    get fun get_config(): PoolConfig {
        return PoolConfig{
            owner: self.owner,
            paused: self.paused,
            maxSwapBps: self.maxSwapBps,
            minReserveUSDT: self.minReserveUSDT,
            timelockDelay: self.timelockDelay,
            protocolWallet: self.protocolWallet,
            deployedAt: self.deployedAt,
            lpFeeBps: self.lpFeeBps,
            protocolFeeBps: self.protocolFeeBps,
            burnFeeBps: self.burnFeeBps,
            lpMaster: self.lpMaster,
            lpJettonWallet: self.lpJettonWallet,
            burnEnabled: self.burnEnabled,
            publicAddLiquidity: self.publicAddLiquidity
        };
    }

    get fun get_launch_info(): LaunchInfo {
        return LaunchInfo{
            launchEndsAt: self.launchEndsAt,
            launchSellFeeBps: self.launchSellFeeBps,
            started: self.launchStarted,
            active: self.launchStarted && now() < self.launchEndsAt
        };
    }

    get fun get_pending_deposit(user: Address): PendingDepositInfo {
        let userHash: Int = self._addressHash(user);
        let ocAmount: Int? = self.pendingOC.get(userHash);
        let usdtAmount: Int? = self.pendingUSDT.get(userHash);
        let ts: Int? = self.pendingTimestamp.get(userHash);
        return PendingDepositInfo{
            user: user,
            ocAmount: ocAmount != null ? ocAmount!! : 0,
            usdtAmount: usdtAmount != null ? usdtAmount!! : 0,
            timestamp: ts != null ? ts!! : 0
        };
    }

    get fun get_removal_info(user: Address): RemovalInfo {
        let userHash: Int = self._addressHash(user);
        let lp: Int? = self.removeLpAmount.get(userHash);
        let ts: Int? = self.removeScheduledAt.get(userHash);
        return RemovalInfo{
            user: user,
            lpAmount: lp != null ? lp!! : 0,
            scheduledAt: ts != null ? ts!! : 0
        };
    }

    // Estimate swap output (view only)
    get fun estimate_swap_oc_to_usdt(inputOC: Int): Int {
        if (self.reserveOC == 0 || self.reserveUSDT == 0) {
            return 0;
        }
        let fees: FeeResult = self._effectiveSellFee(inputOC);
        let swapAmount: Int = inputOC - fees.totalFee;
        let k: Int = self.reserveOC * self.reserveUSDT;
        let newReserveOC: Int = self.reserveOC + swapAmount + fees.lpFee;
        return self.reserveUSDT - (k + newReserveOC - 1) / newReserveOC;
    }

    get fun estimate_swap_usdt_to_oc(inputUSDT: Int): Int {
        if (self.reserveOC == 0 || self.reserveUSDT == 0) {
            return 0;
        }
        let fees: FeeResult = self._calculateFees(inputUSDT);
        let swapAmount: Int = inputUSDT - fees.totalFee;
        let k: Int = self.reserveOC * self.reserveUSDT;
        let newReserveUSDT: Int = self.reserveUSDT + swapAmount + fees.lpFee;
        return self.reserveOC - (k + newReserveUSDT - 1) / newReserveUSDT;
    }
}