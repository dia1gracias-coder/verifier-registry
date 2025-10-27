import "./messages.tact";

const COLLECTION_METADATA_FILENAME: String = "metadata";
const NFT_METADATA_PREFIX: String = "metadata/";
const OFFCHAIN_TAG: Int = 0x01;

const MIN_TON_FOR_STORAGE: Int = ton("0.02");
const GAS_CONSUMPTION: Int = ton("0.02");

fun getNftItemStateInit(index: Int): StateInit {
    return initOf SequoiaNftItem(index, myAddress());
}

contract SequoiaNftCollection {
    override const storageReserve: Int = MIN_TON_FOR_STORAGE;

    nextItemIndex: Int as uint64 = 0;
    baseUrl: String?;
    initialized: Bool = false;
    owner: Address;
    royaltyParams: RoyaltyParams?;
    mintPrice: Int as coins;

    init() {
        self.owner = sender();
        self.mintPrice = ton("1");
        nativeReserve(MIN_TON_FOR_STORAGE, ReserveExact);
    }

    receive(msg: InitializeCollection) {
        require(!self.initialized, "Collection is already initialized");
        require(sender() == self.owner, "Only the owner can initialize the collection");
        self.baseUrl = msg.baseUrl;
        self.initialized = true;
    }

    receive(msg: SetBaseUrl) {
        require(self.initialized, "Collection is not initialized");
        require(sender() == self.owner, "Only the owner can set the base URL");
        self.baseUrl = msg.baseUrl;

        let index: Int = 0;
        while (index < self.nextItemIndex) {    
            let nftItem: StateInit = getNftItemStateInit(index);
            message(MessageParameters {
                to: contractAddress(nftItem),
                value: 0,
                bounce: false,  
                mode: SendRemainingValue,
                body: SetBaseUrl {
                    baseUrl: msg.baseUrl,
                }.toCell(),
            });
            index += 1;
        }
    }

    receive(msg: MintNftItem) {
        require(self.initialized, "Collection is not initialized");
        require(context().value >= self.mintPrice, "Not enough value to mint");
        self.mint(sender());
    }

    receive(msg: MintNftItemAdmin) {
        require(self.initialized, "Collection is not initialized");
        require(sender() == self.owner, "Only the owner can mint");
        self.mint(msg.destination);
    }

    fun mint(owner: Address) {
        require(self.initialized, "Collection is not initialized");
        let nftItem: StateInit = getNftItemStateInit(self.nextItemIndex);

        send(
            SendParameters {
                to: contractAddress(nftItem),
                value: MIN_TON_FOR_STORAGE + GAS_CONSUMPTION,
                bounce: false,
                mode: SendIgnoreErrors,
                body: InitializeNftItem {
                    owner,
                    baseUrl: self.baseUrl!!,
                }.toCell(),
                code: nftItem.code,
                data: nftItem.data,
            },
        );

        self.nextItemIndex += 1;
    }


    receive(msg: GetRoyaltyParams) {
        require(self.initialized, "Collection is not initialized");
        require(self.royaltyParams != null, "Royalty params are not set");
        message(MessageParameters {
            to: sender(),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: ReportRoyaltyParams {
                queryId: msg.queryId,
                numerator: self.royaltyParams!!.numerator,
                denominator: self.royaltyParams!!.denominator,
                destination: self.royaltyParams!!.destination,
            }.toCell(),
        });
    }

    receive(msg: SetRoyaltyParams) {
        require(self.initialized, "Collection is not initialized");
        require(sender() == self.owner, "Only the owner can set the royalty params");
        self.royaltyParams = msg.royaltyParams;
    }

    receive(msg: SetMintPrice) {
        require(self.initialized, "Collection is not initialized");
        require(sender() == self.owner, "Only the owner can set the mint price");
        self.mintPrice = msg.mintPrice;
    }

    get fun get_collection_data(): CollectionData {
        require(self.initialized, "Collection is not initialized");
        return CollectionData {
            nextItemIndex: self.nextItemIndex,
            content: self.getCollectionMetadata(),
            owner: self.owner,
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        require(self.initialized, "Collection is not initialized");
        return contractAddress(getNftItemStateInit(index));
    }

    get fun get_nft_content(index: Int, _: String): Cell {
        require(self.initialized, "Collection is not initialized");
        let sb: StringBuilder = beginString();
        sb.append(self.baseUrl!!);
        sb.append(NFT_METADATA_PREFIX);
        sb.append(index.toString());
        return beginCell().storeUint(OFFCHAIN_TAG, 8).storeRef(sb.toCell()).endCell();
    }

    get fun royalty_params(): RoyaltyParams? {
        require(self.initialized, "Collection is not initialized");
        require(self.royaltyParams != null, "Royalty params are not set");
        return self.royaltyParams;
    }

    inline fun getCollectionMetadata(): Cell {
        require(self.initialized, "Collection is not initialized");
        let sb: StringBuilder = beginString();
        sb.append(self.baseUrl!!);
        sb.append(COLLECTION_METADATA_FILENAME);
        return beginCell().storeUint(OFFCHAIN_TAG, 8).storeRef(sb.toCell()).endCell();
    }
}

contract SequoiaNftItem {
    override const storageReserve: Int = MIN_TON_FOR_STORAGE;

    index: Int as uint64;
    collection: Address;
    baseUrl: String?;

    initialized: Bool = false;
    owner: Address?;

    init(index: Int as uint64, collection: Address) {
        require(sender() == collection, "Only the collection can initialize the NFT item");
        self.index = index;
        self.collection = collection;
        nativeReserve(MIN_TON_FOR_STORAGE, ReserveExact);
    }

    receive(msg: Transfer) {
        require(self.initialized, "NFT item is not initialized");

        require(sender() == self.owner, "Only the owner can transfer the NFT");
        require(context().value >= msg.forwardAmount + GAS_CONSUMPTION, "No enough value to forward");

        self.owner = msg.newOwner;

        if (msg.forwardAmount > 0) {
            message(MessageParameters {
                to: msg.newOwner,
                value: msg.forwardAmount,
                bounce: true,
                mode: SendPayGasSeparately,
                body: OwnershipAssigned {
                    queryId: msg.queryId,
                    prevOwner: sender(),
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }

        message(MessageParameters {
            to: msg.responseDestination!!,
            mode: SendRemainingValue,
            bounce: true,
            value: 0,
            body: Excesses {
                queryId: msg.queryId,
            }.toCell(),
        });
    }

    receive(msg: GetStaticData) {
        require(self.initialized, "NFT item is not initialized");

        message(MessageParameters {
            to: sender(),
            value: 0,
            bounce: false,
            mode: SendRemainingValue,
            body: ReportStaticData {
                queryId: msg.queryId,
                index: self.index,
                collection: self.collection,
            }.toCell(),
        });
    }

    receive(msg: InitializeNftItem) {
        require(!self.initialized, "NFT item is already initialized");
        require(sender() == self.collection, "Only the collection can initialize the NFT item");
        self.owner = msg.owner;
        self.baseUrl = msg.baseUrl;
        self.initialized = true;
    }

    receive(msg: SetBaseUrl) {
        require(sender() == self.collection, "Only the collection can change the base URL");
        self.baseUrl = msg.baseUrl;
    }

    get fun get_nft_data(): NftData {
        return NftData {
            initialized: self.initialized,
            index: self.index,
            collectionAddress: self.collection,
            owner: self.owner!!,
            individualContent: self.getIndividualContent(),
        };
    }

    inline fun getIndividualContent(): Cell {
        let sb: StringBuilder = beginString();
        sb.append(self.baseUrl!!);
        sb.append(NFT_METADATA_PREFIX);
        sb.append(self.index.toString());
        return beginCell().storeUint(OFFCHAIN_TAG, 8).storeRef(sb.toCell()).endCell();
    }
}
