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
    affiliateBalances: map<Address, Int>;
    affiliateKeys: map<Address, Int>; // Affiliate Address -> PubKey
    affiliateNonces: map<Address, Int>; // Affiliate Address -> Nonce
    affiliateBanned: map<Address, Int>; // 1 = banned
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

struct SecurityStatus {
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
    // Affiliate index to enable bounded scans in getters
    nextAffiliateId: Int;
    keys: StorageKeys;
    financial: StorageFinancial;
    config: StorageConfig;
    dicts: StorageDicts;
    affiliateIndexByAddress: map<Address, Int>;
    affiliateByIndex: map<Int, Int>;
}


contract StorageProxy {

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
            nextAffiliateId: 1,
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
                adminCommittedOutstanding: 0
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
                games: emptyMap(),
                affiliateBalances: emptyMap(),
                affiliateKeys: emptyMap(),
                affiliateNonces: emptyMap(),
                affiliateBanned: emptyMap()
            },
            affiliateIndexByAddress: emptyMap(),
            affiliateByIndex: emptyMap()
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

        let op: Int = cs.loadUint(32);

        // Route A: Response from our own Logic Contract (always allowed)
        if (context().sender == self.storage.logicAddress) {
            self.handleLogicResponse(cs);
            return;
        }

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

        // Route C2: Server-signed affiliate key registration (requires pause off)
        if (op == OP_REGISTER_AFFILIATE_KEY) {
            self.handleRegisterAffiliateKey(cs);
            return;
        }

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
        let affiliateCode: Cell? = null;
        if (hasAffiliate == 1) {
            affiliateCode = cs.loadRef();
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
        let serverMsg: Cell = self.buildCreateSigMessage(player, bet, hashCommit, expectedNonce, serverTimestamp);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(serverMsg.hash(), serverSig.asSlice(), self.storage.keys.serverPublicKey));

        let req = CreateGameRequest{
            player: player,
            betAmount: bet, 
            hashCommitment: hashCommit, 
            affiliateCode: affiliateCode,
            gameConfig: gameConfig, 
            serverTimestamp: serverTimestamp, 
            serverSignature: serverSig,
            sys: self.getSystemView(), 
            keys: self.getKeysView(), 
            fin: self.getFinancialView(), 
            cfg: self.getConfigView(),
            allocatedGameId: allocatedGameId, 
            expectedServerNonce: expectedNonce,
            existingUserCell: self.storage.dicts.users.get(player)
        };
        // Never forward attached bet to logic; send 0-value and pay gas separately
        send(SendParameters{ to: self.storage.logicAddress, value: 0, mode: SendPayGasSeparately, body: req.toCell() });
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
        let serverSig: Cell = cs.loadRef();

        let gameCell: Cell = self.storage.dicts.games.get(gameId)!!;
        let playerAddr: Address = gameCell.asSlice().loadAddress();
        let userCell: Cell = self.storage.dicts.users.get(playerAddr)!!;

        let expectedNonce: Int = self.storage.keys.serverNonce + 1;
        // Do not advance serverNonce yet; only after successful logic response via applyDeltas

        // Storage-side basic bound checks to reduce spam
        throwUnless(ERROR_PAYOUT_TOO_HIGH, payout <= self.storage.financial.poolLiquidity);

        // Pre-verify server signature canonically where possible
        let cashSig: Cell = self.buildCashoutSigMessage(gameId, payout, mult, moves, expectedNonce);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(cashSig.hash(), serverSig.asSlice(), self.storage.keys.serverPublicKey));

        let req = CashoutRequest {
            payoutAmount: payout, 
            multiplier: mult,
            moves: moves,
            gameSeed: seed,
            gameSalt: salt,
            finalGameState: finalState,
            backendCommissionAmount: backendComm,
            serverSignature: serverSig,
            sys: self.getSystemView(),
            keys: self.getKeysView(),
            fin: self.getFinancialView(),
            cfg: self.getConfigView(),
            gameId: gameId,
            expectedServerNonce: expectedNonce,
            existingGameCell: gameCell,
            existingUserCell: userCell
        };
        send(SendParameters{ to: self.storage.logicAddress, value: 0, mode: SendPayGasSeparately, body: req.toCell() });
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
        let lostSig: Cell = self.buildMarkLostSigMessage(gameId, seed, salt, expectedNonce);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(lostSig.hash(), serverSig.asSlice(), self.storage.keys.serverPublicKey));

        let req = MarkLostRequest {
            gameSeed: seed, 
            gameSalt: salt, 
            finalGameState: finalState, 
            serverSignature: serverSig,
            sys: self.getSystemView(), 
            keys: self.getKeysView(),
            gameId: gameId, 
            expectedServerNonce: expectedNonce, 
            existingGameCell: gameCell, 
            existingUserCell: userCell
        };
        send(SendParameters{ to: self.storage.logicAddress, value: 0, mode: SendPayGasSeparately, body: req.toCell() });
    }
    
    // ==================================================
    // 🧠 LOGIC RESPONSE HANDLER
    // ==================================================
    fun handleLogicResponse(responseSlice: Slice) {
        let op = responseSlice.preloadUint(32);

        if (op == OP_MSG_CREATE_GAME_RESP) {
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
            self.applyAffiliateCell(affiliateCell);
            self.executeAction(payoutMsg);
        } else if (op == OP_MSG_MARK_LOST_RESP) {
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
        } else if (op == OP_ADMIN_WITHDRAW_HOUSE) {
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= self.storage.financial.houseBalance);
            let availableAfter: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity) - amount;
            throwUnless(ERROR_RESERVE_VIOLATION, availableAfter >= self.storage.financial.minReserve);
            self.storage.financial.houseBalance -= amount;
            send(SendParameters{ to: recipient, value: amount, mode: SendPayGasSeparately, body: emptyCell() });
        } else if (op == OP_ADMIN_WITHDRAW_POOL) {
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= self.storage.financial.poolLiquidity);
            let committed: Int = self.calculateCommittedLiquidity();
            let availableLiquidity: Int = self.storage.financial.poolLiquidity - committed;
            throwUnless(ERROR_INSUFFICIENT_FUNDS, amount <= availableLiquidity);
            let availableAfterPool: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity) - amount;
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
        } else if (op == OP_ADMIN_BAN_AFFILIATE) {
            // Confiscate current affiliate balance to house and ban
            let balOpt: Int? = self.storage.dicts.affiliateBalances.get(recipient);
            let bal: Int = balOpt != null ? balOpt!! : 0;
            if (bal > 0) {
                self.storage.financial.houseBalance += bal;
                self.storage.dicts.affiliateBalances.set(recipient, 0);
            }
            self.storage.dicts.affiliateBanned.set(recipient, 1);
        }
    }

    // ==================================================
    // 🤝 AFFILIATE FUNCTIONS
    // ==================================================
    inline fun handleRegisterAffiliateKey(cs: Slice) {
        // Parse fields
        let affiliateAddress: Address = cs.loadAddress();
        let affiliatePublicKey: Int = cs.loadUint(256);
        let serverNonce: Int = cs.loadUint(64);
        let deadline: Int = cs.loadUint(32);
        let signature: Slice = cs.loadBits(512);

        // Build canonical message
        let b = beginCell()
            .storeUint(OP_REGISTER_AFFILIATE_KEY, 32)
            .storeAddress(affiliateAddress)
            .storeUint(affiliatePublicKey, 256)
            .storeUint(serverNonce, 64)
            .storeUint(deadline, 32)
            .endCell();

        // Verify
        throwUnless(ERROR_NONCE_MISMATCH, serverNonce == self.storage.keys.serverNonce + 1);
        throwUnless(ERROR_SIGNATURE_EXPIRED, now() <= deadline);
        throwUnless(ERROR_UNAUTHORIZED, checkSignature(b.hash(), signature, self.storage.keys.serverPublicKey));

        // Set key only if not set yet
        let stored: Int? = self.storage.dicts.affiliateKeys.get(affiliateAddress);
        if (stored == null) {
            self.storage.dicts.affiliateKeys.set(affiliateAddress, affiliatePublicKey);
        }

        // Ensure affiliate index exists for analytics
        let maybeId: Int? = self.storage.affiliateIndexByAddress.get(affiliateAddress);
        if (maybeId == null) {
            let id: Int = self.storage.nextAffiliateId;
            self.storage.nextAffiliateId = id + 1;
            self.storage.affiliateIndexByAddress.set(affiliateAddress, id);
            // initialize mirror to 0 if absent
            let oldIndexed: Int? = self.storage.affiliateByIndex.get(id);
            if (oldIndexed == null) { self.storage.affiliateByIndex.set(id, 0); }
        }

        // Advance server nonce
        self.storage.keys.serverNonce = serverNonce;
    }
    fun handleAffiliateWithdraw(cs: Slice) {
        let amount: Int = cs.loadCoins();
        let affiliateAddress: Address = cs.loadAddress();
        let affiliateNonce: Int = cs.loadUint(64);
        let providedPubKey: Int = cs.loadUint(256);
        let timestamp: Int = cs.loadUint(32);
        let signature: Slice = cs.loadBits(512);

        // If banned, block withdrawals outright
        let bannedOptW: Int? = self.storage.dicts.affiliateBanned.get(affiliateAddress);
        throwUnless(ERROR_UNAUTHORIZED, !(bannedOptW != null && bannedOptW!! == 1));

        let mbBalance: Int? = self.storage.dicts.affiliateBalances.get(affiliateAddress);
        let currentBalance: Int = mbBalance != null ? mbBalance!! : 0;
        let mbNonce: Int? = self.storage.dicts.affiliateNonces.get(affiliateAddress);
        let expectedNonce: Int = mbNonce != null ? mbNonce!! : 0;
        
        throwUnless(ERROR_INSUFFICIENT_FUNDS, amount > 0 && amount <= currentBalance);
        throwUnless(ERROR_NONCE_MISMATCH, affiliateNonce == expectedNonce + 1);

        // Enforce pre-registered affiliate keys; no self-registration via withdrawal path
        let storedPubKey: Int? = self.storage.dicts.affiliateKeys.get(affiliateAddress);
        throwUnless(ERROR_UNAUTHORIZED, storedPubKey != null);
        throwUnless(ERROR_UNAUTHORIZED, providedPubKey == storedPubKey!!);

        let msgCell: Cell = beginCell()
            .storeUint(OP_AFFILIATE_WITHDRAW_DIRECT, 32)
            .storeCoins(amount)
            .storeAddress(affiliateAddress)
            .storeUint(affiliateNonce, 64)
            .storeUint(timestamp, 32)
            .endCell();
        // Timestamp freshness: within 10 minutes
        let nowTs: Int = now();
        throwUnless(ERROR_SIGNATURE_EXPIRED, nowTs >= timestamp - 600 && nowTs <= timestamp + 600);
        throwUnless(ERROR_UNAUTHORIZED, checkSignature(msgCell.hash(), signature, providedPubKey));
        
        self.storage.dicts.affiliateBalances.set(affiliateAddress, currentBalance - amount);
        self.storage.dicts.affiliateNonces.set(affiliateAddress, affiliateNonce);

        // Mirror into indexed balances for analytics
        let maybeId: Int? = self.storage.affiliateIndexByAddress.get(affiliateAddress);
        let id: Int = 0;
        if (maybeId == null) {
            id = self.storage.nextAffiliateId;
            self.storage.nextAffiliateId = id + 1;
            self.storage.affiliateIndexByAddress.set(affiliateAddress, id);
        } else {
            id = maybeId!!;
        }
        let newIndexedBal: Int = currentBalance - amount;
        self.storage.affiliateByIndex.set(id, newIndexedBal);

        // Reserve safety: ensure total custody after this transfer remains above min reserve
        let availableAfter: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity) - amount;
        throwUnless(ERROR_RESERVE_VIOLATION, availableAfter >= self.storage.financial.minReserve);
        send(SendParameters{ to: affiliateAddress, value: amount, mode: SendPayGasSeparately, body: emptyCell() });
    }

    // ==================================================
    // 🛠️ INTERNAL HELPERS
    // ==================================================
    // Canonical server-signature messages (must match logic)
    inline fun buildCreateSigMessage(player: Address, betAmount: Int, hashCommitment: Cell, expectedServerNonce: Int, serverTimestamp: Int): Cell {
        return beginCell().storeAddress(player).storeCoins(betAmount).storeRef(hashCommitment).storeUint(expectedServerNonce, 64).storeUint(serverTimestamp, 32).endCell();
    }

    inline fun buildCashoutSigMessage(gameId: Int, payoutAmount: Int, multiplier: Int, moves: Cell, expectedServerNonce: Int): Cell {
        return beginCell().storeUint(gameId, 64).storeCoins(payoutAmount).storeUint(multiplier, 16).storeRef(moves).storeUint(expectedServerNonce, 64).endCell();
    }

    inline fun buildMarkLostSigMessage(gameId: Int, gameSeed: Cell, gameSalt: Cell, expectedServerNonce: Int): Cell {
        return beginCell().storeUint(gameId, 64).storeRef(gameSeed).storeRef(gameSalt).storeUint(expectedServerNonce, 64).endCell();
    }
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

    fun applyAffiliateCell(affDeltaCell: Cell) {
        let cs: Slice = affDeltaCell.asSlice();
        if (cs.loadUint(1) == 1) {
            let addr: Address = cs.loadAddress();
            let amt: Int = cs.loadCoins();

            // If affiliate is banned, route commission to house instead
            let bannedOpt: Int? = self.storage.dicts.affiliateBanned.get(addr);
            if (bannedOpt != null && bannedOpt!! == 1) {
                self.storage.financial.houseBalance += amt;
            } else {
                // Update address-keyed balance (legacy dict)
                let mbCur: Int? = self.storage.dicts.affiliateBalances.get(addr);
                let cur: Int = mbCur != null ? mbCur!! : 0;
                let newBal: Int = cur + amt;
                self.storage.dicts.affiliateBalances.set(addr, newBal);
            }

            // Ensure index id exists
            let maybeId: Int? = self.storage.affiliateIndexByAddress.get(addr);
            let id: Int = 0;
            if (maybeId == null) {
                id = self.storage.nextAffiliateId;
                self.storage.nextAffiliateId = id + 1;
                self.storage.affiliateIndexByAddress.set(addr, id);
            } else {
                id = maybeId!!;
            }

            // Update indexed balance mirror (only if not banned)
            let bannedNow: Int = (bannedOpt != null && bannedOpt!! == 1) ? 1 : 0;
            if (bannedNow == 0) {
                let oldIndexed: Int? = self.storage.affiliateByIndex.get(id);
                let prev: Int = oldIndexed != null ? oldIndexed!! : 0;
                self.storage.affiliateByIndex.set(id, prev + amt);
            }
        }
    }

    fun executeAction(actionCell: Cell) {
        let cs: Slice = actionCell.asSlice();
        let to: Address = cs.loadAddress();
        let amount: Int = cs.loadCoins();
        let body: Cell = cs.loadRef();
        let availableAfter: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity) - amount;
        throwUnless(ERROR_RESERVE_VIOLATION, availableAfter >= self.storage.financial.minReserve);
        send(SendParameters{to: to, value: amount, mode: SendPayGasSeparately, body: body});
    }

    fun calculateCommittedLiquidity(): Int {
        // Backward-compat alias used by getters; return reserved exposure
        return self.storage.financial.reservedExposure;
    }

    // ==================================================
    // 👁️ GETTERS & VIEWS (COMPLETE)
    // ==================================================
    get fun getSystemView(): SystemView { return SystemView{ isPaused: self.storage.isPaused }; }
    get fun getKeysView(): KeysView { return KeysView{ adminPublicKey: self.storage.keys.adminPublicKey, serverPublicKey: self.storage.keys.serverPublicKey }; }
    get fun getFinancialView(): FinancialView { return FinancialView{ poolLiquidity: self.storage.financial.poolLiquidity }; }
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
    get fun getAffiliateBalance(addr: Address): Int {
        let mb: Int? = self.storage.dicts.affiliateBalances.get(addr);
        return mb != null ? mb!! : 0;
    }
    // Removed duplicate 4-field getContractInfo; use getStatusKeys() for this tuple

    // ==================================================
    // 👁️ ANALYTICS (camelCase versions of legacy)
    // ==================================================
    get fun getStorageHealthReport(): HealthReport {
        // Approximate storage health using simple cost model (no map sizes available)
        let gameCount: Int = self.storage.nextGameId - 1;
        let annualStorageCost: Int = gameCount * 10000; // rough linear model per game
        let balance: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity; // proxy-held funds only
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
        let totalBalance: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity;
        return PoolLiquidityStatus{ 
            poolLiquidity: self.storage.financial.poolLiquidity, 
            committed: committed, 
            available: available, 
            totalBalance: totalBalance,
            adminCommittedOutstanding: self.storage.financial.adminCommittedOutstanding
        };
    }

    get fun getTotalBalance(): Int {
        return self.storage.financial.houseBalance + self.storage.financial.poolLiquidity;
    }

    get fun getProxyInfo(): ProxyInfo {
        return ProxyInfo{ 
            logicAddress: self.storage.logicAddress, 
            adminPublicKey: self.storage.keys.adminPublicKey, 
            serverPublicKey: self.storage.keys.serverPublicKey, 
            isPaused: self.storage.isPaused 
        };
    }

    // Keys & status view
    get fun getStatusKeys(): StatusKeys {
        return StatusKeys{ 
            logicAddress: self.storage.logicAddress, 
            isPaused: self.storage.isPaused, 
            adminNonce: self.storage.keys.adminNonce, 
            serverNonce: self.storage.keys.serverNonce 
        };
    }

    get fun getContractInfo(): ContractInfo {
        let total: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity;
        return ContractInfo{ 
            totalBalance: total, 
            houseBalance: self.storage.financial.houseBalance, 
            poolLiquidity: self.storage.financial.poolLiquidity, 
            minReserve: self.storage.financial.minReserve, 
            isPaused: self.storage.isPaused, 
            nextGameId: self.storage.nextGameId 
        };
    }

    get fun getIsInitialized(): Bool { return self.storage.initialized; }

    get fun getSecurityStatus(): SecurityStatus {
        return SecurityStatus{ 
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
        return GameStatistics{ total: total, active: active, won: won, lost: lost };
    }
    get fun getEnhancedFinancialHealth(): EnhancedFinancialHealth {
        let balance: Int = self.storage.financial.houseBalance + self.storage.financial.poolLiquidity;
        let committed: Int = self.calculateCommittedLiquidity();
        let availableForPayouts: Int = self.storage.financial.poolLiquidity - committed;
        // Approximate storage cost linearly to game count
        let gameCount: Int = self.storage.nextGameId - 1;
        let storageCost: Int = gameCount * 10000;
        let reserveMargin: Int = (self.storage.financial.houseBalance + self.storage.financial.poolLiquidity) - self.storage.financial.minReserve;
        // Sum affiliate indexed balances (only positive) for exact liability
        let affiliateLiability: Int = self.sumAffiliateLiability();
        return EnhancedFinancialHealth{
            balance: balance,
            houseBalance: self.storage.financial.houseBalance,
            poolLiquidity: self.storage.financial.poolLiquidity,
            availableForPayouts: availableForPayouts,
            storageCost: storageCost,
            reserveMargin: reserveMargin,
            affiliateLiability: affiliateLiability
        };
    }

    get fun getAffiliateLiabilityReport(): AffiliateLiabilityReport {
        let report = self.scanAffiliateLiability();
        return report;
    }

    get fun getAffiliateStatus(addr: Address): AffiliateStatus {
        let bannedOpt: Int? = self.storage.dicts.affiliateBanned.get(addr);
        let banned: Bool = (bannedOpt != null && bannedOpt!! == 1);
        let balOpt: Int? = self.storage.dicts.affiliateBalances.get(addr);
        let bal: Int = balOpt != null ? balOpt!! : 0;
        let nonceOpt: Int? = self.storage.dicts.affiliateNonces.get(addr);
        let nonce: Int = nonceOpt != null ? nonceOpt!! : 0;
        let pkOpt: Int? = self.storage.dicts.affiliateKeys.get(addr);
        let pk: Int = pkOpt != null ? pkOpt!! : 0;
        return AffiliateStatus{ banned: banned, balance: bal, nonce: nonce, publicKey: pk };
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
        return GameAgeDistribution{ age0to30: b0, age31to90: b1, age91to180: b2, age180plus: b3 };
    }

    // ===== Internal analytics helpers =====
    inline fun sumAffiliateLiability(): Int {
        let last: Int = self.storage.nextAffiliateId - 1;
        if (last <= 0) { return 0; }
        let i: Int = 1;
        let total: Int = 0;
        while (i <= last) {
            let balOpt: Int? = self.storage.affiliateByIndex.get(i);
            if (balOpt != null) {
                let b: Int = balOpt!!;
                if (b > 0) { total += b; }
            }
            i += 1;
        }
        return total;
    }

    inline fun scanAffiliateLiability(): AffiliateLiabilityReport {
        let last: Int = self.storage.nextAffiliateId - 1;
        let total: Int = 0;
        let count: Int = 0;
        let maxBal: Int = 0;
        let highCount: Int = 0;
        let i: Int = 1;
        let HIGH: Int = ton("10");
        while (i <= last) {
            let balOpt: Int? = self.storage.affiliateByIndex.get(i);
            if (balOpt != null) {
                let b: Int = balOpt!!;
                if (b > 0) {
                    total += b;
                    count += 1;
                    if (b > maxBal) { maxBal = b; }
                    if (b >= HIGH) { highCount += 1; }
                }
            }
            i += 1;
        }
        return AffiliateLiabilityReport{
            totalLiability: total,
            affiliateCount: count,
            maxSingleBalance: maxBal,
            highBalanceCount: highCount
        };
    }

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
        return GameAgeDistribution{ age0to30: b0, age31to90: b1, age91to180: b2, age180plus: b3 };
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
}