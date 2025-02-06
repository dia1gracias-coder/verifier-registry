import "@stdlib/deploy";
import "@stdlib/ownable";
import "./main_item.tact";
import "./main_messages.tact";

contract MainContract with Deployable, Ownable {
    const minTonForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");
    owner: Address;
    next_item_index: Int as uint32 = 0;
    collection_content: String;
    isPaused: Bool;
    init(){
        self.owner = sender();
        self.collection_content = "TON App NFT Collection";
        self.isPaused = false;
    }

    receive("Mint"){
        require(!self.isPaused, "Minting has Stopped");
        self.mint(sender());
    }

    fun mint(receiver: Address) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNFTItemInit(self.next_item_index);
        let msgValue: Int = context().value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonForStorage - min(tonBalanceBeforeMsg, self.minTonForStorage);
        msgValue = msgValue - (storageFee + self.gasConsumption);
        send(SendParameters{
                to: contractAddress(nft_init),
                value: msgValue,
                mode: SendIgnoreErrors,
                bounce: false,
                body: Transfer{query_id: 0, new_owner: receiver}.toCell(),
                code: nft_init.code,
                data: nft_init.data
            }
        );
        self.next_item_index = self.next_item_index + 1;
    }

    get fun getNFTItemInit(item_index: Int): StateInit {
        let data: StringBuilder = beginString();
        data.append("TON App NFT #");
        data.append(item_index.toString());
        return initOf MainItem(self.owner, myAddress(), item_index, data.toString());
    }

    get fun get_collection_data(): CollectionData {
        return
            CollectionData{
                next_item_index: self.next_item_index,
                collection_content: self.collection_content.asSlice().asCell(),
                owner_address: self.owner
            };
    }
}