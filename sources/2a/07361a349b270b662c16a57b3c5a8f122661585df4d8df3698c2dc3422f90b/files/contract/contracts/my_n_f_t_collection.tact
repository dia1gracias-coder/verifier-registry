import "@stdlib/deploy";

// TEP-62: Transfer message (Opcode 0x5fcc3d14)
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

// TEP-62: Ownership Assigned notification (Opcode 0x05138d91)
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

// TEP-62: Excesses (Opcode 0xd53276db)
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}

// TEP-62: Get Static Data (Opcode 0x2fcb26a2)
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}

// TEP-62: Report Static Data (Opcode 0x8b771735)
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

message Mint {
    query_id: Int as uint64;
    metadata_index: Int as uint16;
    item_owner: Address;
    item_content: Cell;
}

message NftItemDeploy {
    query_id: Int as uint64;
    item_owner: Address;
    item_content: Cell;
}

message SetAgentMinter {
    query_id: Int as uint64;
    agent: Address;
    enabled: Bool;
}

const MINT_PRICE: Int = ton("0.5");
const ITEM_DEPLOY_VALUE: Int = ton("0.03");
const OWNER_PAYOUT: Int = ton("0.44");
const MAX_SUPPLY: Int = 500;

contract MyNFTCollection with Deployable {
    // Sequential on-chain item index required for TEP-62 collection compatibility.
    // "Random mint" is implemented via unique metadata_index assignment instead.
    next_item_index: Int as uint64;
    owner: Address;
    collection_content: Cell;
    // agent_minters is reserved for future off-chain bot integrations.
    // The current Mint handler is fully permissionless — any wallet can mint
    // by sending the correct fee. Agents have no special on-chain mint privilege.
    agent_minters: map<Address, Bool>;
    minted_metadata: map<Int, Bool>;

    init(owner: Address, collection_content: Cell) {
        self.next_item_index = 0;
        self.owner = owner;
        self.collection_content = collection_content;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.value >= MINT_PRICE, "Insufficient mint fee: 0.5 TON required");
        require(self.next_item_index < MAX_SUPPLY, "Collection sold out");
        require(msg.metadata_index >= 1 && msg.metadata_index <= MAX_SUPPLY, "Invalid metadata index");
        require(!self.minted_metadata.exists(msg.metadata_index), "Metadata already minted");

        let item_index: Int = self.next_item_index;
        let nft_init: StateInit = initOf MyNFTItem(myAddress(), item_index);

        self.minted_metadata.set(msg.metadata_index, true);
        self.next_item_index = self.next_item_index + 1;

        // Deterministic split: fund item deployment, pay owner the post-cost mint proceeds,
        // and leave a small fee buffer in the collection so public mints stay reliable.
        send(SendParameters{
            to: contractAddress(nft_init),
            value: ITEM_DEPLOY_VALUE,
            bounce: false,
            code: nft_init.code,
            data: nft_init.data,
            body: NftItemDeploy{
                query_id: msg.query_id,
                item_owner: msg.item_owner,
                item_content: msg.item_content
            }.toCell()
        });

        send(SendParameters{
            to: self.owner,
            value: OWNER_PAYOUT,
            mode: SendPayFwdFeesSeparately,
            bounce: false
        });
    }

    receive(msg: SetAgentMinter) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner can manage agents");

        if (msg.enabled) {
            self.agent_minters.set(msg.agent, true);
        } else {
            self.agent_minters.del(msg.agent);
        }
    }

    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index: self.next_item_index,
            collection_content: self.collection_content,
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        let nft_init: StateInit = initOf MyNFTItem(myAddress(), index);
        return contractAddress(nft_init);
    }

    // Returns individual_content as-is because each NFT already stores its full
    // IPFS URI (TEP-62 off-chain format: 0x01 prefix + URI string). The collection
    // does not need to prepend a base URI.
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }

    get fun is_agent_minter(agent: Address): Bool {
        return self.agent_minters.exists(agent);
    }

    get fun is_metadata_minted(metadata_index: Int): Bool {
        return self.minted_metadata.exists(metadata_index);
    }

    get fun get_mint_price(): Int {
        return MINT_PRICE;
    }

    get fun get_max_supply(): Int {
        return MAX_SUPPLY;
    }
}

contract MyNFTItem {
    collection_address: Address;
    index: Int as uint256;
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool;

    init(collection_address: Address, index: Int) {
        self.collection_address = collection_address;
        self.index = index;
        self.owner = collection_address;
        self.individual_content = emptyCell();
        self.is_initialized = false;
    }

    // Empty receive handler accepts plain TON transfers.
    // NFT items hold a small TON reserve for future transfer gas costs.
    // Any TON above the minimum storage fee sits in the item contract.
    receive() {}

    receive(msg: NftItemDeploy) {
        let ctx: Context = context();
        require(ctx.sender == self.collection_address, "Only collection can deploy item");
        require(!self.is_initialized, "NFT already initialized");

        self.owner = msg.item_owner;
        self.individual_content = msg.item_content;
        self.is_initialized = true;
    }

    receive(msg: Transfer) {
        let ctx: Context = context();
        require(self.is_initialized, "NFT not initialized");
        require(ctx.sender == self.owner, "Invalid sender");

        let prev_owner: Address = self.owner;
        self.owner = msg.new_owner;

        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendPayGasSeparately,
                body: OwnershipAssigned{
                    query_id: msg.query_id,
                    prev_owner: prev_owner,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        send(SendParameters{
            to: msg.response_destination,
            value: 0,
            mode: SendRemainingValue,
            body: Excesses{ query_id: msg.query_id }.toCell()
        });
    }

    receive(msg: GetStaticData) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: ReportStaticData{
                query_id: msg.query_id,
                index: self.index,
                collection: self.collection_address
            }.toCell()
        });
    }

    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.is_initialized,
            index: self.index,
            collection_address: self.collection_address,
            owner_address: self.owner,
            individual_content: self.individual_content
        };
    }
}

struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}

struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}
