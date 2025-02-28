/*
 * NFT Standard
 * https://tonresear.ch/t/create-smart-contracts-on-ton-lesson-10-nft-standard/436
 */

import "@stdlib/deploy";
import "@stdlib/ownable";
import "./NftItem";
import "./messages";
import "./utils/Upgradable";

struct CollectionData {
    next_item_index    : Int;
    collection_content : String;
    owner_address      : Address;
}

struct SupplyInfo {
    current_supply : Int;
    max_supply     : Int;
} 

message UpdateCode {
    queryId : Int as uint64;
    newCode : Cell;
}

contract NftCollection with Deployable, Ownable, Upgradable {
    owner      : Address;
    content    : String;
    cur_index  : Int as uint32 = 0;
    max_supply : Int as uint32;
    
    init(owner: Address, content: String) {
        self.owner      = owner;
        self.content    = content;
        self.max_supply = 999;
    }

    fun calcNftAddress(item_index: Int): Address {
        let initState: StateInit = initOf NftItem(myAddress(), item_index);
        return contractAddress(initState);
    }

    receive(msg: Mint) {
        self.requireOwner();
        require(msg.index <= self.cur_index, "Invalid Index");
        require(self.cur_index < self.max_supply, "Max supply reached");
        
        let nft_init: StateInit = initOf NftItem(myAddress(), msg.index);
        let nft_address: Address = self.calcNftAddress(msg.index);
        
        send(SendParameters{
            to: nft_address,
            value: msg.amount,
            mode: SendPayGasSeparately,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: NftDeploy{
                index   : msg.index,
                content : msg.content,
                owner   : msg.owner,
            }.toCell()
        });

        if(msg.index == self.cur_index) {
            self.cur_index += 1;
        }
    }

    receive(msg: UpdateSettings) {
        self.requireOwner();
        require(msg.maxSupply >= self.cur_index, "New max supply cannot be less than current supply");
        
        self.max_supply = msg.maxSupply;
    }

    receive(msg: Withdraw) {
        self.requireOwner();
        require(msg.amount > 0, "Amount must be positive");
        require(myBalance() >= msg.amount + ton("0.1"), "Insufficient contract balance");

        send(SendParameters{
            to    : msg.destination,
            value : msg.amount,
            mode  : SendPayGasSeparately,
            body  : "Withdrawal processed".asComment()
        });
    }

    get fun get_nft_supply_info(): SupplyInfo {
        return SupplyInfo{
            current_supply : self.cur_index,
            max_supply     : self.max_supply
        };
    }

    get fun get_nft_addresses_by_index(item_indexes: map<Int, Bool>): map<Int, Address> {
        let addresses: map<Int, Address> = emptyMap();
        let index: Int = 0;
        
        while (index < self.cur_index) {
            if (item_indexes.get(index) != null) {
                addresses.set(index, self.calcNftAddress(index));
            }
            index += 1;
        }
        return addresses;
    }


    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index    : self.cur_index,
            collection_content : self.content,
            owner_address      : self.owner,
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        return self.calcNftAddress(index);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

}
