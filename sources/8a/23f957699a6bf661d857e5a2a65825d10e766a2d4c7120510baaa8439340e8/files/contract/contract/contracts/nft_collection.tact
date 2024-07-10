import "@stdlib/deploy";
import "./nft_item";

message Mint {
    query_id: Int as uint64;
    item_index: Int as uint32;
    item_owner: Address;
    item_content: Cell;
}

struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}

contract NftCollection with Deployable {
    const minTonsForStorage: Int = ton("0.03");
    const gasConsumption: Int = ton("0.03");

    next_item_index: Int as uint32 = 0;
    collection_content: Cell;
    owner_address: Address;

    init(collection_content: Cell, owner_address: Address) {
        self.collection_content = collection_content;
        self.owner_address = owner_address;
        self.next_item_index = 0;
    }

    receive(msg: Mint) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue -= (storageFee + self.gasConsumption);

        require(msgValue >= 0, "Insufficient funds");

        let nft_init: StateInit = self.getNftItemInit(msg.item_index);
        let nft_address: Address = contractAddress(nft_init);
        
        send(SendParameters{
            to: nft_address,
            value: msgValue,
            mode: SendIgnoreErrors,
            bounce: false,
            code: nft_init.code,
            data: nft_init.data,
            body: Transfer{
                query_id: msg.query_id,
                new_owner: msg.item_owner,
                response_destination: ctx.sender,
                custom_payload: emptyCell(),
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });

        self.next_item_index += 1;
    }

    receive("Mint") {
        let ctx: Context = context();
        self.mint(ctx.sender);
    }

    fun mint(sender: Address) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        msgValue -= (storageFee + self.gasConsumption);

        require(msgValue >= 0, "Insufficient funds");

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let nft_address: Address = contractAddress(nft_init);
        send(SendParameters{
            to: nft_address,
            value: msgValue,
            mode: SendIgnoreErrors,
            bounce: false,
            code: nft_init.code,
            data: nft_init.data,
            body: Transfer{
                query_id: 0,
                new_owner: sender,
                response_destination: myAddress(),
                custom_payload: emptyCell(),
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });

        self.next_item_index += 1;
    }

    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index: self.next_item_index,
            collection_content: self.collection_content,
            owner_address: self.owner_address
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        let individual_content: Cell = self.get_nft_content(item_index, emptyCell());
        return initOf NftItem(myAddress(), item_index, myAddress(), individual_content);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        b.append("https://auroradev.io/");
        b.append("nft_item_");
        b.append(index.toString());
        b.append(".json");
        
        return beginCell()
        .storeUint(1, 8)
        .storeRef(b.toCell())
        .endCell();
    }

    receive("Bounce") {
        // Handle bounced messages
    }
}