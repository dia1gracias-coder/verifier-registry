import "@stdlib/ownable";
import "./messages.tact";
import "../d_config.tact";
import "../lib/shared/traits/accounting.tact";
import "../lib/shared/traits/initializable.tact";
import "../lib/shared/traits/storage_controller.tact";
import "../d_master/messages.tact";
import "../d_blog/contract.tact";

contract DProfile with Ownable, Initializable,
                       Accounting, StorageController  {
    d_master: Address;
    owner: Address;
    is_initialized: Bool = false;

    username: String?;
    subscriptions: map<Address, Bool>;
    subscriptions_count: Int = 0;

    d_blog: Address?;
    is_waiting_for_blog: Bool = false;
    created_at: Int = 0;


    init(d_master: Address, d_user: Address) {
        self.d_master = d_master;
        self.owner = d_user;
    }

    receive(msg: InitializeDProfile) {
        require(self.d_master == sender(), "Only DMaster can initialize DProfile");
        require(self.d_blog == null, "DProfile already initialized");
        self.initialize();
        self.created_at = now();
        send(SendParameters{
                to: self.owner,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
                body: "DNet Registration Excesses".asComment()
            });
    }

    // User profile

    get fun username(): String? {
        self.requireInitialized();
        return self.username;
    }

    receive(msg: ChangeUsername) {
        self.requireInitialized();
        self.requireOwner();
        self.username = msg.new_username;
        send(SendParameters{
                to: self.owner,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
                body: "DNet Username Change Excesses".asComment()
            });
    }

    // User subscriptions

    get fun subscriptions(): map<Address, Bool> {
        self.requireInitialized();
        return self.subscriptions;
    }

    get fun subscriptions_count(): Int {
        self.requireInitialized();
        return self.subscriptions_count;
    }

    receive(msg: GetSubscribed) {
        self.requireInitialized();
        self.requireOwner();
        let existing_subscription: Bool? = self.subscriptions.get(msg.d_blog);
        if (existing_subscription != null) {
            send(SendParameters{
                    to: self.owner,
                    value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                    mode: SendIgnoreErrors,
                    body: "DNet Subscription Excesses: already subscribed".asComment()
                });
        } else {
            self.subscriptions.set(msg.d_blog, true);
            self.subscriptions_count += 1;
            send(SendParameters{
                    to: msg.d_blog,
                    value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                    mode: SendIgnoreErrors,
                    body: GetNotifiedAboutNewSubscription {
                        query_id: msg.query_id,
                        d_user: self.owner
                    }.toCell()
                });
        }
    }

    receive(msg: GetUnsubscribed) {
        self.requireInitialized();
        self.requireOwner();
        let unsubscribenSuccess: Bool = self.subscriptions.del(msg.d_blog);
        if (unsubscribenSuccess) {
            self.subscriptions_count -= 1;
            send(SendParameters{
                    to: msg.d_blog,
                    value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                    mode: SendIgnoreErrors,
                    body: GetNotifiedAboutLostSubscription {
                        query_id: msg.query_id,
                        d_user: self.owner
                    }.toCell()
                });
        } else {
            send(SendParameters{
                    to: self.owner,
                    value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                    mode: SendIgnoreErrors,
                    body: "DNet Unsubscription Excesses: no subscription found".asComment()
                });
        }
    }

    // Personal blog

    get fun blog_address(): Address? {
        self.requireInitialized();
        return self.d_blog;
    }

    receive(msg: CreateDBlog) {
        self.requireInitialized();
        self.requireOwner();
        require(self.d_blog == null, "DProfile already has a blog");
        let init_balance: Int = self.calculateSendAmountToHoldEnoughTonForStorage();
        require(context().value >= init_balance, "not enough funds to create a blog");
        send(SendParameters{
                to: self.d_master,
                value: 0,
                mode: SendIgnoreErrors | SendRemainingValue,
                body: MintDBlog {
                    query_id: msg.query_id,
                    blog_data: msg.blog_data,
                    d_user: self.owner
                }.toCell()
            });
        self.is_waiting_for_blog = true;
    }

    receive(msg: SetCreatedDBlog) {
        self.requireInitialized();
        require(self.is_waiting_for_blog, "DProfile is not waiting for blog");
        require(self.d_blog == null, "DProfile already has a blog");
        let blog_init: StateInit = initOf DBlog(self.d_master, msg.blog_seq_no);
        let blog_address: Address = contractAddress(blog_init);
        let sender: Address = sender();
        require(sender == blog_address, "Blog address mismatch");
        self.d_blog = sender;
        self.is_waiting_for_blog = false;
        send(SendParameters{
                to: self.owner,
                value: self.calculateSendAmountToHoldEnoughTonForStorage(),
                mode: SendIgnoreErrors,
                body: "DNet Blog Creation Excesses".asComment()
            });
    }
}
