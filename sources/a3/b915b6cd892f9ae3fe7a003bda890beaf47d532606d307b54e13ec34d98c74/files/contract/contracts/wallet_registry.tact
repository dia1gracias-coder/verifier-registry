// WARN: NOT USED IN CURRENT VERSION
import "@stdlib/deploy";
import "@stdlib/ownable";
// import "./traits/skate/ISkate.tact"; // implicit
import "./traits/skate/SkateApp.tact";

//////////////// Stable API ///////////////////

// NOTE: Request/Reply for TON native app to interact with Skate
//
// App actions
message RequestWallet {
    query_id: Int as uint64;
    vm_type: Int as uint256;
    user: Address;
    response_destination: Address;
}
// EXECUTOR ACTIONs
message ReplyWallet {
    query_id: Int as uint64;
    response_destination: Address; // Ton App that receive the message
    user: Address;
    vm_type: Int as uint256;
    chain_address: Int as uint256;
}

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

    // Pay to Skate infra for processing on Kernel + callback here.
    const EXECUTION_FEE: Int = ton("0.00");

    // Polymarket destination constants
    const SKATE_CHAIN: Int = 5051;
    const EVM_TYPE: Int = 1;
    const WALLET_REGISTRY: Int = 0x5f4DB181416289FF60b751CB9B3aB4e36a2e19bE;

    // NOTE: Minimum amount for SkateInitiateTaskNotification to pass, app must calculate this.
    // Excess amount (value - SKATE_FEE - forwardFee) is returned to the app
    const NOTIFICATION_COST: Int = ton("0.008");
    const SKATE_FEE: Int = 0;

    init(owner: Address, skate_gateway: Address) {
        self.owner = owner;
        self.skate_gateway = skate_gateway;
    }

    /////////// Governance actions ////////////
    receive(msg: Slice) {
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

    // NOTE: utility function to construct bind signature
    get fun bind_hash(vm_type: Int, target_address: Int): Int {
        let hash = beginCell().storeUint(vm_type, 256).storeUint(target_address, 256).endCell().hash();
        return hash;
    }

    // NOTE: utility function to verify bind request signature, production logic should be implemented off-chain.
    get fun is_valid_bind_signature(user_public_key: Int, vm_type: Int, target_address: Int, signature: Slice): Bool {
        let hash = self.bind_hash(vm_type, target_address);
        return checkSignature(hash, signature, user_public_key);
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
                        vm_type: self.EVM_TYPE,
                        address: self.WALLET_REGISTRY,
                    }.toCell(),
                    data: execution_data,
                }
            },
            callback: false
        };
        return initiate_params;
    }

    //////////// App interactions ////////////
    // NOTE : (Contracts interop) Request the binding from Kernel
    //  1. Send to gateway -> event emit
    //  2. Executor check on Kernel
    //  3. Reply with the binded address
    receive(msg: RequestWallet) {
        let ctx: Context = context();
        require(ctx.value >= self.EXECUTION_FEE, "WalletRegistry::Not enough fee!");

        // 2. Notify SkateGateway to initiate a task
        self.query_id += 1;
        let initiate_params = self.construct_initiate_params(self.query_id, ctx.sender, msg.toCell());
        self.notify_gateway(initiate_params);
    }
    ///////////////////////////////////////////

    ////////// Executor interactions //////////
    // NOTE : (Contracts interop) Executor will answer the request:
    //  1. Check kernel
    //  2. Return the binded address if any
    receive(msg: ReplyWallet) {
        self.only_gateway();
        send(SendParameters{
            to: msg.response_destination,
            value: 0,
            mode: SendRemainingValue,
            body: msg.toCell(),
        })
    }
}

