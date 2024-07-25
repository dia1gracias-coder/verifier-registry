import "@stdlib/deploy";
import "@stdlib/ownable";
import "./traits/jetton/IJetton.tact";
// import "./traits/skate/ISkate.tact"; // implicit
import "./traits/skate/SkateApp.tact";

//////////////// Stable API ///////////////////
// NOTE: We only allow to bet on Election market now.
struct Bet {
    candidate_id: Int as uint8; // Mapping on frontend, now we allow TRUMP (1) | Harris (2) | Obama (3) |  Kanye (4)
    direction: Bool; // True = YES, False = NO
    // WARN: mind the type, coins != uint256
    usd_amount: Int as coins; // Jetton (USDT) amount => USD equivalent amount will be placed for the bet on PolyMarket
    // NOTE: stateless => no need for status
    // status: Int as uint8 = 0; // 0 = PLACED, 1 = WIN, 2 = LOSE, 3 = ABORT (withdraw)
}

struct BetConfig {
    candidate_id: Int as uint8;
    direction: Bool;
}
// EXECUTOR ACTION
message(0xc4a35d45) SettleBet {
    settle_id: Int as uint64; // For on-chain trace, will be included in stateproof for AVS slashing
    user: Address; // User address
    fee_receiver: Address; // fee receiver address for EXECUTOR_FEE
    // WARN: mind the type, coins != uint256
    usd_amount: Int as coins; // amount Jetton settled for user (0 if lose, X decided by kernel if won)
}

// USER ACTION
message(0x873b1472) RequestSettleBet {
    candidate_id: Int as uint8;
    direction: Bool;
    // WARN: mind the type, coins != uint256
    ct_amount: Int as coins; // Condition Token amount, number of bet tokens for this market(candidate/direction) on PolyMarket
}

// NOTE: Set the contract USDT wallet
// Address pre-calculation is impossible since:
//  + contract address depends on initial params
//  + jetton wallet derivation consists of contract address (the jetton owner)
// -> must set then lock
message(0x77321783) SetJettonWallet {
    jetton_wallet: Address;
}
///////////////////////////////////////////////

/////////////// Unstable API //////////////////
// TODO: Contracts INTEROP
// message PlaceBetNotification {}
// struct SettleBetNotification {}

// TODO: Protocol collect permissible USDT & TON amount
// message ProtocolCollect {}
///////////////////////////////////////////////


//////////////////////////////////////////////////////
contract PolyMarket with Deployable, SkateAppBase, Ownable {
    owner: Address;
    skate_gateway: Address;

    balance: Int = 0; // Jetton balance (USDT)
    initiate_id: Int as uint64 = 0; // task initiated by this contract
    settle_id: Int as uint64 = 0; // task initiated by this contract
    const SETTLE_OFFSET: Int = 0xffffffff; // 2^32 offset.

    total_deposit: Int = 0;
    protocol_amount: Int = 0;

    get fun initiateCount(): Int {
        return self.initiate_id;
    }
    get fun settleCount(): Int {
        return self.settle_id;
    }
    get fun gateway(): Address {
        return self.skate_gateway;
    }

    // TODO: A proper estimation for fee framework before public launch, should satisfy:
    //  1. USER_FEE > SKATE_FEE + EXECUTOR_FEE + APP_FEE
    //  2. all fees >= send message fee
    const USER_FEE: Int = ton("0.00"); // User pay this, app extract a portion of this fee (minus (user_fee + skate_fee)) to fund their operations.
    const SKATE_FEE: Int = ton("0.00"); // Gateway get this (then collected by Skate Infra). NOTE: Ideally should match SkateGateway.SKATE_FEE, excess amount are rebated.
    const EXECUTOR_FEE: Int = ton("0.00"); // Executor reward

    // Polymarket destination constants
    const POLYGON_CHAIN: Int = 137;
    const EVM_TYPE: Int = 0;
    const POLYMARKET_CTF: Int = 0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E;

    // Bet config
    const MIN_BET_SIZE: Int = ton("0.0001"); // TBD - set at 0.1 USDT minimum bet for now
    const MAX_CANDIDATE_ID: Int = 4;

    // Message gas cost
    const NOTIFICATION_COST: Int = ton("0.02"); // WARN: minimum amount for SkateInitiateTaskNotification to pass, app must calculate this.
    const TRANSFER_USDT_COST: Int = ton("0.05"); // WARN: minimum amount for JettonTransfer to pass.

    init(owner: Address, skate_gateway: Address) {
        self.owner = owner;
        self.skate_gateway = skate_gateway;
    }

    // Calculate jetton address and update post deployment
    jetton_wallet: Address = newAddress(0, 0x1000000000000000000000000000000000000000000000000000000000000000); // dummy address
    is_jetton_set: Bool = false;
    receive(msg: SetJettonWallet) {
        self.requireOwner();
        require(!self.is_jetton_set, "PolyMarket::SetJettonWallet::Wallet is set");
        self.jetton_wallet = msg.jetton_wallet;
        self.is_jetton_set = true;
    }
    /////////// Governance actions ////////////
    // TODO: Protocol collect fees + exceeded USDT amounts
    //
    // receive(msg: ProtocolCollect) {}

    //////////// For SkateGateway /////////////
    inline fun construct_initiate_params(query_id: Int, user: Address, execution_data: Cell): SkateInitiateTask {
        let initiate_params = SkateInitiateTask {
            query_id: query_id,
            user: user, // the actual jetton wallet owner.
            processing_fee: self.SKATE_FEE + self.NOTIFICATION_COST,
            execution_info: ExecutionInfo {
                value: 0,
                expiration: now() + 120, // 2 minutes
                payload: Payload {
                    destination: Destination {
                        chain_id: self.POLYGON_CHAIN,
                        chain_type: self.EVM_TYPE,
                        address: self.POLYMARKET_CTF,
                    }.toCell(),
                    data: execution_data,
                }
            }
        };
        return initiate_params;
    }

    //////////// User interactions ////////////
    // NOTE: There is no concept of approve USDT to spend on TON, therefore user can only place bet via transferring Jetton + specify forward_payload.
    // => EQUIVALENTLY, PLACE BET = SENT JETTON (USDT) + BET INFO.
    //
    //// 1. PLACE BET
    receive(msg: JettonTransferNotification) {
        let ctx: Context = context();
        require(ctx.value >= self.USER_FEE, "PolyMarket::Not enough user fee!");

        let bet_config: BetConfig = BetConfig.fromSlice(msg.forward_payload);
        require(msg.amount > self.MIN_BET_SIZE, "PolyMarket::JettonTransferNotification::Bet size too small!");
        require(bet_config.candidate_id <= self.MAX_CANDIDATE_ID, "PolyMarket::JettonTransferNotification::Invalid candidate id!");

        // 1. Create and save the bet struct
        let new_bet: Bet = Bet {
            candidate_id: bet_config.candidate_id,
            usd_amount: msg.amount, // Jetton USDT amount
            direction: bet_config.direction,
        };

        // 2. Notify SkateGateway to initiate a task
        self.initiate_id += 1;
        let initiate_params = self.construct_initiate_params(self.initiate_id, msg.sender, new_bet.toCell());
        self.notify_gateway(ctx, initiate_params);

        // TODO:(IMPORTANT)
        // How to correctly rebates gas for user?

        // TODO: (Contracts INTEROP)
        // 3. Notify the caller that the receiver was executed and forward remaining value back
        // self.notify("Bet placed".asComment());
    }

    // TODO: (Contracts INTEROP)
    // Announce execution is done on other periphery chain (polygon)
    //
    // receive(msg: PlaceBetNotification) {}

    //// 2. Settle Bet
    receive(msg: RequestSettleBet) {
        let ctx: Context = context();
        require(ctx.value >= self.USER_FEE, "PolyMarket::Not enough user fee!");

        // 1. Initiate an withdrawal request
        self.settle_id += 1;
        let initiate_params = self.construct_initiate_params(self.settle_id, ctx.sender, msg.toCell());
        self.notify_gateway(ctx, initiate_params);

        // TODO:(IMPORTANT)
        // How to correctly rebates gas for user?
        send(SendParameters{
            to: ctx.sender,
            value: ctx.value,
            mode: SendPayGasSeparately,
        })
    }
    ///////////////////////////////////////////

    ////////// Executor interactions //////////

    // NOTE: Amount is verified by relayer, this only happens after actual execution is done on PolyMarket (Polygon)
    // Settle the bet by:
    //  1. Transfer Jetton (USDT) TO USER
    //  2. Transfer fee to executor.
    receive(msg: SettleBet) {
        self.only_gateway();
        let ctx: Context = context();

        // TODO: WHY DOESN't THIS WORK (exit code 9)? Suspect tact-lang serialization error
        // Is it related to no support for Either-type?
        // https://docs.tact-lang.org/book/func#convert-serialization
        //
        // let transfer_msg = JettonTransfer {
        //     query_id: msg.settle_id,
        //     amount: msg.usd_amount,
        //     destination: msg.user,
        //     response_destination: msg.user,
        //     custom_payload: null,
        //     forward_ton_amount: 0,
        //     forward_payload: emptySlice()
        // };

        // 1.1 Transfer USDT
        let transfer_msg = beginCell()
            .storeUint(0x0f8a7ea5, 32)
            .storeUint(0, 64) // op, queryId
            .storeCoins(msg.usd_amount)
            .storeAddress(msg.user)
            .storeAddress(myAddress()) // make sure excess gas are returned
            .storeUint(0, 1)
            // TODO: (Contracts INTEROP)
            // Set custom forward payload to user (contract), user needs to pay fee to executor to set gas for processing this payload.
            // forward_payload: SettleBetNotification{}.toCell().asSlice()
            .storeCoins(0)
            .storeUint(0, 1)
            .endCell();
        send(SendParameters{
            to: self.jetton_wallet,
            value: self.TRANSFER_USDT_COST, // NOTE: depends on payload size, this must be enough to pay gas to transfer
            mode: SendPayGasSeparately, // make sure user get their amount
            body: transfer_msg
        });
        // 1.2 Transfer TON amount to user
        send(SendParameters{
            to: msg.user,
            value: ctx.value, // NOTE: depends on payload size, this must be enough to pay gas to transfer
            mode: SendPayGasSeparately, // make sure user get their amount
        });

        // 2. Transfer ton to executor
        if (self.EXECUTOR_FEE > 0) {
            send(SendParameters{
                to: msg.fee_receiver,
                value: self.EXECUTOR_FEE, // NOTE: depends on payload size, this must be enough to pay gas to transfer
                mode: SendPayGasSeparately, // make sure user get their amount
            });
        }
    }
}
