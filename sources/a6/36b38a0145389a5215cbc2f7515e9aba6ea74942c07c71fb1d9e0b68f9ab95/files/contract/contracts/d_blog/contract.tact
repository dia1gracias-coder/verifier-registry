import "@stdlib/deploy";
import "./messages.tact";
import "../d_config.tact";
import "../lib/shared/traits/storage_controller.tact";
import "../lib/shared/traits/initializable.tact";
import "../lib/shared/traits/platform_fees.tact";
import "../lib/nft/collection/trait.tact";
import "../lib/nft/collection_royalty_extention/trait.tact";
import "../d_post/contract.tact";
import "../d_profile/messages.tact";

contract DBlog with StorageController, Initializable, PlatformFees,
                    NftCollection, NftCollectionRoyaltyExtention {
    treasury_address: Address;
    owner: Address;
    is_initialized: Bool = false;
    created_at: Int as uint64 = 0;
    subscribers_count: Int as uint64 = 0;

    master_address: Address;
    blog_seq_no: Int as uint32;


    // NftCollection
    next_item_index: Int as uint32 = 0;
    collection_content: NftCollectionMetadata;
    royalty_params: RoyaltyParams;

    init(d_master_address: Address, blog_seq_no: Int){
        self.owner = d_master_address;
        self.treasury_address = d_master_address;
        // Collections item
        self.master_address = d_master_address;
        self.blog_seq_no = blog_seq_no;
        // NFT collection
        self.collection_content = createEmtyNftCollectionMetadata();
        self.royalty_params = RoyaltyParams{
            numerator: 3,
            denominator: 100,
            destination: self.owner
        };
    }

    // Content

    get fun blog_info(): BlogInfo {
        return BlogInfo{
            id: self.blog_seq_no,
            owner: self.owner,
            master_contract: self.master_address,
            collection_content: self.collection_content,
            is_initialized: self.is_initialized,
            created_at: self.created_at
        };
    }

    get fun posts_count(): Int {
        return self.next_item_index;
    }

    receive(msg: EditBlogMetadata) {
        self.requireInitialized();
        self.requireOwner();
        self.collection_content = msg.new_metadata;
        self.sendExcessesTo(
            self.calculateSendAmountToHoldEnoughTonForStorage(),
            self.owner,
            msg.query_id
        );
    }

    // Subscriptions

    get fun subscribers_count(): Int {
        self.requireInitialized();
        return self.subscribers_count;
    }

    receive(msg: GetNotifiedAboutNewSubscription) {
        self.requireInitialized();
        self.subscribers_count += 1;
        send(SendParameters{
                to: msg.d_user,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
        });
    }

    receive(msg: GetNotifiedAboutLostSubscription) {
        self.requireInitialized();
        if (self.subscribers_count > 0) {
            self.subscribers_count -= 1;
        }
        send(SendParameters{
                to: msg.d_user,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
        });
    }

    // NFT Item

    receive(msg: InitializeDBlog) {
        require(sender() == self.master_address, "Only master can initialize the blog");
        self.initialize();
        self.collection_content = msg.metadata;
        self.owner = msg.owner_address;
        self.royalty_params.destination = msg.owner_address;
        send(SendParameters{
                to: msg.d_profile,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
                body: SetCreatedDBlog {
                    query_id: msg.query_id,
                    blog_seq_no: self.blog_seq_no
                }.toCell()
            });
        self.treasury_address = msg.treasury_address;
        self.created_at = now();
    }

    // NFT Collection

    override fun getNftItemInit(item_index: Int): StateInit {
        return initOf DPost(myAddress(), item_index);
    }

    receive(msg: MintDPost) {
        self.requireInitialized();
        self.requireOwner();
        require(context().value >= CREATE_POST_FEE, "not enough funds to create a post");
        let init_message: Cell = InitializeDPost {
            query_id: 0,
            init_nft_options: InitializeNftOptions {
                owner: self.owner,
                individual_content: msg.post_data
            },
            reply_to: msg.reply_to
        }.toCell();
        let init_balance: Int = self.calculateSendAmountToHoldFeeFromRecieved(CREATE_POST_FEE);
        self.mintNftGeneric(init_message, init_balance);
        self.payPlatformFee(CREATE_POST_FEE, "D Blog Post created");
    }
}
