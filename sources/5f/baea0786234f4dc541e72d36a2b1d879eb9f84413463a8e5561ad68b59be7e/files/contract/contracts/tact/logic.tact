import "./protocol/opcodes.tact";
import "./protocol/types.tact";
import "./protocol/actions.tact";

// ===================================================================
// 🧠 Reekt.Fun Logic Contract (TACT Edition) - PURE & SECURED
// ===================================================================
// This contract contains ALL business logic but is STORAGE-BLIND.
// It receives a Request, performs pure calculations, and returns
// a deterministic Response. It never holds funds or state.
// ===================================================================

// Utility: stable Int key from Slice
// Removed: using Address directly instead of hashed Int keys

// --- Helper Structs for Parsing Cells from Proxy ---
struct GameData {
    player: Address;
    betAmount: Int;
    hashCommitment: Cell;
    createdAt: Int;
    status: Int;
    payoutAmount: Int;
    multiplier: Int;
    gameConfig: Cell;
    // max payout reserved for this game (basis for committed liquidity)
    maxPayoutForGame: Int;
}

struct UserData {
    firstDepositTime: Int;
    affiliateAddress: Address?;
    balance: Int;
}

inline fun refundSurplus() {
    let keep: Int = ton("0.05");
    let incoming: Int = context().value;
    if (incoming > keep) {
        let refund: Int = incoming - keep;
        message(MessageParameters{
            to: sender(),
            value: refund,
            mode: SendPayGasSeparately,
            body: emptyCell()
        });
    }
}

contract Logic {
    init() {}

    // Getters for deployment scripts
    get fun getLogicVersion(): Int { return 10; }
    // Bump to force new code hash/address on redeploy
    get fun getLogicInfo(): Int { return 0x01; }

    // Catch-all handler to safely ignore unexpected/bounced internal messages
    // Prevents cell underflow when someone sends plain TON with empty body
    // 1) Plain empty body (no refs)
    receive() {
        refundSurplus();
        return;
    }

    // Comment-based deploy path: body carries a textual "deploy" comment
    receive("deploy") {
        refundSurplus();
        return;
    }

    // Single untyped dispatcher with explicit opcode routing
    receive(msg: Slice) {
        // If there is no body, just refund
        // (Tact 1.6 lacks remainingBits(), so attempt to read guardedly)
        // Try to slice-load 32 bits; if it fails, refund
        let op: Int = -1;
        try {
            op = msg.preloadUint(32);
        } catch (e) {
            refundSurplus();
            return;
        }

        if (op == OP_MSG_CREATE_GAME_REQ) {
            // Decode CreateGameRequest manually
            // Views
            let sys_isPaused: Bool = msg.loadUint(1) == 1;
            let keys_admin: Int = msg.loadUint(256);
            let keys_server: Int = msg.loadUint(256);
            let fin_pool: Int = msg.loadCoins();
            let cfg_maxBet: Int = msg.loadUint(16);
            let cfg_maxPayout: Int = msg.loadUint(16);
            let cfg_withdrawal: Int = msg.loadUint(16);
            let cfg_lockup: Int = msg.loadUint(32);

            // Params
            let player: Address = msg.loadAddress();
            let betAmount: Int = msg.loadCoins();
            let hashCommitment: Cell = msg.loadRef();
            let hasAff: Int = msg.loadUint(1);
            let affiliateCode: Cell? = null;
            if (hasAff == 1) { affiliateCode = msg.loadRef(); }
            let gameConfig: Cell = msg.loadRef();
            let serverTimestamp: Int = msg.loadUint(32);
            let serverSignature: Cell = msg.loadRef();

            // Context
            let allocatedGameId: Int = msg.loadUint(64);
            let expectedServerNonce: Int = msg.loadUint(64);
            let hasUser: Int = msg.loadUint(1);
            let existingUserCell: Cell? = null;
            if (hasUser == 1) { existingUserCell = msg.loadRef(); }

            // Build views/structs
            let sys = SystemView{ isPaused: sys_isPaused };
            let keys = KeysView{ adminPublicKey: keys_admin, serverPublicKey: keys_server };
            let fin = FinancialView{ poolLiquidity: fin_pool };
            let cfg = ConfigView{
                maxBetPercent: cfg_maxBet,
                maxPayoutPercent: cfg_maxPayout,
                withdrawalFeePercent: cfg_withdrawal,
                lockupPeriod: cfg_lockup
            };

            self.handleCreateGame(sys, keys, fin, cfg, player, betAmount, hashCommitment, affiliateCode, gameConfig, serverTimestamp, serverSignature, allocatedGameId, expectedServerNonce, existingUserCell);
            return;
        }

        if (op == OP_MSG_CASHOUT_REQ) {
            // Views
            let sys_isPaused: Bool = msg.loadUint(1) == 1;
            let keys_admin: Int = msg.loadUint(256);
            let keys_server: Int = msg.loadUint(256);
            let fin_pool: Int = msg.loadCoins();
            let cfg_maxBet: Int = msg.loadUint(16);
            let cfg_maxPayout: Int = msg.loadUint(16);
            let cfg_withdrawal: Int = msg.loadUint(16);
            let cfg_lockup: Int = msg.loadUint(32);

            // Params
            let payoutAmount: Int = msg.loadCoins();
            let multiplier: Int = msg.loadUint(16);
            let moves: Cell = msg.loadRef();
            let gameSeed: Cell = msg.loadRef();
            let gameSalt: Cell = msg.loadRef();
            let finalGameState: Cell = msg.loadRef();
            let backendCommissionAmount: Int = msg.loadCoins();
            let serverSignature: Cell = msg.loadRef();

            // Context
            let gameId: Int = msg.loadUint(64);
            let expectedServerNonce: Int = msg.loadUint(64);
            let existingGameCell: Cell = msg.loadRef();
            let existingUserCell: Cell = msg.loadRef();

            let sys = SystemView{ isPaused: sys_isPaused };
            let keys = KeysView{ adminPublicKey: keys_admin, serverPublicKey: keys_server };
            let fin = FinancialView{ poolLiquidity: fin_pool };
            let cfg = ConfigView{ maxBetPercent: cfg_maxBet, maxPayoutPercent: cfg_maxPayout, withdrawalFeePercent: cfg_withdrawal, lockupPeriod: cfg_lockup };

            self.handleCashout(sys, keys, fin, cfg, payoutAmount, multiplier, moves, gameSeed, gameSalt, finalGameState, backendCommissionAmount, serverSignature, gameId, expectedServerNonce, existingGameCell, existingUserCell);
            return;
        }

        if (op == OP_MSG_MARK_LOST_REQ) {
            // Views
            let sys_isPaused: Bool = msg.loadUint(1) == 1;
            let keys_admin: Int = msg.loadUint(256);
            let keys_server: Int = msg.loadUint(256);

            // Params
            let gameSeed: Cell = msg.loadRef();
            let gameSalt: Cell = msg.loadRef();
            let finalGameState: Cell = msg.loadRef();
            let serverSignature: Cell = msg.loadRef();

            // Context
            let gameId: Int = msg.loadUint(64);
            let expectedServerNonce: Int = msg.loadUint(64);
            let existingGameCell: Cell = msg.loadRef();
            let existingUserCell: Cell = msg.loadRef();

            let sys = SystemView{ isPaused: sys_isPaused };
            let keys = KeysView{ adminPublicKey: keys_admin, serverPublicKey: keys_server };

            self.handleMarkLost(sys, keys, gameSeed, gameSalt, finalGameState, serverSignature, gameId, expectedServerNonce, existingGameCell, existingUserCell);
            return;
        }

        // Unknown op → refund
        refundSurplus();
        return;
    }

    // === Opcode handlers (pure)
    inline fun handleCreateGame(sys: SystemView, keys: KeysView, fin: FinancialView, cfg: ConfigView, player: Address, betAmount: Int, hashCommitment: Cell, affiliateCode: Cell?, gameConfig: Cell, serverTimestamp: Int, serverSignature: Cell, allocatedGameId: Int, expectedServerNonce: Int, existingUserCell: Cell?) {
        throwUnless(ERROR_CONTRACT_PAUSED, !sys.isPaused);
        let maxBet: Int = fin.poolLiquidity * cfg.maxBetPercent / PERCENT_BASE;
        throwUnless(ERROR_BET_TOO_HIGH, betAmount <= maxBet);

        let serverMessage: Cell = self.buildCreateGameMessage(player, betAmount, hashCommitment, expectedServerNonce, serverTimestamp);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(serverMessage.hash(), serverSignature.asSlice(), keys.serverPublicKey));

        let currentTime: Int = now();
        throwUnless(ERROR_SIGNATURE_EXPIRED, currentTime <= serverTimestamp + 300 && currentTime >= serverTimestamp - 300);

        let poolDelta = PoolDelta{ houseBalanceDelta: 0, poolLiquidityDelta: betAmount };
        let nonceDelta = NonceDelta{ serverNonce: expectedServerNonce };
        let maxPayoutCap: Int = betAmount * cfg.maxPayoutPercent / PERCENT_BASE;
        let gameCell: Cell = self.buildNewGameCell(player, betAmount, hashCommitment, gameConfig, maxPayoutCap);

        let newUserBalance: Int = 0;
        let firstDeposit: Int = 0;
        let affiliate: Address? = null;
        if (existingUserCell == null) {
            firstDeposit = currentTime;
            newUserBalance = betAmount;
            if (affiliateCode != null) {
                affiliate = affiliateCode!!.asSlice().loadAddress();
            }
        } else {
            let user: UserData = self.parseUserCell(existingUserCell!!);
            firstDeposit = user.firstDepositTime;
            newUserBalance = user.balance + betAmount;
            affiliate = user.affiliateAddress;
        }
        let ucBuilder = beginCell().storeUint(firstDeposit, 32).storeUint(affiliate != null ? 1 : 0, 1);
        if (affiliate != null) { ucBuilder = ucBuilder.storeAddress(affiliate!!); }
        let newUserCell: Cell = ucBuilder.storeCoins(newUserBalance).endCell();
        let userDelta: Cell = beginCell().storeAddress(player).storeRef(newUserCell).endCell();

        let confBody: Cell = buildConfirmation(OP_CREATE_GAME, allocatedGameId, betAmount, emptyCell());
        let confirmation: Cell = beginCell().storeAddress(player).storeCoins(0).storeRef(confBody).endCell();

        let payloadCreate: Cell = self.buildCreatePayload(allocatedGameId, poolDelta, nonceDelta, gameCell, userDelta, confirmation);
        let bodyCreate: Cell = beginCell().storeUint(OP_MSG_CREATE_GAME_RESP, 32).storeRef(payloadCreate).endCell();
        self.reply(bodyCreate);
    }

    inline fun handleCashout(sys: SystemView, keys: KeysView, fin: FinancialView, cfg: ConfigView, payoutAmount: Int, multiplier: Int, moves: Cell, gameSeed: Cell, gameSalt: Cell, finalGameState: Cell, backendCommissionAmount: Int, serverSignature: Cell, gameId: Int, expectedServerNonce: Int, existingGameCell: Cell, existingUserCell: Cell) {
        throwUnless(ERROR_CONTRACT_PAUSED, !sys.isPaused);
        let game: GameData = self.parseGameCell(existingGameCell);
        let user: UserData = self.parseUserCell(existingUserCell);
        throwUnless(0, game.status == 0);
        throwUnless(ERROR_PAYOUT_TOO_HIGH, payoutAmount <= fin.poolLiquidity);

        let serverMessage: Cell = self.buildCashoutMessage(gameId, payoutAmount, multiplier, moves, expectedServerNonce);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(serverMessage.hash(), serverSignature.asSlice(), keys.serverPublicKey));

        let commitmentInput: Cell = self.buildCanonicalHashInput(gameSeed.asSlice(), gameSalt.asSlice(), game.gameConfig.asSlice());
        throwUnless(ERROR_INVALID_SIGNATURE, commitmentInput.hash() == game.hashCommitment.hash());

        if (now() < user.firstDepositTime + cfg.lockupPeriod) {
            throwUnless(ERROR_LOCKUP_ACTIVE, payoutAmount <= game.betAmount * 3);
            throwUnless(ERROR_LOCKUP_ACTIVE, payoutAmount <= ton("10"));
        }

        let withdrawalFee: Int = payoutAmount * cfg.withdrawalFeePercent / PERCENT_BASE;
        let netPayout: Int = payoutAmount - withdrawalFee;
        let affiliateComm: Int = backendCommissionAmount;

        let poolDelta = PoolDelta{ houseBalanceDelta: withdrawalFee, poolLiquidityDelta: - (payoutAmount + affiliateComm) };
        let nonceDelta = NonceDelta{ serverNonce: expectedServerNonce };
        let updatedGameCell: Cell = self.buildFinishedGameCell(
            game.player, game.betAmount, game.hashCommitment, game.createdAt, 1, payoutAmount, multiplier,
            game.gameConfig, moves, gameSeed, gameSalt, finalGameState, game.maxPayoutForGame
        );

        let newUserBalance: Int = user.balance - game.betAmount + payoutAmount;
        let ucBuilder2 = beginCell().storeUint(user.firstDepositTime, 32).storeUint(user.affiliateAddress != null ? 1 : 0, 1);
        if (user.affiliateAddress != null) { ucBuilder2 = ucBuilder2.storeAddress(user.affiliateAddress!!); }
        let newUserCell: Cell = ucBuilder2.storeCoins(newUserBalance).endCell();
        let userDelta: Cell = beginCell().storeAddress(game.player).storeRef(newUserCell).endCell();

        let payoutBody: Cell = buildConfirmation(OP_CASHOUT, gameId, netPayout, beginCell().storeUint(multiplier, 16).endCell());
        let payoutMsg: Cell = beginCell().storeAddress(game.player).storeCoins(netPayout).storeRef(payoutBody).endCell();

        let affBuilder = beginCell();
        if (user.affiliateAddress != null && affiliateComm > 0) {
            affBuilder = affBuilder.storeUint(1, 1).storeAddress(user.affiliateAddress!!).storeCoins(affiliateComm);
        } else {
            affBuilder = affBuilder.storeUint(0, 1);
        }
        let affDelta: Cell = affBuilder.endCell();

        let payloadCash: Cell = self.buildCashoutPayload(gameId, poolDelta, nonceDelta, updatedGameCell, userDelta, payoutMsg, affDelta);
        let bodyCash: Cell = beginCell().storeUint(OP_MSG_CASHOUT_RESP, 32).storeRef(payloadCash).endCell();
        self.reply(bodyCash);
    }

    inline fun handleMarkLost(sys: SystemView, keys: KeysView, gameSeed: Cell, gameSalt: Cell, finalGameState: Cell, serverSignature: Cell, gameId: Int, expectedServerNonce: Int, existingGameCell: Cell, existingUserCell: Cell) {
        let game: GameData = self.parseGameCell(existingGameCell);
        let user: UserData = self.parseUserCell(existingUserCell);
        throwUnless(0, game.status == 0);

        let serverMessage: Cell = self.buildMarkLostMessage(gameId, gameSeed, gameSalt, expectedServerNonce);
        throwUnless(ERROR_INVALID_SIGNATURE, checkSignature(serverMessage.hash(), serverSignature.asSlice(), keys.serverPublicKey));

        let commitmentInput: Cell = self.buildCanonicalHashInput(gameSeed.asSlice(), gameSalt.asSlice(), game.gameConfig.asSlice());
        throwUnless(ERROR_INVALID_SIGNATURE, commitmentInput.hash() == game.hashCommitment.hash());

        let poolDelta = PoolDelta{ houseBalanceDelta: game.betAmount, poolLiquidityDelta: -game.betAmount };
        let nonceDelta = NonceDelta{ serverNonce: expectedServerNonce };
        let updatedGameCell: Cell = self.buildFinishedGameCell(
            game.player, game.betAmount, game.hashCommitment, game.createdAt, 2, 0, 0,
            game.gameConfig, emptyCell(), gameSeed, gameSalt, finalGameState, game.maxPayoutForGame
        );

        let newUserBalance: Int = user.balance - game.betAmount;
        let ucBuilder3 = beginCell().storeUint(user.firstDepositTime, 32).storeUint(user.affiliateAddress != null ? 1 : 0, 1);
        if (user.affiliateAddress != null) { ucBuilder3 = ucBuilder3.storeAddress(user.affiliateAddress!!); }
        let newUserCell: Cell = ucBuilder3.storeCoins(newUserBalance).endCell();
        let userDelta: Cell = beginCell().storeAddress(game.player).storeRef(newUserCell).endCell();

        let confirmBody: Cell = buildConfirmation(OP_MARK_LOST, gameId, game.betAmount, emptyCell());
        let confirmMsg: Cell = beginCell().storeAddress(game.player).storeCoins(0).storeRef(confirmBody).endCell();

        let payloadLost: Cell = self.buildLostPayload(gameId, poolDelta, nonceDelta, updatedGameCell, userDelta, confirmMsg);
        let bodyLost: Cell = beginCell().storeUint(OP_MSG_MARK_LOST_RESP, 32).storeRef(payloadLost).endCell();
        self.reply(bodyLost);
    }

    // Routed handlers are defined below and called from the dispatcher

    // ==================================================
    // 🧠 PURE HELPERS (CELL & MESSAGE BUILDERS)
    // ==================================================

    // --- Response Payload Builders (compact, fixed-width) ---
    inline fun buildCreatePayload(gameId: Int, pool: PoolDelta, nonces: NonceDelta, gameCell: Cell, userDelta: Cell, confirmation: Cell): Cell {
        let inner: Cell = beginCell().storeRef(gameCell).storeRef(userDelta).storeRef(confirmation).endCell();
        return beginCell()
            .storeUint(1, 1)
            .storeUint(gameId, 64)
            .storeCoins(pool.houseBalanceDelta)
            .storeCoins(pool.poolLiquidityDelta)
            .storeUint(nonces.serverNonce, 64)
            .storeRef(inner)
            .endCell();
    }

    inline fun buildCashoutPayload(gameId: Int, pool: PoolDelta, nonces: NonceDelta, updatedGameCell: Cell, userDelta: Cell, payoutMsg: Cell, affiliateCell: Cell): Cell {
        let inner: Cell = beginCell().storeRef(updatedGameCell).storeRef(userDelta).storeRef(payoutMsg).storeRef(affiliateCell).endCell();
        return beginCell()
            .storeUint(1, 1)
            .storeUint(gameId, 64)
            .storeCoins(pool.houseBalanceDelta)
            .storeCoins(pool.poolLiquidityDelta)
            .storeUint(nonces.serverNonce, 64)
            .storeRef(inner)
            .endCell();
    }

    inline fun buildLostPayload(gameId: Int, pool: PoolDelta, nonces: NonceDelta, updatedGameCell: Cell, userDelta: Cell, confirmMsg: Cell): Cell {
        let inner: Cell = beginCell().storeRef(updatedGameCell).storeRef(userDelta).storeRef(confirmMsg).endCell();
        return beginCell()
            .storeUint(1, 1)
            .storeUint(gameId, 64)
            .storeCoins(pool.houseBalanceDelta)
            .storeCoins(pool.poolLiquidityDelta)
            .storeUint(nonces.serverNonce, 64)
            .storeRef(inner)
            .endCell();
    }

    // --- Signature Message Builders ---
    inline fun buildCreateGameMessage(player: Address, betAmount: Int, hashCommitment: Cell, expectedServerNonce: Int, serverTimestamp: Int): Cell {
        return beginCell().storeAddress(player).storeCoins(betAmount).storeRef(hashCommitment).storeUint(expectedServerNonce, 64).storeUint(serverTimestamp, 32).endCell();
    }
    
    inline fun buildCashoutMessage(gameId: Int, payoutAmount: Int, multiplier: Int, moves: Cell, expectedServerNonce: Int): Cell {
        return beginCell().storeUint(gameId, 64).storeCoins(payoutAmount).storeUint(multiplier, 16).storeRef(moves).storeUint(expectedServerNonce, 64).endCell();
    }
    
    inline fun buildMarkLostMessage(gameId: Int, gameSeed: Cell, gameSalt: Cell, expectedServerNonce: Int): Cell {
        return beginCell().storeUint(gameId, 64).storeRef(gameSeed).storeRef(gameSalt).storeUint(expectedServerNonce, 64).endCell();
    }

    // --- Cell Parsers ---
    inline fun parseGameCell(gameCell: Cell): GameData {
        let cs: Slice = gameCell.asSlice();
        return GameData{
            player: cs.loadAddress(),
            betAmount: cs.loadCoins(),
            hashCommitment: cs.loadRef(),
            createdAt: cs.loadUint(32),
            status: cs.loadUint(8),
            payoutAmount: cs.loadCoins(),
            multiplier: cs.loadUint(16),
            gameConfig: cs.loadRef(),
            maxPayoutForGame: cs.loadCoins()
        };
    }
    
    inline fun parseUserCell(userCell: Cell): UserData {
        let cs: Slice = userCell.asSlice();
        let first: Int = cs.loadUint(32);
        let hasAff: Int = cs.loadUint(1);
        let aff: Address? = null;
        if (hasAff == 1) { aff = cs.loadAddress(); }
        let bal: Int = cs.loadCoins();
        return UserData{ firstDepositTime: first, affiliateAddress: aff, balance: bal };
    }

    // --- Cell Builders ---
    inline fun buildNewGameCell(player: Address, betAmount: Int, hashCommitment: Cell, gameConfig: Cell, maxPayoutCap: Int): Cell {
        return beginCell()
            .storeAddress(player)
            .storeCoins(betAmount)
            .storeRef(hashCommitment)
            .storeUint(now(), 32)
            .storeUint(0, 8)
            .storeCoins(0)
            .storeUint(0, 16)
            .storeRef(gameConfig)
            .storeCoins(maxPayoutCap)
            .endCell();
    }
    
    inline fun buildFinishedGameCell(player: Address, betAmount: Int, hashCommitment: Cell, createdAt: Int, newStatus: Int, payout: Int, multiplier: Int, gameConfig: Cell, moves: Cell, seed: Cell, salt: Cell, finalState: Cell, maxPayoutForGame: Int): Cell {
        return beginCell()
            .storeAddress(player)
            .storeCoins(betAmount)
            .storeRef(hashCommitment)
            .storeUint(createdAt, 32)
            .storeUint(newStatus, 8)
            .storeCoins(payout)
            .storeUint(multiplier, 16)
            .storeRef(gameConfig)
            .storeRef(moves)
            .storeRef(seed)
            .storeRef(salt)
            .storeRef(finalState)
            .storeCoins(maxPayoutForGame)
            .endCell();
    }
    
    // --- Provable Fairness ---
    inline fun buildCanonicalHashInput(seed: Slice, salt: Slice, config: Slice): Cell {
        return beginCell().storeSlice(seed).storeUint(46, 8).storeSlice(salt).storeUint(46, 8).storeSlice(config).endCell();
    }
}