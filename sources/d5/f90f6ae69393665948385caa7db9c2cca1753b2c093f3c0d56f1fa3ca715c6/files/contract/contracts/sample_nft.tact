import "@stdlib/deploy";

const service_address: Address = address("UQAxXEqtsJtMn9BH7vynSG4_AX6TKhOTpNIsSRIhe8jhgHwy"); //Сервисный адрес
const service_numerator: Int = 11; //Сервисные отчисления
const service_denominator: Int = 1000; //Сервисные отчисления
const hundred_percent: Int = 100000000000;

@name(muldiv)
native muldiv(a: Int, b: Int, c: Int): Int;

const minTonsForStorage: Int = ton("0.02"); //Минимальное количество TON на хранение
const gasConsumption: Int = ton("0.02"); //Газ за операцию
const nftMintCommission: Int = ton("0.08"); //Комиссия за МИНТ NFT
const TonTransferValue: Int = ton("0.007"); //Плата за отправку TON


contract NftCollection {
    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    royalty_params: RoyaltyParams?;
    collection_content: Cell;

    //FOR MINT NFT EFTSUKSOFT
    price_for_mint: Int as coins;
    mintable: Bool;
    local_mintable: Bool;
    max_total_nft: Int as uint32;
    isDeployed: Bool = false;
    //FOR MINT NFT EFTSUKSOFT

    //ЗАЩИТА
    // trusted_sign_address: Address = address("UQAvDV3QY4Eux-1zhj2GhTH5mXjhHXEmRQsUoxieURUpQxUH");
    // trusted_success: Bool = false;
    //ЗАЩИТА

    //ROUTE
    route_address: Address = address("UQBP6y8YGEpal4t1vGeJhGLuWG7-SAjtSHd-bnALBWzT0l3T");
    //ROUTE

    init(collection_content: Cell, royalty_params: RoyaltyParams) {
        self.owner_address = sender();
        self.collection_content = collection_content;
        self.royalty_params = royalty_params;

        //FOR MINT NFT EFTSUKSOFT
        self.price_for_mint = ton("0.01");
        self.mintable = true;
        self.local_mintable = true;
        self.max_total_nft = 1000000;
        //FOR MINT NFT EFTSUKSOFT
    }

    receive("Deploy") { //ДЕПЛОЙ СМАРТ-КОНТРАКТА
        if (!self.isDeployed) {
            self.isDeployed = true;
            self.deployMSG(sender());
        }
    }

    // receive("trusted_success") { //ЗАЩИТА СМАРТ-КОНТРАКТА
    //     require(sender()==self.trusted_sign_address, "Only the trusted sign address is allowed to use the function!");
    //     self.trusted_success = !self.trusted_success;
    // }
    receive(msg: RouteMintNFT) { //МИНТ ОТ МАРШРУТА
        self.onlyRoute();
        require(self.mintable, "Can't Mint Anymore");
        require(self.next_item_index<self.max_total_nft, "The maximum NFT limit has been exceeded!");
        
        let ctx: Context = context();
        require(ctx.value >= nftMintCommission, "Insufficient funds for a mint!");

        self.mint(msg.receiver, ctx.value);
        emit(LogEventMintRecord{ minter: msg.receiver, item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }
    receive(msg: ChangeRoute) { //Изменить адрес МАРШРУТА
        self.onlyOwner();
        self.route_address = msg.new_route;
    }
    receive("Mint"){ // Публичный MINT за TON
        //self.checkTrust();
        //Проверить открыт ли MINT
        require(self.mintable, "Mint NFT is currently disabled!");
        require(self.local_mintable, "Mint NFT is currently disabled!");

        let ctx: Context = context(); // get sender Info
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);

        //Включить цену за минт, комиссию за хранение и газ
        msgValue = msgValue - (storageFee + gasConsumption + self.price_for_mint + nftMintCommission);

        //Проверить, оплачена ли цена за минт
        require(msgValue>0, "Insufficient funds to pay for MINT NFT!");

        //Проверить, не превышает ли максимальное количество
        require(self.next_item_index<self.max_total_nft, "The maximum NFT limit has been exceeded!");

        self.mint(ctx.sender, nftMintCommission + gasConsumption);

        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }
    receive(msg: ChangeOwner) { //Изменить адрес владельца смарт-контракта
        self.onlyOwner();
        self.owner_address = msg.new_owner;
    }
    receive(msg: MintableChange) { //Изменить статус GLOBAL MINTABLE
        self.onlyOwner();
        self.mintable = msg.status;
    }
    receive(msg: LocalMintableChange) { //Изменить статус LOCAL MINTABLE
        self.onlyOwner();
        self.local_mintable = msg.status;
    }
    receive(msg: PriceForMintChange) { //Изменить ЦЕНУ ЗА МИНТ В ТОН
        self.onlyOwner();
        self.price_for_mint = msg.value;
    }
    receive(msg: MaxTotalNftChange) { //Изменить МАКСИМАЛЬНОЕ КОЛИЧЕСТВО NFT
        self.onlyOwner();
        self.max_total_nft = msg.value;
    }
    receive("withdraw ton") { //Вывести все средства со смарт-контракта
        self.onlyOwner();
        let ctx: Context = context();
        require(ctx.value - TonTransferValue*2 - gasConsumption - minTonsForStorage > 0, "There are not enough funds for the transaction!");
        //Считаем отчисления сервису
        let service_fee = muldiv(myBalance(), muldiv(service_numerator, hundred_percent, service_denominator), hundred_percent);
        //Отправляем TON сервису
        self.send_service_fee(service_fee);
        //Отправляем TON владельцу
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - minTonsForStorage - service_fee,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    } 
    receive(msg: Withdraw) { //Вывести определённую сумму со смарт-контракта
        self.onlyOwner();
        let amount: Int = min(msg.amount, myBalance() - context().value - minTonsForStorage);
        require(amount>0, "Insufficient balance");
        //Считаем отчисления сервису
        let service_fee = muldiv(amount, muldiv(service_numerator, hundred_percent, service_denominator), hundred_percent);
        //Отправляем TON сервису
        self.send_service_fee(service_fee);
        //Отправляем TON владельцу
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: amount - service_fee,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    }
    receive(msg: ProvideNFTAddress) { //ProvideNFTAddress
        let nft_address: Address = self.get_nft_address_by_index(msg.nft_index);
        send(SendParameters {
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: TakeNFTAddress{
                query_id: msg.query_id,
                nft_address: nft_address,
            }.toCell()
        });
    }
    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) { //Функция минта NFT
        require(self.next_item_index >= 0, "non-sequential NFTs");
        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: msgValue,
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: sender,
                    response_destination: self.owner_address,
                    custom_payload: self.collection_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        // dump(self.next_item_index); // Reference at: https://tact-by-example.org/03-emit
        self.next_item_index = self.next_item_index + 1;
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
                destination: self.owner_address
            }.toCell()
        });        
    }

    fun onlyOwner() {
        require(sender()==self.owner_address, "Only the owner is allowed to use the function!");
        //self.checkTrust();
    }
    fun onlyRoute() {
        require(sender()==self.route_address, "Only the ROUTE is allowed to use the function!");
        //self.checkTrust();
    }
    // fun checkTrust() { //Активация Смарт-контракта
    //     require(self.trusted_success, "Smart-contract currently disabled!");
    // }
    fun deployMSG(address: Address) {
        send(SendParameters{
            to: address, // sending message back to the sender
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: "Deployed!".asComment(),
        });
    }
    fun send_service_fee(service_fee: Int) {
        send(SendParameters{
            to: service_address,
            bounce: true,
            value: service_fee,
            mode: SendPayGasSeparately + SendIgnoreErrors,
            body: "Service fee!".asComment()
        });
    }

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("collection.json");
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }
    get fun get_nft_address_by_index(item_index: Int): Address {      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }
    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index);
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
    get fun get_nft_mintable(): Bool {
        return self.mintable;
    }
    get fun get_nft_mint_price(): Int {
        return self.price_for_mint;
    }
    get fun get_nft_min_mint_price(): Int {
        return (minTonsForStorage + gasConsumption + self.price_for_mint);
    }
}

contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;

    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer){
        let ctx: Context = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context
        let msgValue: Int = self.msgValue(ctx.value);
        
        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.collection_address, "initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            send(SendParameters{
                to: msg.response_destination!!,
                value: msgValue,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        } else {
            require(ctx.sender == self.owner!!, "not owner");
            self.owner = msg.new_owner;  // change current owner to the new_owner
            if (msg.forward_amount > 0) {
                send(SendParameters{
                    to: msg.new_owner,
                    value: msg.forward_amount,
                    mode:  SendPayGasSeparately, 
                    bounce: true,
                    body: OwnershipAssigned{
                        query_id: msg.query_id,
                        prev_owner: ctx.sender,
                        forward_payload: msg.forward_payload
                    }.toCell()
                }); 
            }

            msgValue = msgValue - ctx.readForwardFee(); 
            if (msg.response_destination != null) { 
                send(SendParameters{ 
                    to: msg.response_destination!!,
                    value: msgValue - msg.forward_amount,
                    mode: SendPayGasSeparately,
                    bounce: true,
                    body: Excesses { query_id: msg.query_id }.toCell()
                });
            } 
        }
    }
    
    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: 64,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        b.append(self.item_index.toString());
        b.append(".json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }
}

message LogEventMintRecord {
    minter: Address;
    item_id: Int;
    generate_number: Int;
}

message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}
message(0xa8cb00ad) ReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}
struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}

message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}
message MintableChange {
    status: Bool;
}
message LocalMintableChange {
    status: Bool;
}
message PriceForMintChange {
    value: Int as coins;
}
message MaxTotalNftChange {
    value: Int as uint32;
}
message Withdraw {
    amount: Int as coins;
}
message RouteMintNFT {
    receiver: Address;
}
message ChangeRoute {
    new_route: Address;
}
message ChangeOwner {
    new_owner: Address;
}
message ProvideNFTAddress {
    query_id: Int as uint64;
    nft_index: Int as uint64;
}
message TakeNFTAddress {
    query_id: Int as uint64;
    nft_address: Address;
}

struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}