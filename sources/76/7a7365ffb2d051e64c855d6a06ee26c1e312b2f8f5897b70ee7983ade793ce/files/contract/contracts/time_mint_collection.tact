import "./time_mint_constants";
import "./time_mint_messages";
import "./time_mint_item";

contract TimeMintCollection {
    admin: Address;
    paymentAddress: Address;
    quotePublicKey: Int as uint256;
    nextItemIndex: Int as uint64;
    content: Cell;
    royaltyParams: RoyaltyParams;
    years: map<Int as uint16, YearConfig>;
    mintedSlots: map<Int as uint64, MintedSlot>;

    itemCode: Cell;
    itemCommonData: Builder;

    init(admin: Address, paymentAddress: Address, quotePublicKey: Int, collectionContent: Cell, royaltyParams: RoyaltyParams) {
        self.admin = admin;
        self.paymentAddress = paymentAddress;
        self.quotePublicKey = quotePublicKey;
        self.nextItemIndex = 0;
        self.content = collectionContent;
        self.royaltyParams = royaltyParams;
        self.years = emptyMap();
        self.mintedSlots = emptyMap();

        self.itemCode = codeOf TimeMintItem;
        self.itemCommonData = beginCell()
            .storeUint(0, 3)
            .storeAddress(myAddress());
    }

    receive() {}

    receive(msg: OpenYear) {
        self.requireAdmin();
        throwUnless(InvalidYearConfig, msg.totalSlots > 0);
        throwUnless(InvalidYearConfig, msg.totalSlots <= MaxMinuteSlotsPerLeapYear);
        throwUnless(InvalidYearConfig, msg.itemDeployAmount >= minTonsForStorage);

        let existing = self.years.get(msg.year);
        let mintedCount: Int = 0;

        if (existing != null) {
            mintedCount = existing!!.mintedCount;
        }

        self.years.set(msg.year, YearConfig {
            isOpen: true,
            totalSlots: msg.totalSlots,
            basePrice: msg.basePrice,
            itemDeployAmount: msg.itemDeployAmount,
            mintedCount,
        });
    }

    receive(msg: CloseYear) {
        self.requireAdmin();

        let existing = self.years.get(msg.year);
        throwUnless(InvalidYearConfig, existing != null);

        let config = existing!!;
        self.years.set(msg.year, YearConfig {
            isOpen: false,
            totalSlots: config.totalSlots,
            basePrice: config.basePrice,
            itemDeployAmount: config.itemDeployAmount,
            mintedCount: config.mintedCount,
        });
    }

    receive(msg: ChangeAdmin) {
        self.requireAdmin();
        self.admin = msg.newAdmin;
    }

    receive(msg: SetQuoteSigner) {
        self.requireAdmin();
        self.quotePublicKey = msg.quotePublicKey;
    }

    receive(msg: SetPaymentAddress) {
        self.requireAdmin();
        self.paymentAddress = msg.paymentAddress;
    }

    receive(msg: MintDate) {
        throwUnless(InvalidMintOwner, sender() == msg.owner);
        throwUnless(QuoteExpired, msg.validUntil >= now());

        let yearConfig = self.years.get(msg.year);
        throwUnless(YearClosed, yearConfig != null);

        let config = yearConfig!!;
        throwUnless(YearClosed, config.isOpen);
        throwUnless(SlotOutOfRange, msg.minuteIndex < config.totalSlots);

        let slotKey = self.slotKey(msg.year, msg.minuteIndex);
        throwUnless(SlotAlreadyMinted, self.mintedSlots.get(slotKey) == null);
        throwUnless(InvalidQuote, self.verifyMintQuote(msg));
        throwUnless(InsufficientValue, context().value >= msg.price + config.itemDeployAmount + ton("0.04"));

        let itemIndex = self.nextItemIndex;
        let initBody = InitNFTBody {
            owner: msg.owner,
            content: msg.content,
        }.toCell();

        self.deployNFTItem(itemIndex, config.itemDeployAmount, initBody);

        self.mintedSlots.set(slotKey, MintedSlot {
            owner: msg.owner,
            itemIndex,
            rarity: msg.rarity,
            price: msg.price,
            mintedAt: now(),
        });

        self.years.set(msg.year, YearConfig {
            isOpen: config.isOpen,
            totalSlots: config.totalSlots,
            basePrice: config.basePrice,
            itemDeployAmount: config.itemDeployAmount,
            mintedCount: config.mintedCount + 1,
        });

        self.nextItemIndex += 1;

        message(MessageParameters {
            bounce: false,
            to: self.paymentAddress,
            value: msg.price,
            body: beginCell()
                .storeUint(SalePayment, 32)
                .storeUint(msg.queryId, 64)
                .storeUint(msg.year, 16)
                .storeUint(msg.minuteIndex, 32)
                .storeAddress(msg.owner)
                .endCell(),
            mode: SendPayFwdFeesSeparately,
        });
    }

    receive(msg: GetRoyaltyParams) {
        message(MessageParameters {
            bounce: false,
            to: sender(),
            value: 0,
            body: ReportRoyaltyParams {
                queryId: msg.queryId,
                params: self.royaltyParams,
            }.toCell(),
            mode: SendRemainingValue,
        });
    }

    get fun get_collection_data(): CollectionData {
        let cs: Slice = self.content.beginParse();
        return CollectionData {
            nextItemIndex: self.nextItemIndex,
            collectionContent: cs.loadRef(),
            owner: self.admin,
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        let stateInit = initOf TimeMintItem(null, null, myAddress(), index);
        return contractAddress(stateInit);
    }

    get fun royalty_params(): RoyaltyParams {
        return self.royaltyParams;
    }

    get fun get_nft_content(index: Int, individualNFTContent: Cell): Cell {
        let cs = self.content.beginParse();
        cs.skipRef();
        let commonContent = cs.loadRef().beginParse();
        return beginCell()
            .storeUint(1, 8)
            .storeSlice(commonContent)
            .storeRef(individualNFTContent)
            .endCell();
    }

    get fun get_year_config(year: Int): YearConfig? {
        return self.years.get(year);
    }

    get fun get_date_status(year: Int, minuteIndex: Int): DateStatus {
        let yearConfig = self.years.get(year);
        let slot = self.mintedSlots.get(self.slotKey(year, minuteIndex));
        let nftAddress: Address? = null;

        if (slot != null) {
            nftAddress = self.get_nft_address_by_index(slot!!.itemIndex);
        }

        return DateStatus {
            year,
            minuteIndex,
            isYearOpen: yearConfig != null ? yearConfig!!.isOpen : false,
            minted: slot != null,
            owner: slot != null ? slot!!.owner : null,
            itemIndex: slot != null ? slot!!.itemIndex : null,
            nftAddress,
            rarity: slot != null ? slot!!.rarity : null,
            price: slot != null ? slot!!.price : null,
            mintedAt: slot != null ? slot!!.mintedAt : null,
        };
    }

    get fun get_admin(): Address {
        return self.admin;
    }

    get fun get_payment_address(): Address {
        return self.paymentAddress;
    }

    get fun get_quote_public_key(): Int {
        return self.quotePublicKey;
    }

    fun requireAdmin() {
        throwUnless(IncorrectSender, sender() == self.admin);
    }

    fun slotKey(year: Int, minuteIndex: Int): Int {
        return year * 4294967296 + minuteIndex;
    }

    fun verifyMintQuote(msg: MintDate): Bool {
        let hash = beginCell()
            .storeUint(msg.year, 16)
            .storeUint(msg.minuteIndex, 32)
            .storeCoins(msg.price)
            .storeUint(msg.validUntil, 32)
            .storeAddress(msg.owner)
            .storeUint(msg.rarity, 8)
            .storeUint(msg.content.hash(), 256)
            .storeAddress(myAddress())
            .endCell()
            .hash();

        return checkSignature(hash, msg.signature, self.quotePublicKey);
    }

    fun deployNFTItem(itemIndex: Int, amount: Int, initNFTBody: Cell) {
        let data: Cell = self.itemCommonData.storeUint(itemIndex, 64).endCell();

        deploy(DeployParameters {
            value: amount,
            body: initNFTBody,
            init: StateInit {
                code: self.itemCode,
                data,
            },
            mode: SendPayFwdFeesSeparately,
        });
    }
}
