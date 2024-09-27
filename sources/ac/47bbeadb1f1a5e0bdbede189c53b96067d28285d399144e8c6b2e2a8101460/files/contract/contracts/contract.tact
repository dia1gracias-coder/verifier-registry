import "./message.tact";
const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

contract NftCollection {
    ipfs_hashes: map<Int, Bool>;  // Maps hashed IPFS Cell (as Int) to a boolean flag
    next_item_index: Int as uint32 = 0;
    max_items_supply: Int as uint32 = 1024;
    reserved_items_count: Int as uint32 = 45; // Reserved items for the owner
    minted_reserved_items: Int as uint32 = 0; // Track the number of reserved items minted
    mint_price: Int = ton("1");
    owner_address: Address;
    royalty_params: RoyaltyParams?;
    collection_content: Cell;

    // Add a hashed IPFS Cell to the map
    fun addIpfsHash(hash: Int) {
        self.ipfs_hashes.set(hash, true);  // Use true to signify the hash has been used
    }

    // Check if a hashed IPFS Cell exists in the map
    fun ipfsHashExists(hash: Int): Bool {
        return self.ipfs_hashes.get(hash) != null;  // Return true if hash exists
    }

    // Clear the map after minting is complete
    fun clearIpfsHashes() {
        self.ipfs_hashes = emptyMap();  // Reinitialize the map to free storage
    }

    init(owner_address: Address, collection_content: Cell, royalty_params: RoyaltyParams){
        self.owner_address = owner_address;
        self.collection_content = collection_content; 
        self.royalty_params = royalty_params;
    }

    receive("WithdrawMax") {
        let ctx: Context = context();
        require(ctx.sender == self.owner_address, "Only the owner can withdraw");
        
        let amount: Int = myBalance() - minTonsForStorage;
        if (amount > 0) {
            send(SendParameters{
                to: self.owner_address,
                value: amount,
                bounce: false,
                mode: SendIgnoreErrors
            });
        }
    }

    receive("Withdraw") {
        let ctx: Context = context();
        require(ctx.sender == self.owner_address, "Only the owner can withdraw");
        
        // Calculate the amount needed to store minted NFTs
        let mintedNfts: Int = self.next_item_index;
        let reserveAmount: Int = mintedNfts * minTonsForStorage; // Assuming 0.02 TON per minted NFT
        // Add minimum balance for the collection contract itself
        reserveAmount = reserveAmount + minTonsForStorage;
        // Calculate withdrawable amount
        let withdrawableAmount: Int = myBalance() - reserveAmount;
        
        // Only withdraw if there's excess balance
        if (withdrawableAmount > 0) {
            send(SendParameters{
                to: self.owner_address,
                value: withdrawableAmount,
                bounce: false,
                mode: SendIgnoreErrors
            });
        }
    }

    receive(msg: MintParams) {
        let ctx: Context = context(); // get sender Info
        require(ctx.sender == self.owner_address, "Only the owner can mint, use PaidMint to mint for others");
        require(self.minted_reserved_items < self.reserved_items_count, "Reserved items supply (45) has been reached");
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        self.paidMint(msg.destination, msgValue, msg.item_content);
        self.minted_reserved_items = self.minted_reserved_items + 1; // Increment reserved items count
        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    } 

    receive(msg: PaidMintParams) {
        let ctx: Context = context(); // get sender Info
        require((self.next_item_index - self.minted_reserved_items) < (self.max_items_supply - self.reserved_items_count), "exceed max supply (1024)");
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        msgValue = msgValue - (storageFee + gasConsumption);
        require(msgValue >= self.mint_price, "Not enough funds for minting (1TON + GAS fee per NFT)");
        self.paidMint(msg.destination, msgValue, msg.item_content);
        emit(LogEventMintRecord{ minter: sender(), item_id: self.next_item_index, generate_number: nativeRandom() }.toCell());
    }

    fun paidMint(new_owner: Address, msgValue: Int, item_content: Cell) {
        require(self.next_item_index >= 0, "non-sequential NFTs");

        // Use the item_content Cell directly as the IPFS hash
        let ipfsHashCell: Cell = item_content;
        // Hash the IPFS Cell
        let hashedIpfs: Int = ipfsHashCell.hash();  // Use the built-in hash() function
        require(!self.ipfsHashExists(hashedIpfs), "NFT with this IPFS hash already exists");

        
        // Deduct the mint price from the msgValue
        let nftMsgValue: Int = msgValue - self.mint_price;

        let nft_init: StateInit = self.getNftItemInit(self.next_item_index);
        send(SendParameters{
                to: contractAddress(nft_init), 
                value: nftMsgValue, 
                bounce: false,
                mode: SendIgnoreErrors,
                body: Transfer {
                    query_id: 0,
                    new_owner: new_owner,
                    response_destination: self.owner_address,
                    custom_payload: item_content,
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell(),
                code: nft_init.code,
                data: nft_init.data
            });
        // Store the new hashed IPFS Cell in the map
        self.addIpfsHash(hashedIpfs);
        // increment index
        self.next_item_index = self.next_item_index + 1;
        // Clear the map if all items have been minted
        if (self.next_item_index >= self.max_items_supply) {
            self.clearIpfsHashes();
        }
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
        b.append("Qmej5zvHHvG3Q49di1RwgANUBrEznWHN1sRc4Xk9pLdjm9"); // COLLECTION META.
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: b.toCell(), 
            owner_address: self.owner_address
        };
    }

    get fun get_minting_data(): MintingData {     
        return MintingData{
            next_item_index: self.next_item_index, 
            max_items_supply: self.max_items_supply,
            reserved_items_count: self.reserved_items_count,
            minted_reserved_items: self.minted_reserved_items,
            mint_price: self.mint_price
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address?{      
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    get fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, self.collection_content);
    }
    
    get fun get_nft_content(index: Int, individual_content: Cell): Cell { 
        let b: StringBuilder = beginString();
        let collectionDataString: String = self.collection_content.asSlice().asString();
        let itemIpfsDataHash: String = individual_content.asSlice().asString();
        b.append(collectionDataString);
        b.append(itemIpfsDataHash);
        return b.toCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royalty_params!!;
    }

    // Getter to retrieve all IPFS hashes
    get fun get_ipfs_hashes(): map<Int, Bool> {
        return self.ipfs_hashes;
    }
}

contract NftItem {
    collection_address: Address;
    item_index: Int; 
    is_initialized: Bool;
    common_content: Cell;

    owner: Address?;
    individual_content: Cell?;

    init(collection_address: Address, item_index: Int, common_content: Cell){
        require(sender() == collection_address, "not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
        self.common_content = common_content;
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
        return GetNftData {
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner!!,
            individual_content: self.individual_content!!
        };
    }
}
