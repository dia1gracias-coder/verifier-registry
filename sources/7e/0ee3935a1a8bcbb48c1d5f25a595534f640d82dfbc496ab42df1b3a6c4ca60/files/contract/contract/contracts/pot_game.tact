import "./pot_storage";

message(0xf23ea34) Deploy {
    queryId: Int as uint64;
}

message(0xd53276db) JettonExcesses {
    query_id: Int as uint64;
}

message(0xf8a7ea5) JettonTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Cell?;
}

message(0x7362d09c) JettonTransferNotification {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forward_payload: Cell?;
}

message(0x595f07bc) JettonBurn {
    query_id: Int as uint64;
    amount: Int as coins;
    response_destination: Address;
    custom_payload: Cell?;
}

struct GameMetaData {
    id: Int as uint32;
    nonce: Int as uint32;
    creator: Address;
    creatorTelegramId: Int as uint64;
    tokenAddress: Address;
    description: String;
    imageLink: String;
    jettonWallet: Address;
    gnomeTreasury: Address;
}

struct GameParams {
    initialPrize: Int as coins;
    creatorAmount: Int as coins;
    burnAmount: Int as coins;
    timer: Int as uint32;
    ticketPriceStaticIncrease: Int as coins;
    ticketPricePercentIncrease: Int as uint8;
    lastPlayersWinnersCount: Int as uint8;
    randomWinnersCount: Int as uint8;
    lastPlayersPercent: Int as uint8;
    randomWinnersPercent: Int as uint8;
    referrerPercent: Int as uint8;
    creatorPercent: Int as uint8;
    burnPercent: Int as uint8;
    lastPlayersPrize: Int as coins;
    randomWinnersPrize: Int as coins;
    referrerPrize: Int as coins;
    gnomeCommission: Int as coins;
}

struct CurrentState {
    seqno: Int as uint32;
    balance: Int as coins;
    totalPrize: Int as coins;
    state: Int as uint8;
    ticketPrice: Int as coins;
    timerEnd: Int as uint32;
}

const WIN_RANDOM: Int = 0;
const WIN_LAST: Int = 1;

const GAME_PENDING_INIT_POT: Int = 0;
const GAME_ACTIVE: Int = 1;
const GAME_FINISHED: Int = 2;
const GAME_READY_TO_CLAIM: Int = 3;

const POT_STORAGE_RESERVE: Int = ton("0.02");
const POT_STORAGE_MESSAGE_VALUE: Int = ton("0.01");
const TRANSFER_JETTON_MESSAGE_VALUE: Int = ton("0.05");

contract PotGame {
    id: Int as uint32;
    nonce: Int as uint32;
    creator: Address;
    creatorTelegramId: Int as uint64;
    description: String;
    imageLink: String;
    tokenAddress: Address;
    jettonWallet: Address;
    seqno: Int as uint32 = 0;
    balance: Int as coins = 0;
    initialPrize: Int as coins;
    totalPrize: Int as coins = 0;
    creatorAmount: Int as coins = 0;
    burnAmount: Int as coins = 0;
    timer: Int as uint32;
    timerEnd: Int as uint32 = 0;
    ticketPrice: Int as coins;
    ticketPriceStaticIncrease: Int as coins;
    ticketPricePercentIncrease: Int as uint8;
    pubKey: Int as uint256;
    lastPlayersWinnersCount: Int as uint8;
    randomWinnersCount: Int as uint8;
    lastPlayersPercent: Int as uint8;
    randomWinnersPercent: Int as uint8;
    referrerPercent: Int as uint8;
    creatorPercent: Int as uint8;
    burnPercent: Int as uint8;

    gnomeTreasury: Address;
    gnomeCommission: Int as coins;

    randomWinners: map<Address, Int>;
    lastWinners: map<Address, Int>;
    referrers: map<Address, Int>;
    referrersCount: Int as uint32 = 0;

    lastPlayersPrize: Int as coins = 0;
    randomWinnersPrize: Int as coins = 0;
    referrerPrize: Int as coins = 0;

    state: Int as uint8;

    init(
        id: Int,
        nonce: Int,
        creator: Address,
        creatorTelegramId: Int,
        description: String,
        imageLink: String,
        tokenAddress: Address,
        pubKey: Int,
        timer: Int,
        initialPrize: Int,
        ticketPrice: Int,
        ticketPriceStaticIncrease: Int,
        ticketPricePercentIncrease: Int,
        lastPlayersWinnersCount: Int,
        randomWinnersCount: Int,
        lastPlayersPercent: Int,
        randomWinnersPercent: Int,
        referrerPercent: Int,
        creatorPercent: Int,
        burnPercent: Int,
        gnomeTreasury: Address,
        gnomeCommission: Int
    ) {
        self.id = id;
        self.nonce = nonce;
        self.creator = creator;
        self.creatorTelegramId = creatorTelegramId;
        self.description = description;
        self.imageLink = imageLink;
        self.timer = timer;
        self.initialPrize = initialPrize;
        self.ticketPrice = ticketPrice;
        self.ticketPriceStaticIncrease = ticketPriceStaticIncrease;
        self.ticketPricePercentIncrease = ticketPricePercentIncrease;
        self.tokenAddress = tokenAddress;
        self.jettonWallet = myAddress();
        self.lastPlayersWinnersCount = lastPlayersWinnersCount;
        self.randomWinnersCount = randomWinnersCount;
        self.lastPlayersPercent = lastPlayersPercent;
        self.randomWinnersPercent = randomWinnersPercent;
        self.referrerPercent = referrerPercent;
        self.creatorPercent = creatorPercent;
        self.burnPercent = burnPercent;
        self.state = GAME_PENDING_INIT_POT;
        self.pubKey = pubKey;
        self.gnomeTreasury = gnomeTreasury;
        self.gnomeCommission = gnomeCommission;
    }

    receive(deploy: Deploy) {
        //do nothing
    }

    receive(excesses: JettonExcesses) {
        //do nothing
    }

    receive(msg: JettonTransferNotification) {
        if(self.state == GAME_PENDING_INIT_POT && self.creator == msg.sender) {
            self.jettonWallet = context().sender;
        }
        require(context().sender == self.jettonWallet, "Wrong jetton");
        self.balance += msg.amount;

        if(self.state == GAME_PENDING_INIT_POT && self.balance >= self.initialPrize){
            self.state = GAME_ACTIVE;
            return;
        }

        if(self.state == GAME_ACTIVE) {
            if(self.seqno != 0 && now() > self.timerEnd) {
                self.state = GAME_FINISHED;
                self.transferJettons(msg.amount, msg.sender, "Time is up. Game finished.", 0);
                return;
            } else if(msg.amount < self.ticketPrice) {
                let sb: StringBuilder = beginString();
                sb.append("Not enough for ticket. Ticket price is ");
                sb.append(self.ticketPrice.toString());
                sb.append(".");
                self.transferJettons(msg.amount, msg.sender, sb.toString(), 0);
                return;
            } else if(!self.isValidSign(msg)) {
                self.transferJettons(msg.amount, msg.sender, "Invalid sign", 0);
                return;
            } else if(!self.isEnoughValueForPlay()) {
                let forward_ton_amount = context().value - gasConsumed() - getForwardFee(1, 288, false);
                self.transferTons(msg.sender, forward_ton_amount, "Not enough value for play");
                return;
            } else {
                self.storeTransaction(msg);
                self.updateTimer();
                self.updateTicketPrice();
            }
        } else if(self.state == GAME_FINISHED || self.state == GAME_READY_TO_CLAIM){
            self.transferJettons(msg.amount, msg.sender, "Game is already finished.", 0);
        }
    }

    receive("finish"){
        if(self.state == GAME_ACTIVE && now() > self.timerEnd){
            self.state = GAME_FINISHED;
            self.notify("Game finished".asComment());
        } else {
            self.notify("Game can't be finished yet".asComment());
        }
    }

    receive("award"){
        require(self.state == GAME_FINISHED || self.state == GAME_ACTIVE && now() > self.timerEnd && self.seqno > 0, "Game is still active");

        self.totalPrize = self.balance;

        if(self.lastPlayersWinnersCount > 0){
            self.lastPlayersPrize = self.totalPrize * self.lastPlayersPercent / 100 / self.lastPlayersWinnersCount;
            self.requestLastWinners();
        }
        if(self.randomWinnersCount > 0){
            self.randomWinnersPrize = self.totalPrize * self.randomWinnersPercent / 100 / self.randomWinnersCount;
            self.requestRandomWinners();
        }

        if(self.creatorPercent > 0){
            self.creatorAmount = self.totalPrize * self.creatorPercent / 100;
            self.transferJettons(self.creatorAmount, self.creator, "Creator's share", 0);
        }
        if(self.burnPercent > 0){
            self.burnAmount = self.totalPrize * self.burnPercent / 100;
            self.burn();
        }

        self.transferTons(self.gnomeTreasury, self.gnomeCommission * self.seqno, "Gnome commission");

        self.state = GAME_READY_TO_CLAIM;

        send(SendParameters {
            to: context().sender,
            value: 0,
            mode: SendRemainingValue,
            body: "Game is ready to claim".asComment()
        });
    }

    receive(msg: UserDate) {
        let stateInit: StateInit = initOf PotStorage(msg.storeId, myAddress());
        require(context().sender == contractAddress(stateInit), "Access forbidden");
        if(msg.winType == WIN_LAST){
            let wins: Int? = self.lastWinners.get(msg.userAddress);
            if(wins == null){
                self.lastWinners.set(msg.userAddress, 1);
            } else {
                let winNotNull: Int = self.lastWinners.get(msg.userAddress)!!;
                winNotNull += 1;
                self.lastWinners.set(msg.userAddress,  winNotNull);
            }
            self.storeReferrer(msg.refererAddress);
        } else if(msg.winType == WIN_RANDOM) {
            let wins: Int? = self.randomWinners.get(msg.userAddress);
            if(wins == null){
                self.randomWinners.set(msg.userAddress, 1);
            } else {
                let winNotNull: Int = self.randomWinners.get(msg.userAddress)!!;
                winNotNull += 1;
                self.randomWinners.set(msg.userAddress,  winNotNull);
            }
            self.storeReferrer(msg.refererAddress);
        }
    }

    receive("claim") {
        require(self.state == GAME_READY_TO_CLAIM, "Claim is not ready yet");

        let amount: Int = 0;

        amount += self.getWinCount(self.lastWinners) * self.lastPlayersPrize;
        amount += self.getWinCount(self.randomWinners) * self.randomWinnersPrize;
        amount += self.getWinCount(self.referrers) * self.referrerPrize;

        if(amount > 0) {
            self.transferJettons(amount, context().sender, "Pot prize", SendPayGasSeparately);
            self.lastWinners.del(context().sender);
            self.randomWinners.del(context().sender);
            self.referrers.del(context().sender);
        }
        self.notify("Prize is claimed".asComment());
    }

    fun isEnoughValueForPlay(): Bool {
        return context().value - gasConsumed() - getForwardFee(1, 288, false) - self.gnomeCommission > 0;
    }

    fun isValidSign(msg: JettonTransferNotification): Bool {
        let additionalData: Slice = msg.forward_payload!!.beginParse();
        let refererAddress:Address = additionalData.loadAddress();
        let telegramId: Int = additionalData.loadUint(64);
        let sign: Slice = additionalData.loadRef().asSlice();

        let hash: Int = beginCell()
            .storeUint(msg.query_id, 64)
            .storeCoins(msg.amount)
            .storeAddress(refererAddress)
            .storeAddress(msg.sender)
        .endCell().hash();

        return checkSignature(hash, sign, self.pubKey);
    }

    fun updateTimer(){
        self.timerEnd = now() + self.timer;
    }

    fun updateTicketPrice() {
        if(self.ticketPriceStaticIncrease != 0){
            self.ticketPrice += self.ticketPriceStaticIncrease;
        } else if(self.ticketPricePercentIncrease != 0){
            self.ticketPrice = self.ticketPrice * (100 + self.ticketPricePercentIncrease) / 100;
        }
    }

    fun transferJettons(amount: Int, destination: Address, text: String, mode: Int) {
        self.transferJettonsAndTons(amount, destination, text, mode, 0);
    }

    fun transferJettonsAndTons(amount: Int, destination: Address, text: String, mode: Int, forward_ton_amount: Int){
        require(self.balance >= amount, "Not enough jettons");

        let sb: StringBuilder = beginString();

        sb.append(text);

        let forwardPayload: Cell = beginCell()
        .storeUint(0, 32)
        .storeRef(sb.toCell())
        .endCell();

        let body = JettonTransfer{
            query_id: 0,
            amount: amount,
            destination: destination,
            response_destination: myAddress(),
            custom_payload: null,
            forward_ton_amount: forward_ton_amount,
            forward_payload: forwardPayload
        }.toCell();

        send(SendParameters{
            to: self.jettonWallet,
            value: TRANSFER_JETTON_MESSAGE_VALUE,
            mode: mode,
            body: body,
            bounce: false,
        });

        self.balance -= amount;
    }

    fun transferTons(to: Address, value: Int, body: String) {
        send(SendParameters{
            to: to,
            value: value,
            mode: 0,
            bounce: false,
            body: body.asComment()
        });
    }

    fun storeTransaction(msg: JettonTransferNotification) {
        let stateInit: StateInit = initOf PotStorage(self.seqno, myAddress());

        if (msg.forward_payload != null) {
            let additionalData: Slice = msg.forward_payload!!.beginParse();

            require(additionalData.bits() >= 267, "Invalid refererAddress");
            let refererAddress: Address = additionalData.loadAddress();

            require(additionalData.bits() >= 64, "Invalid telegramId");
            let telegramId: Int = additionalData.loadUint(64);

            require(additionalData.refs() > 0, "Invalid signature data");
            let sign: Slice = additionalData.loadRef().asSlice();

            let body = UserDate{
                storeId: self.seqno,
                userAddress: msg.sender,
                telegramId: telegramId,
                refererAddress: refererAddress,
            }.toCell();

            send(SendParameters{
                to: contractAddress(stateInit),
                value: POT_STORAGE_RESERVE,
                mode: SendPayGasSeparately,
                body: body,
                code: stateInit.code,
                data: stateInit.data,
                bounce: false,
            });

            self.seqno += 1;
        } else {
            require(false, "Missing forward payload");
        }
    }

    fun requestRandomWinners() {
        let winners: map<Int, Bool> = emptyMap();
        let count = 0;

        while (count < self.randomWinnersCount && count < self.seqno) {
            let seqno = random(0, self.seqno);
            if (!winners.exists(seqno)) {
                winners.set(seqno, true);
                self.sendMessageBySeqno(seqno, WIN_RANDOM);
                count += 1;
            }
        }
    }

    fun requestLastWinners() {
        let seqno: Int = self.seqno;
        while(seqno > self.seqno - self.lastPlayersWinnersCount){
            seqno -= 1;
            self.sendMessageBySeqno(seqno, WIN_LAST);
        }
    }

    fun burn() {
        let body = JettonBurn {
            query_id: 0,
            amount: self.burnAmount,
            response_destination: myAddress(),
            custom_payload: null,
        }.toCell();

        send(SendParameters{
            to: self.jettonWallet,
            value: ton("0.1"),
            body: body,
            bounce: false,
        });

        self.balance -= self.burnAmount;
    }

    fun sendMessageBySeqno(seqno: Int, winType: Int) {
        let stateInit: StateInit = initOf PotStorage(seqno, myAddress());
        send(SendParameters{
            to: contractAddress(stateInit),
            value: POT_STORAGE_MESSAGE_VALUE,
            body: UserDateRequest{
                    seqno: seqno,
                    winType: winType,
            }.toCell(),
            bounce: false
        });
    }

    fun storeReferrer(refererAddress: Address) {
        let wins: Int? = self.referrers.get(refererAddress);
        if(wins == null){
            self.referrers.set(refererAddress, 1);
        } else {
            let winNotNull: Int = self.referrers.get(refererAddress)!!;
            winNotNull += 1;
            self.referrers.set(refererAddress,  winNotNull);
        }
        self.referrersCount += 1;
        self.referrerPrize = self.balance * self.referrerPercent / 100 / self.referrersCount;
    }

    fun getWinCount(collection: map<Address, Int>): Int{
        let wins: Int? = collection.get(context().sender);
        if(wins == null){
            return 0;
        } else {
            let winNotNull: Int = collection.get(context().sender)!!;
            return winNotNull;
        }
    }

    get fun storeAddress(seqno: Int): Address {
        return contractAddress(initOf PotStorage(seqno, myAddress()));
    }

    get fun isWinner(address: Address): Int {
        let wins: Int? = self.lastWinners.get(context().sender);
        if(wins == null){
            return 0;
        } else {
            let winNotNull: Int = self.lastWinners.get(context().sender)!!;
            winNotNull += 1;
            return winNotNull;
        }
    }

    get fun creator(): Address {
        return self.creator;
    }

    get fun creatorTelegramId(): Int {
        return self.creatorTelegramId;
    }

    get fun tokenAddress(): Address {
        return self.tokenAddress;
    }

    get fun description(): String {
        return self.description;
    }

    get fun imageLink(): String {
        return self.imageLink;
    }

    get fun jettonWallet(): Address {
        return self.jettonWallet;
    }

    get fun gnomeTreasury(): Address {
        return self.gnomeTreasury;
    }

    get fun initialPrize(): Int {
        return self.initialPrize;
    }

    get fun totalPrize(): Int {
        return self.totalPrize;
    }

    get fun creatorAmount(): Int {
        return self.creatorAmount;
    }

    get fun burnAmount(): Int {
        return self.burnAmount;
    }

    get fun timer(): Int {
        return self.timer;
    }

    get fun ticketPriceStaticIncrease(): Int {
        return self.ticketPriceStaticIncrease;
    }

    get fun ticketPricePercentIncrease(): Int {
        return self.ticketPricePercentIncrease;
    }

    get fun lastPlayersWinnersCount(): Int {
        return self.lastPlayersWinnersCount;
    }

    get fun randomWinnersCount(): Int {
        return self.randomWinnersCount;
    }

    get fun lastPlayersPercent(): Int {
        return self.lastPlayersPercent;
    }

    get fun randomWinnersPercent(): Int {
        return self.randomWinnersPercent;
    }

    get fun referrerPercent(): Int {
        return self.referrerPercent;
    }

    get fun creatorPercent(): Int {
        return self.creatorPercent;
    }

    get fun burnPercent(): Int {
        return self.burnPercent;
    }

    get fun lastPlayersPrize(): Int {
        return self.lastPlayersPrize;
    }

    get fun randomWinnersPrize(): Int {
        return self.randomWinnersPrize;
    }

    get fun referrerPrize(): Int {
        return self.referrerPrize;
    }

    get fun gnomeCommission(): Int {
        return self.gnomeCommission;
    }

    get fun seqno(): Int {
        return self.seqno;
    }

    get fun balance(): Int {
        return self.balance;
    }

    get fun state(): Int {
        return self.state;
    }

    get fun ticketPrice(): Int {
        return self.ticketPrice;
    }

    get fun timerEnd(): Int {
        return self.timerEnd;
    }

    get fun pubKey(): Int {
        return self.pubKey;
    }

    get fun id(): Int {
        return self.id;
    }

    get fun nonce(): Int {
        return self.nonce;
    }

    get fun gameMetaData(): GameMetaData {
        return GameMetaData{
        id: self.id,
        nonce: self.nonce,
        creator: self.creator,
        creatorTelegramId: self.creatorTelegramId,
        tokenAddress: self.tokenAddress,
        description: self.description,
        imageLink: self.imageLink,
        jettonWallet: self.jettonWallet,
        gnomeTreasury: self.gnomeTreasury
        }
    }

    get fun gameParams(): GameParams {
        return GameParams{
        initialPrize: self.initialPrize,
        creatorAmount: self.creatorAmount,
        burnAmount: self.burnAmount,
        timer: self.timer,
        ticketPriceStaticIncrease: self.ticketPriceStaticIncrease,
        ticketPricePercentIncrease: self.ticketPricePercentIncrease,
        lastPlayersWinnersCount: self.lastPlayersWinnersCount,
        randomWinnersCount: self.randomWinnersCount,
        lastPlayersPercent: self.lastPlayersPercent,
        randomWinnersPercent: self.randomWinnersPercent,
        referrerPercent: self.referrerPercent,
        creatorPercent: self.creatorPercent,
        burnPercent: self.burnPercent,
        lastPlayersPrize: self.lastPlayersPrize,
        randomWinnersPrize: self.randomWinnersPrize,
        referrerPrize: self.referrerPrize,
        gnomeCommission: self.gnomeCommission
        }
    }

    get fun currentState(): CurrentState {
        return CurrentState{
        seqno: self.seqno,
        balance: self.balance,
        totalPrize: self.totalPrize,
        state: self.state,
        ticketPrice: self.ticketPrice,
        timerEnd: self.timerEnd
        };
    }
}
