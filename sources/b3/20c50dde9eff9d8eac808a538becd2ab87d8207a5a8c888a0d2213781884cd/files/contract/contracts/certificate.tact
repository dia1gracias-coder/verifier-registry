contract NftItem {
    collection_address: Address;
    item_index: Int; 

    owner: Address?;
    individual_content: Cell?;

    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
    }

    receive(msg: Transfer){
        let ctx: Context = context(); 
        let msgValue: Int = self.msgValue(ctx.value);
        
        require(ctx.sender == self.collection_address, "certificate couldn't be transfered");
        self.owner = msg.new_owner;
        self.individual_content = msg.custom_payload;
        send(SendParameters{ // TODO: check need i this or not
            to: msg.response_destination!!,
            value: msgValue,
            mode: SendPayGasSeparately,
            body: Excesses { query_id: msg.query_id }.toCell()
        });
    }
    
    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        b.append(self.item_index.toString());
        b.append(".json");

        return GetNftData {
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }
}