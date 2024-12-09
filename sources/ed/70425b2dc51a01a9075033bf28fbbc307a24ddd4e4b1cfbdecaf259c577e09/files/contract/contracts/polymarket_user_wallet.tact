import "@stdlib/ownable";

import "./traits/jetton/IJetton.tact";
import "./traits/polymarket/IPolymarket.tact";

message(0xe66e3213) UserWalletDeployed {}
message(0xbbd041b9) InitializeUserWallet {}

struct BetConfig {
    // WARN: Tact does not work with uint256, compiled code automatically turn this into int256 -> Overflow
    token_id: Int; // as uint256, Must match Polymarket ID
}

struct StagedUSDT {
    amount: Int as coins;
    expiration: Int as uint32;
}

message(0xb5c15cd0) PlaceBuyOrder {
    token_id: Int; // Must match Polymarket ID
    usd_amount: Int as coins; // Jetton (USDT) amount WARN: must match the coins serialization used in USDT.
}

message(0x84191731) PlaceSellOrder {
    token_id: Int; // Must match Polymarket ID
    ct_amount: Int as coins; // Condition token amount
}

message(0x4e7bac91) ClaimResolvedMarket {
    token_id: Int;
}

message(0x2336dc57) ConfirmBuyOrder {
    action_id: Int as uint64;
    executor: Address;
    executor_wallet: Address;
    fee: Int as uint16;
}

message(0xe7471374) WithdrawBuyOrder {
    action_id: Int as uint64;
}

message(0x7d292ee4) WithdrawUsdtEmergency {
    amount: Int as coins;
    expiration: Int as uint32;
    nonce: Int as uint32;
    signature: Slice;
}

contract PolymarketUserWallet with Ownable {
    master: Address; // NOTE: to verify the validity of the contract.
    get fun master(): Address {
        return self.master;
    }
    owner: Address;

    usdt_wallet: Address;
    get fun usdt_wallet(): Address {
        return self.usdt_wallet;
    }
    emergency_signer: Int; // An ED25519 public key
    get fun emergency_signer(): Int {
        return self.emergency_signer;
    }
    init(master: Address, owner: Address, usdt_master: Address, usdt_wallet_code: Cell, emergency_signer: Int) {
        self.master = master;
        self.owner = owner;
        self.usdt_wallet = calculate_jetton_wallet_address(myAddress(), usdt_master, usdt_wallet_code);
        self.emergency_signer = emergency_signer;
    }

    //// NOTE: Flow 0.0 - Deploy wallet
    receive(msg: InitializeUserWallet) {
        // Return excess amount, then notify deployment status (in case user is some smart contract)
        self.forward(self.owner, UserWalletDeployed{}.toCell(), false, null);
    }

    //////////////////////////////////////////////////////////////////
    ///////////////////////// FUND CONTROLS //////////////////////////
    receive(msg: JettonExcesses) {
        // NOTE: receive TON and do nothing, be explicit instead of `receive()`
    }
    receive(msg: WithdrawTON) {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
        })
    }

    // Bitmap is better but unnecessary complicated, this should RARELY happen.
    // NOTE: No need to refresh this, uint32 should be more than enough.
    used_emergency_nonce: map<Int as uint32, Bool> = null;
    get fun used_emergency_nonce(): map<Int as uint32, Bool> {
        return self.used_emergency_nonce;
    }
    inline fun calculate_emergency_withdrawal_hash(amount: Int, expiration: Int, nonce: Int): Int {
        let hash = beginCell()
            .storeCoins(amount)
            .storeUint(expiration, 32)
            .storeInt(nonce, 32)
            .storeAddress(self.owner)
            .endCell()
            .hash();
        return hash;
    }
    get fun emergency_withdrawal_hash(amount: Int, expiration: Int, nonce: Int): Int {
        return self.calculate_emergency_withdrawal_hash(amount, expiration, nonce);
    }
    receive(msg: WithdrawUsdtEmergency) {
        self.requireOwner();
        let withdrawal_hash = self.calculate_emergency_withdrawal_hash(msg.amount, msg.expiration, msg.nonce);
        let isValidSignature: Bool = checkSignature(withdrawal_hash, msg.signature, self.emergency_signer);
        require(isValidSignature, "PolymarketUserWallet::Invalid emergency signer signature!");

        require(now() < msg.expiration, "PolymarketUserWallet::Withdrawal signature expired!");
        let is_nonce_used = self.used_emergency_nonce.get(msg.nonce);
        require(is_nonce_used == null, "PolymarketUserWallet::Withdrawal nonce used!");

        self.used_emergency_nonce.set(msg.nonce, true);
        self.send_usdt(msg.amount, self.owner, self.owner);
    }
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////
    ////////////////////////// USER ACTIONS //////////////////////////
    action_id: Int as uint64 = 1;
    get fun action_id(): Int {
        return self.action_id;
    }
    staged_usdt_map: map<Int as uint64, StagedUSDT> = null;
    get fun staged_usdt_map(): map<Int as uint64, StagedUSDT> {
        return self.staged_usdt_map;
    }

    const TRANSFER_USDT_COST: Int = ton("0.009");
    inline fun send_usdt(amount: Int, to: Address, response: Address) {
        let transfer_usdt_msg = beginCell()
            .storeUint(OP_JettonTransfer, 32) // opcode
            .storeUint(0, 64) // queryId
            .storeCoins(amount) // usd amount
            .storeAddress(to) // to address
            .storeAddress(response) // response address
            .storeUint(0, 1) // custom payload
            .storeCoins(0) // forward_amount
            .storeUint(0, 1) // forward_payload
            .endCell();

        send(SendParameters{
            to: self.usdt_wallet,
            value: self.TRANSFER_USDT_COST,
            mode: SendBounceIfActionFail,
            body: transfer_usdt_msg
        });
    }

    //// NOTE: Flow 0.2 - User withdraw (permissible amount of) their USDT
    const WITHDRAW_COST: Int = ton("0.027");
    const WITHDRAW_CALLBACK_COST: Int = ton("0.01");
    receive(msg: WithdrawBuyOrder) {
        // 1. Check request validity
        let ctx: Context = context();
        nativeThrowUnless(132, ctx.sender == self.owner);
        require(ctx.value >= self.WITHDRAW_COST, "PolymarketUserWallet::Insufficient gas for withdrawal!");

        let s = self.staged_usdt_map.get(msg.action_id);
        require(s != null, "PolymarketUserWallet::Invalid withdraw request!");
        let stage_usdt_action = s!!;
        require(stage_usdt_action.expiration < now(), "PolymarketUserWallet::Bet is not expired yet!");

        // 2. Return USDT to user
        self.send_usdt(stage_usdt_action.amount, self.owner, self.owner);

        // 3. Delete the staging entry
        self.staged_usdt_map.del(msg.action_id);

        // 4. Master callback for logging
        send(SendParameters{
            to: self.master,
            value: self.WITHDRAW_CALLBACK_COST,
            mode: SendBounceIfActionFail,
            body: WithdrawBuyOrderNotification{
                action_id: msg.action_id,
                timestamp: now(),
                user: self.owner,
            }.toCell(),
        });

        // 5. Cashback user - empty message
        let remaining = ctx.value - self.WITHDRAW_CALLBACK_COST - 2 * ctx.readForwardFee();
        if (remaining > 0) {
            send(SendParameters {
                to: self.owner,
                value: remaining,
                mode: SendIgnoreErrors,
            })
        }
    }

    //// NOTE: Flow 1.1 - User place a bet by sending USDT + payload
    //   0.1 User send USDT to user's USDT Wallet.
    //   0.2 USDT Wallet send to this's USDT Wallet.
    //   1. This's USDT Wallet call JettonTransferNotification (i.e. this handler) to update the bet status.
    //   2. This callback Polymarket Master.
    //   3. Polymarket Master notify gateway + emit event.
    const BUY_ORDER_COST: Int = ton("0.03");
    const BUY_ORDER_CALLBACK_COST: Int = ton("0.02");
    const BUY_ORDER_EXPIRATION: Int = 300; // 5 minutes
    receive(msg: JettonTransferNotification) {
        // 1. Check bet input validity
        nativeThrowUnless(132, msg.sender == self.owner);

        let ctx: Context = context();
        require(ctx.value >= self.BUY_ORDER_COST, "PolymarketUserWallet::Insufficient gas for BUY order!");

        // 2. bet params and update state
        let expiration = now() + self.BUY_ORDER_EXPIRATION;
        let action_id = self.action_id;
        // WARN: IF MAP GROW TOO LARGE, TRANSACTION MAY FAILED AT STEP 2 BEFORE
        // `self.staged_usdt_map` UPDATE, USDT IS STUCK IN THIS WALLET
        // NEVERTHELESS, the gas requirements amount ensure at least user can holds
        // more than 5000 open positions.
        self.staged_usdt_map.set(action_id, StagedUSDT {
            amount: msg.amount,
            expiration: expiration,
        });
        self.action_id += 1;

        // 3. Master callback for logging
        let bet_config: BetConfig = BetConfig.fromSlice(msg.forward_payload);
        send(SendParameters{
            to: self.master,
            value: self.BUY_ORDER_CALLBACK_COST,
            mode: SendPayGasSeparately | SendBounceIfActionFail,
            body: PlaceBuyOrderNotification{
                action_id: action_id,
                token_id: bet_config.token_id,
                usd_amount: msg.amount,
                expiration: expiration,
                user: self.owner,
            }.toCell(),
        });

        // 4. Cashback user - empty message
        let remaining = ctx.value - self.BUY_ORDER_CALLBACK_COST - 2 * ctx.readForwardFee();
        if (remaining > 0) {
            send(SendParameters {
                to: self.owner,
                value: remaining,
                mode: SendIgnoreErrors,
            })
        }
    }

    //// NOTE: Flow 2.1 - User place a SELL order
    //   1. User send a SELL request to this contract.
    //   2. This define params and update state.
    //   3. This callback Polymarket Master.
    //   4. Polymarket Master notify gateway + emit event.
    //  WARN: Contract is stateless, invalid sell intent will be nullified on Kernel
    //  => It's up to user to send the correct intent.
    const SELL_ORDER_COST: Int = ton("0.03");
    const SELL_ORDER_CALLBACK_COST: Int = ton("0.02");
    const SELL_ORDER_EXPIRATION: Int = 300; // 5 minutes
    receive(msg: PlaceSellOrder) {

        // 1. Check sell order validity
        let ctx: Context = context();
        nativeThrowUnless(132, ctx.sender == self.owner);
        require(ctx.value >= self.SELL_ORDER_COST, "PolymarketUserWallet::Insufficient gas for SELL order!");

        // 2. Define sell params and update state
        let expiration = now() + self.SELL_ORDER_EXPIRATION;
        let action_id = self.action_id;
        self.action_id += 1;

        // 3. Master callback for logging
        send(SendParameters{
            to: self.master,
            value: self.SELL_ORDER_CALLBACK_COST,
            mode: SendPayGasSeparately | SendBounceIfActionFail,
            body: PlaceSellOrderNotification{
                action_id: action_id,
                token_id: msg.token_id,
                ct_amount: msg.ct_amount,
                expiration: expiration,
                user: self.owner,
            }.toCell(),
        });

        // 4. Cashback user - empty message
        let remaining = ctx.value - self.SELL_ORDER_CALLBACK_COST - 2 * ctx.readForwardFee();
        if (remaining > 0) {
            send(SendParameters {
                to: self.owner,
                value: remaining,
                mode: SendIgnoreErrors,
            })
        }
    }

    const CLAIM_RESOLVED_MARKET_COST: Int = ton("0.03");
    const CLAIM_RESOLVED_MARKET_CALLBACK_COST: Int = ton("0.02");
    receive(msg: ClaimResolvedMarket) {
        // 1. Check sell order validity
        let ctx: Context = context();
        nativeThrowUnless(132, ctx.sender == self.owner);
        require(ctx.value >= self.CLAIM_RESOLVED_MARKET_COST, "PolymarketUserWallet::Insufficient gas for SELL order!");

        // 2. Define sell params and update state
        let action_id = self.action_id;
        self.action_id += 1;

        // 3. Master callback for logging
        send(SendParameters{
            to: self.master,
            value: self.CLAIM_RESOLVED_MARKET_CALLBACK_COST,
            mode: SendPayGasSeparately | SendBounceIfActionFail,
            body: ClaimResolvedMarketNotification{
                action_id: action_id,
                token_id: msg.token_id,
                user: self.owner,
            }.toCell(),
        });

        // 4. Cashback user - empty message
        let remaining = ctx.value - self.CLAIM_RESOLVED_MARKET_COST - 2 * ctx.readForwardFee();
        if (remaining > 0) {
            send(SendParameters {
                to: self.owner,
                value: remaining,
                mode: SendIgnoreErrors,
            })
        }
    }


    //////////////////////////////////////////////////////////////////
    //////////////////////// EXECUTOR ACTIONS ////////////////////////
    inline fun only_master() {
        nativeThrowUnless(132, sender() == self.master);
    }

    // NOTE: Flow 1.2 - Executor update once bet is placed
    //  0.1 Executor call Gateway to initiate a fill order
    //  0.2 Gateway
    //  1. Update status for action_id
    //  2. Move user USDT to executor wallet
    receive(msg: ConfirmBuyOrder) {
        // 1. Access control
        self.only_master();

        // 2. Get the bet info, only amount is relevant
        //
        // NOTE: Even if order is expired, executor can still fill it if user decides not to withdraw.
        let s = self.staged_usdt_map.get(msg.action_id);
        require(s != null, "PolymarketUserWallet::BUY order does not exists!");
        let stage_usdt_action = s!!;

        // 3. Send USDT to EXECUTOR WALLET.
        // NOTE: Currently there is no restriction on what executor can do with user USDT once
        // the position is open. Another executor may execute SELL order relating to this position.
        //
        // TODO: Decide whether the fee is platform fee or executor fee. If it's executor fee, do nothing
        self.send_usdt(stage_usdt_action.amount, msg.executor_wallet, msg.executor);

        // 4. Delete the staging entry
        self.staged_usdt_map.del(msg.action_id);

        // 5. Return remaining to executor, the input gas will be high to ensure mapping can grow (RELATIVELY large)
        self.forward(msg.executor, null, false, null);
    }
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
}

