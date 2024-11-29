import "./message.tact";
import "@stdlib/deploy";
const minTonsForStorage: Int = ton("0.05");
const gasConsumption: Int = ton("0.05");

contract NftCollection with Deployable {
    next_item_index: Int as uint32 = 1;
    owner_address: Address;    
    treasury_address: Address;               
    collection_content: Cell;   
    nft_price: Int;
    authority_address: Address;
    max_collection_amount: Int;
    total_minted_amount: Int = 0;
    sale_status: Int = 1; // 0: Not active, 1: Active
    minted_amounts: map<Address, Int>;

    init(treasury_address: Address, collection_content: Cell){
        self.owner_address = sender();
        self.authority_address = sender();
        self.treasury_address = treasury_address;
        self.collection_content = collection_content;
        self.nft_price = 1000000000; // 1 TON
        self.max_collection_amount = 1000000; // 1M NFTs
    }

    receive(msg: MintNFT) {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let totalCost: Int = self.get_nft_mint_total_cost();
        let nftCost: Int = self.get_sale_price();

        require(msg.amount > 0, "Invalid mint amount");
        require(self.sale_status == 1, "Sale is not active");
        require(self.total_minted_amount + msg.amount <= self.max_collection_amount, "Exceeds max collection amount");
        require(msgValue >= totalCost * msg.amount, "Insufficient funds for minting");

        let currentMintedAmount: Int = 0;
        if (self.minted_amounts.get(ctx.sender) != null) {
            currentMintedAmount = self.minted_amounts.get(ctx.sender)!!;
        }
        self.minted_amounts.set(ctx.sender, currentMintedAmount + msg.amount);

        if (self.nft_price > 0) {
            let NftTotalCost = self.nft_price * msg.amount;
            send(SendParameters{
                to: self.treasury_address,
                value: NftTotalCost,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "NFT Sale".asComment()
            });
        }

        repeat(msg.amount) {
            self.mint(ctx.sender);
            self.total_minted_amount += 1;
            emit(LogEventMintRecord{
                minter: sender(),
                item_id: self.next_item_index,
                generate_number: nativeRandom()
            }.toCell());
        }
    }

    // ===== Owner Functions ===== //
    receive(msg: UpdateSaleStatus) {
        require(sender() == self.owner_address, "Only owner can update sale status");
        require(msg.new_status >= 0 && msg.new_status <= 2, "Invalid status");
        self.sale_status = msg.new_status;
    }

    receive(msg: UpdateTreasuryAddress) {
        require(sender() == self.owner_address, "Only owner can update treasury address");
        self.treasury_address = msg.new_treasury_address;
    }

    receive(msg: UpdateSalePrice) {
        require(sender() == self.owner_address, "Only owner can update sale price");
        self.nft_price = msg.new_price;
    }

    receive(msg: UpdateCollectionSize) {
        require(sender() == self.owner_address, "Only owner can update collection size");
        self.max_collection_amount = msg.new_size;
    }

    receive("Withdraw") {
        require(sender() == self.owner_address, "Only owner can withdraw");
        let withdrawAmount: Int = myBalance() - context().value - minTonsForStorage;
        require(withdrawAmount > 0, "No TON to withdraw");
        send(SendParameters{
            to: sender(),
            bounce: true,
            value: withdrawAmount,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    // ===== Private Methods ===== //
    fun mint(sender: Address) {
        require(self.next_item_index > 0, "Invalid NFT index");

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        let nft_address: Address = contractAddress(nft_init);
        let deploymentCost: Int = minTonsForStorage + gasConsumption;

        emit(LogMintDebug{
            index: self.next_item_index,
            nft_address: nft_address,
            deployment_cost: deploymentCost
        }.toCell());

        send(SendParameters{
            to: nft_address,
            value: deploymentCost,     
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

        self.next_item_index += 1;         
    }

    fun sendToTreasury(amount: Int) {
        send(SendParameters{
            to: self.treasury_address,
            bounce: true,
            value: amount,
            mode: SendRemainingBalance + SendIgnoreErrors
        });
    }

    // --------- Get Collection Metadata Function --------- //
    get fun get_collection_data(): CollectionData {     
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        b.append(collectionDataString);
        b.append("meta.json");
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun get_sale_status(): String {
        if (self.sale_status == 0) {
            return "Not active";
        } else if (self.sale_status == 1) {
            return "Active";
        } else {
            return "Paused";
        }
    }

    get fun get_sale_price(): Int {
        return self.nft_price;
    }

    get fun get_collection_size(): Int {
        return self.max_collection_amount;
    }

    get fun get_total_minted_amount(): Int {
        return self.total_minted_amount;
    }

    get fun get_minted_amount_by_user(user_address: Address): Int {
        if (self.minted_amounts.get(user_address) != null) {
            return self.minted_amounts.get(user_address)!!;
        }
        return 0;
    }

    get fun get_nft_mint_total_cost(): Int {
        return (minTonsForStorage + gasConsumption + self.nft_price);
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, self.authority_address);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let ic: String = individual_content.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }
}

contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;

    owner: Address?;
    individual_content: Cell?;

    authority_address: Address?;
    revoked_at: Int as uint64 = 0;

    init(collection_address: Address, item_index: Int, authority_address: Address){
        require(sender() == collection_address, "Not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
        self.authority_address = authority_address;
    }

    receive(msg: Transfer){
        let ctx: Context = context(); 
        let msgValue: Int = self.msgValue(ctx.value);
        
        if (self.is_initialized == false) {  // Initial Transfer, aka the "Minting" of the NFT
            require(ctx.sender == self.collection_address, "Initialized tx need from collection");
            self.is_initialized = true;
            self.owner = msg.new_owner;
            self.individual_content = msg.custom_payload;
            if (msgValue > 0) {
                    send(SendParameters{
                    to: msg.new_owner,
                    value: msgValue,
                    mode: SendPayGasSeparately,
                    body: Excesses { query_id: msg.query_id }.toCell()
                });
            }
        } else {
            require(false, "SBT cannot be transferred");
        }
    }
    
    receive(msg: GetStaticData){ 
        send(SendParameters {
            to: sender(),
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

    receive(msg: ProveOwnership) {
        require(sender() == self.owner, "Not owner");
        send(SendParameters{
            to: msg.dest,
            value: 0,
            mode: 64,
            body: OwnershipProof {
                query_id: msg.query_id,
                item_id: self.item_index,
                owner: self.owner!!,
                data: msg.forward_payload,
                revoked_at: self.revoked_at,
                content: msg.with_content ? self.individual_content : null
            }.toCell()
        });
    }

    receive(msg: RequestOwner) {
        send(SendParameters{
            to: msg.dest,
            value: 0,
            mode: 64,
            body: OwnerInfo {
                query_id: msg.query_id,
                item_id: self.item_index,
                initiator: sender(),
                owner: self.owner!!,
                data: msg.forward_payload,
                revoked_at: self.revoked_at,
                content: msg.with_content ? self.individual_content : null
            }.toCell()
        });
    }

    receive("Destroy") {
        require(sender() == self.owner, "Not owner");
        self.owner = null;
        self.authority_address = null;
        self.revoked_at = 0;
        let excess: Int = myBalance() - context().value - minTonsForStorage;

        if (excess > 0) {
            send(SendParameters{
                to: sender(),
                bounce: false,
                value: excess,
                mode: SendRemainingValue + SendIgnoreErrors
            });
        }
    }

    receive(msg: Revoke) {
        require(sender() == self.authority_address, "Not authorized");
        require(self.revoked_at == 0, "Already revoked");
        self.revoked_at = now();
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }

    // --------- Get Item Metadata Function --------- //
    get fun get_nft_data(): GetNftData {
        let b: StringBuilder = beginString();
        let collectionData: String = (self.individual_content!!).asSlice().asString();
        b.append(collectionData);
        b.append("item.json");

        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: b.toCell()
        };
    }

    get fun get_authority_address(): Address? {
        return self.authority_address;
    }

    get fun get_revoked_time(): Int {
        return self.revoked_at;
    }
}