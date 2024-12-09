import "@stdlib/deploy";
import "@stdlib/ownable";

import "./imports/skate-core/traits/skate/SkateApp.tact";

import "./traits/jetton/IJetton.tact";
import "./traits/polymarket/IPolymarket.tact"; // NOTE: implicit
import "./polymarket_user_wallet.tact";
import "./polymarket_executor_wallet.tact";

/////////////////////////////////////////
/////////////// CONSTANT ////////////////
const POLYGON_CHAIN: Int = 137;
const EVM_TYPE: Int = 1;
const POLYMARKET_CTF: Int = 0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E;
const POLYMARKET_SAFE_FACTORY: Int = 0xaacFeEa03eb1561C4e67d661e40682Bd20E3541b;


///////////////////////////////////////////
/////////////// GOVERNANCE ////////////////
message ChangeEmergencySigner {
    newEmergencySigner: Int;
    currentSignature: Slice;
    newSignature: Slice;
}
///////////////////////////////////////////
///////////////////////////////////////////

/////////////////////////////////////////
////////////// SUB-WALLET ///////////////
message(0x79b77b52) DeployUserWallet {}
message(0x18215f57) DeployExecutorWallet {
    executor: Address
}
/////////////////////////////////////////

/////////////////////////////////////////
///////////// FEES CONTROL //////////////
message(0x3ace80fe) SetBuyFee {
    new_buy_fee: Int as uint16;
}

message(0x59a9d1f3) SetSellFee {
    new_sell_fee: Int as uint16;
}
/////////////////////////////////////////

/////////////////////////////////////////
//////////////// EVENTS /////////////////
message(0xdf7220b1) BuyOrderPlaced {
    action_id: Int as uint64;
    token_id: Int; // Must match Polymarket ID
    usd_amount: Int as coins; // Jetton (USDT) amount WARN: must match the coins serialization used in USDT.
    expiration: Int as uint32;
    user: Address;
}

message(0xbcf754c8) BuyOrderWithdrawn {
    action_id: Int as uint64;
    timestamp: Int as uint32;
    user: Address;
}

message(0x43796c9e) BuyOrderCompleted {
    action_id: Int as uint64;
    executor: Address;
    timestamp: Int as uint32;
    user: Address;
    fee: Int as uint16;
}

message(0x46704197) SellOrderPlaced {
    action_id: Int as uint64;
    token_id: Int; // Must match Polymarket ID
    ct_amount: Int as coins; // Condition Token amount, number of bet tokens for this market on PolyMarket
    expiration: Int as uint32;
    user: Address;
}

message(0x85e10e2a) ClaimRequestPlaced {
    action_id: Int as uint64;
    token_id: Int; // Must match Polymarket ID
    user: Address;
}

message(0xd444585b) SellOrderCompleted {
    action_id: Int as uint64;
    executor: Address;
    timestamp: Int as uint32;
    usd_amount: Int as coins;
    user: Address;
    fee: Int as uint16;
}
/////////////////////////////////////////

/////////////////////////////////////////
//////////// EXECUTOR ENTRY /////////////
message(0x5b40a8cd) FillBuyOrder {
    action_id: Int as uint64;
    user: Address;
    executor: Address;
}

message(0xac863858) FillSellOrder {
    action_id: Int as uint64;
    user: Address;
    executor: Address;
    usd_amount: Int as coins;
}
/////////////////////////////////////////


//////////////////////////////////////////////////////
contract PolymarketMaster with SkateAppBase, Deployable, Ownable {
    owner: Address;
    usdt_wallet_code: Cell;
    usdt_master: Address;
    skate_gateway: Address;
    get fun skate_gateway(): Address {
        return self.skate_gateway;
    }

    version_id: Int;
    get fun version_id(): Int {
        return self.version_id;
    }
    emergency_signer: Int; // An ED25519 public key
    get fun emergency_signer(): Int {
        return self.emergency_signer;
    }

    init(owner: Address, skate_gateway: Address, usdt_master: Address, usdt_wallet_code: Cell, version_id: Int, emergency_signer: Int) {
        self.owner = owner;
        self.skate_gateway = skate_gateway;
        self.usdt_master = usdt_master;
        self.usdt_wallet_code = usdt_wallet_code;
        self.version_id = version_id;
        self.emergency_signer = emergency_signer;
    }

    receive(msg: ChangeEmergencySigner) {
        self.requireOwner();
        self.set_emergency_signer(msg.newEmergencySigner, msg.currentSignature, msg.newSignature);
    }

    const CHANGE_EMERGENCY_SIGNER_MESSAGE: String = "Skate.Polymarket::CHANGE_EMERGENCY_SIGNER";
    get fun change_emergency_signer_message(): String {
        return self.CHANGE_EMERGENCY_SIGNER_MESSAGE;
    }
    inline fun set_emergency_signer(newSigner: Int, currentSignature: Slice, newSignature: Slice) {
        let messageHash: Int = sha256(self.CHANGE_EMERGENCY_SIGNER_MESSAGE);

        let isCurrentSignatureValid: Bool = checkSignature(messageHash, currentSignature, self.emergency_signer);
        require(isCurrentSignatureValid, "PolymarketMaster::set_emergency_signer()::Not approved by current signer!");

        let isNewSignatureValid: Bool = checkSignature(messageHash, newSignature, newSigner);
        require(isNewSignatureValid, "PolymarketMaster::set_emergency_signer()::Not approved by new signer!");
        self.emergency_signer = newSigner;
    }


    inline fun construct_initiate_params(
        query_id: Int, user: Address, processing_fee: Int,
        destination: Destination, execution_data: Cell, expiration: Int
    ): SkateInitiateTask {
        let initiate_params = SkateInitiateTask {
            query_id: query_id,
            user: user,
            processing_fee: processing_fee,
            execution_info: ExecutionInfo {
                value: 0,
                expiration: expiration,
                payload: Payload {
                    destination: destination.toCell(),
                    data: execution_data,
                }
            },
            callback: false
        };
        return initiate_params;
    }

    ///////////////////////////////////////////////////////
    //////////////////////// USERS ////////////////////////
    const DEPLOY_USER_WALLET_COST: Int = ton("0.05");
    const DEPLOY_USER_WALLET_NOTIFICATION_COST: Int = ton("0.007");
    const DEPLOY_USER_WALLET_INIT_COST: Int = ton("0.025");
    receive(msg: DeployUserWallet) {
        let ctx = context();
        require(ctx.value >= self.DEPLOY_USER_WALLET_COST, "PolymarketMaster::Insufficient value to deploy user wallet!");

        // 1. Notify gateway
        let initiate_task_params = self.construct_initiate_params(
            0,
            ctx.sender,
            self.DEPLOY_USER_WALLET_NOTIFICATION_COST,
            Destination {
                chain_id: POLYGON_CHAIN,
                vm_type: EVM_TYPE,
                address: POLYMARKET_SAFE_FACTORY,
            },
            UserWalletDeployed{}.toCell(),
            now() + 3600_00000, // Create wallet is 1-time action, expire at infinity (11 years).
        );
        self.notify_gateway(initiate_task_params);

        // 2. Init wallet
        let wallet_init = initOf PolymarketUserWallet(
            myAddress(),
            ctx.sender,
            self.usdt_master,
            self.usdt_wallet_code,
            self.emergency_signer,
        );
        let user_wallet_address = contractAddress(wallet_init);
        send(SendParameters{
            to: user_wallet_address,
            value: self.DEPLOY_USER_WALLET_INIT_COST,
            mode: SendBounceIfActionFail,
            body: InitializeUserWallet{}.toCell(),
            code: wallet_init.code,
            data: wallet_init.data,
        });
    }
    get fun user_wallet(user: Address): Address {
        let wallet_init = initOf PolymarketUserWallet(
            myAddress(),
            user,
            self.usdt_master,
            self.usdt_wallet_code,
            self.emergency_signer,
        );

        return contractAddress(wallet_init);
    }

    // User loggings
    inline fun requireUserWallet(user: Address) {
        let user_wallet_address = self.user_wallet(user);
        require(sender() == user_wallet_address, "PolymarketMaster::Not user wallet!");
    }
    const BUY_ORDER_NOTIFICATION_COST: Int = ton("0.007");
    receive(msg: PlaceBuyOrderNotification) {
        // 1. Access control
        self.requireUserWallet(msg.user);

        // 2. Notify gateway
        let destination = Destination {
            chain_id: POLYGON_CHAIN,
            vm_type: EVM_TYPE,
            address: POLYMARKET_CTF,
        };
        let buy_order = PlaceBuyOrder {
            token_id: msg.token_id,
            usd_amount: msg.usd_amount,
        };
        let initiate_task_params = self.construct_initiate_params(
            msg.action_id,
            msg.user,
            self.BUY_ORDER_NOTIFICATION_COST,
            destination,
            buy_order.toCell(),
            msg.expiration,
        );
        self.notify_gateway(initiate_task_params);

        // 3. Logging
        emit(BuyOrderPlaced{
            action_id: msg.action_id,
            token_id: msg.token_id,
            usd_amount: msg.usd_amount,
            expiration: msg.expiration,
            user: msg.user,
        }.toCell());

        // 4. Refund excess amount to user
        self.forward(msg.user, null, false, null);
    }

    const SELL_ORDER_NOTIFICATION_COST: Int = ton("0.007");
    receive(msg: PlaceSellOrderNotification) {
        // 1. Access control
        self.requireUserWallet(msg.user);

        // 2. Notify Gateway
        let destination = Destination {
            chain_id: POLYGON_CHAIN,
            vm_type: EVM_TYPE,
            address: POLYMARKET_CTF,
        };
        let sell_order = PlaceSellOrder {
            token_id: msg.token_id,
            ct_amount: msg.ct_amount,
        };
        let initiate_task_params = self.construct_initiate_params(
            msg.action_id,
            msg.user,
            self.SELL_ORDER_NOTIFICATION_COST,
            destination,
            sell_order.toCell(),
            msg.expiration,
        );
        self.notify_gateway(initiate_task_params);

        // 3. Logging
        emit(SellOrderPlaced{
            action_id: msg.action_id,
            token_id: msg.token_id,
            ct_amount: msg.ct_amount,
            expiration: msg.expiration,
            user: msg.user
        }.toCell());

        // 4. Refund excess amount to user
        self.forward(msg.user, null, false, null);
    }

    const CLAIM_RESOLVED_MARKET_NOTIFICATION_COST: Int = ton("0.007");
    receive(msg: ClaimResolvedMarketNotification) {
        // 1. Access control
        self.requireUserWallet(msg.user);

        // 2. Notify Gateway
        let destination = Destination {
            chain_id: POLYGON_CHAIN,
            vm_type: EVM_TYPE,
            address: POLYMARKET_CTF,
        };
        let claim_order = ClaimResolvedMarket {
            token_id: msg.token_id,
        };
        let expiration: Int = now() + 60_000_000; // Non expirable
        let initiate_task_params = self.construct_initiate_params(
            msg.action_id,
            msg.user,
            self.SELL_ORDER_NOTIFICATION_COST,
            destination,
            claim_order.toCell(),
            expiration,
        );
        self.notify_gateway(initiate_task_params);

        // 3. Logging
        emit(ClaimRequestPlaced{
            action_id: msg.action_id,
            token_id: msg.token_id,
            user: msg.user
        }.toCell());

        // 4. Refund excess amount to user
        self.forward(msg.user, null, false, null);
    }

    receive(msg: WithdrawBuyOrderNotification) {
        // 1. Access control
        self.requireUserWallet(msg.user);

        // 2. Logging
        emit(BuyOrderWithdrawn{
            action_id: msg.action_id,
            timestamp: msg.timestamp,
            user: msg.user,
        }.toCell());

        // 3. Refund excess amount to user
        self.forward(msg.user, null, false, null);
    }
    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////
    ////////////////////// EXECUTORS //////////////////////
    const DEPLOY_EXECUTOR_WALLET_COST: Int = ton("0.03");
    // NOTE: No need to notify gateway for this case
    receive(msg: DeployExecutorWallet) {
        // 1. Access control
        let ctx = context();
        nativeThrowUnless(132, ctx.sender == self.skate_gateway); // NOTE: more gas efficient than `self.only_gateway()` in this case
        require(ctx.value >= self.DEPLOY_EXECUTOR_WALLET_COST, "PolymarketMaster::Insufficient value to deploy executor wallet!");

        // 2. Init wallet
        let wallet_init = initOf PolymarketExecutorWallet(
            myAddress(),
            msg.executor,
            self.usdt_master,
            self.usdt_wallet_code,
        );
        let executor_wallet_address = contractAddress(wallet_init);
        send(SendParameters{
            to: executor_wallet_address,
            value: 0,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: InitializeExecutorWallet{}.toCell(),
            code: wallet_init.code,
            data: wallet_init.data,
        });
    }
    get fun executor_wallet(executor: Address): Address {
        let wallet_init = initOf PolymarketExecutorWallet(
            myAddress(),
            executor,
            self.usdt_master,
            self.usdt_wallet_code,
        );

        return contractAddress(wallet_init);
    }

    ///////////////////////////////////////////////////////
    /////////////////////// BUY ORDER /////////////////////
    buy_fee_bps: Int = 25; // 0.25%
    get fun buy_fee(): Int {
        return self.buy_fee_bps;
    }
    const MAX_BUY_FEE_BPS: Int = 100;
    receive(msg: SetBuyFee) {
        self.requireOwner();
        require(msg.new_buy_fee <= self.MAX_BUY_FEE_BPS, "PolymarketMaster::New BUY fee exceeds maximum value allowed!");
        self.buy_fee_bps = msg.new_buy_fee;
    }

    // NOTE: No gas refund for executor to fully optimize cost of callback
    const FILL_BUY_ORDER_COST: Int = ton("0.032");
    const FILL_BUY_ORDER_CALLBACK_COST: Int = ton("0.019");
    receive(msg: FillBuyOrder) {
        // 1. Access control
        let ctx: Context = context();
        nativeThrowUnless(132, sender() == self.skate_gateway);
        require(ctx.value >= self.FILL_BUY_ORDER_COST, "PolymarketMaster::Insufficient value to fill BUY order!");

        // 2. Call user wallet to confirm sell order
        let user_wallet_address = self.user_wallet(msg.user);
        let executor_wallet_address = self.executor_wallet(msg.executor);
        send(SendParameters{
            to: user_wallet_address,
            value: self.FILL_BUY_ORDER_CALLBACK_COST,
            mode: SendBounceIfActionFail,
            body: ConfirmBuyOrder{
                action_id: msg.action_id,
                executor: msg.executor,
                executor_wallet: executor_wallet_address,
                fee: self.buy_fee_bps,
            }.toCell(),
        });

        // 3. Logging
        emit(BuyOrderCompleted{
            action_id: msg.action_id,
            executor: msg.executor,
            timestamp: now(),
            user: msg.user,
            fee: self.buy_fee_bps,
        }.toCell());
    }
    /////////////////////////////////////

    ///////// SELL/CLAIM ORDER //////////
    sell_fee_bps: Int = 25; // 0.25%
    get fun sell_fee(): Int {
        return self.sell_fee_bps;
    }
    const MAX_SELL_FEE_BPS: Int = 100;
    receive(msg: SetSellFee) {
        self.requireOwner();
        require(msg.new_sell_fee <= self.MAX_SELL_FEE_BPS, "PolymarketMaster::New SELL fee exceeds maximum value allowed!");
        self.sell_fee_bps = msg.new_sell_fee;
    }

    // NOTE: No gas refund for executor to fully optimize cost of callback
    // CLAIM = SELL with corresponding USDT value, no separate flow required.
    const FILL_SELL_ORDER_COST: Int = ton("0.025");
    const FILL_SELL_ORDER_CALLBACK_COST: Int = ton("0.017");
    receive(msg: FillSellOrder) {
        // 1. Access control
        let ctx: Context = context();
        nativeThrowUnless(132, sender() == self.skate_gateway);
        require(ctx.value >= self.FILL_SELL_ORDER_COST, "PolymarketMaster::Insufficient value to fill SELL order!");

        // 2. Call executor wallet to confirm sell order
        let executor_wallet_address = self.executor_wallet(msg.executor);
        send(SendParameters{
            to: executor_wallet_address,
            value: self.FILL_SELL_ORDER_CALLBACK_COST,
            mode: SendPayGasSeparately | SendBounceIfActionFail,
            body: ConfirmSellOrder{
                user: msg.user,
                usd_amount: msg.usd_amount,
                fee: self.sell_fee_bps,
            }.toCell(),
        });

        // 3. Logging
        emit(SellOrderCompleted{
            action_id: msg.action_id,
            executor: msg.executor,
            timestamp: now(),
            usd_amount: msg.usd_amount,
            user: msg.user,
            fee: self.sell_fee_bps,
        }.toCell());
    }
    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////
}

