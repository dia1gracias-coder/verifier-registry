import "@stdlib/deploy";
import "@stdlib/ownable";
import "./item";

struct CollectionData {
    next_index: Int;
    content: Cell;
    owner: Address;
}

struct DropStorage {
    supply: Int as uint256;
    current_minted: Int as uint256;
    tier: Int;
    mint_list: map<Address, Bool>;
}

struct NftInfo {
    owner: Address;
    tier: Int;
    nft_address: Address;
}



contract NftCollection with Ownable, Deployable, NftRoyalty {
    owner: Address;
    next_index: Int as uint256 = 0;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
    drop: DropStorage;
    nft_info: map<Int, NftInfo>;

    init(owner: Address, content: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {
        self.drop = DropStorage {
            supply: 2,
            current_minted: 0,
            tier: 1,
            mint_list: emptyMap()
        };
        self.nft_info = emptyMap();
        self.owner = owner;
        self.content = content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
    }

    receive(msg: RequestNftDeploy) {
        require(msg.index <= self.next_index, "Invalid Index");
        require(self.drop.supply > self.drop.current_minted, "Drop ended");
        //require(self.drop.mint_list.get(msg.owner) == null, "Youre claimed");
        let nft_init: StateInit = initOf NftItem(myAddress(), msg.index);
        let nft_address: Address = contractAddress(nft_init);
        send(SendParameters{
            to: nft_address,
            value: msg.amount,
            mode: SendPayGasSeparately,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: NftDeploy{
                index: msg.index,
                owner: msg.owner,
                content: msg.content,
                tier: self.drop.tier,
                royalty_destination: self.royalty_destination,
                numerator: self.numerator,
                denominator: self.denominator
            }.toCell()
        });
        self.drop.mint_list.set(msg.owner, true);
        self.drop.current_minted = self.drop.current_minted + 1;
        self.nft_info.set(msg.index, NftInfo{owner: msg.owner, tier: self.drop.tier, nft_address: nft_address});
        if(msg.index == self.next_index) {
            self.next_index = self.next_index + 1;
        }
    }

    receive(msg: RequestNftLevelUp) {
        require(msg.index <= self.next_index, "Invalid Index");
        require(sender() == msg.owner, "Invalid owner on burn");

        send(SendParameters{
            to: msg.item_address_1,
            value: 0,
            mode: SendPayGasSeparately,
            body: NftDestroy{
                query_id: msg.item_index_1,
                sender: sender(),
                tier: msg.tier
            }.toCell()
        });

        send(SendParameters{
            to: msg.item_address_2,
            value: 0,
            mode: SendPayGasSeparately,
            body: NftDestroy{
                query_id: msg.item_index_2,
                sender: sender(),
                tier: msg.tier
            }.toCell()
        });

        let nft_init: StateInit = initOf NftItem(myAddress(), msg.index);
        let nft_address: Address = contractAddress(nft_init);

        send(SendParameters{
            to: nft_address,
            value: 0,
            mode: SendPayGasSeparately,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: NftDeploy{
                index: msg.index,
                owner: msg.owner,
                content: msg.content,
                tier: msg.tier + 1, 
                royalty_destination: self.royalty_destination,
                numerator: self.numerator,
                denominator: self.denominator
            }.toCell()
        });
        self.nft_info.set(msg.index, NftInfo{owner: msg.owner, tier: msg.tier + 1, nft_address: nft_address});
        if(msg.index == self.next_index) {
            self.next_index = self.next_index + 1;
        }
    }

    get fun get_nft_info(index: Int): NftInfo {
        return self.nft_info.get(index)!!;
    }

    get fun get_collection_data(): CollectionData {
        return CollectionData{next_index: self.next_index, content: self.content, owner: self.owner};
    }
    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(initOf NftItem(myAddress(), index));
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }

    get fun get_drop_storage(): DropStorage {
        return self.drop;
    }

    get fun get_next_index(): Int {
        return self.next_index;
    }

    receive(msg: SetDropStorage) {
        self.requireOwner();
        self.drop.supply = msg.supply;
        self.drop.current_minted = 0;
        self.drop.tier = msg.tier;
        self.drop.mint_list = emptyMap();
    }


    receive("withdraw"){
        require(sender() == self.owner, "only owner");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }
}