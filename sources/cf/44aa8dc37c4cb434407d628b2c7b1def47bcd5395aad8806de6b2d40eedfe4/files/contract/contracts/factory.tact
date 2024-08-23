import "@stdlib/deploy";
import "./omniJetton";
import "./constants";

struct BondingCurveData {
    virtualTonReserve: Int;
    virtualTokenReserve: Int;
    complete: Bool;
    liquidityAdded: Bool;
    jettonCreator: Address;
    tokenDebt: Int;
    myJettonWalletAddress: Address;
}

struct ReferralData {
    owner: Address;
    referrer: Address;
    isInitializedByFactory: Bool;
    factory: Address;
}

struct OutputTokenAmountReturn {
    amountOut: Int;
    tax: Int;
    remainNativeAmount: Int;
}

struct OutputTonAmountReturn {
    amountOut: Int;
    tax: Int;
}

fun getOutputTokenAmount_(inputTonAmount: Int, virtualTonReserve: Int, virtualTokenReserve: Int) : OutputTokenAmountReturn {
    let tax: Int = inputTonAmount * BONDING_CURVE_FEE_BIPS / PRECISION;
    let amountBuy: Int = inputTonAmount - tax;
    let virtualTokenReserveAfter: Int = virtualTonReserve * virtualTokenReserve / (virtualTonReserve + amountBuy);

    if (virtualTokenReserveAfter * (virtualTonReserve + amountBuy) < virtualTonReserve * virtualTokenReserve) {
        virtualTokenReserveAfter += 1;
    }

    let amountOut: Int = 0;
    let remainNativeAmount: Int = 0;

    if (virtualTokenReserveAfter < VIRTUAL_TOKEN_RESERVE_WHEN_ADD_LIQUIDITY) {
        amountOut = virtualTokenReserve - VIRTUAL_TOKEN_RESERVE_WHEN_ADD_LIQUIDITY;
        let virtualTonReserveAfter: Int = virtualTonReserve * virtualTokenReserve / VIRTUAL_TOKEN_RESERVE_WHEN_ADD_LIQUIDITY;
        if (virtualTonReserveAfter * VIRTUAL_TOKEN_RESERVE_WHEN_ADD_LIQUIDITY < virtualTonReserve * virtualTokenReserve) {
            virtualTonReserveAfter += 1;
        }
        amountBuy = virtualTonReserveAfter - virtualTonReserve;
        tax = amountBuy * BONDING_CURVE_FEE_BIPS / (PRECISION - BONDING_CURVE_FEE_BIPS);
        remainNativeAmount = inputTonAmount - amountBuy - tax;
    } else {
        amountOut = virtualTokenReserve - virtualTokenReserveAfter;
    }
    return OutputTokenAmountReturn {
        amountOut,
        tax,
        remainNativeAmount
    };
}

fun getOutputTonAmount_(inputTokenAmount: Int, virtualTonReserve: Int, virtualTokenReserve: Int) : OutputTonAmountReturn {
    let virtualTonReserveAfter: Int = virtualTonReserve * virtualTokenReserve / (virtualTokenReserve + inputTokenAmount);

    if (virtualTonReserveAfter * (virtualTokenReserve + inputTokenAmount) < virtualTonReserve * virtualTokenReserve) {
        virtualTonReserveAfter += 1;
    }

    let outBeforeTax: Int = virtualTonReserve - virtualTonReserveAfter;
    let tax: Int = outBeforeTax * BONDING_CURVE_FEE_BIPS / PRECISION;

    return OutputTonAmountReturn {
        amountOut: outBeforeTax - tax,
        tax
    };
}

contract BondingCurve with Jetton {
    total_supply: Int as coins;
    owner: Address;
    content: Cell;
    mintable: Bool;

    max_supply: Int as coins; // Extract parameter we set here. The Jetton Standards doesn't have this parameter.

    balances: map<Address, Int>;
    virtualTonReserve: Int;
    virtualTokenReserve: Int;
    complete: Bool;
    liquidityAdded: Bool;
    factory: Address;
    jettonCreator: Address;
    tokenDebt: Int;
    myJettonWalletAddress: Address;

    init(jettonCreator: Address, content: Cell) {
        // init map empty
        self.virtualTonReserve = ton("29");
        self.virtualTokenReserve = ton("450660000000");
        self.complete = false;
        self.liquidityAdded = false;
        let init: StateInit = initOf Factory(FACTORY_DEPLOYER);
        let factory: Address = contractAddress(init);
        self.factory = factory;
        self.tokenDebt = 0;
        self.jettonCreator = jettonCreator;

        self.total_supply = 0;
        self.owner = newAddress(0, 0);
        self.myJettonWalletAddress = newAddress(0, 0);
        self.mintable = true;
        self.content = content;
        self.max_supply = ton("420000000000");
    }

    receive(_: Mint) {
        require(sender() == self.factory, "only factory can create");
        self.mint(myAddress(), self.max_supply, myAddress()); // (to, amount, response_destination)
        self.mintable = false;
        let myJettonWalletInit: StateInit = self.getJettonWalletInit(myAddress());
        let myJettonWalletAddress: Address = contractAddress(myJettonWalletInit);
        self.myJettonWalletAddress = myJettonWalletAddress;
    }

    get fun balance(): Int {
        return myBalance();
    }

    fun handlePaymentsForFee(fee: Int, treasury: Address, referrer: Address, referrerDl1: Address, referrerDl2: Address) {
        // first, 10% to token creator
        let tokenCreatorFee: Int = fee * 10 / 100;
        send(SendParameters {
            to: self.jettonCreator,
            value: tokenCreatorFee,              
            mode: SendPayGasSeparately | SendIgnoreErrors,
            bounce: false,
            body: "tokenCreatorReward".asComment()
        });

        let remainingFee: Int = fee - tokenCreatorFee;
        let nullAddress: Address = newAddress(0, 0);
        if (referrer != nullAddress) {
            send(SendParameters {
                to: referrer,
                value: fee * 15 / 100,              
                mode: SendPayGasSeparately | SendIgnoreErrors,
                bounce: false,
                body: "ReferrerReward".asComment()
            });
            remainingFee -= fee * 15 / 100;
        }

        if (referrerDl1 != nullAddress) {
            send(SendParameters {
                to: referrerDl1,
                value: fee * 5 / 100,              
                mode: SendPayGasSeparately | SendIgnoreErrors,
                bounce: false,
                body: "ReferrerDl1Reward".asComment()
            });
            remainingFee -= fee * 5 / 100;
        }

        if (referrerDl2 != nullAddress) {
            send(SendParameters {
                to: referrerDl2,
                value: fee * 5 / 100,              
                mode: SendPayGasSeparately | SendIgnoreErrors,
                bounce: false,
                body: "ReferrerDl2Reward".asComment()
            });
            remainingFee -= fee * 5 / 100;
        }

        send(SendParameters {
            to: treasury,
            value: remainingFee,              
            mode: SendPayGasSeparately | SendIgnoreErrors,
            bounce: false,
            body: "".asComment()
        });
    }

    receive(buy: Buy) {
        require(!self.complete, "complete");
        require(sender() == self.factory, "not factory");
        require(context().value > buy.tonAmount, "value too low");
        require(buy.tonAmount > 0 && buy.tonAmount <= context().value - BUY_GAS_FEE, "ValueMustBeGreaterThanZero");
        
        let outputData: OutputTokenAmountReturn = getOutputTokenAmount_(buy.tonAmount, self.virtualTonReserve, self.virtualTokenReserve);
        require(outputData.amountOut >= buy.minOut, "ExceedsSlipage");
        let currentBalance: Int = 0;
        if (self.balances.get(buy.trader) != null) {
            currentBalance = self.balances.get(buy.trader)!!;
        }
        self.balances.set(buy.trader, currentBalance + outputData.amountOut);
        self.tokenDebt += outputData.amountOut;

        //  handle tax and reserve
        self.virtualTonReserve += buy.tonAmount - outputData.tax - outputData.remainNativeAmount;
        self.virtualTokenReserve -= outputData.amountOut;

        emit(TradeEvent{
            tonAmount: buy.tonAmount - outputData.tax - outputData.remainNativeAmount,
            jettonAmount: outputData.amountOut,
            jetton: myAddress(),
            virtualTonReserve: self.virtualTonReserve,
            virtualTokenReserve: self.virtualTokenReserve,
            trader: buy.trader,
            isBuy: true,
            balance: currentBalance + outputData.amountOut
        }.toCell());

        if (self.virtualTokenReserve <= VIRTUAL_TOKEN_RESERVE_WHEN_ADD_LIQUIDITY) {
            self.complete = true;
            emit(CompleteEvent{
                jetton: myAddress(),
            }.toCell());
        }

        self.handlePaymentsForFee(outputData.tax, buy.treasury, buy.referrer, buy.referrerDl1, buy.referrerDl2);

        if (outputData.remainNativeAmount > 0) {
            // refund
            send(SendParameters {
                to: buy.trader,
                value: outputData.remainNativeAmount,              
                mode: SendPayGasSeparately | SendIgnoreErrors,
            });
        }
    }

    receive(sell: Sell) {
        require(!self.complete, "complete");
        require(sender() == self.factory, "not factory");
                
        require(sell.jettonAmount > 0 && context().value >= BUY_GAS_FEE, "ValueMustBeGreaterThanZero");

        // check have enough balance
        require(self.balances.get(sell.trader) != null, "insufficient jetton balance");
        let currentBalance: Int = self.balances.get(sell.trader)!!;
        require(currentBalance >= sell.jettonAmount, "insufficient jetton balance");

        let outputData: OutputTonAmountReturn = getOutputTonAmount_(sell.jettonAmount, self.virtualTonReserve, self.virtualTokenReserve);
        require(outputData.amountOut >= sell.minTonOut, "ExceedsSlipage");

        // update balance
        self.balances.set(sell.trader, currentBalance - sell.jettonAmount);
        self.tokenDebt -= sell.jettonAmount;

        self.handlePaymentsForFee(outputData.tax, sell.treasury, sell.referrer, sell.referrerDl1, sell.referrerDl2);

        // update virtual reserve
        self.virtualTonReserve -= (outputData.amountOut + outputData.tax);
        self.virtualTokenReserve += sell.jettonAmount;

        emit(TradeEvent{
            tonAmount: outputData.amountOut + outputData.tax,
            jettonAmount: sell.jettonAmount,
            jetton: myAddress(),
            virtualTonReserve: self.virtualTonReserve,
            virtualTokenReserve: self.virtualTokenReserve,
            trader: sell.trader,
            isBuy: false,
            balance: currentBalance - sell.jettonAmount
        }.toCell());
    }

    receive(claim: ClaimToken) {
        require(self.liquidityAdded, "!liquidityAdded");

        let owner: Address = claim.owner;
        // sender jetton wallet
        let senderJettonWalletInit: StateInit = self.getJettonWalletInit(owner);
        let senderJettonWalletAddress: Address = contractAddress(senderJettonWalletInit);

        require(self.balances.get(owner) != null, "no token to claim");
        let balance: Int = self.balances.get(owner)!!;
        self.balances.set(owner, null);
        require(context().value >= ton("0.1"), "invalid value for claim");
        // transfering out
        send(SendParameters{
            to: self.myJettonWalletAddress,
            value: context().value - ton("0.02"),           
            bounce: false, // 0x7362d09c - notify new owner   
            mode: SendPayGasSeparately | SendIgnoreErrors,
            body: TokenTransfer {
                query_id: 0,
                amount: balance,
                destination: owner,
                response_destination: sender(),
                custom_payload: null,
                forward_ton_amount: ton("0.01"),
                forward_payload: emptySlice()
            }.toCell()
        });

        emit(ClaimEvent{
            jetton: myAddress(),
            user: owner,
            balance: balance
        }.toCell());
    }

    receive("AddLiquidity") {
        require(self.complete, "!complete");
        require(!self.liquidityAdded, "!liquidityAdded");

        // TODO: code for adding liquidity
        self.liquidityAdded = true;
    }

    // The notification for the Jetton Token contract noification(when current address receive the token will get the notification)
    receive(stake: TokenNotification) {
        // do nothing
        // // Submit the Log Event
        // emit(TransferEvent{sender_address: stake.from, jetton_amount: stake.amount, score: score}.toCell());
    }

    get fun bondingCurveData(): BondingCurveData {
        return BondingCurveData { 
            virtualTonReserve: self.virtualTonReserve,
            virtualTokenReserve: self.virtualTokenReserve,
            complete: self.complete,
            liquidityAdded: self.liquidityAdded,
            jettonCreator: self.jettonCreator,
            tokenDebt: self.tokenDebt,
            myJettonWalletAddress: self.myJettonWalletAddress
        };
    }

    get fun outputTokenAmount(inputTonAmount: Int) : OutputTokenAmountReturn {
        return getOutputTokenAmount_(inputTonAmount, self.virtualTonReserve, self.virtualTokenReserve);
    }

    get fun outputTonAmount(inputTokenAmount: Int) : OutputTonAmountReturn {
        return getOutputTonAmount_(inputTokenAmount, self.virtualTonReserve, self.virtualTokenReserve);
    }

    get fun boughtBalance(address: Address) : Int {
        if (self.balances.get(address) == null) {
            return 0;
        }
        return self.balances.get(address)!!;
    }
}

message DeployCurveParams {
    content: Cell; 
}

contract Factory with Deployable {
    deployer: Address;
    treasury: Address;
    referrals: map<Address, Address>;
    referralsCount: Int;

    init(treasury: Address) {
        self.deployer = sender(); // sender() of init is who deployed the contract
        self.treasury = treasury;
        self.referralsCount = 0;
    }

    fun getOrUpdateReferrer(user: Address, referrer: Address, shouldUpdate: Bool): Address {
        let nullAddress: Address = newAddress(0, 0);
        if (user == nullAddress) {
            return nullAddress;
        }
        if (self.referrals.get(user) == null) {
            if (self.referralsCount >= 29999) {
                return nullAddress;
            }
            if (shouldUpdate) {
                self.referrals.set(user, referrer);
                self.referralsCount += 1;
            }
            return referrer;
        }

        return self.referrals.get(user)!!;
    }

    receive(deployCurveParams: DeployCurveParams) {
        // deploy token
        let jettonInit: StateInit = initOf BondingCurve(sender(), deployCurveParams.content);
        let jettonAddress: Address = contractAddress(jettonInit);

        send(SendParameters{
            to: jettonAddress,
            value: ton("0.1"),              // pay for message, the deployment and give some TON for storage
            mode: SendPayGasSeparately | SendIgnoreErrors,
            code: jettonInit.code,                // attaching the state init will cause the message to deploy
            data: jettonInit.data,
            body: Mint { 
            }.toCell()
        });

        emit(CreateEvent{
            content: deployCurveParams.content,
            jetton: jettonAddress,
            creator: sender(),
        }.toCell());
    }

    receive(buyCall: BuyCall) {
        require(sender() != buyCall.referrer, "cannot self refer");
        let referrer: Address = self.getOrUpdateReferrer(sender(), buyCall.referrer, true);
        let referrerDl1: Address = self.getOrUpdateReferrer(referrer, newAddress(0, 0), false);
        let referrerDl2: Address = self.getOrUpdateReferrer(referrerDl1, newAddress(0, 0), false);
        send(SendParameters 
        {
            to: buyCall.jetton,
            value: 0,              
            mode: SendRemainingValue | SendIgnoreErrors,
            body: Buy {
                tonAmount: buyCall.tonAmount,
                minOut: buyCall.minOut,
                referrer,
                referrerDl1,
                referrerDl2,
                treasury: self.treasury,
                trader: sender()
            }.toCell()
        });
    }

    receive(sellCall: SellCall) {
        require(sender() != sellCall.referrer, "cannot self refer");
        let referrer: Address = self.getOrUpdateReferrer(sender(), sellCall.referrer, true);
        let referrerDl1: Address = self.getOrUpdateReferrer(referrer, newAddress(0, 0), false);
        let referrerDl2: Address = self.getOrUpdateReferrer(referrerDl1, newAddress(0, 0), false);
        send(SendParameters 
        {
            to: sellCall.jetton,
            value: 0,              
            mode: SendRemainingValue | SendIgnoreErrors,
            body: Sell {
                jettonAmount: sellCall.jettonAmount,
                minTonOut: sellCall.minTonOut,
                referrer,
                referrerDl1,
                referrerDl2,
                treasury: self.treasury,
                trader: sender()
            }.toCell()
        });
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun getBondingCurveInit(creator: Address, content: Cell): StateInit {
        return initOf BondingCurve(creator, content);
    }

    get fun getReferrer(user: Address, referrer: Address): Address {
        let nullAddress: Address = newAddress(0, 0);
        if (user == nullAddress) {
            return nullAddress;
        }
        if (self.referrals.get(user) == null) {
            return referrer;
        }
        return self.referrals.get(user)!!;
    }
}
