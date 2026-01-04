import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./nft_item";

contract NftCollectionAdmin with Deployable, Ownable {
    next_item_index: Int as uint32 = 0;
    owner: Address;
    royalty_params: RoyaltyParams?;
    collection_content: Cell;
    authorized_minter: Address;

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams?, authorized_minter: Address) {
        self.owner = owner_address;
        self.royalty_params = royalty_params;
        self.collection_content = collection_content;
        self.authorized_minter = authorized_minter;
    }

    receive(msg: MintNftV2) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.authorized_minter, "Only owner or authorized minter");
        // Mint to admin wallet (owner) and ignore any custom metadata
        self.mintWithContent(self.owner, ctx.value, null);
    }


    receive(msg: WithdrawFunds) {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
            bounce: false
        });
    }

    receive(msg: UpdateCollectionContent) {
        self.requireOwner();
        self.collection_content = msg.collection_content;
    }

    receive(msg: UpdateAuthorizedMinter) {
        self.requireOwner();
        self.authorized_minter = msg.new_minter;
    }


    // Admin burn by NFT index
    receive(msg: BurnById) {
        let ctx: Context = context();
        require(ctx.sender == self.owner || ctx.sender == self.authorized_minter, "Only owner or authorized minter");
        let nft_init: StateInit = self.getNftItemInit(msg.index);
        let nft_address: Address = contractAddress(nft_init);
        send(SendParameters{
            to: nft_address,
            value: ton("0.06"),
            bounce: false,
            mode: SendIgnoreErrors,
            body: BurnNft{ query_id: 0 }.toCell()
        });
    }

    

    fun mintWithContent(sender: Address, msgValue: Int, individual_content: Cell?) {
        require(self.next_item_index >= 0, "Non-sequential NFTs");
        require(msgValue >= ton("0.05"), "Insufficient funds");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let nft_address: Address = contractAddress(nft_init);
        send(SendParameters{
            to: nft_address,
            value: msgValue - ton("0.05"),
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer {
                query_id: 0,
                new_owner: sender,
                response_destination: self.owner,
                custom_payload: null,
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });
        self.next_item_index = self.next_item_index + 1;
    }

    fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, self.owner, self.collection_content);
    }

    get fun get_collection_data(): CollectionData {
        let b: StringBuilder = beginString();
        let s: String = self.collection_content.asSlice().asString();
        b.append(s);
        b.append("collection.json");
        let off: Cell = beginCell().storeUint(1, 8).storeRef(b.toCell()).endCell();
        return CollectionData{
            next_item_index: self.next_item_index,
            collection_content: off,
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(index: Int): Address? {
        let initCode: StateInit = self.getNftItemInit(index);
        return contractAddress(initCode);
    }

    get fun royalty_params(): RoyaltyParams? {
        return self.royalty_params;
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let slice: Slice = individual_content.beginParse();
        if (slice.bits() > 8) {
            let p: Int = slice.preloadUint(8);
            if (p == 1) {
                return individual_content;
            }
        }
        let b: StringBuilder = beginString();
        let s: String = self.collection_content.asSlice().asString();
        b.append(s);
        b.append("items/");
        b.append(index.toString());
        b.append(".json");
        return beginCell().storeUint(1, 8).storeRef(b.toCell()).endCell();
    }
}
