import "@stdlib/deploy";
import "./messages/game_messages";
import "./structs/game_factory_structs";
import "./referrer_wallet";

// ============================================
// Constants
// ============================================

const COIN_SIDE_NONE: Int = 0;
const COIN_SIDE_CLOSED: Int = 1;
const COIN_SIDE_HEADS: Int = 2;
const COIN_SIDE_TAILS: Int = 3;

const GAME_STATUS_UNINITIALIZED: Int = 0;
const GAME_STATUS_WAITING_FOR_OPPONENT: Int = 1;
const GAME_STATUS_WAITING_FOR_OPEN_BIDS: Int = 2;
const GAME_STATUS_ENDED: Int = 3;
const GAME_STATUS_PAID: Int = 4;

const DENOMINATOR: Int = 10000;

// Gas constants
const MIN_CONTRACT_BALANCE: Int = ton("0.05");
const MIN_TRANSFER_AMOUNT: Int = ton("0.01");
const MIN_MESSAGE_VALUE: Int = ton("0.01");
const GAS_NOTIFICATION: Int = ton("0.01");
const GAS_INIT_BUFFER: Int = ton("0.02");
const GAS_JOIN_BUFFER: Int = ton("0.05");

// Emergency timeout (30 days)
const EMERGENCY_TIMEOUT: Int = 2592000;

// ============================================
// Improved Game Contract - FIXED
// ============================================

contract Game {
    // Immutable parameters
    gameId: Int as uint256;
    factory: Address;

    // Configuration (received from Factory)
    serviceFeeNumerator: Int as uint32;
    referrerFeeNumerator: Int as uint32;
    waitingForOpenBidSeconds: Int as uint32;
    lowestBid: Int as coins;
    highestBid: Int as coins;
    feeReceiver: Address;
    configReceived: Bool;

    // Mutable state
    status: Int as uint8;
    playerOne: Address;
    playerTwo: Address;
    bidValue: Int as coins;
    totalGainings: Int as coins;

    playerOneEncryptedBet: Int as uint256;
    playerTwoEncryptedBet: Int as uint256;

    playerOneChosenSide: Int as uint2;
    playerTwoChosenSide: Int as uint2;

    gameCreatedTimestamp: Int as uint32;
    gameStartedTimestamp: Int as uint32;

    winner: Address;

    playerOneReferrer: Address?;
    playerTwoReferrer: Address?;

    // Race condition protection
    finishing: Bool;

    init(gameId: Int, factory: Address) {
        self.gameId = gameId;
        self.factory = factory;

        self.serviceFeeNumerator = 0;
        self.referrerFeeNumerator = 0;
        self.waitingForOpenBidSeconds = 0;
        self.lowestBid = 0;
        self.highestBid = 0;
        self.feeReceiver = newAddress(0, 0);
        self.configReceived = false;

        self.status = GAME_STATUS_UNINITIALIZED;
        self.playerOne = newAddress(0, 0);
        self.playerTwo = newAddress(0, 0);
        self.bidValue = 0;
        self.totalGainings = 0;

        self.playerOneEncryptedBet = 0;
        self.playerTwoEncryptedBet = 0;

        self.playerOneChosenSide = COIN_SIDE_CLOSED;
        self.playerTwoChosenSide = COIN_SIDE_CLOSED;

        self.gameCreatedTimestamp = 0;
        self.gameStartedTimestamp = 0;

        self.winner = newAddress(0, 0);
        self.playerOneReferrer = null;
        self.playerTwoReferrer = null;

        self.finishing = false;
    }

    // ============================================
    // Game initialization with config
    // ============================================

    receive(msg: InitGameMsg) {
        require(self.status == GAME_STATUS_UNINITIALIZED, "Game already initialized");
        require(sender() == self.factory, "Only factory can initialize");

        // Set config from message
        require(msg.serviceFeeNumerator >= msg.referrerFeeNumerator, "Invalid fees");
        require(msg.lowestBid > 0, "Invalid lowest bid");
        require(msg.highestBid >= msg.lowestBid, "Invalid highest bid");

        self.serviceFeeNumerator = msg.serviceFeeNumerator;
        self.referrerFeeNumerator = msg.referrerFeeNumerator;
        self.waitingForOpenBidSeconds = msg.waitingForOpenBidSeconds;
        self.lowestBid = msg.lowestBid;
        self.highestBid = msg.highestBid;
        self.feeReceiver = msg.feeReceiver;
        self.configReceived = true;

        // Use bidValue from message, not context().value!
        let bidAmount: Int = msg.bidValue;
        require(bidAmount >= self.lowestBid, "Bid too low");
        require(bidAmount <= self.highestBid, "Bid too high");
        require(bidAmount >= MIN_TRANSFER_AMOUNT, "Bid too small");

        // Validate that we received at least the bid amount
        // Allow small gas buffer for message processing
        require(context().value >= bidAmount, "Insufficient value received");

        // Validate referrer if provided
        if (msg.referrer != null) {
            let referrerAddr: Address = msg.referrer!!;
            self.validateAddress(referrerAddr);
            require(referrerAddr != msg.playerOne, "Cannot refer yourself");
            self.playerOneReferrer = referrerAddr;
        } else {
            self.playerOneReferrer = null;
        }

        self.playerOne = msg.playerOne; // Use playerOne from message, not sender()
        self.bidValue = bidAmount;
        self.playerOneEncryptedBet = msg.secret;
        self.playerOneChosenSide = COIN_SIDE_CLOSED;
        self.totalGainings = self.bidValue;
        self.gameCreatedTimestamp = now();
        self.status = GAME_STATUS_WAITING_FOR_OPPONENT;

        // Notify factory (use fixed value to avoid depleting contract balance)
        send(SendParameters {
            to: self.factory,
            value: GAS_NOTIFICATION,
            mode: SendIgnoreErrors,
            body: GameInitializedNotify {
                gameId: self.gameId,
                playerOne: self.playerOne,
                bidValue: self.bidValue,
            }.toCell(),
        });
    }

    // ============================================
    // Join game
    // ============================================

    receive(msg: JoinGameMsg) {
        require(self.status == GAME_STATUS_WAITING_FOR_OPPONENT, "Game not ready");
        require(sender() == self.factory, "Only factory can forward join");
        require(msg.playerTwo != self.playerOne, "Cannot play with yourself");

        // Strict validation: must be at least the bid value (no less allowed)
        // The Factory sends bidValue + small buffer, but gas is deducted during transmission
        // We allow up to GAS_JOIN_BUFFER more (from buffer), but NOT less than bidValue
        require(context().value >= self.bidValue, "Bid too low");
        require(context().value <= self.bidValue + GAS_JOIN_BUFFER, "Bid too high");

        // Validate referrer if provided
        if (msg.referrer != null) {
            let referrerAddr: Address = msg.referrer!!;
            self.validateAddress(referrerAddr);
            require(referrerAddr != msg.playerTwo, "Cannot refer yourself");
            self.playerTwoReferrer = referrerAddr;
        } else {
            self.playerTwoReferrer = null;
        }

        self.playerTwo = msg.playerTwo;
        self.playerTwoEncryptedBet = msg.secret;
        self.playerTwoChosenSide = COIN_SIDE_CLOSED;
        self.status = GAME_STATUS_WAITING_FOR_OPEN_BIDS;
        self.totalGainings = self.bidValue * 2;
        self.gameStartedTimestamp = now();

        // Notify factory (use fixed value to avoid depleting contract balance)
        send(SendParameters {
            to: self.factory,
            value: GAS_NOTIFICATION,
            mode: SendIgnoreErrors,
            body: GameStartedNotify {
                gameId: self.gameId,
                playerOne: self.playerOne,
                playerTwo: self.playerTwo,
                totalGainings: self.totalGainings,
            }.toCell(),
        });
    }

    // ============================================
    // Open bid
    // ============================================

    receive(msg: OpenBidMsg) {
        require(self.status == GAME_STATUS_WAITING_FOR_OPEN_BIDS, "Wrong game status");
        require(self.finishing == false, "Game is finishing");

        let coinSide: Int = COIN_SIDE_CLOSED;

        if (sender() == self.playerOne) {
            require(self.playerOneChosenSide == COIN_SIDE_CLOSED, "Already opened");
            coinSide = self.getCoinSideFromEncryptedBet(self.playerOneEncryptedBet, msg.key, self.playerOne);
            require(coinSide != COIN_SIDE_CLOSED, "Invalid key or coin side");
            self.playerOneChosenSide = coinSide;
            self.playerOneEncryptedBet = 0; // Clear encrypted bet after revealing (save storage)
        } else if (sender() == self.playerTwo) {
            require(self.playerTwoChosenSide == COIN_SIDE_CLOSED, "Already opened");
            coinSide = self.getCoinSideFromEncryptedBet(self.playerTwoEncryptedBet, msg.key, self.playerTwo);
            require(coinSide != COIN_SIDE_CLOSED, "Invalid key or coin side");
            self.playerTwoChosenSide = coinSide;
            self.playerTwoEncryptedBet = 0; // Clear encrypted bet after revealing (save storage)
        } else {
            throw(1000);
        }

        // Notify about secret opened (use fixed value, not SendRemainingValue)
        send(SendParameters {
            to: self.factory,
            value: GAS_NOTIFICATION,
            mode: SendIgnoreErrors,
            body: SecretOpenedNotify {
                gameId: self.gameId,
                player: sender(),
                coinSide,
            }.toCell(),
        });

        // Check if both players opened their bids
        if (self.playerOneChosenSide > COIN_SIDE_CLOSED && self.playerTwoChosenSide > COIN_SIDE_CLOSED) {
            // Finish the game if we have sufficient balance
            // Require full totalGainings amount to ensure all payouts can be made
            if (myBalance() >= self.totalGainings) {
                self.finishing = true; // Set flag BEFORE finishing to prevent race condition
                self.finishGame();
            } else {
                // Critical: insufficient balance - mark as finishing and attempt proportional refund
                self.finishing = true;
                self.status = GAME_STATUS_ENDED;

                // Log insufficient balance for manual intervention
                send(SendParameters {
                    to: self.factory,
                    value: GAS_NOTIFICATION,
                    mode: SendIgnoreErrors,
                    body: InsufficientBalanceNotify {
                        gameId: self.gameId,
                        required: self.totalGainings,
                        actual: myBalance(),
                    }.toCell(),
                });

                // Attempt proportional refund if possible
                let availableBalance: Int = myBalance() - MIN_CONTRACT_BALANCE;
                if (availableBalance >= MIN_TRANSFER_AMOUNT * 2) {
                    let refundPerPlayer: Int = availableBalance / 2;
                    if (refundPerPlayer >= MIN_TRANSFER_AMOUNT) {
                        self.sendPayment(self.playerOne, refundPerPlayer, "Partial refund - insufficient balance");
                        self.sendPayment(self.playerTwo, refundPerPlayer, "Partial refund - insufficient balance");
                        self.status = GAME_STATUS_PAID;
                    }
                }
            }
        }
    }

    // ============================================
    // Cancel game
    // ============================================

    receive(msg: CancelGameMsg) {
        require(msg.gameId == self.gameId, "Wrong game ID");
        require(self.status == GAME_STATUS_WAITING_FOR_OPPONENT, "Cannot cancel");
        require(sender() == self.playerOne, "Only creator can cancel");
        require(now() >= self.gameCreatedTimestamp + self.waitingForOpenBidSeconds, "Too early to cancel");

        self.status = GAME_STATUS_PAID;

        // Calculate service fee even on cancellation
        let serviceFee: Int = self.bidValue * self.serviceFeeNumerator / DENOMINATOR;
        let refundAmount: Int = self.bidValue - serviceFee;

        // Send service fee
        send(SendParameters {
            to: self.feeReceiver,
            value: serviceFee,
            mode: SendIgnoreErrors,
            bounce: false,
            body: "Cancellation fee".asComment(),
        });

        // Return remaining bid to player one
        send(SendParameters {
            to: self.playerOne,
            value: refundAmount,
            mode: SendIgnoreErrors,
            bounce: false,
            body: "Game cancelled - refund".asComment(),
        });

        // Notify factory
        send(SendParameters {
            to: self.factory,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: GameCancelledNotify {
                gameId: self.gameId,
                playerOne: self.playerOne,
            }.toCell(),
        });
    }

    // ============================================
    // Finish game by timeout
    // ============================================

    receive(msg: FinishGameMsg) {
        require(msg.gameId == self.gameId, "Wrong game ID");
        require(self.status == GAME_STATUS_WAITING_FOR_OPEN_BIDS, "Wrong game status");
        require(self.finishing == false, "Already finishing");
        require(now() >= self.gameStartedTimestamp + self.waitingForOpenBidSeconds, "Too early to finish");
        // Anyone can call finish by timeout (like in Solidity)

        self.finishing = true;
        self.finishGame();
    }

    // ============================================
    // Emergency withdrawal
    // ============================================

    receive("emergencyWithdraw") {
        // Only Factory can call this (owner-controlled)
        require(sender() == self.factory, "Only factory");
        require(
            self.status == GAME_STATUS_WAITING_FOR_OPPONENT ||
            self.status == GAME_STATUS_WAITING_FOR_OPEN_BIDS,
            "Wrong status",
        );

        // Must wait EMERGENCY_TIMEOUT after game started/created
        let referenceTimestamp: Int = self.gameStartedTimestamp;
        if (referenceTimestamp == 0) {
            referenceTimestamp = self.gameCreatedTimestamp;
        }
        require(now() >= referenceTimestamp + EMERGENCY_TIMEOUT, "Too early for emergency");

        // Mark as paid
        self.status = GAME_STATUS_PAID;

        // Refund both players equally
        if (self.playerTwo != newAddress(0, 0)) {
            // Game started - refund both
            let refundAmount: Int = self.bidValue;
            self.sendPayment(self.playerOne, refundAmount, "Emergency refund");
            self.sendPayment(self.playerTwo, refundAmount, "Emergency refund");
        } else {
            // Game not started - refund creator only
            self.sendPayment(self.playerOne, self.bidValue, "Emergency refund");
        }

        // Send remaining balance to factory
        send(SendParameters {
            to: self.factory,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: "Emergency withdrawal complete".asComment(),
        });
    }

    // ============================================
    // Bounced message handling
    // ============================================

    bounced(msg: bounced<GameFinishedNotify>) {
        if (self.status == GAME_STATUS_PAID) {
            self.status = GAME_STATUS_ENDED;
            self.finishing = false;
        }
    }

    bounced(src: Slice) {
        // If any transfer bounced, we don't store failed earnings (too expensive in TON)
        // Player should ensure their wallet is able to receive transfers
        // The bounced amount is automatically returned to the contract balance
        // Game owner can manually handle failed cases if needed
    }

    // ============================================
    // Internal functions
    // ============================================

    fun finishGame() {
        require(self.status == GAME_STATUS_WAITING_FOR_OPEN_BIDS, "Wrong status");
        // Balance check is done before calling this function

        let winner: Address = newAddress(0, 0);
        let looser: Address = newAddress(0, 0);

        // Both players opened bids
        if (self.playerOneChosenSide > COIN_SIDE_CLOSED && self.playerTwoChosenSide > COIN_SIDE_CLOSED) {
            if (self.playerOneChosenSide == self.playerTwoChosenSide) {
                winner = self.playerTwo;
                looser = self.playerOne;
            } else {
                winner = self.playerOne;
                looser = self.playerTwo;
            }

            self.winner = winner;
            self.status = GAME_STATUS_ENDED;

            // Calculate fees and payouts
            let serviceFee: Int = self.totalGainings * self.serviceFeeNumerator / DENOMINATOR;
            let referrerFee: Int = self.totalGainings * self.referrerFeeNumerator / DENOMINATOR;

            // Calculate winner earnings
            let winnerEarnings: Int = self.totalGainings - serviceFee - referrerFee;

            // Handle referrer rewards - send to ReferrerWallet
            let winnerReferrer: Address? = null;
            if (winner == self.playerOne) {
                winnerReferrer = self.playerOneReferrer;
            } else {
                winnerReferrer = self.playerTwoReferrer;
            }

            // Change status BEFORE sending any transfers (checks-effects-interactions)
            self.status = GAME_STATUS_PAID;

            // Send service fee
            send(SendParameters {
                to: self.feeReceiver,
                value: serviceFee,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Service fee".asComment(),
            });

            if (winnerReferrer != null) {
                // Send reward to ReferrerWallet (contract) - deploy if not exists
                let init: StateInit = initOf ReferrerWallet(winnerReferrer!!, self.factory, ton("0.1"));
                let referrerWalletAddress: Address = contractAddress(init);
                send(SendParameters {
                    to: referrerWalletAddress,
                    value: referrerFee,
                    mode: SendIgnoreErrors,
                    bounce: false,
                    body: AddReferrerReward {
                        gameId: self.gameId,
                        amount: referrerFee,
                        winner,
                    }.toCell(),
                    code: init.code,
                    data: init.data,
                });
            }

            // Send winnings to winner
            self.sendPayment(winner, winnerEarnings, "You won!");

            // Notify factory
            send(SendParameters {
                to: self.factory,
                value: 0,
                mode: SendRemainingBalance | SendIgnoreErrors,
                body: GameFinishedNotify {
                    gameId: self.gameId,
                    winner,
                    looser,
                    totalGainings: self.totalGainings,
                }.toCell(),
            });
        } else {
            // One player didn't open - draw with service fee like Solidity
            self.status = GAME_STATUS_ENDED;

            // Calculate service fee and refund amount
            let serviceFee: Int = self.totalGainings * self.serviceFeeNumerator / DENOMINATOR;
            let refundAmount: Int = (self.totalGainings - serviceFee) / 2;

            // Change status BEFORE sending transfers
            self.status = GAME_STATUS_PAID;

            // Send service fee
            send(SendParameters {
                to: self.feeReceiver,
                value: serviceFee,
                mode: SendIgnoreErrors,
                bounce: false,
                body: "Service fee (draw)".asComment(),
            });

            // Refund both players equally
            self.sendPayment(self.playerOne, refundAmount, "Draw - refund");
            self.sendPayment(self.playerTwo, refundAmount, "Draw - refund");

            // Notify factory about draw
            send(SendParameters {
                to: self.factory,
                value: 0,
                mode: SendRemainingBalance | SendIgnoreErrors,
                body: DrawNotify {
                    gameId: self.gameId,
                }.toCell(),
            });
        }
    }

    fun sendPayment(to: Address, amount: Int, comment: String) {
        self.validateAddress(to);
        require(amount >= MIN_TRANSFER_AMOUNT, "Amount too small");

        send(SendParameters {
            to,
            value: amount,
            mode: SendPayGasSeparately,
            bounce: false, // User wallets should use bounce: false
            body: comment.asComment(),
        });
    }

    fun validateAddress(addr: Address) {
        require(addr != newAddress(0, 0), "Zero address");
    }

    fun getCoinSideFromEncryptedBet(encryptedBet: Int, key: Int, player: Address): Int {
        let headsHash: Int = self.calculateHash(COIN_SIDE_HEADS, key, player);
        if (encryptedBet == headsHash) {
            return COIN_SIDE_HEADS;
        }

        let tailsHash: Int = self.calculateHash(COIN_SIDE_TAILS, key, player);
        if (encryptedBet == tailsHash) {
            return COIN_SIDE_TAILS;
        }

        return COIN_SIDE_CLOSED;
    }

    get fun calculateHash(coinSide: Int, key: Int, player: Address): Int {
        let builder: Builder = beginCell();
        builder = builder.storeUint(coinSide, 8);
        builder = builder.storeUint(key, 256);
        builder = builder.storeAddress(player);
        return builder.endCell().hash();
    }

    // ============================================
    // Getters
    // ============================================

    get fun gameInfo(): GameInfo {
        return GameInfo {
            gameId: self.gameId,
            status: self.status,
            playerOne: self.playerOne,
            playerTwo: self.playerTwo,
            bidValue: self.bidValue,
            totalGainings: self.totalGainings,
            playerOneChosenSide: self.playerOneChosenSide,
            playerTwoChosenSide: self.playerTwoChosenSide,
            gameCreatedTimestamp: self.gameCreatedTimestamp,
            gameStartedTimestamp: self.gameStartedTimestamp,
            winner: self.winner,
            configReceived: self.configReceived,
        };
    }

    get fun status(): Int {
        return self.status;
    }

    get fun players(): PlayerInfo {
        return PlayerInfo {
            playerOne: self.playerOne,
            playerTwo: self.playerTwo,
        };
    }

    get fun config(): GameConfig {
        return GameConfig {
            serviceFeeNumerator: self.serviceFeeNumerator,
            referrerFeeNumerator: self.referrerFeeNumerator,
            waitingForOpenBidSeconds: self.waitingForOpenBidSeconds,
            feeReceiver: self.feeReceiver,
        };
    }
}
