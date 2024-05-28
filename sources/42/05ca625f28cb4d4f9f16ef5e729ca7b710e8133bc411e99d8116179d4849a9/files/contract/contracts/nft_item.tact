import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";

contract NftItem with Deployable, Ownable {
    id: Int as uint256;
    owner: Address;                    

    minTonsForStorage: Int as coins;
    gasConsumption: Int as coins; 

    collection_address: Address;
    is_initialized: Bool;

    individual_content: String;
    ton_site: String = "";
    expiration_date: Int;

    init(id: Int, collection_address: Address){
        require(sender() == collection_address, "not from collection");
        self.id = id;
        self.owner = sender();

        self.minTonsForStorage = ton("0.02");
        self.gasConsumption = ton("0.02");

        self.collection_address = collection_address;
        self.is_initialized = false;

        self.individual_content = "item_";
        self.expiration_date = now() + (365 * 24 * 3600);
    }

    receive(msg: ItemAddYear){
        self.requireCollection();
        require(msg.from == self.owner, "Item: Not the owner to add 1 year");
        self.expiration_date += 365 * 24 * 3600;
    }

    receive(msg: Mint) {
        //dump("se recibio el min");
        self.requireCollection();
        //dump("paso la validacion del owner = collection");
        self.owner = msg.new_owner;
        self.ton_site = msg.ton_site;
        self.is_initialized =  true;
        //dump("finalizo el mint");
    }

    receive(msg: Transfer){
        self.requireCollection();

        require(self.is_initialized == true, "Not active yet");
        self.owner = msg.new_owner;

        send(SendParameters{
            to: msg.new_owner,
            value: self.calcMsgValue(context().value),
            mode:  SendIgnoreErrors, 
            bounce: false,
            body: emptyCell()
        }); 
    }
    
    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.id,
                collection: self.collection_address
            }.toCell()
        });
    }

    fun requireCollection() {
        require(sender() == self.collection_address, "Access Denied!");
    }

    fun calcMsgValue(val: Int): Int{
        let tonBalanceBeforeMsg: Int = myBalance() - val;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        return val - (storageFee + self.gasConsumption);
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        b.append(self.individual_content);
        b.append(self.id.toString());
        b.append(".json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.id, 
            collection_address: self.collection_address, 
            owner_address: self.owner,
            individual_content: b.toCell()
        };
    }

    get fun get_full_nft_data(): GetFullNftData {
        let b: StringBuilder = beginString();
        b.append(self.individual_content);
        b.append(self.id.toString());
        b.append(".json");

        return GetFullNftData {
            is_initialized: self.is_initialized, 
            index: self.id, 
            collection_address: self.collection_address, 
            owner_address: self.owner,
            individual_content: b.toString(),
            tonsite: self.ton_site,
            expiration_date: self.expiration_date
        };
    }
}