import "../item/item";
import "./message";
import "../common/message";
import "../common/constants";
import "./query-tracker";

contract Collection with QueryTracker {
    owner: Address;
    baseURI: Cell;
    paymentPublicKey: Int as uint256;
    commonData: Builder;

    // Query Tracking
    oldQueries: map<Int as uint13, Cell>;
    queries: map<Int as uint13, Cell>;
    lastCleanTime: Int as uint64;
    timeoutSeconds: Int as uint22;

    // Minted token index map
    mintedTokenIndexMap: map<Int as uint64, Bool>;

    init(owner: Address, collectionContent: Cell, paymentPublicKey: Int as uint256, timeoutSeconds: Int as uint22) {
        self.owner = owner;
        self.baseURI = collectionContent;
        self.paymentPublicKey = paymentPublicKey;
        self.commonData = beginCell().storeUint(0, 1).storeAddress(myAddress());

        // Query tracking
        require(timeoutSeconds >= 3600, "Timeout too short");
        self.timeoutSeconds = timeoutSeconds;
        self.lastCleanTime = now();
        self.queries = emptyMap();
        self.oldQueries = emptyMap();
        self.mintedTokenIndexMap = emptyMap();
    }

    // ===== Receive Methods ===== //
    receive() {}
    receive(msg: Mint){     
        let params = self.extractQueryParams(msg.queryId);

        require(self.isQueryProcessed(params) == false, "Query already processed");
        require(msg.tokenIndex > 0, "Token index must be greater than 0");

        let hasMinted = self.mintedTokenIndexMap.get(msg.tokenIndex);
        if (hasMinted != null){
            require(hasMinted == false, "Token index already minted");
        }

        // Create hash for signature verification (including collectorPoints)
        let hash: Int = beginCell().storeInt(msg.queryId, 64).storeAddress(msg.owner).storeUint(msg.collectorPoints, 16).endCell().hash();
        let check: Bool = checkSignature(hash, msg.signature, self.paymentPublicKey);
        require(check == true, "Invalid signature");


        let ctx: Context = context(); // get sender Info
        let msgValue: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);

        msgValue -= storageFee + gasConsumption;

        self.mint(msg.owner, msgValue, msg.collectorPoints, msg.tokenIndex);
        self.markQueryIdAsProcessed(params);
        self.mintedTokenIndexMap.set(msg.tokenIndex, true);

        emit(LogEventMintRecord{ minter: msg.owner, itemId: msg.tokenIndex, generateNumber: nativeRandom() }.toCell());
    }

    receive(msg: ChangeOwner) {
        // Only current owner can change ownership
        require(sender() == self.owner, "Only owner can change ownership");
        
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        
        // Update owner
        self.owner = msg.newOwner;
        
        // Send excess back to sender
        send(SendParameters{
            to: sender(),
            value: msgValue - gasConsumption,
            mode: SendPayFwdFeesSeparately,
            body: Excesses { queryId: msg.queryId }.toCell()
        });
    }

    receive(msg: ChangePaymentKey) {
        // Only current owner can change payment key
        require(sender() == self.owner, "Only owner can change payment key");
        
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        
        // Update payment public key
        self.paymentPublicKey = msg.newPaymentPublicKey;
        
        // Send excess back to sender
        send(SendParameters{
            to: sender(),
            value: msgValue - gasConsumption,
            mode: SendPayFwdFeesSeparately,
            body: Excesses { queryId: msg.queryId }.toCell()
        });
    }


    // ===== Private Methods ===== //
    // ===== Read Methods ===== //
    get fun get_collection_data(): CollectionData {
        // Collection metadata is available at baseURI/<this.address>
        let collectionContent:Cell = self.getBaseURL();

        return CollectionData{
            nextItemIndex: -1, // Item index not ordered, everything is predefined
            collectionContent: collectionContent,
            ownerAddress: self.owner
        };
    }

    get fun get_nft_item_init(index: Int): StateInit {
        return initOf Item(myAddress(), index);
    }

    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(self.get_nft_item_init(index)); 
    }

    get fun get_nft_content(index: Int, individualContent: Cell): Cell {
        let b: StringBuilder = beginString();
        let ic: String = individualContent.asSlice().asString();
        b.append(ic);
        return b.toCell();
    }


    // ===== Inline Methods ===== //
    inline fun getBaseURL(): Cell {
        return beginCell().storeUint(1, 8).storeSlice(beginString().concat(self.baseURI.beginParse().asString()).toSlice()).storeSlice(myAddress().toString().asSlice()).endCell()
    }

    inline fun mint(sender: Address, msgValue: Int, collectorPoints: Int, indexToMint: Int) {
        let nft_init: StateInit = self.get_nft_item_init(indexToMint);
        
        // Create forwardPayload with collector points
        let forwardPayload: Slice = beginCell()
            .storeUint(collectorPoints, 16)
            .endCell()
            .asSlice();
   
        deploy(DeployParameters{
            value: msgValue,
            body: Transfer {
                queryId: 0,
                newOwner: sender,
                responseDestination: self.owner,
                customPayload: self.baseURI,
                forwardAmount: 0,
                forwardPayload: forwardPayload
            }.toCell(),
            init: nft_init,
            mode: SendDefaultMode,
        });
    }
}