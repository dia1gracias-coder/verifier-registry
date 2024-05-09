import "@stdlib/deploy";
import "@stdlib/ownable";
import "./nft_item.tact";
import "./messages.tact";

message Withdraw {
    amount: Int as coins;
}

contract NftCollection with Deployable, Ownable {
    const minTonForStorage: Int = ton("0.03"); // 1kb for 2,5 year
    const gasConsumption: Int = ton("0.03");
    const minTonForBuyNft: Int = ton("0.5");
    owner: Address;
    contracts: Address;
    next_item_index: Int as uint32 = 0;
    collection_content: String;
    arr: map<Int, Address>;

    init(){
        self.owner = sender();
        self.contracts = myAddress();
        self.collection_content = "Decepticon NFT Collection";
    }

    receive(){}

    receive("buynft"){
        require(context().value > ((self.minTonForBuyNft + self.minTonForStorage) + self.gasConsumption),
            "Not enough ton"
        );
        self.mint(sender());
    }

     fun mint(receiver: Address) {

        require(self.next_item_index >= 0, "non-sequential NFTs");

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let msgValue: Int = ton("0.1");
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

        self.arr.set(self.next_item_index, receiver);
        self.next_item_index = (self.next_item_index + 1);
    }

    receive(msg: Withdraw){
        self.requireOwner();
        let amount: Int = min(msg.amount, ((myBalance() - context().value) - self.minTonForStorage));
        require(amount > 0, "Insufficient balance");
        send(SendParameters{to: sender(), value: amount, mode: (SendIgnoreErrors + SendRemainingValue), bounce: true});
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        let b: StringBuilder = beginString();
        b.append("Item # - ");
        b.append(item_index.toString());
        return initOf NftItem(myAddress(), myAddress(), item_index, b.toString());
    }

    get fun get_nft_address_by_index(item_index: Int): Address {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun get_list_collection_data(): map<Int, Address> {
        return self.arr;
    }

    get fun balance(): Int {
        return myBalance();
    }
}