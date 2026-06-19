import "./jetton";
import "./surf_internal_msgs";
import "./messages";


message BuyOrder {
    buySize: Int;
    recipient: Address;
}

struct SellOrderTx {
    sellAmount: Int as coins;
    tonAmount: Int as coins;
    walletOwner: Address;
}

message LaunchDex {
    buyer: Address;
    surfDexWallet: Address;
}

message SurfOrderExecutedEvent {
    user: Address;
    isBuy: Bool;
    tonAmount: Int as coins;
    tokenAmount: Int as coins;    
    reserveTon: Int as coins;
    reserveSurf: Int as coins;
}

message DexLaunchedEvent {
    
}

struct LocalState {
    reserveTon: Int as coins;
    reserveSurf: Int as coins;
    launchFee: Int as coins;
    proxyTonWallet: Address;
    orderFeeBps: Int as uint32;
    launched: Bool;
    dexRouterTonWallet: Address;

    total_supply: Int;
    owner: Address;
}

//storage fees: 0.05 per 2 years

contract SurfOnTon with Jetton  {
    const BP: Int = 100_00;
    const SELL_ORDER_LIMIT: Int = 10_000;
    
    const JETTON_SIMPLE_TRANSFER: Int = ton("0.1");
    const DEX_LAUNCH: Int = ton("0.4");
    const SELF_STORAGE: Int = ton("0.05");
    const WALLET_DEPLOY: Int = ton("0.06");
    
    vx1: Int as coins; //120bit
    vy1: Int as coins; //120bit
    reserveTon: Int as coins;
    reserveSurf: Int as coins;
    tonThreshold: Int as coins;
    launchFee: Int as coins;
    factory: Address; //288bit
    proxyTonWallet: Address;
    orderFeeBps: Int as uint32;
    launched: Bool;
    dexRouter: Address;
    dexRouterTonWallet: Address;
    tokenDeployer: Address?;
    launchTimestamp: Int as uint32;

    total_supply: Int; 
    mintable: Bool;
    owner: Address;
    content: Cell;


    init(
        owner: Address,
        vx1: Int, 
        vy1: Int, 
        totalSupply: Int, 
        tonThreshold: Int, 
        launchFee: Int, 
        orderFeeBps: Int,
        content: Cell,
        proxyTonMain: Address,
        dexRouter: Address,
    ) {
        require(totalSupply > 0, "wrong total supply");
        require(tonThreshold > 0, "wrong ton threshold");
        require(launchFee > 0, "wrong launch fee 1");
        require(tonThreshold > launchFee, "wrong launch fee 2");
        require((0 < orderFeeBps) && (orderFeeBps <= self.BP), "wrong teamWalletShareBps");

        self.vx1 = vx1;
        self.vy1 = vy1;
        self.reserveTon = 0;
        self.reserveSurf = totalSupply;
        self.tonThreshold = tonThreshold;
        self.launchFee = launchFee;

        self.orderFeeBps = orderFeeBps; //0.5%

        self.owner = owner;

        self.content = content;
        self.proxyTonWallet = proxyTonMain;
        self.dexRouter = dexRouter;

        self.total_supply = 0;
        self.mintable = true;

        self.launched = false;
    

        self.factory = context().sender;
        self.dexRouterTonWallet = myAddress();
        self.launchTimestamp = 0;

        let fwd_fee: Int = context().readForwardFee();
        let remainingValue = context().value;

        remainingValue -= self.SELF_STORAGE;
        remainingValue -= ton("0.01"); //self execution
        remainingValue -= ton("0.05") + fwd_fee;
                
        send(SendParameters{
            to: proxyTonMain,
            value: ton("0.05") + fwd_fee, //0.017 => ~ 0.02
            bounce: false, //should never fail
            mode: 0,
            body: ProvideWalletAddress {
                query_id: 0,
                owner_address: dexRouter,
                include_address: false
            }.toCell()
        });//*/

        
        send(SendParameters{
            to: proxyTonMain,
            value: remainingValue,
            bounce: false, //should never fail
            mode: 0,
            body: DeployPTonWallet {
                query_id: 1,
                ownerAddress: myAddress()
            }.toCell()
        });


    }

    receive(msg: Deploy) {
        if (msg.tokenDeployer != null) {
            require(context().sender == self.factory, "factory only allowed");

            self.launchTimestamp = now() + 3 * 60;
            self.tokenDeployer = msg.tokenDeployer;
        }
    }

    receive(takeWalletMsg: TakeWalletAddress) {
        let ctx: Context = context();

        if (ctx.sender == self.proxyTonWallet) {
            if (takeWalletMsg.query_id == 0) {
                self.dexRouterTonWallet = takeWalletMsg.wallet_address;

                send(SendParameters{
                    to: self.proxyTonWallet,
                    value: 0,
                    bounce: false, //even if we catch bounced message what to do?
                    mode: SendRemainingValue,
                    body: ProvideWalletAddress {
                        query_id: 99,
                        owner_address: myAddress(),
                        include_address: false
                    }.toCell()
                });

            } else if (takeWalletMsg.query_id == 99) {
                self.proxyTonWallet = takeWalletMsg.wallet_address;

                //gas refund?
            }

            return;
        }

        require(false, "access denied");
    }

    receive(jettonMsg: TokenNotification) {
        let ctx: Context = context();
        /*/
        dump("TokenNotification");
        dump("sender");
        dump(ctx.sender);
        dump("pTonWallet");
        dump(self.proxyTonWallet);
        //*/

        if (ctx.sender == self.proxyTonWallet) {
            let buyOrder: BuyOrder? = null;

            dump("correct sender");

            try {
                let buyMsgCell: Cell = jettonMsg.forward_payload.loadRef();
                let buyMsgSlice: Slice = buyMsgCell.beginParse();
                buyOrder = BuyOrder.fromSlice(buyMsgSlice);
                dump("parsed buy");
            } catch (e) {
                dump(e);
            }

            if (buyOrder != null) {
                self._hanldeBuyOrder(buyOrder!!, jettonMsg.amount);
                return;
            }

            if (jettonMsg.from == myAddress()) {
                let launchDex: LaunchDex? = null;

                try {
                    let launchDexCell: Cell = jettonMsg.forward_payload.loadRef();
                    let launchDexSlice: Slice = launchDexCell.beginParse();
                    launchDex = LaunchDex.fromSlice(launchDexSlice);
                    dump("parsed launch dex");
                } catch (e) {
                    dump(e);
                }

                if (launchDex != null) {
                    self._handleLaunchDex(launchDex!!, jettonMsg.amount);
                    return;
                }
            }
        }

        require(false, "access denied");


    }

    receive(msg: TokenExcesses) {

    }

    receive(sellOrder: SellOrder) {
        let ctx: Context = context();
        require(ctx.value >= ton("0.4"), "Gas amount too small");
        self.requireSenderAsWalletOwner(sellOrder.seller!!);
        require(!self.launched, "Token launched on DEX");
        //require(self.sellOrderTxLength < self.SELL_ORDER_LIMIT, "Too many sell orders, try a bit later");
        let amountOut: Int = self._getAmountOutTon(sellOrder.sellSize);
        
        require(amountOut >= sellOrder.amountOutMin, "Slippage too small");

        self.reserveTon -= amountOut;
        self.reserveSurf += sellOrder.sellSize;
        
        let fee: Int = self.orderFeeBps * amountOut / self.BP;

        send(SendParameters{
            to: ctx.sender, 
            value: self.JETTON_SIMPLE_TRANSFER, 
            bounce: false,
            mode: 0,
            body: SellFromWallet{ 
                sellAmount: sellOrder.sellSize
            }.toCell()
        });

        send(SendParameters{
            to: self.proxyTonWallet, 
            value: self.JETTON_SIMPLE_TRANSFER, 
            bounce: false,
            mode: 0,
            body: TokenTransfer{
                query_id: 0,
                amount: fee,
                destination: self.factory,
                response_destination: sellOrder.seller!!,
                forward_ton_amount: 0,
                custom_payload: null,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell()
        });
        let value: Int = context().value;
        let initialBalance: Int = myBalance() - value;
        let storageFee: Int = self.SELF_STORAGE - min(initialBalance, self.SELF_STORAGE);
        let selfExecution: Int = ton("0.002"); //TODO: review it

        send(SendParameters{
            to: self.proxyTonWallet, 
            value: value 
                - 2 * self.JETTON_SIMPLE_TRANSFER 
                - storageFee
                - selfExecution, 
            bounce: false,
            mode: 0,
            body: TokenTransfer{
                query_id: 0,
                amount: amountOut - fee,
                destination: sellOrder.seller!!,
                response_destination: sellOrder.seller!!,
                forward_ton_amount: 0,
                custom_payload: null,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell()
        });

        emit(SurfOrderExecutedEvent {
            user: sellOrder.seller!!,
            isBuy: false,
            tonAmount: amountOut,
            tokenAmount: sellOrder.sellSize,
            reserveTon: self.reserveTon,
            reserveSurf: self.reserveSurf
        }.toCell());
    }

    receive(newOptions: UpdateTokenData) {
        self.requireOwner();

        if (newOptions.owner != null) {
            self.owner = newOptions.owner!!;
        }

        if (newOptions.launchFee != null) {
            self.launchFee = newOptions.launchFee!!;
        }

        if (newOptions.orderFeeBps != null) {
            self.orderFeeBps = newOptions.orderFeeBps!!;
        }
    }

    fun _requireSoft(condition: Bool, user: Address, payedAmount: Int, msg: String) : Bool {
        if (!condition) {
            dump("soft revert");
            dump(msg);

            send(SendParameters{
                to: self.proxyTonWallet, 
                value: self.JETTON_SIMPLE_TRANSFER, 
                bounce: false,
                mode: 0,
                body: TokenTransfer{
                    query_id: 0,
                    amount: payedAmount,
                    destination: user,
                    response_destination: user,
                    forward_ton_amount: 0,
                    custom_payload: null,
                    forward_payload: beginCell().endCell().asSlice()
                }.toCell()
            });

            send(SendParameters{
                to: user, 
                value: 0, 
                bounce: false,
                mode: SendRemainingValue,
                body: GasExcess{}.toCell()
            });
        }

        return !condition;
    }

    fun _hanldeBuyOrder(buyOrder: BuyOrder, payedAmount: Int) {
        let value: Int = context().value;
        let softRevert: Bool = false;
        let selfExecution: Int = ton("0.02");

        dump("reached buy");

        let minGas: Int = 
            3 * self.JETTON_SIMPLE_TRANSFER +
            self.JETTON_SIMPLE_TRANSFER +
            self.SELF_STORAGE +
            selfExecution;

        if (self.launchTimestamp > now()) {
            if (self._requireSoft(self.tokenDeployer == buyOrder.recipient, buyOrder.recipient, payedAmount, "first buyer constraint")) {
                return;
            }
        }

        if (self._requireSoft(value > minGas, buyOrder.recipient, payedAmount, "not enough value")) {
            return;
        }
        
        if (self._requireSoft(!self.launched, buyOrder.recipient, payedAmount, "already launched")) {
            return;
        }


        let amountIn: Int = 0;
        try {
            amountIn = self._getAmountInTon(buyOrder.buySize); //might fail => require soft required
        } catch (e) {
            dump(e);
            self._requireSoft(false, buyOrder.recipient, payedAmount, "error in _getAmountInTon");
        }
        let fee: Int = amountIn * self.orderFeeBps / self.BP;
        let dexLaunchFee: Int = 0;

        /*
        dump("amountIn");
        dump(amountIn);
        dump("fee");
        dump(fee);
        dump("payedAmount");
        dump(payedAmount);
        //*/
        
        if (self._requireSoft((amountIn + fee) <= payedAmount, buyOrder.recipient, payedAmount, "hit slippage")) {
            return;
        }


        if ((self.reserveTon + amountIn) >= self.tonThreshold) {
            dexLaunchFee = self.launchFee;
            amountIn = self.tonThreshold - self.reserveTon;
            fee = amountIn * self.orderFeeBps / self.BP;
            let newBuySize = self._getAmountOutSurf(amountIn);

            buyOrder.buySize = newBuySize < buyOrder.buySize ? newBuySize : buyOrder.buySize;
        }

        /*
        dump("amountIn");
        dump(amountIn);
        dump("fee");
        dump(fee);
        dump("payedAmount");
        dump(payedAmount);
        //*/

        
        self.reserveTon += amountIn;
        self.reserveSurf -= buyOrder.buySize;
    
        // me -> jtWallet -> user
        self.mint(buyOrder.recipient, buyOrder.buySize, buyOrder.recipient, self.JETTON_SIMPLE_TRANSFER, 0);


        // me -> jtWallet -> Factory -> user:
        // 4 forward fee = 0.001 * 4 = 0.004
        // 2 jetton exec = 0.013 * 2 = 0.026
        // 2 jetton storage = 0.019 * 2 = 0.038
        // factory exec
        //  ---
        // 0.068 + fact exec < 0.1

        value -= 3 * self.JETTON_SIMPLE_TRANSFER;

        send(SendParameters{
            to: self.proxyTonWallet, 
            value: self.JETTON_SIMPLE_TRANSFER, 
            bounce: false,
            mode: 0,
            body: TokenTransfer{
                query_id: 0,
                amount: fee + dexLaunchFee,
                destination: self.factory,
                response_destination: buyOrder.recipient,
                forward_ton_amount: ton("0.01"),
                custom_payload: null,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell()
        });

        // me -> jtWallet -> user
        send(SendParameters{
            to: self.proxyTonWallet, 
            value: self.JETTON_SIMPLE_TRANSFER, 
            bounce: false,
            mode: 0,
            body: TokenTransfer{
                query_id: 0,
                amount: payedAmount - amountIn - fee,
                destination: buyOrder.recipient,
                response_destination: buyOrder.recipient,
                forward_ton_amount: 0, 
                custom_payload: null,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell()
        });

        if (dexLaunchFee > 0) {
            self.launched = true;
            value -= self.JETTON_SIMPLE_TRANSFER;
                            
            /*/
            send(SendParameters{
                to: surfDexWallet, 
                value: self.WALLET_DEPLOY, 
                bounce: false,
                mode: 0,
                body: DeployWallet{
                    gasExcessDest: buyOrder.recipient
                }.toCell(),
                code: dexWalletInit.code,
                data: dexWalletInit.data
            });//*/

            send(SendParameters{
                to: self.proxyTonWallet, 
                value:  self.JETTON_SIMPLE_TRANSFER,
                bounce: false,
                mode: 0,
                body: TokenTransferPton1 {
                    query_id: 0,
                    amount: self.reserveTon - dexLaunchFee,
                    destination: myAddress(),
                    response_destination: buyOrder.recipient,
                    forward_ton_amount: ton("0.01"), 
                    forward_payload: LaunchDex {
                        buyer: buyOrder.recipient,
                        surfDexWallet: buyOrder.recipient
                    }.toCell(),
                    custom_payload: null,
                }.toCell()
            });            
        }

        emit(SurfOrderExecutedEvent {
            user: buyOrder.recipient,
            isBuy: true,
            tonAmount: amountIn,
            tokenAmount: buyOrder.buySize,
            reserveTon: self.reserveTon,
            reserveSurf: self.reserveSurf
        }.toCell());
        
        let initialBalance: Int = myBalance() - value;
        let storageFee: Int = self.SELF_STORAGE - min(initialBalance, self.SELF_STORAGE);

        send(SendParameters{
            to: buyOrder.recipient, 
            value: value - storageFee - selfExecution, 
            bounce: false,
            mode: 0,
            body: GasExcess{}.toCell()
        });
    }

    fun _handleLaunchDex(launchDex: LaunchDex, jettonToDeposit: Int) {
        let dexWalletInit: StateInit = self.getJettonWalletInit(self.dexRouter); // Create message
        let surfDexWallet: Address = contractAddress(dexWalletInit);

        self.total_supply = self.total_supply + self.reserveSurf;
        let fwd_fee: Int = context().readForwardFee();
        //*/
        send(SendParameters{
            to: surfDexWallet, 
            value: self.DEX_LAUNCH + self.WALLET_DEPLOY + fwd_fee, 
            bounce: false,
            mode: 0,
            body: TokenTransferInternalCell { 
                query_id: 1,
                amount: self.reserveSurf,
                from: myAddress(),
                response_destination: launchDex.buyer,
                forward_ton_amount: self.DEX_LAUNCH,
                forward_payload: DexProvideLpV1 {
                    otherTokenWallet: self.dexRouterTonWallet,
                    minLpOut: 1                       
                }.toCell(),
            }.toCell(),
            code: dexWalletInit.code,
            data: dexWalletInit.data
        });//*/


        /*
            for V2
            // me -> jtWallet -> jtWallet -> Router -> ...
            // 9 forward fee = 0.001 * 9 = 0.009
            // 2 jetton exec = 0.013 * 2 = 0.026
            // 2 jetton storage = 0.019 * 2 = 0.038
            // Router exec & stor
            // ----
            // 0.073 + Router exec & stor
            send(SendParameters{
                to: surfDexWallet, 
                value: self.DEX_LAUNCH, 
                bounce: false,
                mode: 0, //TODO: checkit out
                body: TokenTransferInternal{ 
                    query_id: 1,
                    amount: self.reserveSurf,
                    from: myAddress(),
                    forward_ton_amount: 0, //TODO: add some gas
                    forward_payload: DexProvideLp {
                        otherTokenWallet: self.dexRouterTonWallet,
                        refundAddress: myAddress(),
                        excessesAddress: buyOrder.recipient,
                        additionalData: DexProvideLpExtraData {
                            minLpOut: 1,
                            receiverAddress: myAddress(),
                            bothPositive: true,
                            forwardGas: self.DEX_LAUNCH - self.JETTON_SIMPLE_TRANSFER,
                            customPayload: null,
                        }.toCell()
                    }.toCell().asSlice(),
                    response_destination: null,
                }.toCell(),
                code: dexWalletInit.code,
                data: dexWalletInit.data
            });

            //*/

        jettonToDeposit -= self.DEX_LAUNCH + self.WALLET_DEPLOY + ton("0.1") + fwd_fee;        

        send(SendParameters{
            to: self.dexRouterTonWallet,
            value: jettonToDeposit,
            bounce: false,
            mode: 0,
            body: TokenTransferPton1 {
                query_id: 0,
                amount: jettonToDeposit - self.DEX_LAUNCH,
                destination: self.dexRouter,
                response_destination: launchDex.buyer,
                forward_ton_amount: self.DEX_LAUNCH - self.JETTON_SIMPLE_TRANSFER, 
                forward_payload: DexProvideLpV1 {
                    otherTokenWallet: surfDexWallet,
                    minLpOut: 1,                       
                }.toCell(),
                custom_payload: null,
            }.toCell()
        });
          /*/
            for V2
            // me -> jtWallet -> jtWallet -> Router -> ...
            // 9 forward fee = 0.001 * 9 = 0.009
            // 2 jetton exec = 0.013 * 2 = 0.026
            // 2 jetton storage = 0.019 * 2 = 0.038
            // Router exec & stor
            // ----
            // 0.073 + Router exec & stor
            send(SendParameters{
                to: self.proxyTonWallet, 
                value: self.DEX_LAUNCH, //TODO: add more gas
                bounce: false,
                mode: 0,
                body: TokenTransfer{
                    query_id: 0,
                    amount: self.reserveTon - self.launchFee,
                    destination: self.dexRouter,
                    forward_ton_amount: 0, //TODO: add some gas
                    forward_payload: DexProvideLpV2 {
                        otherTokenWallet: launchDex.surfDexWallet,
                        refundAddress: myAddress(),
                        excessesAddress: buyOrder.recipient,
                        additionalData: DexProvideLpExtraData {
                            minLpOut: 1,
                            receiverAddress: myAddress(),
                            bothPositive: true,
                            forwardGas: 0,
                            customPayload: null,
                        }.toCell()
                    }.toCell().asSlice(),
                    custom_payload: null,
                    response_destination: null,
                }.toCell()
            });
            //*/
        
        
        emit(DexLaunchedEvent{}.toCell());
    }



    fun _getAmountInTon(surfSize: Int) : Int {
        return self._getAmountIn(surfSize, self.vx1 + self.reserveTon, self.vy1 + self.reserveSurf);
    }

    fun _getAmountOutSurf(tonSize: Int) : Int {
        return self._getAmountOut(tonSize, self.vx1 + self.reserveTon, self.vy1 + self.reserveSurf);
    }

    fun _getAmountInSurf(tonSize: Int) : Int {
        return self._getAmountIn(tonSize, self.vy1 + self.reserveSurf, self.vx1 + self.reserveTon);
    }

    fun _getAmountOutTon(surfSize: Int) : Int {
        return self._getAmountOut(surfSize, self.vy1 + self.reserveSurf, self.vx1 + self.reserveTon);
    }

    fun _getAmountOut(amountIn: Int, reserveIn: Int, reserveOut: Int) : Int {
        let numerator: Int = amountIn * reserveOut;
        let denominator: Int = reserveIn + amountIn;

        return numerator / denominator;
    }

    fun _getAmountIn(amountOut: Int, reserveIn: Int, reserveOut: Int) : Int {
        let numerator: Int = amountOut * reserveIn;
        let denominator: Int = reserveOut - amountOut;

        require (denominator > 0, "Not sufficient liquidity");

        return numerator / denominator + 1;
    }

    

    get fun GetAmountInTon(surfSize: Int) : Int {
        return self._getAmountInTon(surfSize);
    }

    get fun GetAmountOutSurf(tonSize: Int) : Int {
        return self._getAmountOutSurf(tonSize);
    }

    get fun GetAmountInSurf(tonSize: Int) : Int {
        return self._getAmountInSurf(tonSize);
    }

    get fun GetAmountOutTon(surfSize: Int) : Int {
        return self._getAmountOutTon(surfSize);
    }

    //dexRouterTonWallet: Address;
    //self.proxyTonWallet

    get fun GetDexRouterPTonWallet() : Address {
        return self.dexRouterTonWallet;
    }

    get fun GetPTonWallet() : Address {
        return self.proxyTonWallet;
    }

    get fun GetCurrentPrice(): Int {
        let thresholdLeft: Int = self.tonThreshold - self.reserveTon;

        if (thresholdLeft < 0) {
            thresholdLeft = 0;
        }

        return (
            self.reserveTon 
                - (self.launchFee * self.reserveTon ) / self.tonThreshold
                + (self.vx1 * thresholdLeft) / self.tonThreshold
        ) * pow(10,18) / self.reserveSurf;
    }

    get fun GetTonReserve() : LocalState {
        return LocalState {
            reserveTon: self.reserveTon,
            reserveSurf: self.reserveSurf,
            launchFee: self.launchFee,
            proxyTonWallet: self.proxyTonWallet,
            orderFeeBps: self.orderFeeBps,
            launched: self.launched,
            dexRouterTonWallet: self.dexRouterTonWallet,

            total_supply: self.total_supply,
            owner:  self.owner,
        };
    }
}
