import "./message.tact";
const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

contract Certificate {
    override const storageReserve: Int = minTonsForStorage;
    collection_address: Address;
    item_index: Int;
    is_initialized: Bool;
    owner: Address?;
    individual_content: Cell?;
    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false; 
    }

    receive(msg: GetStaticData){
        let ctx: Context = context();
        send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: SendRemainingValue,
                bounce: true,
                body: ReportStaticData{
                    query_id: msg.query_id,
                    index_id: self.item_index,
                    collection: self.collection_address
                }.toCell()
            }
        );
    }

    receive(msg: Transfer){
        require(sender() == self.collection_address, "certificate couldn't be transfered");
        self.is_initialized = true;
        self.owner = msg.new_owner;
        self.individual_content = msg.custom_payload;
    }

    // --------- Get Function  --------- //

    get fun get_nft_data(): GetNftData {
        return
            GetNftData{
                is_initialized: self.is_initialized,
                index: self.item_index,
                collection_address: self.collection_address,
                owner_address: self.owner!!,
                individual_content: self.individual_content!!
            };
    }

    get fun get_balance(): Int {
        return myBalance();
    }
}