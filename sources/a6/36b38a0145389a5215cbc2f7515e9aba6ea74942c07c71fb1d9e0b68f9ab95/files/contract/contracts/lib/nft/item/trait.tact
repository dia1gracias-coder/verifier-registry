import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "../utils/messages_utils.tact";
import "../../shared/traits/accounting.tact";
import "../../shared/traits/initializable.tact";

trait NftItem with Ownable, Accounting, Initializable {
    collection_address: Address;
    item_index: Int;
    owner: Address;
    is_initialized: Bool;
    individual_content: NftMetadata;

    // ===== Customizable functions ===== //

    virtual fun calculateNftItemTransferValue(): Int {
        return self.calculateSendAmountToHoldEnoughTonForStorage();
    }

    virtual fun onNftItemTransfer() {
        // empty
    }

    // ===== Private Methods ===== //

    fun initializeSelfAsNft(options: InitializeNftOptions, query_id: Int) {
        self.owner = options.owner;
        self.individual_content = options.individual_content;
    }

    // --------- Get Function  --------- //


    // ------------------ NFT standard getters  ------------------ //
    // https://github.com/ton-blockchain/TEPs/blob/master/text/0062-nft-standard.md#get-methods
    get fun get_nft_data(): GetNftData {
         return GetNftData {
            is_initialized: self.is_initialized,
            index: self.item_index,
            collection_address: self.collection_address,
            owner_address: self.owner,
            individual_content: serializeNftItemIndividualContent(self.individual_content)
        };
    }

    // ===== Recievers ===== //

    receive(msg: Transfer){
        self.requireOwner();
        self.requireInitialized();
        let msgValue: Int = self.calculateNftItemTransferValue();
        let ctx: Context = context();
        self.owner = msg.new_owner;
        self.onNftItemTransfer();
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

        msgValue = msgValue - ctx.readForwardFee();
        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination,
                value: msgValue - msg.forward_amount,
                mode: SendPayGasSeparately,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
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
}
