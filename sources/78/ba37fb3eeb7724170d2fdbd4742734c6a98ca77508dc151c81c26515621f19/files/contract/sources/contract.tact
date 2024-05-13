import "./message.tact";
import "./jetton.tact";
import "@stdlib/ownable";
const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

message EventMintRecord {
    minter: Address;
    item_id: Int;
    generate_number: Int;
}

struct NFTInfo {
    owner: Address;
    end: Int;
}

contract Stake with Ownable {
    const gasConsumption: Int = ton("0.2");
    const MinTonForStorage: Int = ton("0.01");
    const GasJettonTransfer: Int = ton("0.5");
    const GasNFTTransfer: Int = ton("0.3");

    const phone_amount_start: Int = ton("10500");
    const phone_amount_end: Int = ton("94500");

    nft_info: map<Address, NFTInfo>;
    owner: Address;
    nft_address: Address;
    jetton_address: Address;
    jetton_balance: Int;
    duration: Int = 1000;
    balance: Int = 0;

    last_sender: Address;
    last_init: Address;
    last_index: Int = 10;

    init(nft_address: Address, jetton_address: Address) {
        self.owner = sender();
        self.nft_address = nft_address;
        self.jetton_address = jetton_address;
        self.jetton_balance = 0;
        self.last_sender = jetton_address;
        self.last_init = jetton_address;
    }

    receive() {
        let ctx: Context = context();
        self.balance = self.balance + ctx.value;
    }

    receive("withdraw") {
        self.requireOwner();
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    receive(msg: ChangeNFT) {
        self.requireOwner();
        self.nft_address = msg.nft;
    }

    receive(msg: ChangeJetton) {
        self.requireOwner();
        self.jetton_address = msg.jetton;
    }

    receive(msg: ChangeDuration) {
        self.requireOwner();
        self.duration = msg.duration;
    }

    receive(msg: Recharge) {
        self.requireOwner();
        let ctx: Context = context();
        let final: Int = self.gasConsumption;
        require(ctx.value > final, "Invalid value");
        send(SendParameters{
            to: self.jetton_address, 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransfer{ 
                query_id: 0,
                amount: msg.amount,
                sender: self.owner,
                custom_payload: beginCell().endCell(),
                response_destination: self.owner,
                forward_ton_amount: final,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell()
        });
    }

    receive(msg: OwnershipAssigned) {
        let ctx: Context = context();

        let sinit: StateInit = initOf NftItem(self.nft_address, msg.index); 
        require(contractAddress(sinit) == ctx.sender, "Invalid sender!"); 

        self.last_sender = ctx.sender;
        self.last_init = contractAddress(sinit);
        self.last_index = msg.index;

        let final: Int = self.gasConsumption;
        require(ctx.value > final, "Invalid value");

        require( self.nft_info.get(ctx.sender) == null, "This item has claimed.");
        self.nft_info.set(ctx.sender, NFTInfo{owner: msg.prev_owner, end:now() + self.duration});
        send(SendParameters{
            to: self.jetton_address, 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransfer{ 
                query_id: 0,
                amount: self.phone_amount_start,
                sender: msg.prev_owner,
                custom_payload: emptyCell(),
                response_destination: msg.prev_owner,
                forward_ton_amount: final,
                forward_payload: emptySlice()
            }.toCell()
        });
    }

    receive(msg: Withdraw) {
        let ctx: Context = context();
        let final: Int = self.gasConsumption;
        require(ctx.value > final, "Invalid value");
        let info: NFTInfo = self.nft_info.get(msg.item_address)!!;
        require(ctx.sender == info.owner, "Not the owner of item");
        require(now() >= info.end, "Not end of item");
        send(SendParameters{
            to: msg.item_address, 
            value: self.GasNFTTransfer, 
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer {
                query_id: 0,
                new_owner: info.owner,
                response_destination: info.owner,
                custom_payload: emptyCell(),
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell()
        });
        send(SendParameters{
            to: self.jetton_address, 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransfer{ 
                query_id: 0,
                amount: self.phone_amount_end,
                sender: info.owner,
                custom_payload: emptyCell(),
                response_destination: info.owner,
                forward_ton_amount: final,
                forward_payload: emptySlice()
            }.toCell()
        });
    }

    receive(msg: TokenNotification) {
        // if (ctx.sender != self.jetton_address) { 
        //     let sinit: StateInit = initOf JettonDefaultWallet(msg.from, self.jetton_address); 
        //     require(contractAddress(sinit) == ctx.sender, "Invalid sender!"); 
        // }
        self.jetton_balance = msg.amount + self.jetton_balance;
    }

    get fun get_info_by_item(item_address: Address): NFTInfo?{
        return self.nft_info.get(item_address);
    }

    // get fun get_owner_by_item(item_address: Address): Address?{
    //     let info: NFTInfo? = self.nft_info.get(item_address);
    //     return info?.owner;
    //     if(self.nft_info.get(item_address) == null){
    //         return 0;
    //     }
    //     let info: NFTInfo = self.nft_info.get(item_address)!!;
    //     return info.owner;
    // }

    get fun get_end_by_item(item_address: Address): Int{
        if(self.nft_info.get(item_address) == null){
            return 0;
        }
        let info: NFTInfo = self.nft_info.get(item_address)!!;
        return info.end;
    }

    get fun get_nft_address(): Address{      
        return self.nft_address;
    }

    get fun get_jetton_address(): Address{      
        return self.jetton_address;
    }

    get fun get_jetton_balance(): Int{      
        return self.jetton_balance;
    }

    get fun get_sender(): Address{      
        return self.last_sender;
    }

    get fun get_init(): Address{      
        return self.last_init;
    }

    get fun get_index(): Int{      
        return self.last_index;
    }
    
} 

contract NftCollection with OwnableTransferable {
    owner: Address;
    next_item_index: Int as uint32 = 0;
    max_supply: Int as uint32 = 6000;
    owner_address: Address;
    royalty_params: RoyaltyParams?;                      
    collection_content: Cell;  
    balance: Int as uint32 = 0;
    price: Int as uint256 = ton("10000");
    jetton_address: Address;

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams, owner: Address, jetton_address: Address){
        self.owner_address = owner_address;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
        self.owner = owner;
        self.jetton_address = jetton_address;
    }

    receive("Mint"){
        self.requireOwner();
        let ctx: Context = context(); // get sender Info
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        self.mint(ctx.sender, msgValue);

        emit(EventMintRecord{
            minter: sender(), 
            item_id: self.next_item_index, 
            generate_number: nativeRandom() 
        }.toCell());
    }

    receive(msg: ChangeJetton) {
        self.requireOwner();
        self.jetton_address = msg.jetton;
    }

    receive(msg: Recharge) {
        self.requireOwner();
        let ctx: Context = context();
        let final: Int = gasConsumption;
        require(ctx.value > final, "Invalid value");
        send(SendParameters{
            to: self.jetton_address, 
            value: 0, 
            bounce: true,
            mode: SendRemainingValue,
            body: TokenTransfer{ 
                query_id: 0,
                amount: msg.amount,
                sender: self.owner,
                custom_payload: beginCell().endCell(),
                response_destination: self.owner,
                forward_ton_amount: final,
                forward_payload: beginCell().endCell().asSlice()
            }.toCell()
        });
    }

    receive(msg: TokenNotification) {
        let expectedAddress: Address = self.jetton_address;
        let ctx: Context = context();

        if (ctx.sender != self.jetton_address) { 
            let sinit: StateInit = initOf JettonDefaultWallet(msg.from, self.jetton_address); 
            require(contractAddress(sinit) == ctx.sender, "Invalid sender!"); 
        }
        
        require(msg.amount == self.price, "Not match price");
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        self.mint(msg.from, msgValue);

        emit(EventMintRecord{
            minter: msg.from, 
            item_id: self.next_item_index, 
            generate_number: nativeRandom() 
        }.toCell());
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
        // dump(self.next_item_index);
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

    // ------------------ Get Function  ------------------ //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        // b.append("meta.json"); // You can changed this your self.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
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

    get fun get_jetton_address(): Address {
        return self.jetton_address;
    }
}

contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;
    const PhoneGas: Int = ton("0.4");

    init(collection_address: Address, item_index: Int){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
    }

    receive(msg: Transfer){
        let ctx: Context = context();

        let msgValue: Int = ctx.value; // Check the gasCost for storage
        // require(msgValue >= self.PhoneGas, "More fee for PHONE");
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        
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
                        index: self.item_index,
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

    // --------- Get Function  --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        b.append("metaphone.mypinata.cloud/ipfs/QmZa1ZQvxTPDbfNUDKYULCBp1p1Qf97HkG9PThYYgRzw9Y");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }
}
