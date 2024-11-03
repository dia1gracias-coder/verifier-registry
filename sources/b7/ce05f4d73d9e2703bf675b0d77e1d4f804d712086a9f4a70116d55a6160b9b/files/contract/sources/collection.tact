import "@stdlib/deploy";
import "@stdlib/ownable";
import "./item";

struct CollectionData {
    next_index: Int;
    content: Cell;
    owner: Address;
}

contract NftCollection with Ownable, Deployable, NftRoyalty {
    owner: Address;
    next_index: Int as uint256 = 0;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
    supply: Int;

    init(owner: Address, content: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {

        self.supply = 9999;
        self.owner = owner;
        self.content = content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
    }

    receive(msg: RequestNftDeploy) {
        require(self.next_index < self.supply, "Drop ended");
        let nft_init: StateInit = initOf NftItem(myAddress(), self.next_index);
        let nft_address: Address = contractAddress(nft_init);
        send(SendParameters{
            to: nft_address,
            value: ton("0.03"),
            mode: SendPayGasSeparately,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: NftDeploy{
                index: self.next_index,
                owner: sender(),
                content: msg.asset_metadata,
                royalty_destination: self.royalty_destination,
                numerator: self.numerator,
                denominator: self.denominator
            }.toCell()
        });

        self.next_index = self.next_index + 1;
    }

    receive("withdraw"){
        require(sender() == self.owner, "only owner!");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - ton("0.01"),
            mode: SendRemainingValue + SendIgnoreErrors
        });
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

    get fun get_next_index(): Int {
        return self.next_index;
    }
}