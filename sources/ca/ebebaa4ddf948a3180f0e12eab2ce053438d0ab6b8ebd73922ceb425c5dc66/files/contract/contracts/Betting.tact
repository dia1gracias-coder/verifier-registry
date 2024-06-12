import "@stdlib/ownable";
import "@stdlib/deploy";
import "./Messages";

struct NewRound {
    minBetAmount: Int as coins;
    startTimestamp: Int as uint64;
    lockTimestamp: Int as uint64;
}

struct Round {
    id: Int as uint256;
    token: Address;
    tokenWallet: Address;
    minBetAmount: Int as coins;
    rewardBaseCalAmount: Int as coins;
    rewardAmount: Int as coins;
    result: Int as uint8;
    startTimestamp: Int as uint64;
    lockTimestamp: Int as uint64;
    closeTimestamp: Int as uint64;
    owner: Address;
}

struct RoundTotal {
    totalAmount: Int as coins;
    aAmount: Int as coins;
    bAmount: Int as coins;
}

struct RoundFee {
    platformFeeAmount: Int as coins;
    bankerFeeAmount: Int as coins;
    isBonus: Bool;
}

struct BetPayload {
    id: Int as uint256;
    result: Int as uint8;
}

struct BetInfo {
    result: Int as uint8;
    amount: Int as coins;
    claimed: Bool;
}

message SetTokenWallet {
    token: Address;
    tokenWallet: Address?;
}

message SetRound {
    id: Int as uint256;
    result: Int as uint8;
    forward_ton_amount: Int as coins;
}

message SetFee {
    platformFee: Int;
    platformBonusFee: Int;
    bankerFee: Int;
    bankerBonusFee: Int;    
    platformFeeAddress: Address;
    platformFeeBonusAddress: Address;
}

message Claim {
    id: Int as uint256;
    reward: Int as coins;
}

contract Betting with Deployable {
    const Result_None: Int = 0;
    const Result_A: Int = 1;
    const Result_B: Int = 2;
    const Result_Draw: Int = 3;
    const Result_Cancle: Int = 4;

    const Transfer_OP_Bet: Int = 1;
    const Transfer_OP_NewRound: Int = 2;

    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");

    owner: Address;
    platformFee: Int; // platform fee rate (e.g. 200 = 2%, 150 = 1.50%)
    bankerFee: Int; // banker fee rate (e.g. 200 = 2%, 150 = 1.50%)
    platformBonusFee: Int; // platform bonus fee rate (e.g. 200 = 2%, 150 = 1.50%) 
    bankerBonusFee: Int; // banker bonus fee rate (e.g. 200 = 2%, 150 = 1.50%)

    platformFeeAddress: Address;
    platformFeeBonusAddress: Address;

    publicPrice: Int; // price of public bet

    currentRound: Int as uint256;
    rounds: map<Int, Round>;
    roundFees: map<Int, RoundFee>;
    roundTotals: map<Int, RoundTotal>;
    betInfos: map<Int, BetInfo>;
    tokenMapWallet: map<Address, Address>;
    walletMapToken: map<Address, Address>;

    init(
        platformFee: Int,  
        platformBonusFee: Int,   
        platformFeeAddress: Address, 
        platformFeeBonusAddress: Address, 
        bankerFee: Int, 
        bankerBonusFee: Int,
        publicPrice: Int, 
        sqno: Int
    ) {
        self.owner = sender();
        self.platformFee = platformFee;
        self.platformFeeAddress = platformFeeAddress;
        self.bankerFee = bankerFee;
        self.publicPrice = publicPrice;
        self.currentRound = 0;
        self.platformBonusFee = platformBonusFee;
        self.bankerBonusFee = bankerBonusFee;
        self.platformFeeBonusAddress = platformFeeBonusAddress;
    }

    receive(msg: SetTokenWallet) {
        require(self.owner == sender(), "Only owner!");
        if(msg.tokenWallet == null) {
            self.tokenMapWallet.del(msg.token);
            self.walletMapToken.del(msg.token);
            return;
        }
        self.tokenMapWallet.set(msg.token, msg.tokenWallet!!);
        self.walletMapToken.set(msg.tokenWallet!!, msg.token); 
    }

    receive(msg: SetFee) {
        require(self.owner == sender(), "Only owner!");
        self.platformFee = msg.platformFee;
        self.bankerFee = msg.bankerFee;
        self.platformFeeAddress = msg.platformFeeAddress;
        self.platformBonusFee = msg.platformBonusFee;
        self.bankerBonusFee = msg.bankerBonusFee;
        self.platformFeeBonusAddress = msg.platformFeeBonusAddress;
    }

    receive(msg: TokenNotification) {
        if(msg.forward_payload.empty()) {
             return;
        }
        let token: Address? = self.walletMapToken.get(sender());
        require(token != null, "Invalid token!");

        let op: Int = msg.forward_payload.loadUint(8);
        if(op == self.Transfer_OP_Bet) {
            let id: Int = msg.forward_payload.loadUint(256);
            let result: Int = msg.forward_payload.loadUint(8);
            self.bet(id, result, msg.amount, msg.from);
        } else if(op == self.Transfer_OP_NewRound) {
            require(msg.amount >= self.publicPrice, "NewRound amount error!");
            let tokenWallet: Address? = self.tokenMapWallet.get(token!!);
            let msgNewRound: NewRound = NewRound{
                minBetAmount: msg.forward_payload.loadCoins(),
                startTimestamp: msg.forward_payload.loadUint(64),
                lockTimestamp: msg.forward_payload.loadUint(64)
            };
            self.newRound(token!!, tokenWallet!!, msg.from, msgNewRound);
        }
    }

    receive(msg : SetRound) {
        require(self.owner == sender(), "Only owner!");
        let round: Round = self.rounds.get(msg.id)!!;
        require(round.closeTimestamp == 0, "Round already set");
        let result: Int = msg.result;

        require(round.rewardBaseCalAmount == 0 && round.rewardAmount == 0, "Rewards calculated");
        let rewardBaseCalAmount: Int = 0;
        let rewardAmount: Int = 0;
        let platformFee: Int = 0;
        let platformFeeAddress: Address = self.platformFeeAddress;
        let bankerFee: Int = 0;
        let isBonus: Bool = false;
        let roundTotal: RoundTotal = self.roundTotals.get(round.id)!!;
        round.result = result;

        // A wins
        if (round.result == self.Result_A) {
            rewardBaseCalAmount = roundTotal.aAmount;
            if(roundTotal.aAmount > roundTotal.bAmount 
                && (roundTotal.aAmount > (roundTotal.bAmount + (roundTotal.bAmount * 5 / 100)))) {
                isBonus = true;
            }
        }
        // B wins
        else if (round.result == self.Result_B) {
            rewardBaseCalAmount = roundTotal.bAmount;
            if(roundTotal.bAmount > roundTotal.aAmount 
                && (roundTotal.bAmount > (roundTotal.aAmount + (roundTotal.aAmount * 5 / 100)))) {
                isBonus = true;
            }
        }
        // Draw wins
        else if (round.result == self.Result_Draw) {
            rewardBaseCalAmount = roundTotal.totalAmount;
        }
        // Cancle
        else if (round.result == self.Result_Cancle) {
            rewardBaseCalAmount = roundTotal.totalAmount;
        }  else {
            require(false, "Invalid result!");
        }

        if (round.result != self.Result_Cancle) {
            if(!isBonus) {
                platformFee = roundTotal.totalAmount * self.platformFee / 10000;
                bankerFee = roundTotal.totalAmount * self.bankerFee / 10000;
            } else {
                platformFee = roundTotal.totalAmount * self.platformBonusFee / 10000;
                bankerFee = roundTotal.totalAmount * self.bankerBonusFee / 10000;
                platformFeeAddress = self.platformFeeBonusAddress;
            }
        }
        if(bankerFee > 0) {
            send(SendParameters{
                to: round.tokenWallet, 
                value: msg.forward_ton_amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: TokenTransfer {
                    query_id: 0,
                    amount: bankerFee,
                    destination: round.owner,
                    response_destination: null,
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            });
        }

        if(platformFee > 0) {
            send(SendParameters {
                to: round.tokenWallet, 
                value: 0,
                mode: SendRemainingValue, 
                bounce: true,
                body: TokenTransfer {
                    query_id: 1,
                    amount: platformFee,
                    destination: platformFeeAddress,
                    response_destination: null,
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            });
        }

        rewardAmount = roundTotal.totalAmount - platformFee - bankerFee;
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;
        
        dump(beginString().concat("platformFee: ").concat(platformFee.toString()).toString());
        dump(beginString().concat("bankerFee: ").concat(bankerFee.toString()).toString());

        self.roundFees.set(round.id, RoundFee {
            platformFeeAmount: platformFee,
            bankerFeeAmount: bankerFee,
            isBonus: isBonus
        });
        round.closeTimestamp = now();
        self.rounds.set(round.id, round);
    }

    receive(msg : Claim) {
        self.claim(msg.id, sender());
    }

    fun newRound(token: Address, tokenWallet: Address, owner: Address, msg: NewRound) {
        let id: Int = self.currentRound + 1;
        let round: Round = Round {
                id: id,
                token: token,
                minBetAmount: msg.minBetAmount,
                tokenWallet: tokenWallet,
                startTimestamp: msg.startTimestamp,
                lockTimestamp: msg.lockTimestamp,
                closeTimestamp: 0,
                rewardBaseCalAmount: 0,
                rewardAmount: 0,
                result: 0,
                owner: owner,
        };
        self.rounds.set(id, round);
        self.currentRound = id;
    }

    fun bet(id: Int, result: Int, amount: Int, from: Address) {
        require(self.rounds.get(id) != null, "Invalid round!");
        let round: Round = self.rounds.get(id)!!;
        require(amount >= round.minBetAmount, "Bet amount error!");
        require(round.startTimestamp < now() && round.lockTimestamp > now(), "Round not bettable");
        
        require(result == self.Result_A || result == self.Result_B, "Invalid result!");
        require(round.tokenWallet == sender(), "Invalid sender!");

        let betInfoId: Int = self.betInfoId(id, from);
        let betInfo: BetInfo? = self.betInfos.get(betInfoId);
        require(betInfo == null || betInfo!!.amount == 0, "Can only bet once per round");

        let roundTotal: RoundTotal? = self.roundTotals.get(id);
        if(roundTotal == null) {
            roundTotal = RoundTotal{
                totalAmount: 0,
                aAmount: 0,
                bAmount: 0
            };
        }
        let newRoundTotal: RoundTotal= RoundTotal{
                totalAmount: 0,
                aAmount: 0,
                bAmount: 0
        };
        newRoundTotal.totalAmount = roundTotal!!.totalAmount + amount;
        if(result == self.Result_A) {
            newRoundTotal.aAmount += amount;
        } else {
            newRoundTotal.bAmount += amount;
        }
        self.roundTotals.set(id, newRoundTotal);
        self.betInfos.set(betInfoId, BetInfo{amount: amount, result: result, claimed: false});
    }

    fun claim(id: Int, user: Address) {
        let round: Round = self.rounds.get(id)!!;
        require(now() > round.startTimestamp, "Round has not started");
        require(round.closeTimestamp != 0, "Round has not ended");
        require(self.betInfos.get(self.betInfoId(id, user)) != null, "Not eligible for claim");
        let betinfo: BetInfo = self.betInfos.get(self.betInfoId(id, user))!!;
        require(betinfo.amount > 0, "Not eligible for claim");
        require(!betinfo.claimed, "Already claimed");

        let reward: Int = 0;
        // Round valid, claim rewards
        if (round.result != self.Result_Cancle) {
            reward = (betinfo.amount * round.rewardAmount) / round.rewardBaseCalAmount;
        }
        // Round invalid, refund bet amount
        else {
            require(self.refundable(id, user), "Not eligible for refund");
            reward = betinfo.amount;
        }
        betinfo.claimed = true;
        self.betInfos.set(self.betInfoId(id, user), betinfo);

        if (reward > 0) {
            send(SendParameters{
                    to: round.tokenWallet, 
                    value: 0,
                    mode: SendRemainingValue, 
                    body: TokenTransfer {
                    query_id: 0,
                    amount: reward,
                    destination: user,
                    response_destination: null,
                    custom_payload: null,
                    forward_ton_amount: 0,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            });
        }
    }

    fun refundable(id: Int, user: Address): Bool {
        let betInfo: BetInfo? = self.betInfos.get(self.betInfoId(id, user));
        if(betInfo == null || betInfo!!.amount == 0) {
            return false;
        }
        return true;
    }

    fun betInfoId(id: Int, user: Address): Int {
        return beginCell().storeUint(id, 256).storeAddress(user).endCell().hash();
    }

    get fun current_round(): Int {
        return self.currentRound;
    }

    get fun current_time(): Int {
        return now();
    }

    get fun user_bet_info(id: Int, user: Address): BetInfo? {
        let betInfoId: Int = self.betInfoId(id, user);
        return self.betInfos.get(betInfoId);
    }

    get fun get_round(id: Int): Round? {
        return self.rounds.get(id);
    }

    get fun get_round_fee(id: Int): RoundFee? {
        return self.roundFees.get(id);
    }

    get fun get_round_total(id: Int): RoundTotal? {
        return self.roundTotals.get(id);
    }

    get fun get_public_price(): Int {
        return self.publicPrice;
    }
}