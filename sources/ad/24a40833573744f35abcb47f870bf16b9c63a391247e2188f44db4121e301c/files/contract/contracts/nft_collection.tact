import "@stdlib/deploy";
import "./costs.tact";
import "./messages.tact";
import "./nft_item";

contract NftCollection with Deployable, Ownable, Costs {
    id: Int as uint32;
    owner: Address;                    
    wd_idx: Int as uint256 = 0;
    next_item: Int as uint256 = 0;

    minTonsForStorage: Int as coins;
    gasConsumption: Int as coins; 
    myValue: Int as coins;
    
    collection_content: Cell;   

    init(id: Int, collection_content: Cell){
        self.id = id;
        self.owner= sender();
        self.collection_content = collection_content; 

        self.minTonsForStorage = ton("0.02");
        self.gasConsumption = ton("0.02");
        self.myValue = ton("10");
    }

    receive() {
        self.requireOwner();
    }

    receive(msg: WithdrawSafe) {
        self.requireOwner();

        send(SendParameters{
            to: self.owner,
            value: myBalance() - self.minTonsForStorage, 
            bounce: true,
            mode: SendIgnoreErrors,
            body: emptyCell()
        });
    }

    receive(msg: AddYear) {
        let msgValue: Int = self.calcMsgValue(context().value);

        if(msgValue >= self.myValue) {
            let nft_init: StateInit = self.getNftItemInit(msg.item_id);

            send(SendParameters{
                to: contractAddress(nft_init),
                value: self.minTonsForStorage + self.gasConsumption, 
                bounce: false,
                mode: SendIgnoreErrors,
                body: ItemAddYear {
                    from: sender(),
                    item_id: msg.item_id
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        } else {
            send(SendParameters{
                to: sender(),
                value: 0, 
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: "Invalid Amount".asComment()
            });

        }
    }

    receive(msg: String){
        let msgValue: Int = self.calcMsgValue(context().value);

        if(msgValue >= self.myValue) {
            //dump("el valor es correcto");
            let nft_init: StateInit = self.getNftItemInit(self.next_item);

            send(SendParameters{
                to: contractAddress(nft_init),
                value: self.minTonsForStorage + self.gasConsumption, 
                bounce: true,
                mode: SendBounceIfActionFail,
                body: Mint {
                    new_owner: sender(),
                    ton_site: msg
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });

            self.next_item += 1;
        } else {
            send(SendParameters{
                to: sender(),
                value: 0, 
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors,
                body: "Invalid Amount". asComment()
            });
        }
    }

    bounced(src: bounced<Mint>) {
        throw(sha256("Collection: error trying to mint"));
    }

    fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(item_index, myAddress());
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("collection.json");

        return CollectionData{
            next_item_index: self.next_item, 
            collection_content: b.toCell(), 
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let collectionDataString: String = self.collection_content.asSlice().asString();
        let ic: String = individual_content.asSlice().asString();

        let b: StringBuilder = beginString();
        b.append(collectionDataString);
        b.append(ic);
        
        return b.toCell();
    }

    get fun get_next_item(): Int{
        return self.next_item;
    }
    
    get fun get_value(): Int{
        return self.myValue;
    }
}