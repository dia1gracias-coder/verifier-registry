import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "../d_config.tact";
import "../lib/shared/traits/accounting.tact";
import "../lib/shared/traits/platform_fees.tact";
import "../lib/shared/traits/storage_controller.tact";
import "../d_blog/contract.tact";
import "../d_profile/contract.tact";

contract DMaster with Deployable, OwnableTransferable,
                      PlatformFees, Accounting, StorageController  {
    owner: Address;
    treasury_address: Address;

    next_blog_seq_no: Int as uint32 = 0;

    init() {
        let sender: Address = sender();
        self.owner = sender;
        self.treasury_address = sender;
    }

    get fun version(): String {
        return D_VERSION;
    }

    get fun blogs_count(): Int {
        return self.next_blog_seq_no;
    }

    get fun blog_address_by_index(item_index: Int): Address {
        let initCode: StateInit = self.getBlogInit(item_index);
        return contractAddress(initCode);
    }

    // Profiles

    fun getProfileInit(user: Address): StateInit {
        return initOf DProfile(myAddress(), user);
    }

    get fun profile_address_by_user(user: Address): Address {
        return contractAddress(self.getProfileInit(user));
    }

    receive(msg: Register) {
        let sender: Address = sender();
        let profile_init: StateInit = self.getProfileInit(sender);
        let profile_address: Address = contractAddress(profile_init);
        let init_balance: Int = self.calculateSendAmountToHoldEnoughTonForStorage();
        require(context().value >= init_balance, "not enough funds to register a profile");
        send(SendParameters{
                to: profile_address,
                value: init_balance,
                bounce: false,
                mode: SendIgnoreErrors,
                body: InitializeDProfile {
                    query_id: msg.query_id,
                    d_user: sender,
                }.toCell(),
                code: profile_init.code,
                data: profile_init.data
            });
    }

    // Blogs Collection

    fun getBlogInit(item_index: Int): StateInit {
        return initOf DBlog(myAddress(), item_index);
    }

    receive(msg: MintDBlog) {
        let profile_init: StateInit = self.getProfileInit(msg.d_user);
        let profile_address: Address = contractAddress(profile_init);
        require(profile_address == sender(), "Only the profile owner can mint a blog");
        require(context().value >= CREATE_BLOG_FEE, "not enough funds to create a blog");
        let init_message: Cell = InitializeDBlog {
            query_id: msg.query_id,
            metadata: msg.blog_data,
            owner_address: msg.d_user,
            treasury_address: self.treasury_address,
            d_profile: profile_address,
        }.toCell();
        let init_balance: Int = self.calculateSendAmountToHoldFeeFromRecieved(CREATE_BLOG_FEE);
        let blog_init: StateInit = self.getBlogInit(self.next_blog_seq_no);
        send(SendParameters{
                to: contractAddress(blog_init),
                value: init_balance,
                bounce: false,
                mode: SendIgnoreErrors,
                body: init_message,
                code: blog_init.code,
                data: blog_init.data
            });
        self.next_blog_seq_no += 1;
        self.payPlatformFee(CREATE_BLOG_FEE, "D Blog created");
    }
}
