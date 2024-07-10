import "@stdlib/deploy";
import "@stdlib/ownable";

message Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message GetStaticData {
    query_id: Int as uint64;
}

struct ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}

struct NftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}

contract NftItem with Deployable {
    const minTonsForStorage: Int = ton("0.05");
    const gasConsumption: Int = ton("0.05");

    collection_address: Address;
    item_index: Int;
    owner: Address;
    individual_content: Cell;

    init(collection_address: Address, item_index: Int, owner: Address, individual_content: Cell) {
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = owner;
        self.individual_content = individual_content;
    }

    receive(msg: Transfer) {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Invalid sender");

        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue -= (storageFee + self.gasConsumption);

        require(msgValue >= 0, "Insufficient funds");

        self.owner = msg.new_owner;

        // Update individual_content if custom_payload is provided
        if (msg.custom_payload != null) {
            self.individual_content = msg.custom_payload!!;
        }

        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: msg.forward_payload.asCell()
            });
        }

        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                bounce: false,
                body: "NFT transferred".asComment()
            });
        }
    }

    receive(msg: GetStaticData) {
        let ctx: Context = context();
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    get fun get_nft_data(): NftData {
        return NftData{
            is_initialized: true,
            index: self.item_index,
            collection_address: self.collection_address,
            owner_address: self.owner,
            individual_content: self.individual_content
        };
    }

    receive("Bounce") {
        // Handle bounced messages
    }
}