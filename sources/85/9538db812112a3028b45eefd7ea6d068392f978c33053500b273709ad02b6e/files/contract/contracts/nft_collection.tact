import "./packages/nft/NFTCollection.tact";
import "./packages/utils/Stoppable.tact";
import "./packages/utils/Estimable.tact";
import "./packages/utils/Whitelist.tact";
import "./packages/utils/Withdraw.tact";
import "./nft_item.tact";

// Для бесплатного минта работает по whitelist
message(0xb4f84869) FreeMint {
    query_id: Int as uint64;
    to_address: Address?;
    custom_payload: Cell?;
}
// Для бесплатного минта по ряду адресов работает по whitelist
message(0x02fe6b9d) FreeManyMint {
    query_id: Int as uint64;
    to_addresses: map<Int, Address>; // Массив адресов
    length: Int; // Длина массива
}

message(0x8b2dc417) ChangePrice {
    query_id: Int as uint64;
    new_price: Int;
}

message(0xced97cc4) Mint {
    query_id: Int as uint64;
    custom_payload: Cell?;
}

message(0x3666ce90) TransferOwnership {
    new_owner: Address;
    query_id: Int as uint64;
}


contract NftCollection with NftCollectionStandard, Stoppable, Estimable, Whitelist, Withdraw {
    next_item_index: Int = 0;           // if next_item_index is not -1, means sequential minting is enabled. We want a sequential minting in this example so we set it to uint32.
    collection_content: Cell;           // collection_content may be the prefix of individual_content
    owner_address: Address;             // owner_address is the address of the owner of the collection


    stop: Bool = false;                // mint_blocked is a flag to indicate if minting is blocked
    time_passed: Int = 0;              // time_passed is the time passed since the last minting

    list: List;                        // list is a whitelist of addresses that are free allowed to mint


    // price: Int = 0;                    // price is the price of minting an NFT

    override const gasConsumption: Int = ton("0.005");
    
    init(owner_address: Address, collection_content: Cell) {
        self.next_item_index = 0;
        self.owner_address = owner_address;
        self.collection_content = collection_content;

        // self.price = price;

        self.list = List{
            _map: emptyMap()
        };

        self.list._map.set(owner_address, true);
    }

    //*********************************//
    //             Messages            //
    //*********************************//

    // This is when you don't want to send excesses back
    receive() {}

    // @dev minting is allowed only if the sender owner of the collection
    // Реализовать функции с правами админа
    // * бесплатно сминтить упаковку токенов NFT
    // * отправить NFT на адрес

    receive(msg: FreeManyMint) {
        self._isOwner();
    
        let i: Int = 0;

        repeat (msg.length) {
            let to: Address? = msg.to_addresses.get(i);
            i += 1;
            if(to != null) {
                self._mint(to!!, self.collection_content, msg.query_id);
            }
        }
    }
    /*
        @dev minting is allowed only if the sender is in the whitelist
        Добавить белый список адресов, кто бесплатно может сминтить
        Реализовать функции с правами админа
        - бесплатно сминтить NFT
        - отправить NFT на адрес
    */
    receive(msg: FreeMint) {
        let isInList: Bool = self._isInList(sender());
        require(isInList, "Not in whitelist");

        self._mint(
            msg.to_address == null ? sender() : msg.to_address!!, 
            msg.custom_payload == null ? self.collection_content : msg.custom_payload!!,
            msg.query_id
        );
    }

    // @dev mint price is 0.01 TON
    // Реализовать функции минта токенов NFT за 0.01 тестовых TON
    // receive(msg: Mint) {
    //     require(self.price <= context().value, "Not enough money");

    //     self._mint(
    //         sender(), 
    //         msg.custom_payload == null ? self.collection_content : msg.custom_payload!!,
    //         msg.query_id
    //     );
    // }

    // @dev change the price of minting only owner
    // receive(msg: ChangePrice) {
    //     self._isOwner();
    //     self._changePrice(msg.new_price);
    // }

    /*
        @dev transfer ownership of the collection to a new owner
        Реализовать функции с правами админа
        - передать права админа на коллекцию
    */
    receive(msg: TransferOwnership) {
        self._isOwner();
        self._transferOwner(msg.new_owner);
    }


    //*********************************//
    //       Internal functions        //
    //*********************************//

    // @dev _mint mints a new NFT item of this collection and sends it to the specified address
    // @dev minting is allowed only if the collection is not stopped
    inline fun _mint(to_mint: Address, custom_payload: Cell, query_id: Int) {
        // Проверка может ли пользователь минтить
        self._ensureUnstopped(); 

        let ctx: Context = context();

        let nft_init: StateInit = self._get_nft_item_state_init(self.next_item_index);

        send(SendParameters{
            to: contractAddress(nft_init),
            value: self.estimate_rest_value(ctx),
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer{
                query_id: query_id,
                new_owner: to_mint,
                response_destination: to_mint,
                custom_payload: custom_payload,
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });

        self.next_item_index = self.next_item_index + 1;
    }

    // @dev _get_nft_item_state_init returns the initCode of NFTItem
    override inline fun _get_nft_item_state_init(index: Int): StateInit {
        return initOf NftItem(myAddress(), index);
    }

    // @dev _canEditList checks if the sender is the owner of the collection
    // Реализовать функции с правами админа
    // * добавить/удалить адрес в белый список
    override inline fun _canEditList() {
        self._isOwner();
    }

    // @dev _canWithdraw checks if the sender is the owner of the collection
    // Реализовать функции с правами админа
    // * вывести средства из контракта
    override inline fun _canWithdraw() {
        self._isOwner();
    }

    // @dev _canEditStop checks if the sender is the owner of the collection
    // Реализовать функции с правами админа
    // * остановить/разблокировать минт
    override inline fun _canEditStop() {
        self._isOwner();
    }


    // @dev _isOwner checks if the sender is the owner of the collection
    inline fun _isOwner() {
        require(self.owner_address == context().sender, "Only owner");
    }

    // @dev _transferOwner transfers the ownership of the collection to a new owner
    // Реализовать функции с правами админа
    // * передать права админа на коллекцию
    inline fun _transferOwner(new_owner: Address) {
        self.owner_address = new_owner;
    }


    // @dev _changePrice changes the price of minting
    // inline fun _changePrice(new_price: Int) {
    //     self.price = new_price;
    // }

    //*********************************//
    //             Getters             //
    //*********************************//

    get fun balance(): Int {
        return myBalance();
    }
    

}
