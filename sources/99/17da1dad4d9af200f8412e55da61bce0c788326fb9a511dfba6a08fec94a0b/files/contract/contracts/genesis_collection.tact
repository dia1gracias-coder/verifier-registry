import "./TEPs/0066-nft-royalty-standard";
import "./messages";
import "./genesis_item";

contract NftGenesisCollection {
    owner: Address;
    next_item_index: Int as uint64 = 0;
    content: Cell;

    royalty_destination: Address;
    royalty_numerator: Int as uint16;
    royalty_denominator: Int as uint16;

    init(owner: Address, content: Cell, royalty_numerator: Int, royalty_denominator: Int) {
        self.owner = owner;
        self.content = content;

        require(royalty_denominator > 0, "Invalid royalty denominator");
        require(royalty_numerator <= royalty_denominator, "Invalid royalty numerator");
        self.royalty_destination = owner;
        self.royalty_numerator = royalty_numerator;
        self.royalty_denominator = royalty_denominator;
    }

    receive() {
        // ignore empty internal messages
    }

    receive(msg: NFTGetRoyaltyParams) {
        send(SendParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: NFTReportRoyaltyParams {
                query_id: msg.query_id,
                numerator: self.royalty_numerator,
                denominator: self.royalty_denominator,
                destination: self.royalty_destination
            }.toCell()
        });
    }

    receive(msg: MintNft) {
        require(sender() == self.owner, "Invalid Sender");
        require(msg.item_index <= self.next_item_index, "Invalid Index");

        let is_last: Bool = msg.item_index == self.next_item_index;
        let nft_init: StateInit = initOf NftGenesisItem(myAddress(), msg.item_index);
        let nft_address: Address = contractAddress(nft_init);

        send(SendParameters {
            to: nft_address,
            value: msg.amount,
            mode: SendPayFwdFeesSeparately,
            data: nft_init.data,
            code: nft_init.code,
            body: msg.content
        });

        if (is_last) {
            self.next_item_index = self.next_item_index + 1;
        }
    }

    receive(msg: ChangeCollectionOwner) {
        require(sender() == self.owner, "Invalid Sender");
        self.owner = msg.new_owner;
    }

    get fun get_collection_data(): NftCollectionData {
        let cs: Slice = self.content.beginParse();
        return NftCollectionData {
            next_item_index: self.next_item_index,
            collection_content: cs.loadRef(),
            owner_address: self.owner
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(initOf NftGenesisItem(myAddress(), index));
    }

    get fun royalty_params(): NFTRoyaltyParams {
        return NFTRoyaltyParams {
            numerator: self.royalty_numerator,
            denominator: self.royalty_denominator,
            royalty_destination: self.royalty_destination
        };
    }

    get fun get_nft_content(index: Int, individual_nft_content: Cell): Cell {
        let cs: Slice = self.content.beginParse();
        cs.loadRef();
        let common_content: Slice = cs.loadRef().beginParse();
        return beginCell()
            .storeUint(1, 8)
            .storeSlice(common_content)
            .storeRef(individual_nft_content)
            .endCell();
    }
}
