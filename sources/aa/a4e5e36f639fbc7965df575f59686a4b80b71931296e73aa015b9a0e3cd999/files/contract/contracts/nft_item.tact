import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
    const minTonsForStorage: Int = ton("0.02");
    const gasConsumption: Int = ton("0.02");
contract NftItem with Ownable, Deployable {



    owner: Address;
    collection_address: Address;
    item_index: Int;
    individual_content: Cell?;
    is_initialized: Bool;

    init(
        owner: Address,
        collection_address: Address,
        item_index: Int,
        individual_content: Cell?
    ) {
        self.owner = owner;
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.individual_content = individual_content;
        self.is_initialized = false;
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    receive(msg: Transfer){
        let ctx: Context = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context
        let msgValue: Int = self.msgValue(ctx.value);

        // if (msg.forward_payload != null() || msg.forward_amount > 0) {
        //     send(SendParameters{
        //         to: self.owner,
        //         value: msg.forward_amount,   // вот здесь используем forward_amount
        //         bounce: false,
        //         body: (msg.forward_payload ?? beginCell().endCell()) // пустая ячейка если null
        //     });
        // }
    
        let payload: Cell = beginCell().endCell();
        if (msg.forward_payload != null) {
            payload = msg.forward_payload!!;
        }

        // если нужно, отправляем что-то новому владельцу с forward_amount
        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                bounce: false,
                body: payload
            });
        }

        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = "MY NFT".asSlice().asCell();
            send(SendParameters{
                to: msg.new_owner,
                value: msgValue,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        }
    }

    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.is_initialized ? -1 : 0,
            index: self.item_index,
            collection_address: self.collection_address,
            owner_address: self.owner,
            individual_content: self.individual_content!!
        };
    }
  
    //  get fun get_nft_data(): GetNftData {
    //     let b: StringBuilder = beginString();
    //     let collectionData: String = (self.individual_content!!).asSlice().asString();
    //     b.append(collectionData);
    //     b.append(self.item_index.toString());
    //     b.append(".json");

    //     return GetNftData {
    //         is_initialized: self.is_initialized, 
    //         index: self.item_index, 
    //         collection_address: self.collection_address, 
    //         owner_address: self.owner,
    //         individual_content: b.toCell()
    //     };
    // }
   
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }
}
