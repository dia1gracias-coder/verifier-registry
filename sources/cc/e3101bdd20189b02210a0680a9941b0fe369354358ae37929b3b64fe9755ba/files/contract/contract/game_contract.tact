import "@stdlib/ownable";
import "./player_contract";
import "./jetton-minter";
import "./jetton-wallet";
import "./structs";
import "./messages";
import "./functions";
import "./constants";

contract GameContract with Ownable {
    owner: Address;
    tokenMinted: Bool;
    tokenAddress: Address?;
    walletAddress: Address?;
    deployTime: Int as uint64;
    gameStarted: Int as uint64;
    airdropDuration: Int as uint64;
    /// влияет на вознаграждение красным, чем ниже - тем ниже
    streakState: Int as uint64;
    greenCount: Int as uint64;
    redCount: Int as uint64;
    // Remote config
    cpaReward: Int as uint256;
    /// minimum time before new config change is allowed, made for smooth changes
    changeInterval: Int as uint256;
    lastChanged: Int as uint256;
    maxBet: Int as uint256;
    minBet: Int as uint256;
    streakRatio: Int as uint256;
    greenPrice: Int;
    redPrice: Int;
    // Game History
    // Each uint256 stores 256 booleans, total capacity 2048 bits for storing last 2000 operations
    gameHistory1: Int as uint256; // Stores entries 0-255
    gameHistory2: Int as uint256; // Stores entries 256-511
    gameHistory3: Int as uint256; // Stores entries 512-767
    gameHistory4: Int as uint256; // Stores entries 768-1023
    gameHistory5: Int as uint256; // Stores entries 1024-1279
    gameHistory6: Int as uint256; // Stores entries 1280-1535
    gameHistory7: Int as uint256; // Stores entries 1536-1791
    gameHistory8: Int as uint256; // Stores entries 1792-2047
    currentHistoryLength: Int as uint16; // Current position in circular buffer (0-1999)

    init() {
        self.owner = sender();
        self.tokenMinted = false;
        self.deployTime = now();
        self.gameStarted = now();
        self.airdropDuration = 8640000;
        self.streakState = 0;
        self.greenCount = 0;
        self.redCount = 0;
        // Remote config
        self.cpaReward = 5000000000;
        self.changeInterval = 43200;
        self.lastChanged = now();
        self.maxBet = 10000000000000;
        self.minBet = 1000000000;
        self.streakRatio = 50;
        self.greenPrice = ton("0.05");
        self.redPrice = ton("1");
        // Game History
        self.gameHistory1 = 0;
        self.gameHistory2 = 0;
        self.gameHistory3 = 0;
        self.gameHistory4 = 0;
        self.gameHistory5 = 0;
        self.gameHistory6 = 0;
        self.gameHistory7 = 0;
        self.gameHistory8 = 0;
        self.currentHistoryLength = 0;
    }

    receive() {
        cashback(sender());
    }

 fun addToHistory(value: Bool) {
    // Shift all segments left by 1 bit
    self.gameHistory1 = (self.gameHistory1 << 1) | ((self.gameHistory2 >> 255) & 1);
    self.gameHistory2 = (self.gameHistory2 << 1) | ((self.gameHistory3 >> 255) & 1);
    self.gameHistory3 = (self.gameHistory3 << 1) | ((self.gameHistory4 >> 255) & 1);
    self.gameHistory4 = (self.gameHistory4 << 1) | ((self.gameHistory5 >> 255) & 1);
    self.gameHistory5 = (self.gameHistory5 << 1) | ((self.gameHistory6 >> 255) & 1);
    self.gameHistory6 = (self.gameHistory6 << 1) | ((self.gameHistory7 >> 255) & 1);
    self.gameHistory7 = (self.gameHistory7 << 1) | ((self.gameHistory8 >> 255) & 1);
    self.gameHistory8 <<= 1;

    // Set the rightmost bit based on value
    if (value) {
        self.gameHistory1 |= 1;  // set to 1
    } else {
        self.gameHistory1 &= ~1; // set to 0
    }

    self.currentHistoryLength = min(self.currentHistoryLength + 1, 2048);
}


    get fun playerAddress(address: Address): Address {
        let playerContract = initOf PlayerContract(myAddress(), address);
        return contractAddress(playerContract);
    }

    get fun jettonAddress(address: Address): Address {
        let walletContract = initOf JettonWallet(address, self.tokenAddress!!, 0);
        return contractAddress(walletContract);
    }

    get fun contractState(): GameState {
        return GameState {
            owner: self.owner,
            tokenAddress: self.tokenAddress,
            walletAddress: self.walletAddress,
            deployTime: self.deployTime,
            gameStarted: self.gameStarted,
            airdropDuration: self.airdropDuration,
            streakState: self.streakState,
            greenCount: self.greenCount,
            redCount: self.redCount,
            cpaReward: self.cpaReward,
            changeInterval: self.changeInterval,
            lastChanged: self.lastChanged,
            maxBet: self.maxBet,
            minBet: self.minBet,
            streakRatio: self.streakRatio,
            greenPrice: self.greenPrice,
            redPrice: self.redPrice,
            gameHistory1: self.gameHistory1,
            gameHistory2: self.gameHistory2,
            gameHistory3: self.gameHistory3,
            gameHistory4: self.gameHistory4,
            gameHistory5: self.gameHistory5,
            gameHistory6: self.gameHistory6,
            gameHistory7: self.gameHistory7,
            gameHistory8: self.gameHistory8,
            currentHistoryLength: self.currentHistoryLength,
            createAt: now(),
        };
    }

    receive("increaseChangeInterval") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        //TODO check interval value
        self.changeInterval += 3600;
        self.lastChanged = now();
    }

    receive("decreaseChangeInterval") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.changeInterval > 7200, "Min reached");
        //TODO check interval value
        self.changeInterval -= 3600;
        self.lastChanged = now();
    }

    receive("increaseMaxBet") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        self.maxBet += 1000000000;
        self.lastChanged = now();
    }

    receive("decreaseMaxBet") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        self.maxBet -= 1000000000;
        self.lastChanged = now();
    }

    receive("increaseMinBet") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.maxBet - self.minBet > 1000000000, "Max reached");
        self.minBet += 1000000000;
        self.lastChanged = now();
    }

    receive("decreaseMinBet") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.minBet > 1000000000, "Min reached");
        self.minBet -= 1000000000;
        self.lastChanged = now();
    }

    receive("increaseStreakRatio") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.streakRatio < 100, "Max reached");
        self.streakRatio += 1;
        self.lastChanged = now();
    }

    receive("decreaseStreakRatio") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.streakRatio > 10, "Min reached");
        self.streakRatio -= 1;
        self.lastChanged = now();
    }

    receive("increaseGreenPrice") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.greenPrice < ton("0.1"), "Max reached");
        self.greenPrice += ton("0.01");
        self.lastChanged = now();
    }

    receive("decreaseGreenPrice") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.greenPrice > ton("0.009"), "Min reached");
        self.greenPrice -= ton("0.01");
        self.lastChanged = now();
    }

    receive("increaseRedPrice") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.redPrice < ton("0.1"), "Max reached");
        self.redPrice += ton("0.01");
        self.lastChanged = now();
    }

    receive("decreaseRedPrice") {
        self.requireOwner();
        require(now() - self.lastChanged > self.changeInterval, "Not allowed yet, try later");
        require(self.redPrice > ton("0.009"), "Min reached");
        self.redPrice -= ton("0.01");
        self.lastChanged = now();
    }

    fun useBalance(): Bool {
        return now() - self.deployTime >= self.airdropDuration;
    }

    fun redPrice(): Int {
        //TODO implement red price calc
        return self.redPrice;
    }

    receive(msg: W2GStartGame) {
        let ctx: Context = context();
        require(ctx.value >= self.greenPrice, "Insufficient TON amount");
        let bet = 1000000000;
        if (self.useBalance()) {
            require(msg.bet >= self.minBet, "Min reached");
            require(msg.bet <= self.maxBet, "Max reached");
            bet = msg.bet;
        }
        self.addToHistory(true);
        let referrer = self.owner;
        if (msg.referrer != null) {
            referrer = msg.referrer!!;
        }
        self.streakState += 1;
        self.greenCount += 1;
        let playerContract = initOf PlayerContract(myAddress(), sender());
        let startPlayerMessage = G2PStartPlayer {
            bet,
            useBalance: self.useBalance(),
            player: ctx.sender,
            referrer,
            streakState: self.streakState,
            greenCount: self.greenCount,
            redCount: self.redCount,
        };
        let params = DeployParameters {
            init: playerContract,
            value: 0,
            mode: SendRemainingValue,
            body: startPlayerMessage.toCell(),
        };
        deploy(params);
    }

    receive(msg: W2GStopGame) {
        let playerContract = initOf PlayerContract(myAddress(), sender());
        let playerAddress = contractAddress(playerContract);
        let stopPlayerMessage = G2PStopPlayer {
            player: sender(),
            streakState: self.streakState,
            greenCount: self.greenCount,
            redCount: self.redCount,
        };
        let params = SendParameters {
            to: playerAddress,
            value: 0,
            mode: SendRemainingValue,
            body: stopPlayerMessage.toCell(),
        };
        send(params);
    }

    receive(msg: W2GRedGame) {
        let ctx: Context = context();
        require(ctx.value >= self.redPrice, "Insufficient TON amount");
        self.addToHistory(false);
        let playerContract = initOf PlayerContract(myAddress(), sender());
        let playerAddress = contractAddress(playerContract);
        let redPlayerMessage = G2PRedPlayer {
            player: ctx.sender,
            referrer: msg.referrer,
            price: self.redPrice(),
            greenCount: self.greenCount,
            redCount: self.redCount,
            streakState: self.streakState,
        };
        let params = SendParameters {
            to: playerAddress,
            value: 0,
            mode: SendRemainingValue,
            body: redPlayerMessage.toCell(),
        };
        self.redCount += 1;
        self.streakState = 0;
        send(params);
    }

    receive(msg: JettonNotification) {
        require(sender() == self.walletAddress, "Incorrect Jetton Sender");
        let playerInit = initOf PlayerContract(myAddress(), msg.sender);
        let playerAddress = contractAddress(playerInit);
        let depositMessageBody = G2PTokenDeposit {
            amount: msg.amount,
            sender: msg.sender,
        };
        let params = SendParameters {
            to: playerAddress,
            value: 0,
            mode: SendRemainingValue,
            body: depositMessageBody.toCell(),
        };
        send(params);
    }

    receive(msg: JettonExcesses) {}

    receive(msg: W2GTokenWithdraw) {
        let playerInit = initOf PlayerContract(myAddress(), sender());
        let playerAddress = contractAddress(playerInit);
        let withdrawMessageBody = G2PTokenWithdraw {
            amount: msg.amount,
            player: sender(),
        };
        let params = SendParameters {
            to: playerAddress,
            value: 0,
            mode: SendRemainingValue,
            body: withdrawMessageBody.toCell(),
        };
        send(params);
    }

    receive(msg: P2GTokenWithdraw) {
        let playerInit = initOf PlayerContract(myAddress(), msg.destination);

        require(playerInit.hasSameBasechainAddress(sender()), "Incorrect sender2");

        let messageBody = JettonTransfer {
            queryId: 0,
            amount: msg.amount,
            destination: msg.destination,
            responseDestination: msg.destination,
            forwardTonAmount: 0,
            forwardPayload: "Sent!".asSlice(),
        };

        let params = MessageParameters {
            to: self.walletAddress!!,
            value: 0,
            mode: SendRemainingValue,
            body: messageBody.toCell(),
        };

        message(params);
    }

    receive("claimTON") {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);
        message(MessageParameters {
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
        });
    }

    receive("initialMint") {
        self.requireOwner();
        require(self.tokenMinted == false, "Token minted");
        self.tokenMinted = true;

        let jettonMetadata = composeJettonMetadata(
            "DEVSSSSS Test Token",
            "DEVSSSS Test Token description",
            "DEVSSSS",
            "https://streakslanding.pages.dev/icons/Icon-256-dev.png",
        );

        let minterContract: StateInit = initOf JettonMinter(4000000000000000001, myAddress(), jettonMetadata, true);
        let tokenAddr: Address = contractAddress(minterContract);
        self.tokenAddress = tokenAddr;

        let walletContract = initOf JettonWallet(myAddress(), tokenAddr, 0);
        self.walletAddress = contractAddress(walletContract);

        let mintMessage = JettonTransferInternal {
            queryId: 0,
            amount: 4000000000000000000,
            sender: myAddress(),
            responseDestination: myAddress(),
            forwardTonAmount: 0,
            forwardPayload: "Minted!".asSlice(),
        };

        let params = SendParameters {
            to: tokenAddr,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            code: minterContract.code,
            data: minterContract.data,
            body: Mint { queryId: 0, receiver: myAddress(), tonAmount: 0, mintMessage }.toCell(),
        };

        send(params);
    }
}
