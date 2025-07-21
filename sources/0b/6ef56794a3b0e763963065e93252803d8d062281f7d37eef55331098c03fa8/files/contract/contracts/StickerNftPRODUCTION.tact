import "@stdlib/deploy";
import "@stdlib/ownable";

// ✅ TEP-62 COMPLIANT: Standard NFT Item Contract for GetGems
contract NftItem with Deployable {
    collection_address: Address;
    item_index: Int;
    owner: Address;
    individual_content: Cell;
    is_initialized: Bool;
    
    init(collection_address: Address, item_index: Int, individual_content: Cell) {
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = collection_address;
        self.individual_content = individual_content;
        self.is_initialized = false;
    }
    
    receive(msg: MintNft) {
        let ctx: Context = context();
        require(ctx.sender == self.collection_address, "Only collection can mint");
        require(!self.is_initialized, "Already minted");
        
        self.owner = msg.owner;
        self.individual_content = msg.content;
        self.is_initialized = true;
        
        // ✅ FIX: Better gas management for confirmation
        let min_gas_reserve: Int = ton("0.01");
        require(ctx.value >= min_gas_reserve, "Insufficient gas for mint");
        
        send(SendParameters{
            to: self.collection_address,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: MintConfirmation{
                query_id: msg.query_id,
                item_index: self.item_index
            }.toCell()
        });
    }

    receive(msg: Transfer) {
        let ctx: Context = context();
        
        require(ctx.sender == self.owner, "Only owner can transfer");
        require(self.is_initialized, "NFT not initialized");
        
        // ✅ FIX: More conservative gas calculations
        let storage_fee: Int = ton("0.05");
        let gas_consumption: Int = ton("0.02"); // Increased gas reserve
        let min_balance: Int = storage_fee + gas_consumption;
        
        // Check if we have enough to cover forward amount + fees
        require(ctx.value >= msg.forward_amount + min_balance, "Insufficient value for transfer");
        
        let prev_owner: Address = self.owner;
        self.owner = msg.new_owner;
        
        // Send ownership notification if requested
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
        
        // Send excess back to response destination
        if (msg.response_destination != newAddress(0, 0)) {
            send(SendParameters{
                to: msg.response_destination,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors,
                body: Excesses{
                    query_id: msg.query_id
                }.toCell()
            });
        }
    }
    
    receive(msg: GetStaticData) {
        send(SendParameters{
            to: context().sender,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: ReportStaticData{
                query_id: msg.query_id,
                index: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    receive(msg: GetRoyaltyParams) {
        send(SendParameters{
            to: context().sender,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: ReportRoyaltyParams{
                query_id: msg.query_id,
                numerator: 50,
                denominator: 1000,
                destination: self.collection_address
            }.toCell()
        });
    }

    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.is_initialized,
            index: self.item_index,
            collection_address: self.collection_address,
            owner_address: self.owner,
            individual_content: self.individual_content
        };
    }
}

contract NftCollection with Deployable, Ownable {
    owner: Address;
    next_item_index: Int as uint64;
    collection_content: Cell;
    nft_item_code: Cell;
    royalty_params: RoyaltyParams;
    
    mint_price: Int as coins;
    public_minting_enabled: Bool;
    pending_mints: map<Int as uint64, Address>;
    
    init(owner: Address, collection_content: Cell, nft_item_code: Cell, royalty_params: RoyaltyParams, mint_price: Int) {
        self.owner = owner;
        self.next_item_index = 0;
        self.collection_content = collection_content;
        self.nft_item_code = nft_item_code;
        self.royalty_params = royalty_params;
        self.mint_price = mint_price;
        self.public_minting_enabled = true;
        self.pending_mints = emptyMap();
    }
    
    receive(msg: OwnerMint) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Only owner can mint");
        
        // ✅ FIX: Ensure sufficient gas for minting operations
        let min_mint_gas: Int = ton("0.08");
        require(ctx.value >= min_mint_gas, "Insufficient gas for mint operation");
        
        self.performMint(msg.new_owner, msg.content, msg.query_id);
    }
    
    receive(msg: PublicMint) {
        let ctx: Context = context();
        require(self.public_minting_enabled, "Public minting disabled");
        require(ctx.value >= self.mint_price, "Insufficient payment");
        
        // ✅ FIX: Better gas management for public mints
        let mint_gas: Int = ton("0.08");
        let total_required: Int = self.mint_price + mint_gas;
        require(ctx.value >= total_required, "Insufficient value for minting");
        
        self.performMint(ctx.sender, msg.content, msg.query_id);
    }
    
    receive(msg: MintConfirmation) {
        // Clean up pending mints tracking
        self.pending_mints.set(msg.item_index, null);
    }
    
    receive(msg: WithdrawFunds) {
        require(context().sender == self.owner, "Only owner can withdraw");
        
        // ✅ FIX: Leave some balance for contract operations
        let reserve_balance: Int = ton("0.1");
        let available_balance: Int = myBalance() - reserve_balance;
        
        if (available_balance > 0) {
            send(SendParameters{
                to: self.owner,
                value: available_balance,
                mode: SendPayGasSeparately,
                body: "Collection withdrawal".asComment()
            });
        }
    }
    
    receive(msg: TogglePublicMinting) {
        require(context().sender == self.owner, "Only owner can toggle");
        self.public_minting_enabled = !self.public_minting_enabled;
    }
    
    receive(msg: SetMintPrice) {
        require(context().sender == self.owner, "Only owner can set price");
        self.mint_price = msg.new_price;
    }
    
    // ✅ FIX: Enhanced mint function with better error handling
    fun performMint(to: Address, content: Cell, query_id: Int) {
        let current_index: Int = self.next_item_index;
        
        let empty_content: Cell = beginCell().endCell();
        let nft_init: StateInit = initOf NftItem(myAddress(), current_index, empty_content);
        let nft_address: Address = contractAddress(nft_init);
        
        // Track pending mint
        self.pending_mints.set(current_index, to);
        
        // ✅ FIX: Increased gas for NFT deployment and initialization
        let deploy_gas: Int = ton("0.06");
        
        send(SendParameters{
            to: nft_address,
            value: deploy_gas,
            mode: SendPayGasSeparately, // Changed from SendIgnoreErrors
            bounce: true, // Enable bounce for better error handling
            data: nft_init.data,
            code: nft_init.code,
            body: MintNft{
                query_id: query_id,
                owner: to,
                content: content
            }.toCell()
        });
        
        self.next_item_index = self.next_item_index + 1;
        
        emit(MintEvent{
            to: to,
            item_index: current_index,
            nft_address: nft_address
        }.toCell());
    }
    
    // ✅ BOUNCED: Handle bounced messages from failed mints
    bounced(src: bounced<MintNft>) {
        // Reset the index if mint failed
        if (self.next_item_index > 0) {
            self.next_item_index = self.next_item_index - 1;
        }
        
        // Note: We can't access the original message fields in bounced messages
        // The pending_mints cleanup will happen via timeout or manual cleanup
    }
    
    // ✅ NEW: Manual cleanup function for pending mints
    receive(msg: CleanupPendingMints) {
        require(context().sender == self.owner, "Only owner can cleanup");
        
        // Clear all pending mints (simplified approach)
        self.pending_mints = emptyMap();
    }
    
    get fun get_collection_data(): GetCollectionData {
        return GetCollectionData{
            next_item_index: self.next_item_index,
            collection_content: self.collection_content,
            owner_address: self.owner
        };
    }
    
    get fun get_nft_address_by_index(item_index: Int): Address {
        require(item_index >= 0, "Invalid index");
        require(item_index < self.next_item_index, "Index out of range");
        
        let empty_content: Cell = beginCell().endCell();
        let nft_init: StateInit = initOf NftItem(myAddress(), item_index, empty_content);
        return contractAddress(nft_init);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }
    
    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params;
    }
    
    // ✅ NEW: Debug getter to check pending mints
    get fun get_pending_mints_count(): Int {
        // This would require iterating through the map in a real implementation
        return 0; // Placeholder - implement map counting if needed
    }
}

// Messages remain the same...
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}

message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

message(0xd53276db) Excesses {
    query_id: Int as uint64;
}

message OwnerMint {
    query_id: Int as uint64;
    new_owner: Address;
    content: Cell;
}

message(0x1) PublicMint {
    query_id: Int as uint64;
    content: Cell;
}

message MintNft {
    query_id: Int as uint64;
    owner: Address;
    content: Cell;
}

message MintConfirmation {
    query_id: Int as uint64;
    item_index: Int as uint64;
}

message MintEvent {
    to: Address;
    item_index: Int as uint64;
    nft_address: Address;
}

message WithdrawFunds {}

message TogglePublicMinting {}

message SetMintPrice {
    new_price: Int as coins;
}

message CleanupPendingMints {}

struct RoyaltyParams {
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

struct GetNftData {
    is_initialized: Bool;
    index: Int as uint256;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}

struct GetCollectionData {
    next_item_index: Int as uint64;
    collection_content: Cell;
    owner_address: Address;
}