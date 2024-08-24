import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "../utils/messages_utils.tact";
import "../../shared/traits/accounting.tact";

trait NftCollection with Deployable, Ownable, Accounting {
    next_item_index: Int;
    owner: Address;
    collection_content: NftCollectionMetadata;

    // ===== Customizable functions ===== //

    abstract fun getNftItemInit(item_index: Int): StateInit;

    // ===== Private Methods ===== //

    fun mintNftGeneric(initialize_nft_options: Cell, init_balance: Int) {
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init),
                value: init_balance,
                bounce: false,
                mode: SendIgnoreErrors,
                body: initialize_nft_options,
                code: nft_init.code,
                data: nft_init.data
            });
        self.next_item_index = self.next_item_index + 1;
    }

    // ------------------ Get Function  ------------------ //


    // ------------------ NFT standard getters  ------------------ //
    // https://github.com/ton-blockchain/TEPs/blob/master/text/0062-nft-standard.md#get-methods-1

    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index: self.next_item_index,
            collection_content: serializeNftCollectionContent(self.collection_content),
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        require(index >= 0, "index must be positive");
        require(index < self.next_item_index, "index must be less than next_item_index");
        return individual_content;
    }

    // ===== Recievers ===== //

}
