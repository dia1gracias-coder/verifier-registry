import "@stdlib/deploy";
import "@stdlib/ownable";
import "./item";
import "./messages";

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
    nft_metadata: Cell;
    mint_price: Int as uint128 = ton("2");  // Устанавливаем цену минта в 2 TON

    init(owner: Address, content: Cell, nft_metadata: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {
        self.owner = owner;
        self.content = content;
        self.nft_metadata = nft_metadata;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
    }

    receive(msg: RequestNftDeploy) {
        require(context().value >= self.mint_price, "Insufficient funds: 2 TON required for minting");

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
                content: self.nft_metadata,
                royalty_destination: self.royalty_destination,
                numerator: self.numerator,
                denominator: self.denominator
            }.toCell()
        });
        self.next_index = self.next_index + 1;
    }

    receive(msg: UpdateMetadata) {
        require(sender() == self.owner, "Only owner can update metadata");
        self.nft_metadata = msg.new_metadata;
    }

    receive("withdraw"){
        require(sender() == self.owner, "Only owner can do it");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - ton("0.01"),
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // receive(msg: ChangeOwner){
    //     require(self.owner == sender(), "Only owner can do it");
    //     self.owner = msg.new_owner;
    // }

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
