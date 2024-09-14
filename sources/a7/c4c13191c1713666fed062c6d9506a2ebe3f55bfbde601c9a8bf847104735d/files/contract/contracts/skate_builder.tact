import "@stdlib/deploy";
import "./imports/skate-core/traits/skate/SkateApp.tact";
import "./traits/nft/NFTCollection.tact";
import "./skate_nft.tact";

//// USER ACTIONs
const BUILD_OP: Int = 0x605a9218;
const MINT_OP: Int = 0x4dc16665;

//// EXECUTOR ACTIONs
// NOTE: Both request mint or build will create a new NFT.
// Therefore executor only action is mint NFT corresponding Skateboard NFT to correct user.
message(0x775281a7) MintTo {
    user: Address;
    token_id: Int as uint256;
    part: Int as uint8; // 0 = Skateboard | 1 = Deck | 2 = Wheel | 3 = Truck
}

// GOVERNANCE ACTIONs
message(0x44807e69) WithdrawTON {}

//////////////////////////////////////////////////////
contract SkateBuilder with Deployable, SkateAppBase, NFTCollectionBase {
    skate_gateway: Address;
    get fun gateway(): Address {
        return self.skate_gateway;
    }

    next_item_index: Int = -1; // NOTE: this is sequential NFT, but id is not continous.
    collection_content: Cell;
    owner_address: Address;
    nft_parts_content: map<Int, Cell>;

    const SKATE_FEE: Int = ton("0.00");

    // Skate Builder NFT destination constants
    const SKATE_CHAIN: Int = 5051;
    const EVM_TYPE: Int = 1;

    // NOTE: Current SkateNFT proxy on Nollie
    const NFT_BUILDER: Int = 0x2ee6732AaD365b15EB5544Ad8b8a10cda385384c;

    // Skate gateway message cost
    const NOTIFICATION_COST: Int = ton("0.01");

    deployment_nonce: Int;
    init(owner: Address, skate_gateway: Address, collection_content: Cell, nft_parts_content: map<Int, Cell>) {
        self.owner_address = owner;
        self.skate_gateway = skate_gateway;
        self.collection_content = collection_content;
        self.nft_parts_content = nft_parts_content;
        self.deployment_nonce = 1;
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

    //////////// User interactions ////////////
    //// 1. Request to bind TON address to an address
    get fun mint_hash(receiver_address: Address): Int {
        let payload_slice: Slice = beginCell()
            .storeUint(MINT_OP, 32)
            .storeUint(receiver_address.asSlice().loadUint(256), 256)
            .endCell().asSlice();
        return sha256(payload_slice);
    }
    get fun is_valid_mint_signature(user_public_key: Int, receiver_address: Address, signature: Slice): Bool {
        let hash = self.mint_hash(receiver_address);
        return checkSignature(hash, signature, user_public_key);
    }

    get fun build_hash(receiver_address: Address): Int {
        let payload_slice: Slice = beginCell()
            .storeUint(BUILD_OP, 32)
            .storeUint(receiver_address.asSlice().loadUint(256), 256)
            .endCell().asSlice();
        return sha256(payload_slice);
    }
    get fun is_valid_build_signature(user_public_key: Int, receiver_address: Address, signature: Slice): Bool {
        let hash = self.build_hash(receiver_address);
        return checkSignature(hash, signature, user_public_key);
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

