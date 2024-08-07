import "@stdlib/deploy";
import "@stdlib/ownable";
// import "./traits/skate/ISkate.tact"; // implicit
import "./traits/skate/SkateApp.tact";

//////////////// Stable API ///////////////////

// USER ACTIONs
message(0xcd2612b0) RequestBindWallet {
    chain_type: Int as uint256; // <- Skate chainType convention || 0=EVM, 1=Solana, 2=TON, 3=others.
    bind_address: Int as uint256; // <- target address to bind, bytes32 as universal repr
}

// TODO: Request/Reply for TON native app to interact with Skate
// // APP ACTIONs
// message RequestWallet {
//     query_id: Int as uint64;
//     chain_type: Int as uint256;
//     user: Address;
//     response_destination: Address;
// }
// // EXECUTOR ACTIONs
// message ReplyWallet {
//     query_id: Int as uint64;
//     chain_type: Int as uint256;
//     user: Address;
//     evm_address: Int as uint256;
//     registered: Bool;
// }

// GOVERNANCE ACTIONs
message(0x44807e69) WithdrawTON {}

///////////////////////////////////////////////

/////////////// Future API //////////////////
// TODO: Contracts INTEROP
// TODO: Protocol collect permissible TON amount
// message ProtocolCollect {}
///////////////////////////////////////////////


//////////////////////////////////////////////////////
contract WalletRegistry with Deployable, SkateAppBase, Ownable {
    owner: Address;
    query_id: Int as uint64 = 0; // task initiated by this contract
    get fun queryId(): Int {
        return self.query_id;
    }
    skate_gateway: Address;
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
    const SKATE_CHAIN: Int = 5051;
    const EVM_TYPE: Int = 0;
    const WALLET_REGISTRY: Int = 0xf42dCFF1b722212c790C254B8E96ae1881DD24Ff; // TODO: do this once done.

    // NOTE: Minimum amount for SkateInitiateTaskNotification to pass, app must calculate this.
    // Excess amount (value - SKATE_FEE - forwardFee) is returned to the app
    const NOTIFICATION_COST: Int = ton("0.007");

    init(owner: Address, skate_gateway: Address) {
        self.owner = owner;
        self.skate_gateway = skate_gateway;
    }

    /////////// Governance actions ////////////
    receive() {
        // Do nothing, just accept TON.
        // TODO: incentive to fund this
    }

    receive(msg: WithdrawTON) {
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
        })
    }

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
                        chain_id: self.SKATE_CHAIN,
                        chain_type: self.EVM_TYPE,
                        address: self.WALLET_REGISTRY,
                    }.toCell(),
                    data: execution_data,
                }
            },
            callback: false
        };
        return initiate_params;
    }

    //////////// User interactions ////////////
    //// 1. Request to bind TON address to an address
    receive(msg: RequestBindWallet) {
        let ctx: Context = context();
        require(ctx.value >= self.USER_FEE, "WalletRegistry::Not enough user fee!");

        // 2. Notify SkateGateway to initiate a task
        self.query_id += 1;
        let initiate_params = self.construct_initiate_params(self.query_id, ctx.sender, msg.toCell());
        self.notify_gateway(initiate_params);

        // NOTE: For gas rebates
        // We shouldn't do it as the contract can be gas DoS.
        // send(SendParameters{
        //     to: msg.sender,
        //     value: self.TRANSFER_USDT_GAS + ctx.value,
        //     mode: SendPayGasSeparately,
        // })
    }

    // TODO : (Contracts interop) App/user request the binded address to be used, e.g. app own logic to distribute rewards (not via Skate)
    // receive(msg: RequestWallet) {
    // }
    ///////////////////////////////////////////

    ////////// Executor interactions //////////
    // TODO : (Contracts interop) Executor will answer the request:
    //  1. Check kernel
    //  2. Return the binded address if any
    // receive(msg: ReplyWallet) {
    //     self.only_gateway();
    // }
}

