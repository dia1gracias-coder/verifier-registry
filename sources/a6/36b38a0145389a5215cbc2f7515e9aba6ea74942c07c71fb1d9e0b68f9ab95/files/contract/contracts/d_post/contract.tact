import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "../lib/nft/item/trait.tact";
import "../lib/shared/traits/initializable.tact";
import "../lib/shared/traits/storage_controller.tact";

const day: Int = 24 * 60 * 60;

contract DPost with Initializable, StorageController, NftItem {
    collection_address: Address;
    item_index: Int as uint32;
    owner: Address;
    is_initialized: Bool = false;
    individual_content: NftMetadata;

    replies: map<Int as uint8, Address>;
    next_reply_index: Int as uint8 = 0;
    are_replies_full: Bool = false;
    created_at:  Int as uint64 = 0;
    edited_at: Int? as uint64;
    replied_to: Address?;

    // Initialization

    init(collection_address: Address, item_index: Int){
        self.owner = collection_address;
        self.collection_address = collection_address;
        self.item_index = item_index;
        self.individual_content = createEmtyNftMetadata();
    }

    receive(msg: InitializeDPost) {
        require(sender() == self.collection_address, "Only the blog can initialize the post");
        self.initialize();
        self.initializeSelfAsNft(msg.init_nft_options, msg.query_id);
        self.created_at = now();
        if (msg.reply_to == null) {
            send(SendParameters{
                to: self.owner,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
                body: Excesses { query_id: msg.query_id }.toCell()
            });
        } else {
            send(SendParameters{
                to: msg.reply_to!!,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
                body: CreateDPostReplyLink{
                    query_id: msg.query_id,
                    reply_blog_address: self.collection_address,
                    reply_index: self.item_index,
                    reply_author: self.owner
                }.toCell()
            });
            self.replied_to = msg.reply_to;
        }
    }

    // Content

    get fun post_info(): DPostInfo {
        return DPostInfo{
            blog_address: self.collection_address,
            id: self.item_index,
            owner: self.owner,
            nft_content: self.individual_content,
            created_at: self.created_at,
            edited_at: self.edited_at,
            replied_to: self.replied_to,
            replies_count: self.next_reply_index
        };
    }

    receive(msg: EditDPost) {
        self.requireInitialized();
        self.requireOwner();
        require(self.created_at + day > now(), "You can only edit a post after 24 hours");
        self.individual_content = msg.new_metadata;
        self.edited_at = now();
        self.sendExcessesTo(
            self.calculateSendAmountToHoldEnoughTonForStorage(),
            self.owner,
            msg.query_id
        );
    }

    // Replies
    get fun replies_count(): Int {
        if (self.are_replies_full) {
            return 256;
        }
        return self.next_reply_index;
    }

    get fun replies(): map<Int as uint8, Address> {
        return self.replies;
    }

    get fun reply_address_by_index(index: Int): Address {
        return self.replies.get(index)!!;
    }

    receive(msg: CreateDPostReplyLink) {
        self.requireInitialized();
        let reply_address: Address = sender();
        let reply_check_address: Address = contractAddress(
            initOf DPost(msg.reply_blog_address, msg.reply_index)
        );
        require(reply_address == reply_check_address, "Only DPost can create a reply link");
        require(!self.are_replies_full, "Reached maximum number of replies");
        self.replies.set(self.next_reply_index, reply_address);
        if (self.next_reply_index == 255) {
            self.are_replies_full = true;
        } else {
            self.next_reply_index += 1;
        }

        send(SendParameters{
            to: msg.reply_author,
            value: self.calculateSendAmountToHoldEnoughTonForStorage(),
            mode: SendIgnoreErrors,
            body: Excesses { query_id: msg.query_id }.toCell()
        });

        let comment_sb: StringBuilder = beginComment();
        comment_sb.append("New reply to your post: ");
        comment_sb.append(myAddress().asSlice().asString());
        send(SendParameters{
            to: self.owner,
            value: ton("0.001"),
            mode: SendIgnoreErrors | SendPayGasSeparately,
            body: comment_sb.toString().asComment()
        });
    }
}
