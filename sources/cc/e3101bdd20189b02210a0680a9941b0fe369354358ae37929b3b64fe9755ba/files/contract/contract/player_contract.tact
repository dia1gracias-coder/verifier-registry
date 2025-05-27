import "./messages";
import "./constants";
import "./structs";

contract PlayerContract {
    parent: Address;
    player: Address;
    tokenBalance: Int as uint64;
    initTime: Int as uint64;
    isPlaying: Bool;
    lastRedDate: Int as uint64;
    bet: Int as uint32;
    gameStarted: Int as uint64;
    streakStateOnStart: Int as int64;
    greenCountOnStart: Int as uint64;
    redCountOnStart: Int as uint64;
    playerGreenCount: Int as uint32;
    playerRedCount: Int as uint32;

    // referral system
    const maxRefMapSize: Int = 2001;
    const minRefMapSize: Int = 49;

    refMapSize: Int;
    cpaPaid: Bool;
    referrer: Address?;
    refereesCount: Int as uint32;
    refereesMap: map<Int, Address>;
    arrStart: Int as uint16;
    arrLength: Int as uint16;

    init(parent: Address, player: Address) {
        self.parent = parent;
        self.player = player;
        self.tokenBalance = 0;
        self.refereesCount = 0;
        self.initTime = now();
        self.isPlaying = false;
        self.lastRedDate = 0;
        self.bet = 0;
        self.gameStarted = 0;
        self.streakStateOnStart = 0;
        self.greenCountOnStart = 0;
        self.redCountOnStart = 0;
        self.playerGreenCount = 0;
        self.playerRedCount = 0;
        // referral system
        self.refMapSize = 100;
        self.cpaPaid = false;
        self.arrLength = 0;
        self.arrStart = 0;
    }

    get fun playerState(): PlayerState {
        return PlayerState {
            parent: self.parent,
            player: self.player,
            tokenBalance: self.tokenBalance,
            initTime: self.initTime,
            isPlaying: self.isPlaying,
            lastRedDate: self.lastRedDate,
            bet: self.bet,
            gameStarted: self.gameStarted,
            streakStateOnStart: self.streakStateOnStart,
            greenCountOnStart: self.greenCountOnStart,
            redCountOnStart: self.redCountOnStart,
            playerGreenCount: self.playerGreenCount,
            playerRedCount: self.playerRedCount,
            refMapSize: self.refMapSize,
            cpaPaid: self.cpaPaid,
            referrer: self.referrer,
            refereesCount: self.refereesCount,
            refereesMap: self.refereesMap,
            arrStart: self.arrStart,
            arrLength: self.arrLength,
            createAt: now(),

        };
    }

    fun addRefereeToMap(item: Address) {
        if (self.refereesCount < self.refMapSize) {
            self.refereesMap.set(self.arrLength, item);
            self.refereesCount += 1;
        } else {
            self.refereesMap.set(self.arrStart, item);
            self.arrStart = (self.arrStart + 1) % self.refMapSize;
        }
    }

    receive(msg: G2PStartPlayer) {
        require(sender() == self.parent, "Access denied, Not Parent");
        require(msg.player == self.player, "Access denied, Not Player");
        require(self.isPlaying == false, "Playing now, call StopPlayer to start again");
        nativeReserve(ton("0.01"), 2);

        if (msg.useBalance) {
            require(msg.bet <= self.tokenBalance, "Insufficient balance");
            self.tokenBalance -= msg.bet;
        }

        if (self.referrer == null && msg.referrer != null) {
            self.referrer = msg.referrer;
        }

        self.bet = msg.bet;
        self.isPlaying = true;
        self.gameStarted = now();
        self.streakStateOnStart = msg.streakState;
        self.greenCountOnStart = msg.greenCount;
        self.redCountOnStart = msg.redCount;

        cashback(self.parent);
    }

    receive(msg: G2PStopPlayer) {
        require(sender() == self.parent, "Access denied, Not Parent");
        require(msg.player == self.player, "Access denied, Not Player");
        require(self.isPlaying == true, "Not Playing");
        let greenDiff = self.greenCountOnStart - msg.greenCount;
        let redDiff = self.redCountOnStart - msg.redCount;
        let streakDiff = self.streakStateOnStart - msg.streakState;

        let streakBonusBase: Int = 100;
        let streakBonus: Int = max(streakBonusBase, (abs(self.streakStateOnStart) * 20 / 5 + streakBonusBase));

        let redPenaltyBase: Int = 100;
        let redPenalty: Int = max(10, (redPenaltyBase - redDiff * redPenaltyBase / 3));

        let reward: Int = (self.bet * streakBonus * redPenalty) / (streakBonusBase * redPenaltyBase);

        reward = max(self.bet, reward);
        self.tokenBalance += reward;
        self.isPlaying = false;
        self.gameStarted = 0;
        if (self.referrer != null) {
            //TODO calc aff rewards
            let cpaReward: Int = 0;
            let refShareReward: Int = 0;
            let sendRewardBody = P2PAffRewardInternal {
                cpaReward: cpaReward,
                refShareReward: refShareReward,
                cashback: self.player,
            };
            let params = MessageParameters {
                to: self.referrer!!,
                value: 0,
                mode: SendRemainingValue,
                body: sendRewardBody.toCell(),
            };
            message(params);
        } else {
            cashback(self.parent);
        }
    }

    receive(msg: G2PRedPlayer) {
        require(sender() == self.parent, "Access denied, Not Parent");
        require(msg.player == self.player, "Access denied, Not Player");
        require(self.isPlaying == false, "Playing, call StopPlayer to start again");

        // Update the last red action timestamp
        self.lastRedDate = now();

        // Calculate reward based on streak state
        // Base of 100 (100 = 1.0x multiplier)
        let rewardBase: Int = 100;

        // Calculate streak factor - grows linearly with streak
        let streakFactor: Int = max(100, msg.streakState * 10 + 100);

        // Calculate reward multiplier - grows faster than linear but not quadratic
        // Using a power of 1.2 approximation: x^1.2 ≈ x * x^0.2
        // For integer math with base 100: x^1.2 ≈ (x * (x^0.2 * 100)) / 100
        // Simplified approximation: x^1.2 ≈ (x * (100 + x/5)) / 100
        let rewardMultiplier: Int = (streakFactor * (100 + msg.streakState / 5)) / 100;

        // Calculate final reward
        let reward: Int = (msg.price * rewardMultiplier) / rewardBase;

        // Add reward to player's token balance
        self.tokenBalance += reward;

        // If player is currently in a game, update the streak state
        if (self.isPlaying) {
            self.streakStateOnStart -= 1;
        }

        // If referrer is provided and not already set, set it
        if (self.referrer == null && msg.referrer != null) {
            self.referrer = msg.referrer;
        }

        if (self.referrer != null) {
            //TODO calc aff rewards RED
            let cpaReward: Int = 0;
            let refShareReward: Int = 0;
            let sendRewardBody = P2PAffRewardInternal {
                cpaReward: cpaReward,
                refShareReward: refShareReward,
                cashback: self.player,
            };
            let params = MessageParameters {
                to: self.referrer!!,
                value: 0,
                mode: SendRemainingValue,
                body: sendRewardBody.toCell(),
            };
            message(params);
        } else {
            cashback(self.parent);
        }
    }

    receive(msg: P2PAffRewardInternal) {
        let senderPlayer = initOf PlayerContract(self.parent, sender());
        require(senderPlayer.hasSameBasechainAddress(myAddress()) && sender() != myAddress(), "Incorrect Sender");

        if (self.refereesCount > 49) {
            self.tokenBalance += msg.refShareReward;
        }

        if (!self.cpaPaid) {
            self.tokenBalance += msg.cpaReward;
        }

        if (msg.isRed) {
            //
        }

        cashback(msg.cashback);
    }

    receive(msg: G2PTokenDeposit) {
        require(sender() == self.parent, "Access denied, Not Parent");
        self.tokenBalance += msg.amount;
        cashback(msg.sender);
    }

    receive(msg: G2PTokenWithdraw) {
        require(sender() == self.parent, "Access denied, Not Parent");
        require(self.tokenBalance >= msg.amount, "Insufficient balance");
        self.tokenBalance -= msg.amount;
        let sendTokenRewardBody = P2GTokenWithdraw {
            destination: msg.player,
            amount: msg.amount,
        };

        let messageParams = MessageParameters {
            to: self.parent,
            mode: SendRemainingValue,
            value: 0,
            body: sendTokenRewardBody.toCell(),
        };

        message(messageParams);
    }

    receive("claimTON") {
        require(sender() == self.player, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);
        message(MessageParameters {
            to: self.player,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive(msg: JettonExcesses) {}

    get fun getBalance(): Int {
        return myBalance();
    }
}
