import "@stdlib/deploy";
import "./protocol/opcodes.tact";
import "./protocol/types.tact";
import "./protocol/actions.tact";

// Using Address directly as dictionary keys
// ===================================================================
// 🏦 Reekt.Fun Storage & Proxy Contract (TACT Edition) - SECURED & COMPLETE
// ===================================================================
// This contract holds ALL funds and state. It is the single source of
// truth. It delegates business logic to an upgradeable `logic` contract
// and executes the deterministic actions it receives in response.
// This is a complete port of the FunC v2 storage contract logic.
// ===================================================================

// --- Storage Structs (Internal Physical Layout, mirroring FunC V2) ---
struct StorageKeys {
    adminPublicKey: Int;
    serverPublicKey: Int;
    serverNonce: Int;
    adminNonce: Int;
}

struct StorageFinancial {
    minReserve: Int;
    houseBalance: Int;
    poolLiquidity: Int;
    reservedExposure: Int; // sum of max payout caps for active games
    adminCommittedOutstanding: Int; // remaining admin capital to recover
    affiliatePot: Int; // dedicated pot for affiliate commissions
}

struct StorageConfig {
    maxBetPercent: Int;
    maxPayoutPercent: Int;
    withdrawalFeePercent: Int;
    affiliateCommissionPercent: Int;
    lockupPeriod: Int;
}

struct StorageDicts {
    users: map<Address, Cell>;
    games: map<Int, Cell>;
}

// View structs
struct HealthReport {
    healthLevel: Int;
    daysCovered: Int;
    annualStorageCost: Int;
    message: Cell;
}

// Struct views for getters that previously returned raw tensors
struct GameStatistics {
    total: Int;
    active: Int;
    won: Int;
    lost: Int;
}

struct PoolLiquidityStatus {
    poolLiquidity: Int;
    committed: Int;
    available: Int;
    totalBalance: Int;
    adminCommittedOutstanding: Int;
}

// Suggested bet options for UI
struct BetOptionsView {
    min: Int;      // 0.01 TON
    third: Int;    // floor(max/3) to 0.01 TON
    half: Int;     // floor(max/2) to 0.01 TON
    max: Int;      // floor(max) to 0.01 TON
    quant: Int;    // 0.01 TON
}

struct ProxyInfo {
    logicAddress: Address;
    adminPublicKey: Int;
    serverPublicKey: Int;
    isPaused: Bool;
}

struct StatusKeys {
    logicAddress: Address;
    isPaused: Bool;
    adminNonce: Int;
    serverNonce: Int;
}

struct ContractInfo {
    totalBalance: Int;
    houseBalance: Int;
    poolLiquidity: Int;
    minReserve: Int;
    isPaused: Bool;
    nextGameId: Int;
}

struct NonceStatus {
    serverNonce: Int;
    adminNonce: Int;
}

// Additional analytics views
struct EnhancedFinancialHealth {
    balance: Int;
    houseBalance: Int;
    poolLiquidity: Int;
    availableForPayouts: Int;
    storageCost: Int;
    reserveMargin: Int;
    affiliateLiability: Int;
}

struct AffiliateLiabilityReport {
    totalLiability: Int;
    affiliateCount: Int;
    maxSingleBalance: Int;
    highBalanceCount: Int;
}

struct AffiliateStatus {
    banned: Bool;
    balance: Int;
    nonce: Int;
    publicKey: Int;
}

// View for listing affiliates by index
struct AffiliateView {
    address: Address?;
    balance: Int;
    banned: Bool;
    publicKey: Int;
    codeHash: Int;
}

//

// Correctly spelled alias for external consumers; keep old struct for compatibility
struct PruningRecommendations {
    prunableGames: Int;
    estimatedStorageSavings: Int;
    totalGames: Int;
}

struct GameAgeDistribution {
    age0to30: Int;
    age31to90: Int;
    age91to180: Int;
    age180plus: Int;
}

struct GameSession {
    player: Address;
    betAmount: Int;
    hashCommitment: Cell;
    createdAt: Int;
    status: Int;
    payoutAmount: Int;
    multiplier: Int;
    maxPayoutForGame: Int;
    moves: Cell;
    gameConfig: Cell;
    gameSeed: Cell;
    gameSalt: Cell;
    finalGameState: Cell;
}

// Typed record for user withdrawals view
struct WithdrawalRecord {
    gameId: Int;
    date: Int;   // uses game.createdAt (cashout timestamp not stored)
    amount: Int; // payoutAmount
}

struct WithdrawalsPage {
    count: Int; // number of records encoded in items
    items: Cell; // packed list of (uint64 gameId, uint32 date, coins amount)
}

// Fixed-size typed page (up to 10 records)
struct WithdrawalsTypedPage10 {
    count: Int;
    r1: WithdrawalRecord;
    r2: WithdrawalRecord;
    r3: WithdrawalRecord;
    r4: WithdrawalRecord;
    r5: WithdrawalRecord;
    r6: WithdrawalRecord;
    r7: WithdrawalRecord;
    r8: WithdrawalRecord;
    r9: WithdrawalRecord;
    r10: WithdrawalRecord;
}

// --- Main Storage Layout ---
struct Storage {
    version: Int;
    initialized: Bool;
    logicAddress: Address;
    // Timelocked upgrade state
    upgradeProposed: Bool;
    proposedLogic: Address;
    proposedCodeHash: Int;
    upgradeEta: Int;
    isPaused: Bool;
    nextGameId: Int;
    keys: StorageKeys;
    financial: StorageFinancial;
    config: StorageConfig;
    dicts: StorageDicts;
    affiliateRegistryRoot: Int; // root over (codeHash, address, pubKey, banned, index)
    currentAffEpoch: Int;       // current earnings epoch
    affEarningsRoots: map<Int, Int>; // epoch -> root
    usedClaims: map<Int, Int>;  // nullifier -> 1
    activeGamesRoot: Int;       // rolling root for recent/active window
    gameEpochRoots: map<Int, Int>; // epoch -> sealed games root
}


contract ReektStorageProxy {

    storage: Storage;

    // ==================================================
    // ⚙️ DEPLOYMENT & INITIALIZATION
    // ==================================================
    init(logicAddress: Address, adminPublicKey: Int, serverPublicKey: Int) {
            self.storage = Storage{
            version: STORAGE_VERSION,
            initialized: true,
            isPaused: true, // Start paused for safety
            logicAddress: logicAddress,
                upgradeProposed: false,
                proposedLogic: logicAddress,
                proposedCodeHash: 0,
                upgradeEta: 0,
            nextGameId: 1,
            keys: StorageKeys{
                adminPublicKey: adminPublicKey,
                serverPublicKey: serverPublicKey,
                serverNonce: 0,
                adminNonce: 0
            },
            financial: StorageFinancial{
                minReserve: ton("2.0"),
                houseBalance: 0,
                poolLiquidity: 0,
                reservedExposure: 0,
                adminCommittedOutstanding: 0,
                affiliatePot: 0
            },
            config: StorageConfig{
                maxBetPercent: 100,    // 1%
                maxPayoutPercent: 500, // 5%
                withdrawalFeePercent: 500, // 5% (basis points)
                affiliateCommissionPercent: 500, // 5%
                lockupPeriod: 604800 // 7 days in seconds
            },
            dicts: StorageDicts{
                users: emptyMap(),
                games: emptyMap()
            },
            affiliateRegistryRoot: 0,
            currentAffEpoch: 0,
            affEarningsRoots: emptyMap(),
            usedClaims: emptyMap(),
            activeGamesRoot: 0,
            gameEpochRoots: emptyMap()
        };
    }

    receive(deploy: Deploy) {
        // keep enough to avoid pruning; adjust if you prefer
        let keep: Int = ton("0.50");
        let incoming: Int = context().value;
        let refund: Int = incoming > keep ? (incoming - keep) : 0;

        let ok: Cell = DeployOk{ queryId: deploy.queryId }.toCell();

        // send back DeployOk with refund, paying gas separately; do NOT use carry-remaining mode
        message(MessageParameters{
            to: sender(),
            value: refund,
            mode: SendPayGasSeparately,
            body: ok
        });
    }

    // ==================================================
    // 📩 MESSAGE ROUTER (COMPLETE)
    // ==================================================
    receive(msg: Slice) {
        throwUnless(ERROR_NOT_INITIALIZED, self.storage.initialized);
        let cs: Slice = msg;

        // Route A: Response from our own Logic Contract (always allowed)
        if (context().sender == self.storage.logicAddress) {
            self.handleLogicResponse(cs);
            return;
        }

        let op: Int = cs.loadUint(32);

        // Route B: Admin Operations (Can bypass pause state)
        if (op >= 0xF00 && op <= 0xFFF) {
            self.handleAdminOperation(op, cs);
            return;
        }
        
        // --- Pause Gate for all subsequent user operations ---
        throwUnless(ERROR_CONTRACT_PAUSED, !self.storage.isPaused);

        // Route C: Affiliate Direct Withdrawal (Cannot bypass pause state)
        if (op == OP_AFFILIATE_WITHDRAW_DIRECT) {
            self.handleAffiliateWithdraw(cs);
            return;
        }

        // Route C2 removed: affiliate registration handled via Merkle root only

        // Route D: User Game Operations
        if (op == OP_CREATE_GAME) { self.delegateCreateGame(cs); } 
        else if (op == OP_CASHOUT) { self.delegateCashout(cs); } 
        else if (op == OP_MARK_LOST) { self.delegateMarkLost(cs); }
        else { throw(ERROR_UNAUTHORIZED); }
    }

    // ==================================================
    // 🎮 GAME OPERATIONS (DELEGATION TO LOGIC)
    // ==================================================
    fun delegateCreateGame(cs: Slice) {
        let player: Address = cs.loadAddress();
        let bet: Int = cs.loadCoins();
        let hashCommit: Cell = cs.loadRef();
        // Optional affiliate code: encoded as presence bit followed by ref when present
        let hasAffiliate: Int = cs.loadUint(1);
        // For first-write binding: if hasAffiliate==1, the next ref is an affiliate bundle Cell:
        // bundle := ref(codeCell) + address + pubKey(256) + bannedBit(1) + index(32) + ref(regProof)
        let affiliateBundle: Cell? = null;
        if (hasAffiliate == 1) {
            affiliateBundle = cs.loadRef();
        }
        let gameConfig: Cell = cs.loadRef();
        let serverTimestamp: Int = cs.loadUint(32);
        let serverSig: Cell = cs.loadRef();

        // Payment validation: require msg value to cover bet (gas is paid separately by sender)
        throwUnless(ERROR_INSUFFICIENT_FUNDS, context().value >= bet);

        // Storage-side pre-checks to avoid wasteful delegation
        // 1) Pause already checked in router
        // 2) Bet cap based on current pool and limits
        let maxBetCap: Int = self.storage.financial.poolLiquidity * self.storage.config.maxBetPercent / PERCENT_BASE;
        throwUnless(ERROR_BET_TOO_HIGH, bet <= maxBetCap);
        // 3) Server signature freshness window (match logic ±300s)
        throwUnless(ERROR_SIGNATURE_EXPIRED, now() <= (serverTimestamp + 300) && now() >= (serverTimestamp - 300));

        // Allocate but only advance nextGameId after success response
        let allocatedGameId: Int = self.storage.nextGameId;
        let expectedNonce: Int = self.storage.keys.serverNonce + 1;
        // Do not advance serverNonce yet; only after successful logic response via applyDeltas

        // Pre-verify server signature canonically (storage-side spam filter)
        let serverMsg: Cell = buildCreateSigMessage(player, bet, hashCommit, expectedNonce, serverTimestamp);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(serverMsg.hash(), serverSig.asSlice(), self.storage.keys.serverPublicKey));

        // Build request body exactly as Logic.receive expects
        let existingUserCell: Cell? = self.storage.dicts.users.get(player);
        let views1: Cell = beginCell()
            .storeUint(self.storage.isPaused ? 1 : 0, 1)
            .storeUint(self.storage.keys.adminPublicKey, 256)
            .storeUint(self.storage.keys.serverPublicKey, 256)
            .storeCoins(self.storage.financial.poolLiquidity)
            .storeUint(self.storage.config.maxBetPercent, 16)
            .storeUint(self.storage.config.maxPayoutPercent, 16)
            .storeUint(self.storage.config.withdrawalFeePercent, 16)
            .storeUint(self.storage.config.lockupPeriod, 32)
            .storeUint(self.storage.config.affiliateCommissionPercent, 16)
            .endCell();
        // Resolve affiliate bundle via registry Merkle proof if present and user has no existing record
        let resolvedAffiliateAddr: Address? = null;
        if (existingUserCell == null && affiliateBundle != null) {
            let bs: Slice = affiliateBundle!!.asSlice();
            let codeCell: Cell = bs.loadRef();
            let affAddr: Address = bs.loadAddress();
            let pubKey: Int = bs.loadUint(256);
            let bannedBit: Int = bs.loadUint(1);
            let index: Int = bs.loadUint(32);
            let regProof: Cell = bs.loadRef();
            // Verify against on-chain affiliateRegistryRoot
            let codeHash: Int = codeCell.hash();
            let regLeaf: Int = buildAffiliateRegistryLeafHash(codeHash, affAddr, pubKey, bannedBit, index);
            if (bannedBit == 0 && verifyMerkle(regLeaf, self.storage.affiliateRegistryRoot, regProof)) {
                resolvedAffiliateAddr = affAddr;
            }
        }

        let body = beginCell()
            .storeUint(OP_MSG_CREATE_GAME_REQ, 32)
            .storeRef(views1)
            // Params
            .storeAddress(player)
            .storeCoins(bet)
            .storeRef(hashCommit)
            .storeUint(resolvedAffiliateAddr != null ? 1 : 0, 1);
        if (resolvedAffiliateAddr != null) { body = body.storeRef(beginCell().storeAddress(resolvedAffiliateAddr!!).endCell()); }
        body = body
            .storeRef(gameConfig)
            .storeUint(serverTimestamp, 32)
            .storeRef(serverSig)
            // Context
            .storeUint(allocatedGameId, 64)
            .storeUint(expectedNonce, 64)
            .storeUint(existingUserCell != null ? 1 : 0, 1);
        if (existingUserCell != null) { body = body.storeRef(existingUserCell!!); }
        // Never forward attached bet to logic; send 0-value and pay gas separately
        // Provide minimal value to ensure delivery in sandbox
        send(SendParameters{ 
            to: self.storage.logicAddress, 
            value: ton("0.05"), 
            mode: SendPayGasSeparately, 
            body: body.endCell() 
        });
    }

    fun delegateCashout(cs: Slice) {
        let gameId: Int = cs.loadUint(64);
        let payout: Int = cs.loadCoins();
        let mult: Int = cs.loadUint(16);
        let moves: Cell = cs.loadRef();
        let seed: Cell = cs.loadRef();
        let salt: Cell = cs.loadRef();
        let finalState: Cell = cs.loadRef();
        let backendComm: Int = cs.loadCoins();
        // Read signature as bits to keep top-level ref count ≤ 4
        let serverSigBits: Slice = cs.loadBits(512);
        let serverSig: Cell = beginCell().storeSlice(serverSigBits).endCell();

        let gameCell: Cell = self.storage.dicts.games.get(gameId)!!;
        let playerAddr: Address = gameCell.asSlice().loadAddress();
        let userCell: Cell = self.storage.dicts.users.get(playerAddr)!!;

        let expectedNonce: Int = self.storage.keys.serverNonce + 1;
        // Do not advance serverNonce yet; only after successful logic response via applyDeltas

        // Storage-side basic bound checks to reduce spam
        throwUnless(ERROR_PAYOUT_TOO_HIGH, payout <= self.storage.financial.poolLiquidity);

        // Pre-verify server signature canonically where possible
        let cashSig: Cell = buildCashoutSigMessage(gameId, payout, mult, moves, expectedNonce);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(cashSig.hash(), serverSig.asSlice(), self.storage.keys.serverPublicKey));

        // Build request body exactly as Logic.receive expects
        let views2: Cell = beginCell()
            .storeUint(self.storage.isPaused ? 1 : 0, 1)
            .storeUint(self.storage.keys.adminPublicKey, 256)
            .storeUint(self.storage.keys.serverPublicKey, 256)
            .storeCoins(self.storage.financial.poolLiquidity)
            .storeUint(self.storage.config.maxBetPercent, 16)
            .storeUint(self.storage.config.maxPayoutPercent, 16)
            .storeUint(self.storage.config.withdrawalFeePercent, 16)
            .storeUint(self.storage.config.lockupPeriod, 32)
            .storeUint(self.storage.config.affiliateCommissionPercent, 16)
            .endCell();
        let body2 = beginCell()
            .storeUint(OP_MSG_CASHOUT_REQ, 32)
            .storeRef(views2)
            // Params
            .storeCoins(payout)
            .storeUint(mult, 16)
            .storeRef(moves)
            .storeRef(seed)
            .storeRef(salt)
            .storeRef(finalState)
            .storeCoins(backendComm)
            .storeRef(serverSig)
            // Context
            .storeUint(gameId, 64)
            .storeUint(expectedNonce, 64)
            .storeRef(gameCell)
            .storeRef(userCell);
        send(SendParameters{ 
            to: self.storage.logicAddress, 
            value: ton("0.05"), 
            mode: SendPayGasSeparately, 
            body: body2.endCell() 
        });
    }

    fun delegateMarkLost(cs: Slice) {
        let gameId: Int = cs.loadUint(64);
        let seed: Cell = cs.loadRef();
        let salt: Cell = cs.loadRef();
        let finalState: Cell = cs.loadRef();
        let serverSig: Cell = cs.loadRef();
        
        let gameCell: Cell = self.storage.dicts.games.get(gameId)!!;
        let playerAddr: Address = gameCell.asSlice().loadAddress();
        let userCell: Cell = self.storage.dicts.users.get(playerAddr)!!;

        let expectedNonce: Int = self.storage.keys.serverNonce + 1;
        // Do not advance serverNonce yet; only after successful logic response via applyDeltas

        // Pre-verify server signature canonically
        let lostSig: Cell = buildMarkLostSigMessage(gameId, seed, salt, expectedNonce);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(lostSig.hash(), serverSig.asSlice(), self.storage.keys.serverPublicKey));

        // Build request body exactly as Logic.receive expects
        let views3: Cell = beginCell()
            .storeUint(self.storage.isPaused ? 1 : 0, 1)
            .storeUint(self.storage.keys.adminPublicKey, 256)
            .storeUint(self.storage.keys.serverPublicKey, 256)
            .endCell();
        let body3 = beginCell()
            .storeUint(OP_MSG_MARK_LOST_REQ, 32)
            .storeRef(views3)
            // Params
            .storeRef(seed)
            .storeRef(salt)
            .storeRef(finalState)
            .storeRef(serverSig)
            // Context
            .storeUint(gameId, 64)
            .storeUint(expectedNonce, 64)
            .storeRef(gameCell)
            .storeRef(userCell);

        send(SendParameters{ 
            to: self.storage.logicAddress, 
            value: ton("0.05"), 
            mode: SendPayGasSeparately, 
            body: body3.endCell() 
        });
    }
    
    // ==================================================
    // 🧠 LOGIC RESPONSE HANDLER
    // ==================================================
    fun handleLogicResponse(responseSlice: Slice) {
        let op = responseSlice.preloadUint(32);

        if (op == OP_MSG_CREATE_GAME_RESP) {
            responseSlice.loadUint(32);
            let payload: Cell = responseSlice.loadRef();
            let ps: Slice = payload.asSlice();
            let okf: Int = ps.loadUint(1);
            throwUnless(ERROR_GAME_NOT_CREATED, okf == 1);
            let gameId: Int = ps.loadUint(64);
            let houseDelta: Int = ps.loadCoins();
            let poolDelta: Int = ps.loadCoins();
            let serverNonce: Int = ps.loadUint(64);
            let inner: Cell = ps.loadRef();
            let ins: Slice = inner.asSlice();
            let gameCell: Cell = ins.loadRef();
            let userDelta: Cell = ins.loadRef();
            let confirm: Cell = ins.loadRef();
            self.applyDeltas(PoolDelta{ houseBalanceDelta: houseDelta, poolLiquidityDelta: poolDelta }, NonceDelta{ serverNonce: serverNonce });
            self.storage.dicts.games.set(gameId, gameCell);
            // Track reserved exposure for active game
            let gcs: Slice = gameCell.asSlice();
            gcs.loadAddress();
            gcs.loadCoins();
            gcs.loadRef();
            gcs.loadUint(32);
            let statusCreate: Int = gcs.loadUint(8);
            gcs.loadCoins();
            gcs.loadUint(16);
            gcs.loadRef();
            let maxPayoutCapCreate: Int = gcs.loadCoins();
            if (statusCreate == 0) {
                self.storage.financial.reservedExposure += maxPayoutCapCreate;
            }
            self.applyUserDelta(userDelta);
            self.executeAction(confirm);
            // Advance nextGameId only after successful creation
            if (gameId == self.storage.nextGameId) { self.storage.nextGameId = gameId + 1; }
        } else if (op == OP_MSG_CASHOUT_RESP) {
            responseSlice.loadUint(32);
            let payload: Cell = responseSlice.loadRef();
            let ps: Slice = payload.asSlice();
            let okf: Int = ps.loadUint(1);
            throwUnless(ERROR_CASHOUT_FAILED, okf == 1);
            let gameId: Int = ps.loadUint(64);
            let houseDelta: Int = ps.loadCoins();
            let poolDelta: Int = ps.loadCoins();
            let serverNonce: Int = ps.loadUint(64);
            let inner: Cell = ps.loadRef();
            let ins: Slice = inner.asSlice();
            let updatedGame: Cell = ins.loadRef();
            let userDelta: Cell = ins.loadRef();
            let payoutMsg: Cell = ins.loadRef();
            let affiliateCell: Cell = ins.loadRef();
            self.applyDeltas(PoolDelta{ houseBalanceDelta: houseDelta, poolLiquidityDelta: poolDelta }, NonceDelta{ serverNonce: serverNonce });
            self.storage.dicts.games.set(gameId, updatedGame);
            // Remove reserved exposure when game finishes (cashout)
            let ucs: Slice = updatedGame.asSlice();
            ucs.loadAddress();
            ucs.loadCoins();
            ucs.loadRef();
            ucs.loadUint(32);
            let statusCash: Int = ucs.loadUint(8);
            ucs.loadCoins();
            ucs.loadUint(16);
            // skip refs: gameConfig, moves, seed, salt, finalState
            ucs.loadRef();
            ucs.loadRef();
            ucs.loadRef();
            ucs.loadRef();
            ucs.loadRef();
            if (statusCash != 0) {
                // If finished, tail coin is still maxPayoutForGame
                let maxPayoutCapCash: Int = ucs.loadCoins();
                self.storage.financial.reservedExposure -= maxPayoutCapCash;
                if (self.storage.financial.reservedExposure < 0) { self.storage.financial.reservedExposure = 0; }
            }
            self.applyUserDelta(userDelta);
            // Credit affiliate commission to dedicated pot if present
            let affs: Slice = affiliateCell.asSlice();
            let hasAff: Int = affs.loadUint(1);
            if (hasAff == 1) {
                affs.loadAddress();
                let affAmount: Int = affs.loadCoins();
                if (affAmount > 0) { self.storage.financial.affiliatePot += affAmount; }
            }
            self.executeAction(payoutMsg);
        } else if (op == OP_MSG_MARK_LOST_RESP) {
            responseSlice.loadUint(32);
            let payload: Cell = responseSlice.loadRef();
            let ps: Slice = payload.asSlice();
            let okf: Int = ps.loadUint(1);
            throwUnless(ERROR_MARK_LOST_FAILED, okf == 1);
            let gameId: Int = ps.loadUint(64);
            let houseDelta: Int = ps.loadCoins();
            let poolDelta: Int = ps.loadCoins();
            let serverNonce: Int = ps.loadUint(64);
            let inner: Cell = ps.loadRef();
            let ins: Slice = inner.asSlice();
            let updatedGame: Cell = ins.loadRef();
            let userDelta: Cell = ins.loadRef();
            let confirmMsg: Cell = ins.loadRef();
            self.applyDeltas(PoolDelta{ houseBalanceDelta: houseDelta, poolLiquidityDelta: poolDelta }, NonceDelta{ serverNonce: serverNonce });
            self.storage.dicts.games.set(gameId, updatedGame);
            // Remove reserved exposure when game finishes (lost)
            let ucs2: Slice = updatedGame.asSlice();
            ucs2.loadAddress();
            ucs2.loadCoins();
            ucs2.loadRef();
            ucs2.loadUint(32);
            let statusLost: Int = ucs2.loadUint(8);
            ucs2.loadCoins();
            ucs2.loadUint(16);
            // skip refs: gameConfig, moves, seed, salt, finalState
            ucs2.loadRef();
            ucs2.loadRef();
            ucs2.loadRef();
            ucs2.loadRef();
            ucs2.loadRef();
            if (statusLost != 0) {
                let maxPayoutCapLost: Int = ucs2.loadCoins();
                self.storage.financial.reservedExposure -= maxPayoutCapLost;
                if (self.storage.financial.reservedExposure < 0) { self.storage.financial.reservedExposure = 0; }
            }
            self.applyUserDelta(userDelta);
            self.executeAction(confirmMsg);
        } else {
            throw(ERROR_INVALID_RESPONSE);
        }
    }
    
    // ==================================================
    // 👑 ADMIN & FINANCIAL FUNCTIONS
    // ==================================================
    fun handleAdminOperation(op: Int, cs: Slice) {
        let nonce: Int = cs.loadUint(64);
        let deadline: Int = cs.loadUint(32);
        
        throwUnless(ERROR_NONCE_MISMATCH, nonce == self.storage.keys.adminNonce + 1);
        throwUnless(ERROR_SIGNATURE_EXPIRED, now() <= deadline);

        // Build canonical message for signature verification while parsing params once
        let b = beginCell().storeUint(op, 32).storeUint(nonce, 64).storeUint(deadline, 32);

        // Local vars for applying after signature verified
        let newPaused: Bool = self.storage.isPaused;
        let newLogic: Address = self.storage.logicAddress;
        let newServerKey: Int = self.storage.keys.serverPublicKey;
        let adjMaxBet: Int = self.storage.config.maxBetPercent;
        let adjMaxPayout: Int = self.storage.config.maxPayoutPercent;
        let adjWithdrawFee: Int = self.storage.config.withdrawalFeePercent;
        let adjLockup: Int = self.storage.config.lockupPeriod;
        let adjAffiliateCommission: Int = self.storage.config.affiliateCommissionPercent;
        let amount: Int = 0;
        let recipient: Address = self.storage.logicAddress;
        let proposedAddr: Address = self.storage.logicAddress;
        let proposedCodeHash: Int = 0;
        let proposedEta: Int = 0;

        if (op == OP_ADMIN_TOGGLE_PAUSE) {
            let bit: Int = cs.loadUint(1);
            b = b.storeUint(bit, 1);
            newPaused = bit == 1;
        } else if (op == OP_ADMIN_UPGRADE_LOGIC) {
            let addr: Address = cs.loadAddress();
            b = b.storeAddress(addr);
            newLogic = addr;
        } else if (op == OP_ADMIN_SET_SERVER_KEY) {
            let pk: Int = cs.loadUint(256);
            b = b.storeUint(pk, 256);
            newServerKey = pk;
        } else if (op == OP_ADMIN_ADJUST_LIMITS) {
            let mb: Int = cs.loadUint(16);
            let mp: Int = cs.loadUint(16);
            let wf: Int = cs.loadUint(16);
            let ac: Int = cs.loadUint(16);
            let lp: Int = cs.loadUint(32);
            b = b.storeUint(mb, 16).storeUint(mp, 16).storeUint(wf, 16).storeUint(ac, 16).storeUint(lp, 32);
            adjMaxBet = mb; adjMaxPayout = mp; adjWithdrawFee = wf; adjAffiliateCommission = ac; adjLockup = lp;
        } else if (op == OP_ADMIN_SET_AFFILIATE_ROOT) {
            let root: Int = cs.loadUint(256);
            b = b.storeUint(root, 256);
            // reuse variable: proposedCodeHash as temporary holder
            proposedCodeHash = root;
        } else if (op == OP_ADMIN_SET_AFF_EPOCH_ROOT) {
            let epoch: Int = cs.loadUint(32);
            let rootE: Int = cs.loadUint(256);
            b = b.storeUint(epoch, 32).storeUint(rootE, 256);
            // stash into locals via proposed* and amount fields to apply later
            proposedEta = epoch;
            proposedCodeHash = rootE;
        } else if (op == OP_ADMIN_ROLL_AFF_EPOCH) {
            let newEpoch: Int = cs.loadUint(32);
            b = b.storeUint(newEpoch, 32);
            proposedEta = newEpoch;
        } else if (op == OP_ADMIN_SET_GAMES_EPOCH_ROOT) {
            let epochG: Int = cs.loadUint(32);
            let gamesRoot: Int = cs.loadUint(256);
            b = b.storeUint(epochG, 32).storeUint(gamesRoot, 256);
            proposedEta = epochG;
            proposedCodeHash = gamesRoot;
        } else if (op == OP_ADMIN_PRUNE_GAMES_BATCH) {
            let idsCell: Cell = cs.loadRef(); // packed list of uint64 ids
            // Include a hash of idsCell into signature to bind exact batch
            b = b.storeUint(idsCell.hash(), 256);
        } else if (op == OP_ADMIN_PROPOSE_LOGIC_UPGRADE) {
            let addrP: Address = cs.loadAddress();
            let expectedHash: Int = cs.loadUint(256);
            let eta: Int = cs.loadUint(32);
            b = b.storeAddress(addrP).storeUint(expectedHash, 256).storeUint(eta, 32);
            proposedAddr = addrP; proposedCodeHash = expectedHash; proposedEta = eta;
        } else if (op == OP_ADMIN_ACTIVATE_LOGIC_UPGRADE) {
            // no extra fields for signature
        } else if (op == OP_ADMIN_CANCEL_LOGIC_UPGRADE) {
            // no extra fields for signature
        } else if (op == OP_ADMIN_ADD_POOL_CAPITAL || op == OP_ADMIN_MOVE_TO_POOL || op == OP_ADMIN_MOVE_TO_HOUSE) {
            let amt: Int = cs.loadCoins();
            b = b.storeCoins(amt);
            amount = amt;
        } else if (op == OP_ADMIN_BAN_AFFILIATE) {
            let addrBan: Address = cs.loadAddress();
            b = b.storeAddress(addrBan);
            recipient = addrBan; // reuse var for ban target
        } else if (op == OP_ADMIN_WITHDRAW_HOUSE) {
            let amtH: Int = cs.loadCoins();
            let addrH: Address = cs.loadAddress();
            b = b.storeCoins(amtH).storeAddress(addrH);
            amount = amtH; recipient = addrH;
        } else if (op == OP_ADMIN_WITHDRAW_POOL) {
            let amtP: Int = cs.loadCoins();
            let addrP: Address = cs.loadAddress();
            b = b.storeCoins(amtP).storeAddress(addrP);
            amount = amtP; recipient = addrP;
        }

        let signature: Slice = cs.loadBits(512);
        throwUnless(ERROR_UNAUTHORIZED, checkSignature(b.endCell().hash(), signature, self.storage.keys.adminPublicKey));
        self.storage.keys.adminNonce = nonce;

        if (op == OP_ADMIN_TOGGLE_PAUSE) {
            self.storage.isPaused = newPaused;
        } else if (op == OP_ADMIN_UPGRADE_LOGIC) {
            // Disable immediate upgrade in secured build; require timelock path
            throw(ERROR_UNAUTHORIZED);
        } else if (op == OP_ADMIN_PROPOSE_LOGIC_UPGRADE) {
            self.storage.upgradeProposed = true;
            self.storage.proposedLogic = proposedAddr;
            self.storage.proposedCodeHash = proposedCodeHash;
            self.storage.upgradeEta = proposedEta;
        } else if (op == OP_ADMIN_ACTIVATE_LOGIC_UPGRADE) {
            throwUnless(ERROR_NO_UPGRADE_PROPOSED, self.storage.upgradeProposed);
            throwUnless(ERROR_ETA_NOT_REACHED, now() >= self.storage.upgradeEta);
            // Optional: verify expected code hash of target address
            // Skipped due to lack of on-chain code hash read in Tact std
            self.storage.logicAddress = self.storage.proposedLogic;
            self.storage.upgradeProposed = false;
        } else if (op == OP_ADMIN_CANCEL_LOGIC_UPGRADE) {
            self.storage.upgradeProposed = false;
        } else if (op == OP_ADMIN_SET_SERVER_KEY) {
            self.storage.keys.serverPublicKey = newServerKey;
        } else if (op == OP_ADMIN_ADJUST_LIMITS) {
            self.storage.config.maxBetPercent = adjMaxBet;
            self.storage.config.maxPayoutPercent = adjMaxPayout;
            self.storage.config.withdrawalFeePercent = adjWithdrawFee;
            self.storage.config.affiliateCommissionPercent = adjAffiliateCommission;
            self.storage.config.lockupPeriod = adjLockup;
        } else if (op == OP_ADMIN_SET_AFFILIATE_ROOT) {
            self.storage.affiliateRegistryRoot = proposedCodeHash;
        } else if (op == OP_ADMIN_SET_AFF_EPOCH_ROOT) {
            self.storage.affEarningsRoots.set(proposedEta, proposedCodeHash);
        } else if (op == OP_ADMIN_ROLL_AFF_EPOCH) {
            self.storage.currentAffEpoch = proposedEta;
        } else if (op == OP_ADMIN_SET_GAMES_EPOCH_ROOT) {
            self.storage.gameEpochRoots.set(proposedEta, proposedCodeHash);
        } else if (op == OP_ADMIN_WITHDRAW_HOUSE) {
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= self.storage.financial.houseBalance);
            let availableAfter: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot) - amount;
            throwUnless(ERROR_RESERVE_VIOLATION, availableAfter >= self.storage.financial.minReserve);
            self.storage.financial.houseBalance -= amount;
            send(SendParameters{ to: recipient, value: amount, mode: SendPayGasSeparately, body: emptyCell() });
        } else if (op == OP_ADMIN_WITHDRAW_POOL) {
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= self.storage.financial.poolLiquidity);
            let committed: Int = self.calculateCommittedLiquidity();
            let availableLiquidity: Int = self.storage.financial.poolLiquidity - committed;
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= availableLiquidity);
            let availableAfterPool: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot) - amount;
            throwUnless(ERROR_RESERVE_VIOLATION, availableAfterPool >= self.storage.financial.minReserve);
            self.storage.financial.poolLiquidity -= amount;
            send(SendParameters{ to: recipient, value: amount, mode: SendPayGasSeparately, body: emptyCell() });
        } else if (op == OP_ADMIN_ADD_POOL_CAPITAL) {
            // Require the admin to attach exactly the capital amount as value
            throwUnless(ERROR_INSUFFICIENT_FUNDS, context().value == amount);
            self.storage.financial.poolLiquidity += amount;
            // Track admin capital outstanding
            self.storage.financial.adminCommittedOutstanding += amount;
        } else if (op == OP_ADMIN_MOVE_TO_POOL) {
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= self.storage.financial.houseBalance);
            self.storage.financial.houseBalance -= amount;
            self.storage.financial.poolLiquidity += amount;
            // Moving house→pool is not new committed capital; do not change outstanding
        } else if (op == OP_ADMIN_MOVE_TO_HOUSE) {
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= self.storage.financial.poolLiquidity);
            let committed: Int = self.calculateCommittedLiquidity();
            let availableLiquidity: Int = self.storage.financial.poolLiquidity - committed;
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= availableLiquidity);
            self.storage.financial.poolLiquidity -= amount;
            self.storage.financial.houseBalance += amount;
            // Reduce admin outstanding by the recovered portion, capped at outstanding
            let recover: Int = amount;
            if (recover > self.storage.financial.adminCommittedOutstanding) { recover = self.storage.financial.adminCommittedOutstanding; }
            self.storage.financial.adminCommittedOutstanding -= recover;
        }
    }

    // ==================================================
    // 🤝 AFFILIATE FUNCTIONS
    // ==================================================
    // Affiliate registration removed (handled via Merkle root off-chain)
    fun handleAffiliateWithdraw(cs: Slice) {
        // Merkle-based withdrawal: (epoch, index, amount, address, pubKey, bannedBit, codeHash, regProof, earnProof, timestamp, signature)
        let epoch: Int = cs.loadUint(32);
        let index: Int = cs.loadUint(32);
        let amount: Int = cs.loadCoins();
        let affiliateAddress: Address = cs.loadAddress();
        let providedPubKey: Int = cs.loadUint(256);
        let bannedBit: Int = cs.loadUint(1);
        let codeHash: Int = cs.loadUint(256);
        let regProof: Cell = cs.loadRef();
        let earnProof: Cell = cs.loadRef();
        let timestamp: Int = cs.loadUint(32);
        let signatureCell: Cell = cs.loadRef();
        let signature: Slice = signatureCell.asSlice();

        // 1) Verify affiliate registry membership
        let regLeaf: Int = buildAffiliateRegistryLeafHash(codeHash, affiliateAddress, providedPubKey, bannedBit, index);
        throwUnless(ERROR_UNAUTHORIZED, verifyMerkle(regLeaf, self.storage.affiliateRegistryRoot, regProof));
        throwUnless(ERROR_UNAUTHORIZED, bannedBit == 0);

        // 2) Verify earnings snapshot membership
        let rootOpt: Int? = self.storage.affEarningsRoots.get(epoch);
        let root: Int = rootOpt != null ? rootOpt!! : 0;
        throwUnless(ERROR_UNAUTHORIZED, root != 0);
        let earnLeaf: Int = buildAffiliateEarningsLeafHash(epoch, index, affiliateAddress, amount);
        throwUnless(ERROR_UNAUTHORIZED, verifyMerkle(earnLeaf, root, earnProof));

        // 3) Prevent double-claim via nullifier
        let nullifier: Int = buildClaimNullifier(epoch, index, affiliateAddress);
        let used: Int? = self.storage.usedClaims.get(nullifier);
        throwUnless(ERROR_UNAUTHORIZED, used == null);

        // 4) Verify affiliate-signed withdrawal intent (timestamped)
        let msgCell: Cell = beginCell()
            .storeUint(OP_AFFILIATE_WITHDRAW_DIRECT, 32)
            .storeUint(epoch, 32)
            .storeUint(index, 32)
            .storeCoins(amount)
            .storeAddress(affiliateAddress)
            .storeUint(timestamp, 32)
            .endCell();
        let nowTs: Int = now();
        throwUnless(ERROR_SIGNATURE_EXPIRED, nowTs >= timestamp - 600 && nowTs <= timestamp + 600);
        throwUnless(ERROR_UNAUTHORIZED, checkSignature(msgCell.hash(), signature, providedPubKey));

        // 5) Mark claimed and pay out from affiliatePot only
        self.storage.usedClaims.set(nullifier, 1);
        throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= self.storage.financial.affiliatePot);
        self.storage.financial.affiliatePot -= amount;
        // Ensure overall reserve is still respected
        let totalAfter: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot;
        throwUnless(ERROR_RESERVE_VIOLATION, totalAfter >= self.storage.financial.minReserve);
        send(SendParameters{ 
            to: affiliateAddress, 
            value: amount, 
            mode: SendPayGasSeparately, 
            body: emptyCell() 
        });
    }

    // ==================================================
    // 🛠️ INTERNAL HELPERS
    // ==================================================
    // Canonical signature builders moved to protocol/actions.tact
    fun applyDeltas(pool: PoolDelta, nonces: NonceDelta) {
        self.storage.financial.houseBalance += pool.houseBalanceDelta;
        self.storage.financial.poolLiquidity += pool.poolLiquidityDelta;
        // Maintain committed liquidity running total based on game updates routed by logic responses
        // poolDelta already reflects increased pool for create and reduced for cashout/lost
        // serverNonce must advance exactly by 1 to match expected
        throwUnless(ERROR_NONCE_MISMATCH, self.storage.keys.serverNonce + 1 == nonces.serverNonce);
        self.storage.keys.serverNonce = nonces.serverNonce;
    }
    
    fun applyUserDelta(delta: Cell) {
        let cs: Slice = delta.asSlice();
        self.storage.dicts.users.set(cs.loadAddress(), cs.loadRef());
    }

    // Affiliate accrual path removed

    fun executeAction(actionCell: Cell) {
        let cs: Slice = actionCell.asSlice();
        let to: Address = cs.loadAddress();
        let amount: Int = cs.loadCoins();
        let body: Cell = cs.loadRef();
        let availableAfter: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity) - amount;
        throwUnless(ERROR_RESERVE_VIOLATION, availableAfter >= self.storage.financial.minReserve);
        send(SendParameters{
            to: to, 
            value: amount, 
            mode: SendPayGasSeparately, 
            body: body
        });
    }

    // Merkle helpers moved to protocol/actions.tact

    // Read-only verifier for affiliate bundle (helps clients/tests)
    get fun verifyAffiliateBundle(code: Cell, addr: Address, pubKey: Int, bannedBit: Int, index: Int, proof: Cell): Bool {
        let codeHash: Int = code.hash();
        let regLeaf: Int = buildAffiliateRegistryLeafHash(codeHash, addr, pubKey, bannedBit, index);
        if (bannedBit != 0) { return false; }
        return verifyMerkle(regLeaf, self.storage.affiliateRegistryRoot, proof);
    }
    fun calculateCommittedLiquidity(): Int {
        // Backward-compat alias used by getters; return reserved exposure
        return self.storage.financial.reservedExposure;
    }

    // ==================================================
    // 👁️ GETTERS & VIEWS (COMPLETE)
    // ==================================================
    get fun getIsPaused(): SystemView { 
        return SystemView{ 
            isPaused: self.storage.isPaused 
        }; 
    }
    get fun getKeysView(): KeysView { 
        return KeysView{ 
            adminPublicKey: self.storage.keys.adminPublicKey, 
            serverPublicKey: self.storage.keys.serverPublicKey 
        };
    }
    get fun getPoolLiquidity(): FinancialView { 
        return FinancialView{ 
            poolLiquidity: self.storage.financial.poolLiquidity 
        };
    }
    // Quantize to 0.01 TON (1e7 nanotons). Returns suggested options and max based on current pool and config.
    get fun getBetOptions(): BetOptionsView {
        let pool: Int = self.storage.financial.poolLiquidity;
        let maxUncapped: Int = pool * self.storage.config.maxBetPercent / PERCENT_BASE;
        // Quantization unit = 0.01 TON
        let q: Int = 10000000; // 1e7 nanoTON
        // floor to quantization when >= q; otherwise keep raw (small pools)
        let maxQ: Int = (maxUncapped / q) * q;
        if (maxQ == 0 && maxUncapped > 0) { maxQ = maxUncapped; }

        let minOpt: Int = (maxQ >= q) ? q : maxQ;
        let halfQ: Int = (maxQ >= q) ? ((maxQ / 2 / q) * q) : (maxQ / 2);
        let thirdQ: Int = (maxQ >= q) ? ((maxQ / 3 / q) * q) : (maxQ / 3);
        if (halfQ < minOpt && maxQ >= q) { halfQ = minOpt; }
        if (thirdQ < minOpt && maxQ >= q) { thirdQ = minOpt; }
        return BetOptionsView{ min: minOpt, third: thirdQ, half: halfQ, max: maxQ, quant: q };
    }
    // Validate an arbitrary bet against the current cap
    get fun getIsBetAllowed(bet: Int): Bool {
        let pool: Int = self.storage.financial.poolLiquidity;
        let maxUncapped: Int = pool * self.storage.config.maxBetPercent / PERCENT_BASE;
        return bet > 0 && bet <= maxUncapped;
    }
    // Expose dedicated affiliate pot balance
    get fun getAffiliatePot(): Int { return self.storage.financial.affiliatePot; }
    // Verify a sealed game against a per-epoch Merkle root
    get fun verifyGameProof(epoch: Int, gameId: Int, player: Address, bet: Int, createdAt: Int, maxPayout: Int, hashCommitment: Int, proof: Cell): Bool {
        let rootOpt: Int? = self.storage.gameEpochRoots.get(epoch);
        if (rootOpt == null) { return false; }
        let root: Int = rootOpt!!;
        if (root == 0) { return false; }
        let leaf: Int = buildGameLeafHash(epoch, gameId, player, bet, createdAt, maxPayout, hashCommitment);
        return verifyMerkle(leaf, root, proof);
    }
    get fun getConfigView(): ConfigView {
        return ConfigView{ 
            maxBetPercent: self.storage.config.maxBetPercent, 
            maxPayoutPercent: self.storage.config.maxPayoutPercent,
            withdrawalFeePercent: self.storage.config.withdrawalFeePercent, 
            lockupPeriod: self.storage.config.lockupPeriod,
            affiliateCommissionPercent: self.storage.config.affiliateCommissionPercent
        };
    }
    get fun getFullConfig(): StorageConfig { return self.storage.config; }
    get fun getFinancials(): StorageFinancial { return self.storage.financial; }
    get fun getGame(gameId: Int): Cell? { return self.storage.dicts.games.get(gameId); }
    // Affiliate balance dict removed in Merkle model
    // Removed duplicate 4-field getContractInfo; use getStatusKeys() for this tuple

    // ==================================================
    // 👁️ ANALYTICS
    // ==================================================
    get fun getStorageHealthReport(): HealthReport {
        // Approximate storage health using simple cost model (no map sizes available)
        let gameCount: Int = self.storage.nextGameId - 1;
        let annualStorageCost: Int = gameCount * 10000; // rough linear model per game
        let balance: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot; // proxy-held funds only
        let daysCovered: Int = annualStorageCost == 0 ? 0 : balance / (annualStorageCost / 365);
        let healthLevel: Int = 0;
        if (daysCovered < 30) { healthLevel = 2; }
        else if (daysCovered < 90) { healthLevel = 1; }
        // Encode simple message as a single-byte code equal to healthLevel
        let msgCell: Cell = beginCell().storeUint(healthLevel, 8).endCell();
        return HealthReport{ 
            healthLevel: healthLevel, 
            daysCovered: daysCovered, 
            annualStorageCost: annualStorageCost, 
            message: msgCell 
        };
    }

    get fun getGameStatistics(): GameStatistics {
        let total: Int = 0; let active: Int = 0; let won: Int = 0; let lost: Int = 0;
        let gameId: Int = 1;
        while (true) {
            let gameCell: Cell? = self.storage.dicts.games.get(gameId);

            if (gameCell == null) { 
                return GameStatistics{ 
                    total: total, 
                    active: active, 
                    won: won, 
                    lost: lost 
                }; 
            }
            
            let cs: Slice = gameCell!!.asSlice();
            cs.loadAddress();
            cs.loadCoins();
            cs.loadRef();
            cs.loadUint(32);

            let status: Int = cs.loadUint(8);
            total += 1;

            if (status == 0) { active += 1; }
            else if (status == 1) { won += 1; }
            else if (status == 2) { lost += 1; }
            gameId += 1;
        }
        return GameStatistics{ 
            total: total, 
            active: active, 
            won: won, 
            lost: lost 
        };
    }

    get fun getPoolLiquidityStatus(): PoolLiquidityStatus {
        let committed: Int = self.calculateCommittedLiquidity();
        let available: Int = self.storage.financial.poolLiquidity - committed;
        let totalBalance: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot;
        return PoolLiquidityStatus{ 
            poolLiquidity: self.storage.financial.poolLiquidity, 
            committed: committed, 
            available: available, 
            totalBalance: totalBalance,
            adminCommittedOutstanding: self.storage.financial.adminCommittedOutstanding
        };
    }

    get fun getTotalBalance(): Int { return self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot; }

    // Expose current chain timestamp
    get fun getChainNow(): Int {
        return now();
    }

    get fun getNextGameId(): Int { 
        return self.storage.nextGameId; 
    }

    get fun getProxyInfo(): ProxyInfo {
        return ProxyInfo{ 
            logicAddress: self.storage.logicAddress, 
            adminPublicKey: self.storage.keys.adminPublicKey, 
            serverPublicKey: self.storage.keys.serverPublicKey, 
            isPaused: self.storage.isPaused 
        };
    }

    get fun getContractInfo(): ContractInfo {
        let total: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot;
        return ContractInfo{ 
            totalBalance: total, 
            houseBalance: self.storage.financial.houseBalance, 
            poolLiquidity: self.storage.financial.poolLiquidity, 
            minReserve: self.storage.financial.minReserve, 
            isPaused: self.storage.isPaused, 
            nextGameId: self.storage.nextGameId 
        };
    }

    get fun getIsInitialized(): Bool { 
        return self.storage.initialized; 
    }

    get fun getNonces(): NonceStatus {
        return NonceStatus{ 
            serverNonce: self.storage.keys.serverNonce, 
            adminNonce: self.storage.keys.adminNonce 
        };
    }

    // ==============================
    // Extended analytics getters
    // ==============================
    get fun getGameStatisticsRange(startId: Int, endId: Int): GameStatistics {
        let total: Int = 0; let active: Int = 0; let won: Int = 0; let lost: Int = 0;
        let minId: Int = startId < 1 ? 1 : startId;
        let maxExist: Int = self.storage.nextGameId - 1;
        let maxId: Int = endId > maxExist ? maxExist : endId;
        if (maxId < minId) { return GameStatistics{ total: 0, active: 0, won: 0, lost: 0 }; }
        let id: Int = minId;
        while (id <= maxId) {
            let gameCell: Cell? = self.storage.dicts.games.get(id);
            if (gameCell != null) {
                let cs: Slice = gameCell!!.asSlice();
                cs.loadAddress();
                cs.loadCoins();
                cs.loadRef();
                cs.loadUint(32);
                let status: Int = cs.loadUint(8);
                total += 1;
                if (status == 0) { active += 1; }
                else if (status == 1) { won += 1; }
                else if (status == 2) { lost += 1; }
            }
            id += 1;
        }
        return GameStatistics{ 
            total: total, 
            active: active, 
            won: won, 
            lost: lost 
        };
    }

    get fun getEnhancedFinancialHealth(): EnhancedFinancialHealth {
        let balance: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot;
        let committed: Int = self.calculateCommittedLiquidity();
        let availableForPayouts: Int = self.storage.financial.poolLiquidity - committed;
        // Approximate storage cost linearly to game count
        let gameCount: Int = self.storage.nextGameId - 1;
        let storageCost: Int = gameCount * 10000;
        let reserveMargin: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity + self.storage.financial.affiliatePot) - self.storage.financial.minReserve;
        return EnhancedFinancialHealth{
            balance: balance,
            houseBalance: self.storage.financial.houseBalance,
            poolLiquidity: self.storage.financial.poolLiquidity,
            availableForPayouts: availableForPayouts,
            storageCost: storageCost,
            reserveMargin: reserveMargin,
            affiliateLiability: 0
        };
    }

    // Correctly spelled alias getter (same data), to be used by clients
    get fun getPruningRecommendations(): PruningRecommendations {
        let totalGames: Int = self.storage.nextGameId - 1;
        let prunable: Int = self.computePrunableGames();
        let estimatedSavings: Int = prunable * 10000;
        return PruningRecommendations{
            prunableGames: prunable,
            estimatedStorageSavings: estimatedSavings,
            totalGames: totalGames
        };
    }

    get fun getPrunableGamesInRange(startId: Int, endId: Int): Int {
        // Use the same adaptive age threshold as full-scan
        let baseAge: Int = 60 * 24 * 3600; // 60 days
        let gameCount: Int = self.storage.nextGameId - 1;
        let adjust: Int = gameCount >= 5000 ? (baseAge / 2) : (gameCount >= 1000 ? (baseAge * 3 / 4) : baseAge);
        let nowTs: Int = now();
        let minId: Int = startId < 1 ? 1 : startId;
        let last: Int = self.storage.nextGameId - 1;
        let maxId: Int = endId > last ? last : endId;
        if (maxId < minId) { return 0; }
        let prunable: Int = 0;
        let id: Int = minId;
        while (id <= maxId) {
            let gc: Cell? = self.storage.dicts.games.get(id);
            if (gc != null) {
                let cs: Slice = gc!!.asSlice();
                cs.loadAddress();
                cs.loadCoins();
                cs.loadRef();
                let createdAt: Int = cs.loadUint(32);
                let status: Int = cs.loadUint(8);
                if (status != 0) {
                    if (nowTs - createdAt >= adjust) { prunable += 1; }
                }
            }
            id += 1;
        }
        return prunable;
    }

    get fun getGameAgeDistribution(): GameAgeDistribution {
        return self.computeGameAgeDistribution();
    }

    get fun getGameAgeDistributionRange(startId: Int, endId: Int): GameAgeDistribution {
        let b0: Int = 0; let b1: Int = 0; let b2: Int = 0; let b3: Int = 0;
        let nowTs: Int = now();
        let d30: Int = 30 * 24 * 3600;
        let d90: Int = 90 * 24 * 3600;
        let d180: Int = 180 * 24 * 3600;
        let minId: Int = startId < 1 ? 1 : startId;
        let last: Int = self.storage.nextGameId - 1;
        let maxId: Int = endId > last ? last : endId;
        if (maxId < minId) { return GameAgeDistribution{ age0to30: 0, age31to90: 0, age91to180: 0, age180plus: 0 }; }
        let id: Int = minId;
        while (id <= maxId) {
            let gc: Cell? = self.storage.dicts.games.get(id);
            if (gc != null) {
                let cs: Slice = gc!!.asSlice();
                cs.loadAddress();
                cs.loadCoins();
                cs.loadRef();
                let createdAt: Int = cs.loadUint(32);
                cs.loadUint(8);
                // skip to tail in a layout-safe manner (as in full version)
                cs.loadCoins();
                cs.loadUint(16);
                cs.loadRef();
                let age: Int = nowTs - createdAt;
                if (age <= d30) { b0 += 1; }
                else if (age <= d90) { b1 += 1; }
                else if (age <= d180) { b2 += 1; }
                else { b3 += 1; }
            }
            id += 1;
        }
        return GameAgeDistribution{ 
            age0to30: b0, 
            age31to90: b1, 
            age91to180: b2, 
            age180plus: b3 
        };
    }

    // ===== Internal analytics helpers =====

    inline fun computePrunableGames(): Int {
        // Smart pruning based on storage pressure: scale target age with game count
        // Base = 60d; if many games, effectively lower the age threshold modestly
        let baseAge: Int = 60 * 24 * 3600; // 60 days
        let gameCount: Int = self.storage.nextGameId - 1;
        let adjust: Int = gameCount >= 5000 ? (baseAge / 2) : (gameCount >= 1000 ? (baseAge * 3 / 4) : baseAge);
        let nowTs: Int = now();
        let prunable: Int = 0;
        let id: Int = 1;
        let maxId: Int = self.storage.nextGameId - 1;
        while (id <= maxId) {
            let gc: Cell? = self.storage.dicts.games.get(id);
            if (gc != null) {
                let cs: Slice = gc!!.asSlice();
                cs.loadAddress();
                cs.loadCoins();
                cs.loadRef();
                let createdAt: Int = cs.loadUint(32);
                let status: Int = cs.loadUint(8);
                if (status != 0) {
                    if (nowTs - createdAt >= adjust) { prunable += 1; }
                }
            }
            id += 1;
        }
        return prunable;
    }

    inline fun computeGameAgeDistribution(): GameAgeDistribution {
        let b0: Int = 0; // 0-30d
        let b1: Int = 0; // 31-90d
        let b2: Int = 0; // 91-180d
        let b3: Int = 0; // 180d+
        let nowTs: Int = now();
        let d30: Int = 30 * 24 * 3600;
        let d90: Int = 90 * 24 * 3600;
        let d180: Int = 180 * 24 * 3600;
        let id: Int = 1;
        let maxId: Int = self.storage.nextGameId - 1;
        while (id <= maxId) {
            let gc: Cell? = self.storage.dicts.games.get(id);
            if (gc != null) {
                let cs: Slice = gc!!.asSlice();
                cs.loadAddress();
                cs.loadCoins();
                cs.loadRef();
                let createdAt: Int = cs.loadUint(32);
                cs.loadUint(8); // status (unused here)
                // skip to end properly for layout safety
                cs.loadCoins();
                cs.loadUint(16);
                cs.loadRef();
                // age calc
                let age: Int = nowTs - createdAt;
                if (age <= d30) { b0 += 1; }
                else if (age <= d90) { b1 += 1; }
                else if (age <= d180) { b2 += 1; }
                else { b3 += 1; }
            }
            id += 1;
        }
        return GameAgeDistribution{ 
            age0to30: b0, 
            age31to90: b1, 
            age91to180: b2, 
            age180plus: b3 
        };
    }

    get fun getGameSession(gameId: Int): GameSession? {
        let gameCell: Cell? = self.storage.dicts.games.get(gameId);
        if (gameCell == null) { return null; }
        let cs: Slice = gameCell!!.asSlice();
        let player: Address = cs.loadAddress();
        let betAmount: Int = cs.loadCoins();
        let hashCommitment: Cell = cs.loadRef();
        let createdAt: Int = cs.loadUint(32);
        let status: Int = cs.loadUint(8);
        let payoutAmount: Int = cs.loadCoins();
        let multiplier: Int = cs.loadUint(16);
        let gameConfig: Cell = cs.loadRef();
        // In our layout, moves/seed/salt/final state may be in refs depending on status
        // For active games, we store only maxPayoutForGame tail
        let maybeMoves: Cell = status == 0 ? emptyCell() : cs.loadRef();
        let gameSeed: Cell = status == 0 ? emptyCell() : cs.loadRef();
        let gameSalt: Cell = status == 0 ? emptyCell() : cs.loadRef();
        let finalGameState: Cell = status == 0 ? emptyCell() : cs.loadRef();
        let maxPayoutForGame: Int = cs.loadCoins();
        return GameSession{
            player: player,
            betAmount: betAmount,
            hashCommitment: hashCommitment,
            createdAt: createdAt,
            status: status,
            payoutAmount: payoutAmount,
            multiplier: multiplier,
            maxPayoutForGame: maxPayoutForGame,
            moves: maybeMoves,
            gameConfig: gameConfig,
            gameSeed: gameSeed,
            gameSalt: gameSalt,
            finalGameState: finalGameState
        };
    }

    // Typed withdrawals view: returns count and a packed list of records
    // Each record is encoded as: uint64 gameId | uint32 date | coins amount
    // Note: date uses game.createdAt (cashout timestamp is not stored on-chain)
    get fun getUserWithdrawalsInRange(user: Address, startId: Int, endId: Int, limit: Int): WithdrawalsPage {
        let minId: Int = startId < 1 ? 1 : startId;
        let last: Int = self.storage.nextGameId - 1;
        let maxId: Int = endId > last ? last : endId;
        if (maxId < minId) { return WithdrawalsPage{ count: 0, items: emptyCell() }; }
        let maxCount: Int = (limit <= 0) ? 0 : (limit > 50 ? 50 : limit);
        let b = beginCell();
        let count: Int = 0;
        let id: Int = minId;
        let scanCap: Int = 1000;
        let scanned: Int = 0;
        while (id <= maxId && count < maxCount && scanned < scanCap) {
            let gameCell: Cell? = self.storage.dicts.games.get(id);
            if (gameCell != null) {
                let cs: Slice = gameCell!!.asSlice();
                let player: Address = cs.loadAddress();
                cs.loadCoins();
                cs.loadRef();
                let createdAt: Int = cs.loadUint(32);
                let status: Int = cs.loadUint(8);
                let payoutAmount: Int = cs.loadCoins();
                if (status == 1 && player == user && payoutAmount > 0) {
                    b = b.storeUint(id, 64).storeUint(createdAt, 32).storeCoins(payoutAmount);
                    count += 1;
                }
            }
            id += 1;
            scanned += 1;
        }
        return WithdrawalsPage{ count: count, items: b.endCell() };
    }

    // Strictly typed variant returning up to 10 WithdrawalRecord entries
    get fun getUserWithdrawalsTypedInRange(user: Address, startId: Int, endId: Int, limit: Int): WithdrawalsTypedPage10 {
        let minId: Int = startId < 1 ? 1 : startId;
        let last: Int = self.storage.nextGameId - 1;
        let maxId: Int = endId > last ? last : endId;
        if (maxId < minId) {
            return WithdrawalsTypedPage10{
                count: 0,
                r1: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r2: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r3: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r4: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r5: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r6: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r7: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r8: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r9: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 },
                r10: WithdrawalRecord{ gameId: 0, date: 0, amount: 0 }
            };
        }
        let maxCount: Int = (limit <= 0) ? 0 : (limit > 10 ? 10 : limit);
        let c: Int = 0;
        // Initialize slots
        let s1 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s2 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s3 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s4 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s5 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s6 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s7 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s8 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s9 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let s10 = WithdrawalRecord{ gameId: 0, date: 0, amount: 0 };
        let id: Int = minId;
        let scanCap: Int = 1000;
        let scanned: Int = 0;
        while (id <= maxId && c < maxCount && scanned < scanCap) {
            let gameCell: Cell? = self.storage.dicts.games.get(id);
            if (gameCell != null) {
                let cs: Slice = gameCell!!.asSlice();
                let player: Address = cs.loadAddress();
                cs.loadCoins();
                cs.loadRef();
                let createdAt: Int = cs.loadUint(32);
                let status: Int = cs.loadUint(8);
                let payoutAmount: Int = cs.loadCoins();
                if (status == 1 && player == user && payoutAmount > 0) {
                    c += 1;
                    if (c == 1) { s1 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 2) { s2 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 3) { s3 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 4) { s4 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 5) { s5 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 6) { s6 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 7) { s7 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 8) { s8 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 9) { s9 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                    else if (c == 10) { s10 = WithdrawalRecord{ gameId: id, date: createdAt, amount: payoutAmount }; }
                }
            }
            id += 1;
            scanned += 1;
        }
        return WithdrawalsTypedPage10{ 
            count: c, 
            r1: s1, 
            r2: s2, 
            r3: s3, 
            r4: s4, 
            r5: s5, 
            r6: s6, 
            r7: s7, 
            r8: s8, 
            r9: s9, 
            r10: s10 
        };
    }
}