import "@stdlib/deploy";
import "@stdlib/ownable";
import "./campaign.tact";
import "./message.tact";

struct CampaignList{
    id: Int as uint32;
    name: String;
    address: Address;
}

contract Donation with Deployable, Ownable {
    owner: Address;
    campaigns: map<Int, CampaignList>;
    numCampaign: Int as uint32;

    init(owner: Address) {
        self.owner = owner;
        self.campaigns = emptyMap();
        self.numCampaign = 0;
    }

    get fun name(id: Int): String?{
        let campaign = self.campaigns.get(id);

        if(campaign == null){
            return null;
        }

        return campaign!!.name;
    }

    get fun address(id: Int): Address?{
        let campaign = self.campaigns.get(id);

        if(campaign == null){
            return null;
        }

        return campaign!!.address;
    }

    get fun totalCampaign(): Int{
        return self.numCampaign;
    }

    receive(msg: CreateCampaign){
        self.requireOwner();

        require(!self.campaigns.exists(msg.id), "campaign id already exists");
        require(myBalance() > ton("1"), "insufficient balance");

        let address = myAddress();
        let init: StateInit = initOf Campaign(self.owner, address, msg.id);

        send(SendParameters{
            to: contractAddress(init),
            value: ton("1"),
            mode: 0, 
            code: init.code,
            data: init.data,
            bounce: true,
            body: CreateCampaign{id: msg.id, name: msg.name}.toCell(), 
        });

        self.campaigns.set(msg.id, CampaignList{
            id: msg.id,
            name: msg.name,
            address: contractAddress(init)
        });

        self.numCampaign += 1;
    }

    receive(msg: DeleteCampaign){
        self.requireOwner();
        require(self.campaigns.exists(msg.id), "campaign id not found");

        let address = myAddress();
        let campaign: CampaignList? = self.campaigns.get(msg.id);

        send(SendParameters{
            to: campaign!!.address,
            value: ton("0.05"),
            mode: 0, 
            bounce: true,
            body: RemoveCampaign{parent: address}.toCell()
        });

        self.campaigns.del(msg.id);
        self.numCampaign -= 1;
    }
}
