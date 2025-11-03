// contracts/nft_item.tact
import "@stdlib/deploy";

// --- Standard TEP-62 & TEP-64 Messages ---

message NftTransfer {
    query_id: Int;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int;
    forward_payload: Cell?;
}

message NftTransferNotification {
    query_id: Int;
    forward_amount: Int;
    forward_payload: Cell?;
}

message GetStaticData {
    query_id: Int;
}

message ReportStaticData {
    query_id: Int;
    index: Int;
    collection: Address;
}

//
// THIS IS THE FIX: Define a struct for the return data
//
struct NftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell?;
}

// --- Contract ---

contract NftItem {

    // --- Storage ---

    collection: Address; // Address of the parent collection
    index: Int;          // Item's index (0, 1, 2...)
    owner: Address;      // Current owner of this NFT
    content: Cell?;      // Individual content (if any)

    init(collection: Address, index: Int, owner: Address, content: Cell?) {
        self.collection = collection;
        self.index = index;
        self.owner = owner;
        self.content = content;
    }

    // --- Message Handlers ---

    receive() {
        // Forward the remaining value in the
        // incoming message back to the sender
        // cashback(sender());
    }

    // Standard transfer function
    receive(msg: NftTransfer) {
        // 1. Require the sender is the current owner
        require(context().sender == self.owner, "Not the owner");

        // 2. Send "ownership assigned" notification to new owner
        send(SendParameters{
            to: msg.new_owner,
            value: msg.forward_amount,
            mode: SendIgnoreErrors,
            body: NftTransferNotification{
                query_id: msg.query_id,
                forward_amount: 0,
                forward_payload: msg.forward_payload
            }.toCell()
        });
        
        // 3. Send response back to the original owner
        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: 0, // Send remaining value
                mode: SendRemainingValue | SendIgnoreErrors
            });
        }
        
        // 4. Update the owner
        self.owner = msg.new_owner;
    }

    // --- Get Methods (Standard TEP-62) ---

    //
    // THIS IS THE SECOND PART OF THE FIX
    //
    get fun get_nft_data(): NftData { // <-- 1. Return the struct
        return NftData{              // <-- 2. Create and return an instance of the struct
            is_initialized: true,
            index: self.index,
            collection_address: self.collection,
            owner_address: self.owner,
            individual_content: self.content
        };
    }
}