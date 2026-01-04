import "@stdlib/deploy";
import "./messages";

// NFT Item smart contract
contract NftItem with Deployable {
    collection_address: Address;
    item_index: Int;
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool = false;

    init(collection_address: Address, item_index: Int, owner: Address, individual_content: Cell) {
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = owner;
        self.individual_content = individual_content;
    }

    // ===== Receivers ===== //

    // Transfer NFT to new owner
    receive(msg: Transfer) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        
        // Check if the sender is the owner OR if this is initial mint from collection
        let sender: Address = ctx.sender;
        
        // Allow transfer if:
        // 1. Sender is the current owner (normal transfer)
        // 2. Sender is the collection (initial mint)
        // 3. NFT is not initialized yet (first transfer)
        require(
            sender == self.owner || 
            sender == self.collection_address || 
            !self.is_initialized, 
            "Only owner can transfer"
        );
        
        // Gas checks
        require(msgValue >= ton("0.05"), "Insufficient funds for transfer");
        
        // Update owner
        self.owner = msg.new_owner;
        
        // ✅ NEW: Handle custom_payload for individual metadata
        // If this is from collection (first transfer) and custom_payload is provided,
        // use it as the individual_content
        if (sender == self.collection_address && msg.custom_payload != null) {
            self.individual_content = msg.custom_payload!!;
        }
        
        // Mark as initialized after first transfer
        if (!self.is_initialized) {
            self.is_initialized = true;
        }
        
        // Send notification to new owner
        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: OwnershipAssigned{
                    query_id: msg.query_id,
                    prev_owner: sender,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }
        
        // Send excess back to sender
        let restAmount: Int = msgValue - ton("0.05") - msg.forward_amount;
        if (restAmount > 0) {
            send(SendParameters{
                to: msg.response_destination,
                value: restAmount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: Excesses{
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }

    // Get static data
    receive(msg: GetStaticData) {
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportStaticData{
                query_id: msg.query_id,
                index: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    // Update individual content (only from collection)
    receive(msg: UpdateNftContent) {
        let ctx: Context = context();
        require(ctx.sender == self.collection_address, "Only collection can update content");
        self.individual_content = msg.individual_content;
    }

    // Burn NFT (self-destruct)
    receive(msg: BurnNft) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.collection_address, "Only owner or collection can burn");
        
        // Send remaining balance to owner
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance + SendDestroyIfZero,
            bounce: false,
            body: NftBurned{
                query_id: msg.query_id
            }.toCell()
        });
    }

    // ===== Get Methods ===== //
    
    get fun get_nft_data(): NftData {
        return NftData{
            is_initialized: self.is_initialized,
            index: self.item_index,
            collection_address: self.collection_address,
            owner_address: self.owner,
            individual_content: self.individual_content
        };
    }

    get fun get_owner(): Address {
        return self.owner;
    }

    get fun get_collection_address(): Address {
        return self.collection_address;
    }

    get fun get_item_index(): Int {
        return self.item_index;
    }

    get fun get_individual_content(): Cell {
        return self.individual_content;
    }

    // TEP-64 compliant: Return individual NFT metadata
    // If individual_content is set, return it directly
    // This allows custom metadata URLs per NFT
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        // If NFT is initialized, check if we have custom metadata
        if (self.is_initialized) {
            let slice: Slice = self.individual_content.beginParse();
            // Check if individual_content has the 0x01 prefix (offchain content)
            if (slice.bits() > 8) {
                let maybePrefix: Int = slice.preloadUint(8);
                if (maybePrefix == 1) {
                    // This is offchain content with custom URL, return as-is
                    return self.individual_content;
                }
            }
        }
        
        // Fallback: return the provided individual_content parameter
        // (This maintains compatibility with collection-based metadata)
        return individual_content;
    }
}
