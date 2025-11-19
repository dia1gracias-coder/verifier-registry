import "@stdlib/content";
import "./Errors.tact";

// ===== Messages =====
message(0x5fcc3d14) NFTTransfer {
    queryId: Int as uint64;
    newOwner: Address; // Address of the new owner of the NFT item.
    responseDestination: Address; // Address to send a response confirming a successful transfer and the remaining incoming message coins.
    customPayload: Cell? = null; // Optional custom data. In most cases, this should be null.
    forwardAmount: Int as coins; // The amount of nanotons to be sent to the new owner.
    forwardPayload: Slice as remaining; // Optional custom data that should be sent to the new owner.
}
message(0xca9e378a) BurnFromCollection {}

// ===== Structs =====
struct NftData {
    init: Int;
    index: Int;
    collection_address: Slice;
    owner_address: Slice;
    individual_content: Cell;
}    

contract PartnerNftItem {

    // ==== Storage ====
    collection: Address;       // address of PartnerNftCollection
    owner: Address?;           // owner address, null if burned
    index: Int;      // index in collection
    content: Cell;             // individual content (uri as comment cell)
    shareBps: Int;   // 0..10000
    // successfulTxCount will be stored in collection (as you have now), to avoid going to item

    // ==== Error codes ====
    const ExitCodeNonTransferable: Int = 1001;

    // ==== Init ====
    init(
        collection: Address,
        owner: Address,
        index: Int,
        uri: String,
        shareBps: Int
    ) {
        self.collection = collection;
        self.owner = owner;
        self.index = index;
        self.content = createOffchainContent(uri);
        self.shareBps = shareBps;
    }

    // ==== Internal helpers ====
    inline fun onlyCollection() {
        throwIf(NotOwner, sender() != self.collection);
    }    
    
    // ==== Receives ====
    receive() { 
        // default receive handler to accept plain TONs transfers
    }

    receive(msg: NFTTransfer) { 
        throw(self.ExitCodeNonTransferable); // Non-transferable NFT error code
    }

    // Signal from collection to burn (if you want to actually destroy the contract)
    receive(msg: BurnFromCollection) {
        self.onlyCollection();
        // Either just mark as uninitialized:
        self.owner = null;
        // Or completely shut down the contract:
        //selfdestruct(self.collection);
    }

    // ==== TEP-62 mandatory get-method ====
    get fun get_nft_data(): NftData {
        let initFlag: Int = self.owner == null ? 0 : 1;
        let ownerSlice: Slice = self.owner == null
            ? newAddress(0, 0).asSlice()
            : self.owner!!.asSlice();

        return NftData{
            init: initFlag,
            index: self.index,
            collection_address: self.collection.asSlice(),
            owner_address: ownerSlice,
            individual_content: self.content
        };
    }

    // ==== Additional getters ====
    get fun get_share_bps(): Int {
        return self.shareBps;
    }

    get fun get_owner(): Address? {
        return self.owner;
    }

    get fun get_index(): Int {
        return self.index;
    }

    get fun get_content(): Cell {
        return self.content;
    }
}
