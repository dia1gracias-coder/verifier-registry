import "./message.tact";

const minTonsForStorage: Int = ton("0.05");
const gasConsumption: Int = ton("0.05");
const CREATOR_ROYALTY_BP: Int = 500;  // 5% royalty
const CREATOR_TRANSFER_FEE: Int = ton("0.0025");
const MAX_SUPPLY: Int = 5000;         // 5000 total NFTs
const PREMINT_COUNT: Int = 0;       // You get 200 at deployment

contract NftCollection {
    next_item_index: Int as uint32 = 1;
    owner_address: Address;
    creator_address: Address;
    collection_content: Cell;
    nft_price: Int;
    authority_address: Address;
    paused: Bool = false;

    init(owner_address: Address, creator_address: Address, collection_content: Cell, nft_price: Int) {
        self.owner_address = owner_address;
        self.creator_address = creator_address;
        self.collection_content = collection_content;
        self.nft_price = nft_price;
        self.authority_address = owner_address;

        // Pre-mint first 200 NFTs to creator
        repeat(PREMINT_COUNT) {
            let currentIndex: Int = self.next_item_index;
            self.next_item_index = currentIndex + 1;
            self.mint(self.creator_address, 0, currentIndex);
        }
    }

    // Admin: Pause minting
    receive("Pause") {
        require(sender() == self.owner_address, "Not owner");
        self.paused = true;
    }

    receive("Unpause") {
        require(sender() == self.owner_address, "Not owner");
        self.paused = false;
    }

    // Admin: Update price (in TON nano)
    receive("UpdatePrice") {
        require(sender() == self.owner_address, "Not owner");
        let newPrice: Int = context().toSlice().loadInt(32);
        require(newPrice > 0, "Price must be > 0");
        self.nft_price = newPrice;
    }

    // Admin: Withdraw contract balance
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

    get fun get_collection_data(): CollectionData {
        return CollectionData {
            next_item_index: self.next_item_index,
            collection_content: self.collection_content,
            owner_address: self.owner_address
        };
    }

    get fun royalty_params(): RoyaltyParams {
        return RoyaltyParams {
            numerator: CREATOR_ROYALTY_BP,
            denominator: 10000,
            destination: self.creator_address
        };
    }

    get fun get_supply_info(): SupplyInfo {
        let minted: Int = self.next_item_index - 1;
        return SupplyInfo {
            total_supply: MAX_SUPPLY,
            minted: minted,
            remaining: MAX_SUPPLY - minted
        };
    }

    receive("mint") {
        require(!self.paused, "Contract paused");
        require(self.next_item_index <= MAX_SUPPLY, "Collection sold out");
        
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        let totalCost: Int = self.get_nft_mint_total_cost();
        require(msgValue >= totalCost, "Insufficient funds");

        // Send creator fee
        send(SendParameters{
            to: self.creator_address,
            value: CREATOR_TRANSFER_FEE,
            bounce: false,
            mode: SendIgnoreErrors,
            body: "Creator mint fee".asComment()
        });

        let currentIndex: Int = self.next_item_index;
        let tonBalanceBeforeMsg: Int = myBalance() - msgValue;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        let remainingValue: Int = msgValue - (storageFee + gasConsumption + self.nft_price + CREATOR_TRANSFER_FEE);

        // Send NFT price to owner
        if (self.nft_price > 0) {
            send(SendParameters{
                to: self.owner_address,
                value: self.nft_price,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "NFT Sale".asComment()
            });
        }

        // Update state BEFORE minting (reentrancy protection)
        self.next_item_index = currentIndex + 1;
        self.mint(ctx.sender, remainingValue, currentIndex);
    }

    fun mint(sender: Address, msgValue: Int, item_index: Int) {
        let nft_init: StateInit = self.getNftItemInit(item_index);
        let metadataUri = self.get_nft_content(item_index, self.collection_content);

        send(SendParameters{
            to: contractAddress(nft_init),
            value: msgValue,
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer {
                query_id: 0,
                new_owner: sender,
                response_destination: self.owner_address,
                custom_payload: metadataUri,
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });
    }

    get fun get_nft_mint_total_cost(): Int {
        return minTonsForStorage + gasConsumption + self.nft_price + CREATOR_TRANSFER_FEE;
    }

    get fun get_nft_address_by_index(item_index: Int): Address? {
        let initCode: StateInit = self.getNftItemInit(item_index);
        return contractAddress(initCode);
    }

    fun getNftItemInit(item_index: Int): StateInit {
        return initOf NftItem(myAddress(), item_index, self.authority_address, self.creator_address);
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let b: StringBuilder = beginString();
        b.append("https://ipfs.io/ipfs/QmcGb1Xy4wXFSSGtBw1fXdto1AYrJDFo36bW4rqM27ohUE/item_");
        b.append(index.toString());
        b.append(".json");
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
    creator_address: Address;
    for_sale: Bool = false;
    sale_price: Int = 0;

    init(collection_address: Address, item_index: Int, authority_address: Address, creator_address: Address) {
        require(sender() == collection_address, "Not from collection");
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.is_initialized = false;
        self.authority_address = authority_address;
        self.creator_address = creator_address;
    }

    receive(msg: Transfer) {
        let ctx: Context = context();
        let msgValue: Int = self.msgValue(ctx.value);

        if (!self.is_initialized) {
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
            require(ctx.sender == self.owner!!, "Only owner can transfer");
            require(msgValue >= CREATOR_TRANSFER_FEE, "Insufficient TON for creator fee");
            let transferValue: Int = msgValue - CREATOR_TRANSFER_FEE;

            send(SendParameters{
                to: self.creator_address,
                value: CREATOR_TRANSFER_FEE,
                bounce: false,
                mode: SendIgnoreErrors,
                body: "Creator transfer fee".asComment()
            });

            self._transferOwnership(msg.new_owner, msg.response_destination, msg.forward_amount, msg.forward_payload, transferValue);
        }
    }

    fun _transferOwnership(newOwner: Address, responseDest: Address?, forwardAmount: Int, forwardPayload: Slice, msgValue: Int) {
        self.for_sale = false;
        self.sale_price = 0;
        let oldOwner: Address = self.owner!!;
        self.owner = newOwner;

        if (msgValue > 0) {
            send(SendParameters{
                to: oldOwner,
                value: msgValue,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: 0 }.toCell()
            });
        }

        send(SendParameters{
            to: newOwner,
            value: 0,
            mode: SendPayGasSeparately,
            body: OwnershipAssigned {
                query_id: 0,
                prev_owner: oldOwner,
                forward_payload: forwardPayload
            }.toCell()
        });
    }

    receive("SetSalePrice") {
        require(sender() == self.owner!!, "Not owner");
        let price: Int = context().toSlice().loadInt(32);
        require(price > 0, "Price must be > 0");
        self.for_sale = true;
        self.sale_price = price;
    }

    receive("CancelSale") {
        require(sender() == self.owner!!, "Not owner");
        self.for_sale = false;
        self.sale_price = 0;
    }

    receive("Buy") {
        let ctx: Context = context();
        let msgValue: Int = ctx.value;
        require(self.for_sale, "Not for sale");
        let totalNeeded: Int = self.sale_price + CREATOR_TRANSFER_FEE;
        require(msgValue >= totalNeeded, "Insufficient funds");

        let buyer: Address = ctx.sender;
        let seller: Address = self.owner!!;
        let price: Int = self.sale_price;

        send(SendParameters{
            to: self.creator_address,
            value: CREATOR_TRANSFER_FEE,
            bounce: false,
            mode: SendIgnoreErrors,
            body: "Creator sale fee".asComment()
        });

        if (price > 0) {
            send(SendParameters{
                to: seller,
                value: price,
                bounce: true,
                mode: SendIgnoreErrors,
                body: "Sale proceeds".asComment()
            });
        }

        let remainingValue: Int = msgValue - totalNeeded;
        self._transferOwnership(buyer, null, 0, emptySlice(), remainingValue);
    }

    receive(msg: GetStaticData) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: 64,
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    get fun get_nft_data(): GetNftData {
        return GetNftData {
            is_initialized: self.is_initialized,
            index: self.item_index,
            collection_address: self.collection_address,
            owner_address: self.owner!!,
            individual_content: self.individual_content!!
        };
    }

    get fun get_sale_info(): SaleInfo {
        return SaleInfo {
            is_for_sale: self.for_sale,
            price: self.sale_price
        };
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        return value - (storageFee + gasConsumption);
    }
}

struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}

struct SaleInfo {
    is_for_sale: Bool;
    price: Int;
}

struct SupplyInfo {
    total_supply: Int;
    minted: Int;
    remaining: Int;
}