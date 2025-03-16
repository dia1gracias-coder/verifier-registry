import "@stdlib/deploy";
import "@stdlib/ownable";
import "./nft_item.tact";
import "./messages.tact";

contract SounrigCollectionMaker with Deployable, Ownable {
    const minTonForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");

    newAddress: Address; /// TODO: make the initial value of this zero

    owner: Address;
    next_item_index: Int as uint32 = 0;
    collection_content: String;
    id: Int;
    supply: Int;

    init(id: Int, collection_name: String, collection_supply: Int) {
        self.owner = sender();
        self.collection_content = "SoundRig NFT Collection";   
        //self.collection_content = collection_name;
        self.id = id;
        self.supply = collection_supply;
        self.newAddress = sender(); //TODO: remove this and find better solution to make newAddress zero
    }

    // receive("Mint"){
    //     self.requireOwner();   //TO-DO: rermove this so anyone can mint
    //     self.mint(sender());
    // }

    receive(msg: Mint){
        self.requireOwner();   //TO-DO: rermove this so anyone can mint
        self.mint(msg.mintAddress);
    }

    fun mint(receiver: Address) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let msgValue: Int = context().value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonForStorage - min(tonBalanceBeforeMsg, self.minTonForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);

        send(SendParameters{
            to: contractAddress(nft_init),
            value: msgValue,
            mode: SendIgnoreErrors,
            bounce: false,
            body: Transfer{
                query_id: 0,
                new_owner: receiver
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });
        self.next_item_index = self.next_item_index + 1;
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        let b: StringBuilder = beginString();
        b.append("Item # - ");
        b.append(item_index.toString());

        return initOf NftItem(self.owner, myAddress(), item_index, b.toString());
    }

    get fun get_nft_address_by_index(item_index: Int): Address {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index: self.next_item_index,
            collection_content: self.collection_content.asSlice().asCell(),
            owner_address: self.owner
        };
    }

    receive("Create") {
        let init: StateInit = initOf SounrigCollectionMaker(1, "Michaelzy", 5);
        self.newAddress = contractAddress(init);

        //TO-DO: id (1 above) should be incremented automatically before it is passed to SoundrigCollectionMaker
        

        send(SendParameters{
            to: self.newAddress,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: true,
            code: init.code,
            data: init.data,
            body: Deploy{queryId: 0}.toCell()
        });
    }

    get fun myAddress(): Address {
        return myAddress();
    }

    get fun newAddress(): Address {
        return self.newAddress;
    }

    get fun Okowner(): Address {
        return self.owner;
    }
}