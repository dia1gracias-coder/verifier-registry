import "@stdlib/deploy";

@name(set_code)
native setCode(code: Cell);

@name(set_data)
native setData(d: Cell);

// Player info
struct PlayerInfo {
    telegramId: String;
}

// Rule of allocating the prize
struct RuleInfo {
    ranking: Int as uint8;
    prizesShare: String;
}

// Winner info
struct WinnerInfo {
    telegramId: String;
    walletAddress: Address?;
    ranking: Int as uint8;
    prizeWon: Int as coins;
    prizeSentStatus: Int as uint8;
}

// Match info
struct MatchInfo {
    matchId: Int as uint64;
    game: String;
    players: map<Int as uint8, PlayerInfo>;
    playerCount: Int as uint8;
    prizePool: String;
    commissionFee: String;
    rules: map<Int as uint8, RuleInfo>;
    ruleCount: Int as uint8;
}

// Winners of the match
struct MatchResult {
    winners: map<Int as uint8, WinnerInfo>;
    winnerCount: Int as uint8;
}

/**
 * Master action request
 * id:      unique id
 * action:
 *      0 => None
 *      1 => Withdraw (Toncoin)
 *      2 => Withdraw (USDT)
 * status:
 *      0 => Waiting for voting
 *      1 => Accepted
 *      2 => Timeout
 * weight:  Current or final weight
 * amount:  amount of nanoton
 * address: Address of target wallet
*/
struct MasterActionRequest {
    id: Int;
    action: Int as uint8;
    timeout: Int as uint32;
    status: Int as uint8;
    weight: Int as uint32;
    amount: Int;
    address: Address;
    voters: map<Address, Bool>;
}

// Message for submit a master action request
message MasterActionRequestMsg {
    seqno: Int as uint32;
    request: MasterActionRequest;
}

// Message for vote
message VoteMsg {
    seqno: Int as uint32;
    requestId: Int;
    queryIdPrefix: Int as uint64;
}

// Message for recording match info
message CreateMatchMsg {
    seqno: Int as uint32;
    matchInfo: MatchInfo;
}

struct RecipientInfo {
    telegramId: String;
    winnerIndex: Int as uint8;
    sendMode: Int as uint8;
    walletAddress: Address?;
    txCommentCell: Cell?;
}

// Message for sending prize
message SendPrizeMsg {
    seqno: Int as uint32;
    matchId: Int as uint64;
    recipients: map<Int as uint8, RecipientInfo>;

    matchResult: MatchResult?;
}

// Message for removing match dump
message RemoveMatchDumpMsg {
    seqno: Int as uint32;
    matchIds: map<Int, Int as uint64>;
}

// Message for removing all match dump
message RemoveAllMatchDumpMsg {
    seqno: Int as uint32;
}

// Message for setting mininum balance
message MinBalanceMsg {
    seqno: Int as uint32;
    value: Int as coins;
}

message SetUSDTJettonWalletAddressMsg {
    seqno: Int as uint32;
    value: Address;
}

message SetGasValueForJettonTransferMsg {
    seqno: Int as uint32;
    value: Int as coins;
}

message Upgrade {
    seqno: Int as uint32;
    newCode: Cell;
    newData: Cell?;
}

message UpgradeCode {
    seqno: Int as uint32;
    newCode: Cell;
}

message UpgradeData {
    seqno: Int as uint32;
    newData: Cell;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0xd53276db) Excesses {
    queryId: Int as uint64;
}

extends fun toInt(self: String): Int {
    let string: Slice = self.asSlice();

    let acc: Int = 0;

    while (!string.empty()) {
        let char: Int = string.loadUint(8);
        acc = (acc * 10) + (char - 48);
    }

    return acc;
}

contract MiniTonToncoinMatchContract with Deployable {
    // Values of WinnerInfo.prizeSentStatus
    const pssNotSendPrizeYet: Int = 0;
    const pssOnChainPrizeSent: Int = 1;
    const pssOffChainPrizeSent: Int = 2;
    const pssFraudPlayer: Int = 3;
    const pssOtherReasonNotSendPrizeYet: Int = 4;

    // Values of RecipientInfo.sendMode
    const smOffChain: Int = 0;
    const smOnChain: Int = 1;

    owner: Address;
    voters: map<Address, Bool>;
    voterCount: Int;
    requiredWeight: Int;
    masterActionRequests: map<Int, MasterActionRequest>;
    masterActionRequestCount: Int;
    currentSeqno: Int as uint32;
    matches: map<Int, MatchInfo>;
    matchCount: Int;
    matchResults: map<Int, MatchResult>;
    matchResultCount: Int;
    minBalance: Int as coins;
    myUSDTJettonWalletAddress: Address;
    isMyUSDTJettonWalletAddressValid: Bool;
    gasValueForJettonTransfer: Int as coins;
    contractIndex: Int;

    init(owner: Address, contractIndex: Int, requiredWeight: Int, voters: map<Address, Bool>) {
        self.owner = owner;
        self.contractIndex = contractIndex;
        self.minBalance = ton("0.05"); // default mininum = 0.05
        self.currentSeqno = 0;
        // newAddress(0, 0) will throw exception 'Error: Invalid address hash length: 0' in @ton/core 0.56.3
        // so be it
        self.myUSDTJettonWalletAddress = newAddress(0, 0x1234567812345678123456781234567812345678123456781234567812345678);
        self.isMyUSDTJettonWalletAddressValid = false;

        self.voters = emptyMap();
        self.voterCount = 0;
        foreach(key, value in voters) {
            self.voters.set(key, value);
            self.voterCount += 1;
        }
        if (requiredWeight > self.voterCount) {
            requiredWeight = self.voterCount;
        }
        self.requiredWeight = requiredWeight;

        self.masterActionRequests = emptyMap();
        self.masterActionRequestCount = 0;

        self.matches = emptyMap();
        self.matchCount = 0;
        self.matchResults = emptyMap();
        self.matchResultCount = 0;

        self.gasValueForJettonTransfer = ton("0.1");
    }

    receive() {
    }

    receive(comment: String) {

    }

    receive(msg: Excesses) {
    }
    
    // Record match info
    receive(msg: CreateMatchMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        let exist: Bool = self.matches.get(msg.matchInfo.matchId) != null;
        self.matches.set(msg.matchInfo.matchId, msg.matchInfo);
        if (exist == false) {
            self.matchCount += 1;
        }

        self.incSeqno();
        self.reply("".asComment());
    }

    fun incSeqno() {
        if (self.currentSeqno >= 1000000000) {
            self.currentSeqno = 0;
        }
        self.currentSeqno += 1;
    }

    get fun seqno(): Int {
        return self.currentSeqno;
    }
    
    receive(msg: MasterActionRequestMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");
        require(self.masterActionRequests.get(msg.request.id) == null, "This id is already exists");

        msg.request.status = 0;
        msg.request.weight = 0;
        msg.request.voters = emptyMap();
        self.masterActionRequests.set(msg.request.id, msg.request);
        self.masterActionRequestCount += 1;

        let sbuilder = beginString();
        sbuilder.append("Withdraw Request(");
        sbuilder.append(msg.request.id.toString());
        sbuilder.append("): ");
        sbuilder.append(msg.request.amount.toCoinsString());
        sbuilder.append(" -> ");
        sbuilder.append(msg.request.address.toString());
        emit(sbuilder.toString().asComment());

        self.incSeqno();
        self.reply("".asComment());
    }

    receive(msg: VoteMsg) {
        require(self.voters.get(sender()) == true, "Only voter can call this function");
        require(self.masterActionRequests.get(msg.requestId) != null, "Can not found this request");

        let request = self.masterActionRequests.get(msg.requestId)!!;
        if (request.action >= 1 && request.action <= 2 && request.status == 0 && request.amount > 0) {
            if (request.timeout > now()) {
                let sender = sender();
                if (request.voters.get(sender) != true) {
                    request.voters.set(sender, true);
                    request.weight += 1;
                }

                if (request.weight >= self.requiredWeight) {
                    let bodyMsg = beginString();
                    bodyMsg.append("Withdaw Quest Id: ");
                    bodyMsg.append(request.id.toString());
                    let sbuilder = beginString();

                    if (request.action == 1) {  // withdraw toncoin
                        require(myBalance() - self.minBalance > request.amount, "Balance is not enough");

                        send(SendParameters{
                            to: request.address,
                            bounce: true,
                            value: request.amount, 
                            mode: SendPayGasSeparately | SendIgnoreErrors,
                            body: bodyMsg.toCell()
                        });

                        sbuilder.append("Execute Withdraw (");
                    } else if (request.action == 2) { // withdraw usdt
                        let queryIdString = beginString();
                        queryIdString.append(msg.queryIdPrefix.toString());
                        queryIdString.append(3.toString()); //prefix of withdraw usdt
                        queryIdString.append(request.id.toString());
                        self.sendUSDT(request.address, request.amount, queryIdString.toString().toInt(), bodyMsg.toString());

                        sbuilder.append("Execute Withdraw USDT (");
                    }

                    sbuilder.append(request.id.toString());
                    sbuilder.append("): ");
                    sbuilder.append(request.amount.toCoinsString());
                    sbuilder.append(" -> ");
                    sbuilder.append(request.address.toString());
                    emit(sbuilder.toString().asComment());

                    request.status = 1;
                }
            }
            else { // timeout
                request.status = 2;
            }

            self.masterActionRequests.set(request.id, request);
        }

        self.reply("".asComment());
    }

    get fun masterRequest(id: Int): MasterActionRequest? {
        return self.masterActionRequests.get(id);
    }

    get fun masterActionRequestCount(): Int {
        return self.masterActionRequestCount;
    }

    fun sendUSDT(target: Address, amount: Int, queryId: Int, comment: String) {
        require(self.isMyUSDTJettonWalletAddressValid, "myUSDTJettonWalletAddress is not be set");

        let commentCell = comment.asComment();

        send(SendParameters{
            to: self.myUSDTJettonWalletAddress,
            bounce: false,
            value: self.gasValueForJettonTransfer,
            mode: SendIgnoreErrors,
            body: TokenTransfer{
                queryId: queryId,
                amount: amount,
                destination: target,
                response_destination: myAddress(),
                custom_payload: null,
                forward_ton_amount: 1,
                forward_payload: beginCell().storeBool(true).storeRef(commentCell).endCell().asSlice()
            }.toCell()
        });
    }

    receive(msg: SetUSDTJettonWalletAddressMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        self.myUSDTJettonWalletAddress = msg.value;
        self.isMyUSDTJettonWalletAddressValid = true;

        let comment = beginString();
        comment.append("Set USDTJettonWalletAddress => ");
        comment.append(self.myUSDTJettonWalletAddress.toString());
        emit(comment.toString().asComment());

        self.incSeqno();
        self.reply("".asComment());
    }

    get fun usdtJettonWalletAddress(): Address {
        return self.myUSDTJettonWalletAddress;
    }

    receive(msg: SetGasValueForJettonTransferMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        self.gasValueForJettonTransfer = msg.value;

        let comment = beginString();
        comment.append("Set gasValueForJettonTransfer => ");
        comment.append(self.gasValueForJettonTransfer.toString());
        emit(comment.toString().asComment());

        self.incSeqno();
        self.reply("".asComment());
    }

    get fun gasValueForJettonTransfer(): Int {
        return self.gasValueForJettonTransfer;
    }

    receive(msg: SendPrizeMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        let modified = false;
        let t_matchResult = self.matchResults.get(msg.matchId);
        let exist: Bool = t_matchResult != null;
        if (t_matchResult == null) {
            require(self.matches.get(msg.matchId) != null, "This match was not found");
            require(msg.matchResult != null, "This match has not submitted a result yet.");
            t_matchResult = msg.matchResult!!;
            modified = true;
        }
        let matchResult = t_matchResult!!;

        foreach (key, recipient in msg.recipients) {
            let t_winner = matchResult.winners.get(recipient.winnerIndex);
            if (t_winner != null) {
                let winner = t_winner!!;
                if (recipient.sendMode == self.smOffChain || recipient.sendMode == self.smOnChain) {
                    if (winner.prizeSentStatus == self.pssNotSendPrizeYet || winner.prizeSentStatus == self.pssOtherReasonNotSendPrizeYet) {
                        let sendFailed = false;
                        if (winner.prizeWon > 0 && recipient.walletAddress != null
                            && recipient.txCommentCell != null
                        ) {
                            if (myBalance() - winner.prizeWon >= self.minBalance) {
                                send(SendParameters{
                                    to: recipient.walletAddress!!,
                                    bounce: false,
                                    value: winner.prizeWon,
                                    mode: SendPayGasSeparately | SendIgnoreErrors,
                                    body: recipient.txCommentCell!!
                                    });
                                winner.walletAddress = recipient.walletAddress;
                            } else {
                                emit("[WARNING] Failed to send prize.".asComment());

                                sendFailed = true;
                            }
                        }

                        if (sendFailed) {
                            winner.prizeSentStatus = self.pssOtherReasonNotSendPrizeYet;
                        } else if (recipient.sendMode == self.smOffChain) {
                            winner.prizeSentStatus = self.pssOffChainPrizeSent;
                        } else if (recipient.sendMode == self.smOnChain) {
                            winner.prizeSentStatus = self.pssOnChainPrizeSent;
                        }

                        matchResult.winners.set(recipient.winnerIndex, winner);
                        modified = true;
                    }
                } else {
                    let s = beginString();
                    s.append("[ERROR] Unknown sendMode: ");
                    s.append(recipient.sendMode.toString());
                    emit(s.toString().asComment());

                    winner.prizeSentStatus = self.pssOtherReasonNotSendPrizeYet;
                    matchResult.winners.set(recipient.winnerIndex, winner);
                    modified = true;
                }
            } else {
                let s = beginString();
                s.append("[ERROR] Cannot find the winner: ");
                s.append(recipient.winnerIndex.toString());
                emit(s.toString().asComment());
            }
        }

        if (modified) {
            self.matchResults.set(msg.matchId, matchResult);
            if (!exist) {
                self.matchResultCount += 1;
            }
        }

        self.incSeqno();
        self.reply("".asComment());
    }

    receive(msg: RemoveMatchDumpMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        let ori = self.matchCount;
        foreach(key, value in msg.matchIds) {
            if (self.matches.del(value)) {
                self.matchCount -= 1;
            }
            if (self.matchResults.del(value)) {
                self.matchResultCount -= 1;
            }
        }

        let removedCount = ori - self.matchCount;
        let comment = beginString();
        comment.append("Removed ");
        comment.append(removedCount.toString());
        comment.append(" MatchDumps");
        emit(comment.toString().asComment());
        self.incSeqno();
        self.reply("".asComment());
    }

    receive(msg: RemoveAllMatchDumpMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        let count = self.matchCount;
        self.matches = emptyMap();
        self.matchCount = 0;
        self.matchResults = emptyMap();
        self.matchResultCount = 0;

        let comment = beginString();
        comment.append("Removed All ");
        comment.append(count.toString());
        comment.append(" MatchDumps");
        emit(comment.toString().asComment());

        self.incSeqno();
        self.reply("".asComment());
    }

    // set mininum balance
    receive(msg: MinBalanceMsg) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        self.minBalance = msg.value;

        let comment = beginString();
        comment.append("Set MinBalance to ");
        comment.append(self.minBalance.toCoinsString());
        emit(comment.toString().asComment());
        self.incSeqno();
        self.reply("".asComment());
    }

    receive(msg: Upgrade) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        setCode(msg.newCode);
        if (msg.newData != null) {
            setData(msg.newData!!);
        }

        self.incSeqno();
        self.reply("".asComment());
    }

    receive(msg: UpgradeCode) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        setCode(msg.newCode);

        self.incSeqno();
        self.reply("".asComment());
    }

    receive(msg: UpgradeData) {
        require(sender() == self.owner, "Only owner can call this function");
        require(msg.seqno == self.currentSeqno, "Invalid sequence number");

        setData(msg.newData);
        self.reply("".asComment());
    }

    get fun minBalance(): Int {
        return self.minBalance;
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun matchInfo(matchId: Int): MatchInfo? {
        return self.matches.get(matchId);
    }

    get fun matchCount(): Int {
        return self.matchCount;
    }

    get fun matchResult(matchId: Int): MatchResult? {
        return self.matchResults.get(matchId);
    }

    get fun matchResultCount(): Int {
        return self.matchResultCount;
    }

    get fun contractIndex(): Int {
        return self.contractIndex;
    }
}
