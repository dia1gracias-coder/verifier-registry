import "@stdlib/deploy";
import "./traits/skate/SkateApp.tact";
import "./traits/nft/NFTCollection.tact";
import "./skate_nft.tact";

//////////////// Stable API ///////////////////

//// USER ACTIONs
// WARN: Deprecated, user actions are intent-based now
message(0x605a9218) RequestMint {}
message(0x4dc16665) RequestBuild {}

//// EXECUTOR ACTIONs
// NOTE: Both mint or build will create a new NFT.
// Make sure to populate the correct part of the NFT with corresponding Metadata
message(0x775281a7) MintTo {
    user: Address;
    token_id: Int as uint256;
    part: Int as uint8; // 0 = Skateboard | 1 = Deck | 2 = Wheel | 3 = Truck
}

// GOVERNANCE ACTIONs
message(0x44807e69) WithdrawTON {}
///////////////////////////////////////////////

//////////////////////////////////////////////////////
contract SkateBuilder with Deployable, SkateAppBase, NFTCollectionBase {
    query_id: Int as uint64 = 0; // task initiated by this contract
    get fun query_id(): Int {
        return self.query_id;
    }
    skate_gateway: Address;
    get fun gateway(): Address {
        return self.skate_gateway;
    }

    next_item_index: Int = -1; // NOTE: this is sequential NFT, but id is not continous.
    collection_content: Cell;
    owner_address: Address;

    // NOTE: extra mapping for collection content.
    nft_parts_content: map<Int, Cell>;

    // NOTE:
    //  1. USER_FEE > SKATE_FEE + EXECUTOR_FEE + APP_FEE (NOTIFICATION_COST + APP_REVENUE + MSG GAS)
    //  2. all fees >= send message fee
    const USER_FEE: Int = ton("0.005"); // User pay this, app extract a portion of this fee (minus (user_fee + skate_fee)) to fund their operations.
    const SKATE_FEE: Int = ton("0.00"); // Gateway get this (then collected by Skate Infra). NOTE: Ideally should match SkateGateway.SKATE_FEE, excess amount are rebated.
    const EXECUTOR_FEE: Int = ton("0.00"); // Executor reward

    // Skate Builder NFT destination constants
    const SKATE_CHAIN: Int = 5051;
    const EVM_TYPE: Int = 0;

    // NOTE: Current SkateNFT proxy on Nollie
    // This is static during integration process with non-EVMs
    const NFT_BUILDER: Int = 0x2ee6732AaD365b15EB5544Ad8b8a10cda385384c;

    // Skate gateway message cost
    const NOTIFICATION_COST: Int = ton("0.01");

    init(owner: Address, skate_gateway: Address, collection_content: Cell, nft_parts_content: map<Int, Cell>) {
        self.owner_address = owner;
        self.skate_gateway = skate_gateway;
        self.collection_content = collection_content;
        self.nft_parts_content = nft_parts_content;
    }

    /////////// Governance actions ////////////
    receive() {
        // Accept TON, e.g. excesses amount refund from SkateGateway.
    }

    receive(msg: WithdrawTON) {
        send(SendParameters{
            to: self.owner_address,
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
                expiration: now() + 60, // 1 minutes
                payload: Payload {
                    destination: Destination {
                        chain_id: self.SKATE_CHAIN,
                        chain_type: self.EVM_TYPE,
                        address: self.NFT_BUILDER,
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
    receive(msg: RequestMint) {
        let ctx: Context = context();
        require(ctx.value >= self.USER_FEE, "SkateBuilder::Not enough user fee!");

        // Notify SkateGateway to initiate a task
        self.query_id += 1;
        let initiate_params = self.construct_initiate_params(self.query_id, ctx.sender, msg.toCell());
        self.notify_gateway(initiate_params);
    }

    receive(msg: RequestBuild) {
        let ctx: Context = context();
        require(ctx.value >= self.USER_FEE, "SkateBuilder::Not enough user fee!");

        // 2. Notify SkateGateway to initiate a task
        self.query_id += 1;
        let initiate_params = self.construct_initiate_params(self.query_id, ctx.sender, msg.toCell());
        self.notify_gateway(initiate_params);
    }
    ///////////////////////////////////////////


    /////// Skate Builder NFT Collection //////
    override inline fun _get_nft_item_state_init(index: Int): StateInit {
        return initOf SkateBuilderNFT(myAddress(), index);
    }

    ////////// Executor interactions //////////
    receive(msg: MintTo) {
        self.only_gateway();
        require(msg.part >=0 && msg.part <=3, "SkateBuilder.MintTo()::Invalid skateboard part, must be within 0-3");
        let nft_init = self._get_nft_item_state_init(msg.token_id);
        let ctx: Context = context();
        send(SendParameters{
            to: contractAddress(nft_init),
            value: 0,
            mode: SendRemainingValue,
            body: Transfer{
                query_id: 0,
                new_owner: msg.user,
                response_destination: newAddress(0, 0),
                custom_payload: self.nft_parts_content.get(msg.part),
                forward_amount: 0,
                forward_payload: emptySlice(),
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data,
        })
    }
}

