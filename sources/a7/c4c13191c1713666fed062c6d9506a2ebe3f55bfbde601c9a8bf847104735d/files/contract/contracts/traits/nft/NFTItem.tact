import "./INFT.tact";

// For `get_nft_data()` method
struct NftData {
    initialized: Bool;            // it should be `init`, but it is a reserved keyword in tact. if not zero, then this NFT is fully initialized and ready for interaction.
    index: Int as uint64;         // numerical index of this NFT in the collection. For collection-less NFT - arbitrary but constant value.
    collection_address: Address;  // address of the smart contract of the collection to which this NFT belongs. For collection-less NFT this parameter should be addr_none
    owner_address: Address;       // address of the current owner of this NFT
    individual_content: Cell;     // if NFT has collection - individual NFT content in any format; if NFT has no collection - NFT content in format that complies with standard TEP-64
}

// Implementations
trait NFTItemBase {
    virtual const minTonsForStorage: Int = ton("0.000");
    virtual const gasConsumption: Int = ton("0.000");

    collection_address: Address;
    index: Int;
    owner_address: Address;
    individual_content: Cell;
    initialized: Bool;

    virtual inline fun transfer(ctx: Context, msg: Transfer, excess_amount: Int) {
        // 1. Set current owner to new owner
        self.owner_address = msg.new_owner;
        // 2. Send forward amount + payload if required
        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: OwnershipAssigned{
                    query_id: msg.query_id,
                    prev_owner: ctx.sender,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }
        // 3. Send excesses amount to response destination
        if (msg.response_destination != newAddress(0, 0)) {
            send(SendParameters{
                to: msg.response_destination,
                value: excess_amount,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        }
    }
    virtual inline fun _transfer_validate(ctx: Context, msg: Transfer) {
        nativeThrowUnless(132, ctx.sender == self.owner_address);
        // TODO: ensure this is a workchain (0) address. Tact not supported yet.
    }
    receive(msg: Transfer){
        let ctx: Context = context();
        self._transfer_validate(ctx, msg);

        let tonBalanceBeforeMsg: Int = myBalance() - ctx.value;
        let storageFee: Int = self.minTonsForStorage - min(tonBalanceBeforeMsg, self.minTonsForStorage);
        let excess_amount = ctx.value - (storageFee + self.gasConsumption);

        let forward_fee: Int = ctx.readForwardFee();
        if (msg.forward_amount > 0) {
            excess_amount -= (msg.forward_amount + forward_fee);
        }
        if (msg.response_destination != newAddress(0, 0)) {
            excess_amount -= forward_fee;
        }
        require(excess_amount >= 0, "NFTItemBase::Not enough in-message value!");

        // NOTE: use in place of an explicit mint function
        if (!self.initialized) {
            self.initialized = true;
        }

        self.transfer(ctx, msg, excess_amount);
    }

    virtual inline fun _report_static_data(msg: GetStaticData) {
        let ctx: Context = context();
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportStaticData{
                query_id: msg.query_id,
                index: self.index,
                collection: self.collection_address
            }.toCell()
        });
    }
    receive(msg: GetStaticData){
        self._report_static_data(msg);
    }

    // NOTE:Mind the TEP-64 metadata standard
    // uri metadata: https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md#nft-item-metadata-example-offchain
    // Cell serialization: https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md#content-representation
    virtual inline fun _get_nft_data(): NftData {
        return NftData {
            initialized: self.initialized,
            index: self.index,
            collection_address: self.collection_address,
            owner_address: self.owner_address,
            individual_content: self.individual_content,
        };
    }
    get fun get_nft_data(): NftData {
        return self._get_nft_data();
    }
}

