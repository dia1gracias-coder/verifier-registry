import "./message.tact";
import "@stdlib/ownable";

const minTonsForStorage: Int = ton("0.01");
const gasConsumption: Int = ton("0.02");

contract MintManager with OwnableTransferable{
    owner: Address;
    cards_content: String = "https://storage.mappasaurus.com/meta/";
    pets_content: String = "https://storage.mappasaurus.com/petmeta/";

    init(owner_address: Address){
        self.owner = owner_address;
    }

    receive(msg: AddTowhitelist) {
        self.requireOwner();
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let whiteListinfo: StateInit = initOf WhiteListInfo(msg.whitelistThis, msg.id);
        let storageFee: Int = (minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage));
        msgValue = (msgValue - (storageFee + gasConsumption));
        send(SendParameters {
            to: contractAddress(whiteListinfo),
            bounce: false,
            value: msgValue,
            mode: SendIgnoreErrors,
            body: MakeWhitelist {whitelistThis: msg.whitelistThis, id: msg.id}.toCell(),
            code: whiteListinfo.code,
            data: whiteListinfo.data
        });
    }

    get fun get_whitelist_info_address(whitelisted: Address, id: Int): Address? {
        let whiteListinfo: StateInit = initOf WhiteListInfo(whitelisted, id);
        return contractAddress(whiteListinfo);
    }

    get fun get_collection_test_cards(): Address {
    let testCards: StateInit = initOf TestCards(self.owner);
        return contractAddress(testCards);
    }

    get fun get_collection_test_pets(): Address {
    let testPets: StateInit = initOf TestPets(self.owner);
        return contractAddress(testPets);
    }
}

contract TestCards with OwnableTransferable {
    next_item_index: Int as uint32 = 0;
    owner: Address;
    collection_content: String = "https://storage.mappasaurus.com/meta/";
    royalty_params: RoyaltyParams?;                      
    manager_contract: Address;
    min_num: Int as uint64 = 0;
    max_num: Int as uint64 = 101;


    init(owner_address: Address){
    self.owner = owner_address;
    self.royalty_params = RoyaltyParams{
        numerator: 900,
    denominator: 1000,
    destination: address("0QBLhgReyKQxCD5RrhsF2HakNpgiYJTsOT-TO6u7R_-yx6fI")
    };
    self.manager_contract = contractAddress(initOf MintManager(self.owner));

    }

    receive(msg: SetURI) {
        self.requireOwner();
        self.collection_content = msg.content;
    }

    receive(msg: MintMsg){
        let expectedAddress: Address = contractAddress(initOf WhiteListInfo(msg.owner, msg.id));
        require(sender() == expectedAddress, "MintMsg : Access denied");
        let ctx: Context = context(); 
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage));
        msgValue = (msgValue - (storageFee + gasConsumption));
        let randomNum: Int = random(self.min_num, self.max_num);
        let b: StringBuilder = beginString();
        b.append(self.collection_content);
        b.append((msg.id).toString());
        b.append("-");
        b.append(randomNum.toString());
        b.append(".json");
        self.mint(msg.owner, msgValue, b.toCell());
        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }

    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  (self.royalty_params!!).numerator,
                denominator: (self.royalty_params!!).denominator,
                destination: (self.royalty_params!!).destination
            }.toCell()
        });        
    }

    receive(msg: SetNums) {
        self.requireOwner();
        self.min_num = msg.min;
        self.max_num = msg.max;
    }

    // ===== Private Methods ===== //
     fun mint(sender: Address, msgValue: Int, uri: Cell) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init),
                value: msgValue,
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer{
                    query_id: 0,
                    new_owner: sender,
                    response_destination: self.owner,
                    custom_payload: uri,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            }
        );
        emit("2".asComment());
        // dump(self.next_item_index);
        self.next_item_index = (self.next_item_index + 1);
    }

    // ------------------ Get Function  ------------------ //

    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        b.append(self.collection_content);
        b.append("1-1.json");
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner
        };
    }


    get fun get_nft_address_by_index(item_index: Int): Address? {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }


    get fun get_whitelist_info_address(whitelisted: Address, id: Int): Address? {
        let whiteListinfo: StateInit = initOf WhiteListInfo(whitelisted, id);
        return contractAddress(whiteListinfo);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf TestCard(myAddress(), item_index);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params!!;
    }

}

contract TestPets with OwnableTransferable {
    next_item_index: Int as uint32 = 0;
    owner: Address;
    collection_content: String = "https://storage.mappasaurus.com/petmeta/";
    royalty_params: RoyaltyParams?;   
    manager_contract: Address;
    min_num: Int as uint64 = 0;
    max_num: Int as uint64 = 101;               

    init(owner_address: Address){
        self.owner = owner_address;
        self.royalty_params = RoyaltyParams{
        numerator: 900,
        denominator: 1000,
        destination: address("0QBLhgReyKQxCD5RrhsF2HakNpgiYJTsOT-TO6u7R_-yx6fI")
        };
        self.manager_contract = contractAddress(initOf MintManager(self.owner));
    }

     receive(msg: SetURI) {
        self.requireOwner();
        self.collection_content = msg.content;
    }

     receive(msg: MintMsg){
        let expectedAddress: Address = contractAddress(initOf WhiteListInfo(msg.owner, msg.id));
        require(sender() == expectedAddress, "MintMsg : Access denied");
        let ctx: Context = context(); 
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage));
        msgValue = (msgValue - (storageFee + gasConsumption));
        let randomNum: Int = random(self.min_num, self.max_num);
        let rarity: Int = self.get_select_rarity(msg.id);
        let petId: Int = self.get_random_petid(msg.id, rarity);
        let b: StringBuilder = beginString();
        b.append(self.collection_content);
        b.append((msg.id).toString());
        b.append("/");
        b.append(rarity.toString());
        b.append("/");
        b.append(petId.toString());
        b.append(".json");
        self.mint(msg.owner, msgValue, b.toCell());
        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }


    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context(); // get sender Info
        send(SendParameters{
            to: ctx.sender,
            value: 0,
            mode: 64, 
            bounce: false,
            body: ReportRoyaltyParams {
                query_id: msg.query_id,
                numerator:  (self.royalty_params!!).numerator,
                denominator: (self.royalty_params!!).denominator,
                destination: (self.royalty_params!!).destination
            }.toCell()
        });        
    }

    receive(msg: SetNums) {
        self.requireOwner();
        self.min_num = msg.min;
        self.max_num = msg.max;
    }

    // ===== Private Methods ===== //
     fun mint(sender: Address, msgValue: Int, uri: Cell) {
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init),
                value: msgValue,
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer{
                    query_id: 0,
                    new_owner: sender,
                    response_destination: self.owner,
                    custom_payload: uri,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            }
        );
        // dump(self.next_item_index);
        self.next_item_index = (self.next_item_index + 1);
    }

    // ------------------ Get Function  ------------------ //

    get fun get_select_rarity(seed: Int): Int {
    let randomValue: Int = random(self.min_num, self.max_num);
    if (randomValue < 50) {
        return 1;
    } else if (randomValue < 99) {
        return 2;
    } else {
        return 3;
    }
    }

    get fun get_random_petid(tokenId: Int, rarity: Int): Int {
        if (rarity == 1) {
            return random(1, 433);
        } else if (rarity == 2) {
            return random(1, 433);
        } else {
            return random(1, 433);
        }
    }

    get fun get_collection_data(): CollectionData {
        let b: StringBuilder = beginString();
        b.append(self.collection_content);
        b.append("1-1.json");
        return
            CollectionData{
                next_item_index: self.next_item_index,
                collection_content: b.toCell(),
                owner_address: self.owner
            };
    }

    get fun get_nft_address_by_index(item_index: Int): Address? {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }


    get fun get_whitelist_info_address(whitelisted: Address, id: Int): Address? {
        let whiteListinfo: StateInit = initOf WhiteListInfo(whitelisted, id);
        return contractAddress(whiteListinfo);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf TestPet(myAddress(), item_index);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params!!;
    }

}

contract TestCard {
    collection_address: Address;
    item_index: Int;
    is_initialized: Bool;
    owner: Address?;
    individual_content: Cell?;


    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection check again");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer){
        let ctx: Context = context();
        let msgValue: Int = ctx.value; // Check the gasCost for storage
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage));
        msgValue = (msgValue - (storageFee + gasConsumption));
        if (self.is_initialized == false) {
            // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: msgValue,
                    mode: SendPayGasSeparately,
                    body: Excesses{query_id: msg.query_id}.toCell()
                }
            );
        } else {
            require(ctx.sender == self.owner!!, "not owner");
            self.owner = msg.new_owner; // change current owner to the new_owner
            if (msg.forward_amount > 0) {
                send(SendParameters{
                        to: msg.new_owner,
                        value: msg.forward_amount,
                        mode: SendPayGasSeparately,
                        bounce: true,
                        body: OwnershipAssigned{
                            query_id: msg.query_id,
                            prev_owner: ctx.sender,
                            forward_payload: msg.forward_payload
                        }.toCell()
                    }
                );
            }
            msgValue = (msgValue - ctx.readForwardFee());
            if (msg.response_destination != null) {
                send(SendParameters{
                        to: msg.response_destination!!,
                        value: (msgValue - msg.forward_amount),
                        mode: SendPayGasSeparately,
                        bounce: true,
                        body: Excesses{query_id: msg.query_id}.toCell()
                    }
                );
            }
        }
    }

    receive(msg: GetStaticData){
        let ctx: Context = context();
        send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: 64, // (return msg amount except gas fees)
                bounce: true,
                body: ReportStaticData{
                    query_id: msg.query_id,
                    index_id: self.item_index,
                    collection: self.collection_address
                }.toCell()
            }
        );
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        return
            GetNftData{
                is_initialized: self.is_initialized,
                index: self.item_index,
                collection_address: self.collection_address,
                owner_address: self.owner!!,
                individual_content: b.toCell()
            };
    }
}

contract TestPet {
    collection_address: Address;
    item_index: Int;
    is_initialized: Bool;
    owner: Address?;
    individual_content: Cell?;
    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection check again");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer){
        let ctx: Context = context();
        let msgValue: Int = ctx.value; // Check the gasCost for storage
        let tonBalanceBeforeMsg: Int = (myBalance() - msgValue);
        let storageFee: Int = (minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage));
        msgValue = (msgValue - (storageFee + gasConsumption));
        if (self.is_initialized == false) {
            // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            send(SendParameters{
                    to: msg.response_destination!!,
                    value: msgValue,
                    mode: SendPayGasSeparately,
                    body: Excesses{query_id: msg.query_id}.toCell()
                }
            );
        } else {
            require(ctx.sender == self.owner!!, "not owner");
            self.owner = msg.new_owner; // change current owner to the new_owner
            if (msg.forward_amount > 0) {
                send(SendParameters{
                        to: msg.new_owner,
                        value: msg.forward_amount,
                        mode: SendPayGasSeparately,
                        bounce: true,
                        body: OwnershipAssigned{
                            query_id: msg.query_id,
                            prev_owner: ctx.sender,
                            forward_payload: msg.forward_payload
                        }.toCell()
                    }
                );
            }
            msgValue = (msgValue - ctx.readForwardFee());
            if (msg.response_destination != null) {
                send(SendParameters{
                        to: msg.response_destination!!,
                        value: (msgValue - msg.forward_amount),
                        mode: SendPayGasSeparately,
                        bounce: true,
                        body: Excesses{query_id: msg.query_id}.toCell()
                    }
                );
            }
        }
    }

    receive(msg: GetStaticData){
        let ctx: Context = context();
        send(SendParameters{
                to: ctx.sender,
                value: 0,
                mode: 64, // (return msg amount except gas fees)
                bounce: true,
                body: ReportStaticData{
                    query_id: msg.query_id,
                    index_id: self.item_index,
                    collection: self.collection_address
                }.toCell()
            }
        );
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        return
            GetNftData{
                is_initialized: self.is_initialized,
                index: self.item_index,
                collection_address: self.collection_address,
                owner_address: self.owner!!,
                individual_content: b.toCell()
            };
    }
}

contract WhiteListInfo {
    manager_contract: Address;
    whitelisted: Address;
    only_owner: Address = address("EQDSjuCyZ_w_79JSNJ0YopGXpZGyP9HIYDSxBrelcTRyqYZH");
    cards_content: String = "https://storage.mappasaurus.com/meta/";
    pets_content: String = "https://storage.mappasaurus.com/petmeta/";
    egg_id: Int = 0;

    init(whitelisted: Address, id: Int) {
    let expectedAddress: Address = contractAddress(initOf MintManager(self.only_owner));
    require(sender() == expectedAddress, "Access denied on init");
    self.whitelisted = whitelisted;
    self.manager_contract = expectedAddress;
    self.egg_id = id;
    }

    receive("mintNFT") {
        let ctx: Context = context();
        require(sender() == self.whitelisted, "Only owner can mint");
        let msgValue: Int = ctx.value;
        let halfMsgValue: Int = msgValue / 2;

        let tonBalanceBeforeMsg: Int = myBalance() - halfMsgValue;
        let storageFee: Int = (minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage));
        let adjustedMsgValueFirst: Int = halfMsgValue - (storageFee + gasConsumption);
        let testCards: StateInit = initOf TestCards(self.only_owner);
        send(SendParameters {
            to: contractAddress(testCards),
            value: adjustedMsgValueFirst,
            mode: SendIgnoreErrors,
            body: MintMsg {owner: sender(), id: self.egg_id}.toCell(),
            code: testCards.code,
            data: testCards.data
        });    
    let testPets: StateInit = initOf TestPets(self.only_owner);
    tonBalanceBeforeMsg = myBalance() - adjustedMsgValueFirst;
    storageFee = (minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage));
    let adjustedMsgValueSecond: Int = halfMsgValue - (storageFee + gasConsumption);
        send(SendParameters {
            to: contractAddress(testPets),
            value: adjustedMsgValueSecond,
            mode: SendIgnoreErrors,
            body: MintMsg {owner: sender(), id: self.egg_id}.toCell(),
            code: testPets.code,
            data: testPets.data
        }); 
        send(SendParameters{
            to: self.only_owner,
            value: 0,
            mode: SendRemainingBalance | SendDestroyIfZero
        });
    }

    receive(msg: MakeWhitelist) {
        let expectedAddress: Address = contractAddress(initOf MintManager(self.only_owner));
        require(sender() == expectedAddress, "MakeWhitelist : Access denied");
        self.whitelisted = msg.whitelistThis;
        self.egg_id = msg.id;
    }


    get fun get_collection_test_cards(): Address {
    let testCards: StateInit = initOf TestCards(self.only_owner);
        return contractAddress(testCards);
    }
    get fun get_collection_test_pets(): Address {
    let testPets: StateInit = initOf TestPets(self.only_owner);
        return contractAddress(testPets);
    }
    get fun get_whitelisted_user(): Address {
        return self.whitelisted;
    }
    get fun get_manager_contract(): Address {
        return self.manager_contract;
    }
    get fun get_egg_id(): Int {
        return self.egg_id;
    }
}