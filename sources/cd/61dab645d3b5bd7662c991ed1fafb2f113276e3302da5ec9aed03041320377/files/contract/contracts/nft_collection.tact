// contracts/nft_collection.tact
import "@stdlib/deploy";
import "@stdlib/ownable";
import "./nft_item.tact";

// --- Custom Messages ---

// --- Op-Codes ---
const mint_pack: Int = 0x1;    // You can use a simple number
const airdrop_pack: Int = 0x2; // Or a hash: op("AirdropPack")
const withdraw: Int = 0x3;     // op("Withdraw")

message(mint_pack) MintPack {
}

message(airdrop_pack) AirdropPack {
    to_address: Address;
}

message(withdraw) Withdraw {
}

struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}

// --- Contract ---

contract NftCollection with Ownable {

    // --- Storage ---
    
    owner: Address;             // Collection owner
    next_item_index: Int;       // Counter for the next NFT
    collection_content: Cell;   // Cell with IPFS URL to collection.json
    // self.nft_item_code HAS BEEN REMOVED - it's not needed
    royalty_params: Cell;       // Royalty data
    is_testnet: Bool;           // Flag for testnet/mainnet pricing

    // --- Pricing ---

    const MAINNET_PRICE: Int = ton("5");    // 5 TON
    const TESTNET_PRICE: Int = ton("0.1");  // 0.1 TON
    const GAS_FEE: Int = ton("0.5");        // Gas and deployment fee buffer (0.05 per NFT)

    init(
        owner: Address, 
        collection_content: Cell, 
        royalty_params: Cell, 
        is_testnet: Bool
    ) {
        self.owner = owner;
        self.next_item_index = 0;
        self.collection_content = collection_content;
        self.royalty_params = royalty_params;
        self.is_testnet = is_testnet;
        //self.initOwner(owner); // Initialize Ownable trait
        // self.nft_item_code line is gone
    }

    receive() {
        // Forward the remaining value in the
        // incoming message back to the sender
        cashback(sender());
    }

    // --- Public Mint Function ---

    receive(msg: MintPack) {
        let sender = context().sender; // Removed '!!'
        let value = context().value;
        
        // 1. Determine the correct price
        let price = self.is_testnet ? self.TESTNET_PRICE : self.MAINNET_PRICE;
        let required_value = price + self.GAS_FEE;

        // 2. Check if enough TON was sent
        require(value >= required_value, "Not enough TON sent for a 10-pack");

        // 3. Mint and deploy 10 NFTs in a loop
        let i = 0;
        repeat(10) {
            self.deployNft(sender, null); // Deploy NFT, ownership to 'sender'
            i = i + 1;
        }

        // 4. Send any remaining change back to the minter
        send(SendParameters{
            to: sender,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors
        });
    }

    // --- Owner Airdrop Function ---

    receive(msg: AirdropPack) {
        self.requireOwner();
        require(context().value >= self.GAS_FEE, "Not enough TON for gas fees");
        let i = 0;
        repeat(10) {
            self.deployNft(msg.to_address, null); // Deploy NFT, ownership to 'to_address'
            i = i + 1;
        }
    }

    // --- Owner Withdraw Function ---

    receive(msg: Withdraw) {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors
        });
    }

    // --- Internal Deploy Function ---

    fun deployNft(owner: Address, content: Cell?) {
        let index = self.next_item_index;
        
        //
        // THIS IS THE FIX
        //
        // 'initOf' takes the contract and its init args,
        // and returns the complete StateInit
        let item_init = initOf NftItem(
            myAddress(), // Link to this collection
            index,
            owner,
            content      // You can pass custom content here if needed
        );
        
        // Get the future address of the NFT
        let item_address = contractAddress(item_init);

        // Send a message to that address to deploy it
        send(SendParameters{
            to: item_address,
            value: ton("0.05"), // Value to deploy the contract
            body: emptyCell(),
            code: item_init.code,
            data: item_init.data
        });

        // Increment the counter for the next mint
        self.next_item_index = index + 1;
    }

    // --- Get Methods (Standard TEP-62) ---

    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index: self.next_item_index,
            collection_content: self.collection_content,
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        //
        // THIS IS THE SECOND FIX
        //
        let init = initOf NftItem(
            myAddress(),
            index,
            self.owner, // Owner is temporary, will be set on deploy
            null
        );
        return contractAddress(init);
    }

    get fun get_royalty_params(): Cell {
        return self.royalty_params;
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        // Per TEP-64, collection_content cell should contain:
        // 1. Ref to collection.json metadata
        // 2. Ref to common content base URL (e.g., "ipfs://CID_FOLDER/")
        
        let cs = self.collection_content.beginParse(); 
        
        //
        // THIS IS THE FIX
        //
        let discarded_ref = cs.loadRef(); // <-- Removed the tilde (~)
        //
        //
        //
        
        let common_base_url_slice = cs.loadRef().asSlice(); // <-- Also removed the tilde (~)
        
        // Now we build the full URL: "ipfs://CID_FOLDER/1.json"
        let item_url_builder = beginCell()
            .storeSlice(common_base_url_slice)
            .storeSlice(index.toString().asSlice())
            .storeSlice(".json".asSlice());

        // And finally, we build the TEP-64 content cell:
        // [prefix (0x01)][ref_to_item_url_cell]
        let content_full = beginCell()
            .storeInt(0x01, 8) // Off-chain content prefix
            .storeRef(item_url_builder.endCell())
            .endCell();
            
        return content_full;
    }
}