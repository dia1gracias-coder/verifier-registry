import "@stdlib/deploy";
import "@stdlib/ownable";
import "./nft_item";

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
    seqno: Int;

    init(owner: Address, content: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {
        self.owner = owner;
        self.content = content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
        self.seqno = now();
    }

    receive(msg: Withdraw) {
        self.requireOwner();        
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendPayGasSeparately
        });
    }
    receive(msg: RequestNftDeploy) {
        self.requireOwner();
        require(msg.index <= self.next_index, "Invalid Index");
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
                owner: msg.owner,
                content: msg.content,
                lastOwner: msg.lastOwner
            }.toCell()
        });
        if(msg.index == self.next_index) {
            self.next_index = self.next_index + 1;
        }
    }

    receive(msg: BatchNftDeploy) {
        self.requireOwner();
        require(context().value >= min_balance * msg.nftAmount, "wrong amount of tons");
        let nft_init: StateInit = initOf NftItem(myAddress(), msg.next_index);
        let nft_address: Address = contractAddress(nft_init);
        let counter: Int = 0;
        repeat(msg.nftAmount){
            nft_init = initOf NftItem(myAddress(), msg.next_index + counter);
            nft_address = contractAddress(nft_init);
            send(SendParameters{
                to: nft_address,
                value: msg.amount,
                mode: SendPayGasSeparately,
                bounce: false,
                data: nft_init.data,
                code: nft_init.code,
                body: NftDeploy{
                    owner: msg.wallets.get(counter)!!,
                    content: msg.content,
                    lastOwner: msg.lastOwner
                }.toCell()
            });
            counter += 1;   
        }
        self.next_index += msg.nftAmount;
    }  

    // receive(msg: SendNFTs) {
    //     self.requireOwner();
    //     let nft_init: StateInit = initOf NftItem(myAddress(), msg.index);
    //     let nft_address: Address = contractAddress(nft_init);
    //     let wallet: Address = msg.wallets.get(0)!!;
    //     let counter: Int = 0;
    //     repeat(msg.nftAmount) {
    //         wallet = msg.wallet.get(counter)!!; 
    //         nft_init: StateInit = initOf NftItem(myAddress(), msg.index + counter);
    //         nft_address: Address = contractAddress(nft_init);
    //         send(SendParameters{
    //             to: nft_address,
    //             value: msg.amount,
    //             mode: SendPayGasSeparately,
    //             bounce: false,
    //             data: nft_init.data,
    //             code: nft_init.code,
    //             body: NftTransfer{
    //                 query_id: now(),
    //                 new_owner: wallet,
    //                 response_destination: wallet,
    //                 forward_amount: 0,
    //                 forward_payload: emptySlice()
    //             }.toCell()
    //         });
    //         counter += 1;
    //     }
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
}