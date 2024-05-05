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

contract NftCollection with Ownable, Deployable, NftRoyalty {
    owner: Address;
    next_index: Int as uint256 = 0;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
    drop: DropStorage;

    init(owner: Address, content: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {
        self.drop = DropStorage {
            supply: 3,
            current_minted: 0,
            tier: 1,
            mint_list: emptyMap()
        };
        self.owner = owner;
        self.content = content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
    }

    receive(msg: RequestNftDeploy) {
        require(msg.index <= self.next_index, "Invalid Index");
        require(self.drop.supply > self.drop.current_minted, "Drop ended");
        require(self.drop.mint_list.get(msg.owner) == null, "Youre claimed");
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
        if(msg.index == self.next_index) {
            self.next_index = self.next_index + 1;
        }
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

    fun set_drop_storage(supply: Int, tier: Int) {
        self.requireOwner();
        self.drop.supply = supply;
        self.drop.current_minted = 0;
        self.drop.tier = tier;
        self.drop.mint_list = emptyMap();
    }
}