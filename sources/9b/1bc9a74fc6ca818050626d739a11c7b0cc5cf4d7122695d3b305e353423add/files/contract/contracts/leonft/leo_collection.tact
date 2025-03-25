import "@stdlib/deploy";
import "./leo_const.tact";


contract NftCollection with Deployable {
    next_item_index: Int as uint32 = 0;
    owner_address: Address;
    royalty_params: RoyaltyParams?;
    collection_content: Cell;
    nft_item_code: Cell;
    price_for_mint: Int as coins;
    mintable: Bool;
    public_mintable: Bool;
    max_total_nft: Int as uint32;
    route_address: Address;
    json_list: map<Int, Cell>;
    json_list_index: Int as uint32 = 0;
    json_list_max_index: Int as uint32;
    json_list_change_index: Int as uint32;

    init(royalty_params: RoyaltyParams, owner: Address, nft_item_code: Cell) {
        self.owner_address = owner;
        self.royalty_params = royalty_params;
        self.nft_item_code = nft_item_code;
        self.price_for_mint = ton("0.25");
        self.mintable = true;
        self.public_mintable = true;
        self.max_total_nft = 1000000;
        self.route_address = self.owner_address;
        self.json_list_max_index = 9;
        self.json_list_change_index = 100000;
        self.json_list.set(0, "https://gateway.pinata.cloud/ipfs/bafybeifxlq676z4ikwvfflrn7f7fhyunbbl6ug4lrv7hs6nr63cxmamxgi/".asSlice().asCell());
        self.json_list.set(1, "https://gateway.pinata.cloud/ipfs/bafybeia5rmezprq3dy4l4h3jn6l5m5hbt3tdbxddtaoprtspubwzoq3fh4/".asSlice().asCell());
        self.json_list.set(2, "https://gateway.pinata.cloud/ipfs/bafybeifqtutaafvg5cwu53xmirsifbjinh34vceuaztr5colbnykxacmea/".asSlice().asCell());
        self.json_list.set(3, "https://gateway.pinata.cloud/ipfs/bafybeig7svu7kzxoqwik433bckphwnyxdwpec5oqk4mbpeswuees5rk5be/".asSlice().asCell());
        self.json_list.set(4, "https://gateway.pinata.cloud/ipfs/bafybeiaxptjithjpxj7xiqgstatecvucqn4nuve5xyrgzz3lxssuxqvw4y/".asSlice().asCell());
        self.json_list.set(5, "https://gateway.pinata.cloud/ipfs/bafybeih3q5hctwij7je7x6yn4zlowjddhnsoduq7ujk6xps44je72iib4u/".asSlice().asCell());
        self.json_list.set(6, "https://gateway.pinata.cloud/ipfs/bafybeiedqnxafyoa3zcsukjsirzyvmy7cxcpd6tqckuixpg6dproals3wq/".asSlice().asCell());
        self.json_list.set(7, "https://gateway.pinata.cloud/ipfs/bafybeifse2mr34m4g4fq54kb7gmdn5oobcjyxfodbpbxzp3ldupcchh4sa/".asSlice().asCell());
        self.json_list.set(8, "https://gateway.pinata.cloud/ipfs/bafybeidhhefyut4t26ktk2tpvichbropge6ixjpeimdaeounbvloiexxxy/".asSlice().asCell());
        self.json_list.set(9, "https://gateway.pinata.cloud/ipfs/bafybeidcugwwuuao7bf2ie2xchnpirwhyy6bwyqugikgdwzlsqxdnzemry/".asSlice().asCell());
        let contentCell = beginCell().storeInt(0x01, 8).storeSlice((self.json_list.get(self.json_list_index)!!).asSlice()).endCell();
        self.collection_content = contentCell;
    }

    receive() {}
    receive(str: String) {}
    receive(msg: Slice) {}

    receive("Mint"){
        require(self.mintable, "Mint NFT is currently disabled!");
        require(self.public_mintable, "Mint NFT is currently disabled!");
        let ctx: Context = context();
        let msgValue: Int = self.msgValue(ctx.value);
        require(msgValue-(self.price_for_mint+nftMintCommission)>=0, "Insufficient funds to pay for MINT NFT!");
        require(self.next_item_index<self.max_total_nft, "The maximum NFT limit has been exceeded!");
        self.mint(ctx.sender, nftMintCommission + gasConsumption);
        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }
    receive("mintable") {
        self.onlyOwner();
        self.mintable = !self.mintable;
    }
    receive("public_mintable") {
        self.onlyOwner();
        self.public_mintable = !self.public_mintable;
    }
    receive("withdraw ton") {
        self.onlyOwner();
        let ctx: Context = context();
        require(ctx.value - TonTransferValue*2 - gasConsumption - minTonsForStorage > 0, "There are not enough funds for the transaction!");
        let service_fee = muldiv(myBalance(), muldiv(service_numerator, hundred_percent, service_denominator), hundred_percent);
        self.send_service_fee(service_fee);
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: myBalance() - context().value - minTonsForStorage - service_fee,
            mode: SendIgnoreErrors + SendRemainingValue
        });
    } 
    receive(msg: RouteMintNFT) {
        self.onlyRoute();
        require(self.mintable, "Can't Mint Anymore");
        require(self.next_item_index<self.max_total_nft, "The maximum NFT limit has been exceeded!");
        let ctx: Context = context();
        let msgValue: Int = self.msgValue(ctx.value);
        if (msgValue - nftMintCommission >= 0) {
            self.mint(msg.receiver, msgValue);
            emit(LogEventMintRecord{ minter: msg.receiver, item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
        }
    }
    receive(msg: ChangeRoute) {
        self.onlyOwner();
        self.route_address = msg.new_route;
    }
    receive(msg: ChangePrice) {
        self.onlyOwner();
        self.price_for_mint = msg.value;
    }
    receive(msg: ChangeMaxTotal) {
        self.onlyOwner();
        self.max_total_nft = msg.value;
    }
    receive(msg: Withdraw) {
        self.onlyOwner();
        let amount: Int = min(msg.amount, myBalance() - context().value - minTonsForStorage);
        require(amount>0, "Insufficient balance");
        let service_fee = muldiv(amount, muldiv(service_numerator, hundred_percent, service_denominator), hundred_percent);
        self.send_service_fee(service_fee);
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
    receive(msg: ChangeOwner) {
        self.onlyOwner();
        self.owner_address = msg.newOwner;
    }
    receive(msg: GetRoyaltyParams) {   
        let ctx: Context = context();
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

    // ===== Private Methods ===== //
    fun mint(sender: Address, msgValue: Int) {
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
        self.next_item_index = self.next_item_index + 1;
        if (self.next_item_index%self.json_list_change_index==0) {
            if (self.json_list_index < self.json_list_max_index) {
                self.json_list_index = self.json_list_index + 1;
                self.collection_content = self.createCollContent();
            }
        }
    }
    fun createCollContent(): Cell {
        let contentCell = beginCell().storeInt(0x01, 8).storeSlice((self.json_list.get(self.json_list_index)!!).asSlice()).endCell();
        return contentCell;
    }
    fun onlyOwner() {
        require(sender()==self.owner_address, "Only the owner is allowed to use the function!");
    }
    fun onlyRoute() {
        require(sender()==self.route_address, "Only the ROUTE is allowed to use the function!");
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
    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }
    // ===== Private Methods ===== //


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
        let data = beginCell()
            .storeUint(0, 1)
            .storeAddress(myAddress())
            .storeInt(item_index, 257)
        .endCell();
        return StateInit {
            code: self.nft_item_code,
            data: data
        }
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
    get fun get_nft_mintable_public(): Bool {
        return self.public_mintable;
    }
    get fun get_nft_min_mint_price(): Int {
        return (nftMintCommission + gasConsumption + self.price_for_mint);
    }
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
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message LogEventMintRecord {
    minter: Address;
    item_id: Int;
    generate_number: Int;
}
message ProvideNFTAddress {
    query_id: Int as uint64;
    nft_index: Int as uint64;
}
message TakeNFTAddress {
    query_id: Int as uint64;
    nft_address: Address;
}
message RouteMintNFT {
    receiver: Address;
}
message ChangeRoute {
    new_route: Address;
}
message ChangePrice {
    value: Int as coins;
}
message ChangeOwner {
    newOwner: Address;
}
message Withdraw {
    amount: Int as coins;
}
message ChangeMaxTotal {
    value: Int as uint32;
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