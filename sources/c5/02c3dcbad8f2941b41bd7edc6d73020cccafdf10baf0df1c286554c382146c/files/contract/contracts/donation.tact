import "@stdlib/deploy";
import "@stdlib/ownable";

struct Campaign{
    id: Int as uint32;
    name: String;
    balance: Int;
}

message CreateCampaign{
    id: Int as uint32;
    name: String;
}

message ReceiveDonate{
    id: Int as uint32;
    amount: Int as uint32;
}

message WithdrawCampaign{
    id: Int as uint32;
    amount: Int as uint32;
    recipient: Address;
}

message DeleteCampaign{
    id: Int as uint32;
}

contract Donation with Deployable, Ownable {
    owner: Address;
    campaigns: map<Int, Campaign>;
    numOfCampaigns : Int as uint32;

    init(){
        self.owner = sender();
        self.numOfCampaigns = 0;
        self.campaigns = emptyMap();
    }

    get fun campaign(id: Int) : Campaign? {
        return self.campaigns.get(id);
    }

    get fun balance() : Int {
        return myBalance();
    }

    get fun totalCampaign(): Int{
        return self.numOfCampaigns;
    }

    receive(msg: CreateCampaign) {
        self.requireOwner();

        self.campaigns.set(msg.id, Campaign{
            id: msg.id,
            name: msg.name,
            balance: 0,
        });

        self.numOfCampaigns += 1;
    }

    receive(msg: ReceiveDonate) {
        require(self.campaigns.exists(msg.id), "campaign id not found!");

        let campaign = self.campaigns.get(msg.id);

        self.campaigns.replace(msg.id, Campaign{
            id: msg.id,
            name: campaign!!.name,
            balance: campaign!!.balance + msg.amount,
        });
    }

    receive(msg: WithdrawCampaign) {
        self.requireOwner();

        require(self.campaigns.exists(msg.id), "campaign id not found!");

        let campaign: Campaign? = self.campaigns.get(msg.id);

        require(campaign!!.balance >= msg.amount, "insufficient balance");

        send(SendParameters{
            to: msg.recipient,
            value: msg.amount,
            mode: SendDefaultMode,
            body: "withdraw campaign".asComment(),
            bounce: true
        });

        self.campaigns.replace(msg.id, Campaign{
            id: msg.id,
            name: campaign!!.name,
            balance: campaign!!.balance - msg.amount,
        });
    }

    receive(msg: DeleteCampaign){
        self.requireOwner();

        require(self.campaigns.exists(msg.id), "campaign id not found!");

        self.campaigns.del(msg.id);
        self.numOfCampaigns -= 1;
    }
}
