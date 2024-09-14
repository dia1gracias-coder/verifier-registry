import "./traits/nft/NFTItem.tact";

contract SkateBuilderNFT with NFTItemBase {
    collection_address: Address;
    index: Int;
    owner_address: Address;
    individual_content: Cell;
    initialized: Bool = false;

    init(collection_address: Address, index: Int) {
        self.collection_address = collection_address;
        self.index = index;
        self.owner_address = collection_address;
        self.individual_content = emptyCell();
    }

    override inline fun transfer(ctx: Context, msg: Transfer, excess_amount: Int) {
        // 1. Set current owner to new owner
        self.owner_address = msg.new_owner;
        self.individual_content = msg.custom_payload!!; // NOTE: asserted non-nullable in _transfer_validate()

        // 2. Send forward amount + payload if required
        // NOTE: disable to optimize gas
        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendIgnoreErrors,
                bounce: false,
                body: OwnershipAssigned {
                    query_id: msg.query_id,
                    prev_owner: ctx.sender,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        // 3. Send excesses amount to response destination
        // NOTE:Executor should optimize call so there is no need for refund
        if (msg.response_destination != newAddress(0, 0)) {
            send(SendParameters{
                to: msg.response_destination,
                value: excess_amount,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        }
    }

    override inline fun _transfer_validate(ctx: Context, msg: Transfer) {
        nativeThrowUnless(132, ctx.sender == self.owner_address);
        require(msg.custom_payload != null, "SkateBuilderNFT::Custom payload must contain NFT content");
        require(!self.initialized, "SkateBuilderNFT::NFT is not transferable!")
    }
}

