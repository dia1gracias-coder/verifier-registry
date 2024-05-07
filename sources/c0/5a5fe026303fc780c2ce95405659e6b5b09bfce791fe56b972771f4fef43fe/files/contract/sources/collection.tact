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
    price: Int;
}

struct NftInfo {
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
    mint_accoint: Address;

    init(owner: Address, mint_accoint: Address, content: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {
        self.mint_accoint = mint_accoint;
        self.drop = DropStorage {
            supply: 1250,
            current_minted: 0,
            tier: 3,
            mint_list: emptyMap(),
            price: ton("0")
        };
        self.nft_info = emptyMap();
        self.owner = owner;
        self.content = content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
    }

    receive(msg: RequestNftDeploy) {
        require(self.mint_accoint == sender(), "error mint");
        require(self.drop.supply > self.drop.current_minted, "Drop ended");
        require(context().value > self.drop.price, "Price is higher");
        let nft_init: StateInit = initOf NftItem(myAddress(), self.next_index);
        let nft_address: Address = contractAddress(nft_init);
        send(SendParameters{
            to: nft_address,
            value: msg.amount,
            mode: SendPayGasSeparately,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: NftDeploy{
                index: self.next_index,
                owner: sender(),
                content: msg.content,
                tier: self.drop.tier,
                royalty_destination: self.royalty_destination,
                numerator: self.numerator,
                denominator: self.denominator
            }.toCell()
        });
        self.drop.current_minted = self.drop.current_minted + 1;
        self.nft_info.set(self.next_index, NftInfo{tier: self.drop.tier, nft_address: nft_address});
        self.next_index = self.next_index + 1;
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
        self.drop.price = msg.price;
    }

    receive("withdraw"){
        require(sender() == self.owner, "only owner");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - ton("0.01"),
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }


}