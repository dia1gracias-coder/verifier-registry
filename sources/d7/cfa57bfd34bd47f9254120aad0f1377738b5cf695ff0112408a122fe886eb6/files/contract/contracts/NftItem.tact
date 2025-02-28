import "@stdlib/deploy";
import "./messages";

const min_balance     : Int = ton("0.05");
const gas_consumption : Int = ton("0.02");

struct NftData {
    index              : Int;
    collection_address : Address;
    owner_address      : Address;
    content            : String;
}

contract NftItem with Deployable {
    deployed   : Bool = false;
    collection : Address;
    owner      : Address;
    index      : Int as uint32;
    content    : String;
    
    init(collection: Address, index: Int) {
        self.index      = index;
        self.collection = collection;
        self.owner      = collection;
        self.content    = "";
    }
    
    receive(msg: NftDeploy) {
        require(sender() == self.collection, "Invalid Sender");
        require(self.index == msg.index, "Invalid Index");
        require(!self.deployed, "Already Deployed");
        
        self.owner   = msg.owner;
        self.content = msg.content;

        self.deployed = true;
    }

    receive(msg: NftTransfer) {
        let ctx: Context = context();
        require(self.deployed, "Not Deployed");
        require(ctx.sender == self.owner, "Invalid Owner");
        
        let min      : Int = min_balance - min(min_balance, myBalance());
        let required : Int = gas_consumption + msg.forward_amount + min;
        
        if (msg.forward_amount != 0) {
            required += ctx.readForwardFee();
        }
        
        require(ctx.value >= required, "Invalid Amount");
        
        let cashback: Int = ctx.value - gas_consumption - msg.forward_amount - min;
        if (msg.forward_amount != 0) {
            cashback -= ctx.readForwardFee();
            
            send(SendParameters{
                to    : msg.new_owner,
                value : msg.forward_amount,
                mode  : SendPayGasSeparately,
                body  : NftOwnershipAssigned{
                    query_id   : msg.query_id,
                    prev_owner : self.owner,
                    forward_payload : msg.forward_payload
                }.toCell()
            });
        }
        
        self.owner = msg.new_owner;
        
        if (cashback > 0) {
            send(SendParameters{
                to    : msg.response_destination,
                value : cashback,
                body  : NftExcesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

    receive(msg: NftGetStaticData) {
        send(SendParameters{
            to    : sender(),
            value : 0,
            mode  : SendRemainingValue,
            body  : NftReportStaticData{
                query_id : msg.query_id,
                index    : self.index,
                collection_address: self.collection
            }.toCell()
        });
    }
    
    get fun get_nft_data(): NftData {
        return NftData{
            index   : self.index,
            content : self.content,
            collection_address : self.collection,
            owner_address      : self.owner
        };
    }
} 