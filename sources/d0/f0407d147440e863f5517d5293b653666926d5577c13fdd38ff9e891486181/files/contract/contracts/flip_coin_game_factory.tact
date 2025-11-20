import "@stdlib/ownable";
import "@stdlib/deploy";
import "@stdlib/stoppable";

import "./errors";
import "./messages/game_factory_messages";
import "./messages/game_messages";
import "./structs/game_factory_structs";
import "./flip_coin_game";

// Factory-specific gas constants
const FACTORY_RESERVE: Int = ton("0.05");
const MIN_DEPLOY_VALUE: Int = ton("0.15");
const MAX_BATCH_SIZE: Int = 10;

contract FlipCoinGameFactory with Ownable, Deployable, Stoppable {
    stopped: Bool;
    owner: Address;

    // Configuration
    serviceFeeNumerator: Int as uint256;
    referrerFeeNumerator: Int as uint256;
    lowestBid: Int as uint256;
    highestBid: Int as uint256;
    waitingForOpenBidSeconds: Int as uint256;
    minReferrerPayoutValue: Int as uint256;

    feeReceiver: Address;

    // Salt for unique contract addresses on each deployment
    salt: Int as uint64;

    // Statistics
    totalGamesCreated: Int as uint64;
    totalGamesInitialized: Int as uint64;
    totalGamesFinished: Int as uint64;
    totalGamesCancelled: Int as uint64;
    totalGamesDrawn: Int as uint64;
    totalSecretsOpened: Int as uint64;
    totalInsufficientBalance: Int as uint64;

    // Tracking last created game for potential rollback
    lastCreatedGameId: Int as uint64;

    init(
        serviceFeeNumerator: Int,
        referrerFeeNumerator: Int,
        lowestBid: Int,
        highestBid: Int,
        waitingForOpenBidSeconds: Int,
        minReferrerPayoutValue: Int,
        feeReceiver: Address,
        stopped: Bool,
        salt: Int,
    ) {
        self.owner = sender();
        self.stopped = false;
        self.salt = salt;

        // Validation
        require(feeReceiver != newAddress(0, 0), ZERO_ADDRESS);
        require(serviceFeeNumerator >= referrerFeeNumerator, "Invalid fees");
        require(serviceFeeNumerator <= 2000, "Fee too high (max 20%)");
        require(waitingForOpenBidSeconds > 0, "Invalid timeout");

        self.feeReceiver = feeReceiver;
        self.serviceFeeNumerator = serviceFeeNumerator;
        self.referrerFeeNumerator = referrerFeeNumerator;
        self.lowestBid = lowestBid;
        self.highestBid = highestBid;
        self.waitingForOpenBidSeconds = waitingForOpenBidSeconds;
        self.minReferrerPayoutValue = minReferrerPayoutValue;

        self.totalGamesCreated = 0;
        self.totalGamesInitialized = 0;
        self.totalGamesFinished = 0;
        self.totalGamesCancelled = 0;
        self.totalGamesDrawn = 0;
        self.totalSecretsOpened = 0;
        self.totalInsufficientBalance = 0;
        self.lastCreatedGameId = 0;
    }

    // ============================================
    // Helper Functions
    // ============================================

    fun openMultipleBids(
        gameIds: map<Int as uint16, Int as uint256>,
        keys: map<Int as uint16, Int as uint256>,
        count: Int,
    ) {
        require(count <= MAX_BATCH_SIZE, "Batch too large");

        let i: Int = 0;
        while (i < count) {
            let gameId: Int? = gameIds.get(i);
            let key: Int? = keys.get(i);

            if (gameId != null && key != null) {
                let gameAddress: Address = self.calculateGameAddress(gameId!!);

                // Send open bid message to game
                // Gas will be deducted from the sent GAS_OPEN_BID
                send(SendParameters {
                    to: gameAddress,
                    value: ton("0.05"), // GAS_OPEN_BID
                    mode: SendIgnoreErrors, // Only ignore errors flag
                    bounce: false,
                    body: OpenBidMsg {
                        key: key!!,
                    }.toCell(),
                });
            }

            i = i + 1;
        }
    }

    // ============================================
    // Batch Operations
    // ============================================

    receive(msg: CreateGameAndOpenBidsMsg) {
        self.requireNotStopped();

        // Validate bid value
        require(msg.bidValue >= self.lowestBid, "Bid too low");
        require(msg.bidValue <= self.highestBid, "Bid too high");

        // 1. Создаем новую игру
        self.totalGamesCreated += 1;
        let newGameId: Int = self.totalGamesCreated;
        self.lastCreatedGameId = newGameId;

        let init: StateInit = initOf Game(newGameId, myAddress());
        let gameAddress: Address = contractAddress(init);

        // Calculate value distribution
        let incomingValue: Int = context().value;
        let factoryReserve: Int = FACTORY_RESERVE;
        let openBidsReserve: Int = ton("0.05") * msg.count; // Reserve for opening other bids
        let deployValue: Int = MIN_DEPLOY_VALUE; // Deployment cost
        let bidWithBuffer: Int = msg.bidValue + GAS_INIT_BUFFER; // Bid + init buffer

        let requiredValue: Int = deployValue + bidWithBuffer + openBidsReserve + factoryReserve;
        require(incomingValue >= requiredValue, "Insufficient value");

        // Deploy contract with state initialization only
        send(SendParameters {
            to: gameAddress,
            value: deployValue,
            mode: 0,
            bounce: false,
            code: init.code,
            data: init.data,
        });

        // Send Init message with bid value + buffer
        send(SendParameters {
            to: gameAddress,
            value: bidWithBuffer,
            mode: 0,
            bounce: true,
            body: InitGameMsg {
                playerOne: sender(),
                bidValue: msg.bidValue,
                secret: msg.secret,
                referrer: msg.referrer,
                serviceFeeNumerator: self.serviceFeeNumerator,
                referrerFeeNumerator: self.referrerFeeNumerator,
                waitingForOpenBidSeconds: self.waitingForOpenBidSeconds,
                lowestBid: self.lowestBid,
                highestBid: self.highestBid,
                feeReceiver: self.feeReceiver,
            }.toCell(),
        });

        emit(GameDeployedEvent {
            gameId: newGameId,
            gameAddress,
            creator: sender(),
            timestamp: now(),
        }.toCell());

        // 2. Открываем ставки в других играх
        self.openMultipleBids(msg.gameIdsToOpen, msg.keysToOpen, msg.count);
    }

    // ============================================
    // Game Operations
    // ============================================

    receive(msg: CreateGameMsg) {
        self.requireNotStopped();

        // Validate bid value
        require(msg.bidValue >= self.lowestBid, "Bid too low");
        require(msg.bidValue <= self.highestBid, "Bid too high");

        // Create new game
        self.totalGamesCreated += 1;
        let newGameId: Int = self.totalGamesCreated;
        self.lastCreatedGameId = newGameId;

        let init: StateInit = initOf Game(newGameId, myAddress());
        let gameAddress: Address = contractAddress(init);

        // Calculate required gas buffer
        // Player must send: bidValue + deployValue + factoryReserve + gasBuffer
        let deployValue: Int = MIN_DEPLOY_VALUE; // Deployment cost
        let factoryReserve: Int = FACTORY_RESERVE; // Minimal reserve for Factory
        let gasBuffer: Int = ton("0.05"); // Extra buffer for gas costs
        let requiredValue: Int = msg.bidValue + deployValue + factoryReserve + gasBuffer;
        require(context().value >= requiredValue, "Insufficient value");

        // Step 1: Deploy the contract with state initialization only
        send(SendParameters {
            to: gameAddress,
            value: deployValue,
            mode: 0, // Normal send - gas from value
            bounce: false,
            code: init.code,
            data: init.data,
        });

        // Step 2: Send Init message with EXACT bid value + gas buffer
        send(SendParameters {
            to: gameAddress,
            value: msg.bidValue + ton("0.02"), // Send bid + small gas buffer (GAS_INIT_BUFFER)
            mode: 0, // Normal send - gas from value
            bounce: false,
            body: InitGameMsg {
                playerOne: sender(), // Pass the actual player address
                bidValue: msg.bidValue,
                secret: msg.secret,
                referrer: msg.referrer,
                serviceFeeNumerator: self.serviceFeeNumerator,
                referrerFeeNumerator: self.referrerFeeNumerator,
                waitingForOpenBidSeconds: self.waitingForOpenBidSeconds,
                lowestBid: self.lowestBid,
                highestBid: self.highestBid,
                feeReceiver: self.feeReceiver,
            }.toCell(),
        });

        emit(GameDeployedEvent {
            gameId: newGameId,
            gameAddress,
            creator: sender(),
            timestamp: now(),
        }.toCell());
    }

    // Forward OpenBidMsg to specific game
    receive(msg: ForwardOpenBidMsg) {
        let gameAddress: Address = self.calculateGameAddress(msg.gameId);
        require(self.isGameExists(msg.gameId), "Game not exists");

        // Forward to game contract
        send(SendParameters {
            to: gameAddress,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: OpenBidMsg {
                key: msg.key,
            }.toCell(),
        });
    }

    // Forward JoinGameMsg to specific game (convenience wrapper)
    receive(msg: ForwardJoinGameMsg) {
        self.requireNotStopped();

        let gameAddress: Address = self.calculateGameAddress(msg.gameId);
        require(self.isGameExists(msg.gameId), "Game not exists");

        // Validate bid value (must match game's bid)
        require(msg.bidValue >= self.lowestBid, "Bid too low");
        require(msg.bidValue <= self.highestBid, "Bid too high");

        // Calculate required value
        let factoryReserve: Int = FACTORY_RESERVE;
        let gasBuffer: Int = ton("0.05"); // Gas buffer for join message
        let requiredValue: Int = msg.bidValue + factoryReserve + gasBuffer;
        require(context().value >= requiredValue, "Insufficient value");

        // Forward join to game contract with bid value + gas buffer
        // Gas will be deducted from the sent value during transmission
        let joinValue: Int = msg.bidValue + ton("0.05"); // bid + gas buffer (GAS_JOIN_BUFFER)
        send(SendParameters {
            to: gameAddress,
            value: joinValue,
            mode: 0, // Normal send - gas deducted from value
            bounce: true,
            body: JoinGameMsg {
                playerTwo: sender(), // Pass the actual player address
                secret: msg.secret,
                referrer: msg.referrer,
            }.toCell(),
        });
    }

    // ============================================
    // Bounced message handling with rollback
    // ============================================

    bounced(src: Slice) {
        // Deploy failed - rollback
        let op: Int = src.loadUint(32);

        // Check if this was the last created ID
        if (self.lastCreatedGameId == self.totalGamesCreated) {
            // Rollback counter
            if (self.totalGamesCreated > 0) {
                self.totalGamesCreated -= 1;
            }
            self.lastCreatedGameId = 0;
        }

        emit(BouncedMessageEvent {
            op,
            gameId: self.lastCreatedGameId,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: JoinGameAndOpenBidsMsg) {
        self.requireNotStopped();

        // 1. Присоединяемся к игре
        let gameAddress: Address = self.calculateGameAddress(msg.gameId);
        require(self.isGameExists(msg.gameId), "Game not exists");

        // Validate bid value
        require(msg.bidValue >= self.lowestBid, "Bid too low");
        require(msg.bidValue <= self.highestBid, "Bid too high");

        // Calculate required value for everything
        let openBidsReserve: Int = ton("0.05") * msg.count; // GAS_OPEN_BID * count
        let factoryReserve: Int = FACTORY_RESERVE;
        let joinValue: Int = msg.bidValue + ton("0.05"); // bid + GAS_JOIN_BUFFER
        let requiredValue: Int = joinValue + openBidsReserve + factoryReserve;
        require(context().value >= requiredValue, "Insufficient value");

        // Forward join message to game with exact value
        send(SendParameters {
            to: gameAddress,
            value: joinValue,
            mode: 0, // Send exact amount
            bounce: true,
            body: JoinGameMsg {
                playerTwo: sender(), // Pass the actual player address
                secret: msg.secret,
                referrer: msg.referrer,
            }.toCell(),
        });

        // 2. Открываем ставки в других играх
        self.openMultipleBids(msg.gameIdsToOpen, msg.keysToOpen, msg.count);
    }

    receive(msg: OpenMultipleGamesMsg) {
        // Validate we have enough value for all operations
        let requiredValue: Int = ton("0.05") * msg.count + FACTORY_RESERVE; // GAS_OPEN_BID * count + reserve
        require(context().value >= requiredValue, "Insufficient value");

        // Просто открываем ставки в нескольких играх
        self.openMultipleBids(msg.gameIdsToOpen, msg.keysToOpen, msg.count);
    }

    // ============================================
    // Game Notification Handlers
    // ============================================
    receive(msg: GameInitializedNotify) {
        // Verify sender is a valid game contract
        let expectedAddress: Address = self.calculateGameAddress(msg.gameId);
        require(sender() == expectedAddress, "Invalid game sender");

        self.totalGamesInitialized += 1;

        emit(GameInitializedEvent {
            gameId: msg.gameId,
            playerOne: msg.playerOne,
            bidValue: msg.bidValue,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: GameStartedNotify) {
        let expectedAddress: Address = self.calculateGameAddress(msg.gameId);
        require(sender() == expectedAddress, "Invalid game sender");

        emit(GameStartedEvent {
            gameId: msg.gameId,
            playerOne: msg.playerOne,
            playerTwo: msg.playerTwo,
            totalGainings: msg.totalGainings,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: GameFinishedNotify) {
        let expectedAddress: Address = self.calculateGameAddress(msg.gameId);
        require(sender() == expectedAddress, "Invalid game sender");

        self.totalGamesFinished += 1;

        emit(GameFinishedEvent {
            gameId: msg.gameId,
            winner: msg.winner,
            looser: msg.looser,
            totalGainings: msg.totalGainings,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: GameCancelledNotify) {
        let expectedAddress: Address = self.calculateGameAddress(msg.gameId);
        require(sender() == expectedAddress, "Invalid game sender");

        self.totalGamesCancelled += 1;

        emit(GameCancelledEvent {
            gameId: msg.gameId,
            playerOne: msg.playerOne,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: DrawNotify) {
        let expectedAddress: Address = self.calculateGameAddress(msg.gameId);
        require(sender() == expectedAddress, "Invalid game sender");

        self.totalGamesDrawn += 1;

        emit(DrawEvent {
            gameId: msg.gameId,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: SecretOpenedNotify) {
        let expectedAddress: Address = self.calculateGameAddress(msg.gameId);
        require(sender() == expectedAddress, "Invalid game sender");

        // Track total secrets opened for statistics
        self.totalSecretsOpened += 1;
    }

    receive(msg: InsufficientBalanceNotify) {
        let expectedAddress: Address = self.calculateGameAddress(msg.gameId);
        require(sender() == expectedAddress, "Invalid game sender");

        // Track insufficient balance occurrences for monitoring
        self.totalInsufficientBalance += 1;
    }

    // ============================================
    // Admin functions
    // ============================================

    receive(msg: SetFeeReceiverMsg) {
        self.requireOwner();
        require(msg.newReceiver != newAddress(0, 0), ZERO_ADDRESS);

        self.feeReceiver = msg.newReceiver;

        emit(FeeReceiverChangedEvent {
            newReceiver: msg.newReceiver,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: SetServiceFeeMsg) {
        self.requireOwner();
        require(msg.newValue >= self.referrerFeeNumerator, WRONG_VALUE);

        self.serviceFeeNumerator = msg.newValue;

        emit(ServiceFeeChangedEvent {
            newValue: msg.newValue,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: SetReferrerFeeMsg) {
        self.requireOwner();
        require(self.serviceFeeNumerator >= msg.newValue, WRONG_VALUE);

        self.referrerFeeNumerator = msg.newValue;

        emit(ReferrerFeeChangedEvent {
            newValue: msg.newValue,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: SetLowestBidMsg) {
        self.requireOwner();

        self.lowestBid = msg.newValue;

        emit(LowestBidChangedEvent {
            newValue: msg.newValue,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: SetHighestBidMsg) {
        self.requireOwner();

        self.highestBid = msg.newValue;

        emit(HighestBidChangedEvent {
            newValue: msg.newValue,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: SetWaitingForOpenBidSecondsMsg) {
        self.requireOwner();

        self.waitingForOpenBidSeconds = msg.newValue;

        emit(WaitingForOpenBidSecondsChangedEvent {
            newValue: msg.newValue,
            timestamp: now(),
        }.toCell());
    }

    receive(msg: SetMinReferrerPayoutValueMsg) {
        self.requireOwner();

        self.minReferrerPayoutValue = msg.newValue;

        emit(MinReferrerPayoutValueChangedEvent {
            newValue: msg.newValue,
            timestamp: now(),
        }.toCell());
    }

    receive("stop") {
        self.requireOwner();
        require(!self.stopped, "Already stopped");

        self.stopped = true;

        emit(SystemStoppedEvent {
            timestamp: now(),
        }.toCell());
    }

    receive("resume") {
        self.requireOwner();
        require(self.stopped, "Not stopped");

        self.stopped = false;

        emit(SystemResumeEvent {
            timestamp: now(),
        }.toCell());
    }

    // ============================================
    // Getters
    // ============================================

    get fun calculateGameAddress(gameId: Int): Address {
        let init: StateInit = initOf Game(gameId, myAddress());
        return contractAddress(init);
    }

    get fun isGameExists(gameId: Int): Bool {
        return gameId > 0 && gameId <= self.totalGamesCreated;
    }

    get fun getGameAddressBatch(startId: Int, count: Int): GameAddressBatch {
        let addresses: map<Int as uint32, Address> = emptyMap();

        let endId: Int = min(startId + count - 1, self.totalGamesCreated);

        let i: Int = startId;
        while (i <= endId) {
            addresses.set(i, self.calculateGameAddress(i));
            i = i + 1;
        }

        return GameAddressBatch {
            startId,
            addresses,
        };
    }

    get fun statistics(): DetailedStats {
        return DetailedStats {
            totalGamesCreated: self.totalGamesCreated,
            totalGamesInitialized: self.totalGamesInitialized,
            totalGamesFinished: self.totalGamesFinished,
            totalGamesCancelled: self.totalGamesCancelled,
            totalGamesDrawn: self.totalGamesDrawn,
            totalSecretsOpened: self.totalSecretsOpened,
            totalInsufficientBalance: self.totalInsufficientBalance,
        };
    }

    get fun config(): FactoryConfig {
        return FactoryConfig {
            serviceFeeNumerator: self.serviceFeeNumerator,
            referrerFeeNumerator: self.referrerFeeNumerator,
            waitingForOpenBidSeconds: self.waitingForOpenBidSeconds,
            feeReceiver: self.feeReceiver,
            stopped: self.stopped,
        };
    }

    get fun minReferrerPayoutValue(): Int {
        return self.minReferrerPayoutValue;
    }
}
