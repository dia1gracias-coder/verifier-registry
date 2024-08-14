import "@stdlib/deploy";
import "./messages.tact";

contract NftItem with Deployable {
    collection_address: Address;
    item_index: Int as uint256; 
    is_initialized: Int;
    individual_content: Cell?;
    owner: Address?;

    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = 0;
    }

	receive() {}

	receive(msg: Mint) {
        require(sender() == self.collection_address, "only from collection");

		let content_storage: String = msg.content_storage.asSlice().asString();
		let b: StringBuilder = beginString();
		b.append(content_storage);
        b.append(self.item_index.toString());
        b.append(".json");

		self.owner = msg.owner;
		self.individual_content = b.toCell();
		self.is_initialized = 1;
	}

    receive(msg: Transfer){
		require(sender() == self.owner, "Access denied. Not owner.");
        let msgValue: Int = context().value;
		let ctx: Context = context();

		self.owner = msg.new_owner;

        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode:  SendPayGasSeparately, 
                bounce: true,
                body: OwnershipAssigned{
                    query_id: msg.query_id,
                    prev_owner: sender(),
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        msgValue = msgValue - ctx.readForwardFee();

        if (msg.response_destination != null) { 
            send(SendParameters{ 
                to: msg.response_destination!!,
                value: msgValue - msg.forward_amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        }
    }

    receive(msg: GetStaticData){
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
		return GetNftData {
			init: 1,
			index: self.item_index,
			collection_address: self.collection_address,
			owner_address: self.owner!!,
			individual_content: self.individual_content!!
		};
    }
}