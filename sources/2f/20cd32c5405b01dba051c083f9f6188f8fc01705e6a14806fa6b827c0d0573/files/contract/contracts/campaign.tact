import "@stdlib/deploy";
import "@stdlib/ownable";
import "./message.tact";

contract Campaign with Deployable, Ownable{
    owner: Address;
    parent : Address;
    id: Int as uint32;
    name: String;
    balance : Int as uint32;

    init(owner: Address, parent: Address, id: Int) {
        self.owner = owner;
        self.parent = parent;
        self.id = id;
        self.name = "";
        self.balance = 0;
    }

    get fun name(): String{
        return self.name;
    }

    get fun balance(): Int{
        return self.balance;
    }

    get fun totalBalance(): Int{
        return myBalance();
    }

    receive(msg: NewCampaign){
        require(msg.parent == self.parent, "you are not parent");

        self.name = msg.name;
    }

    receive(msg: ReceiveDonate) {
        self.balance += msg.amount;
    }

    receive(msg: WithdrawCampaign){
        self.requireOwner();

        require(myBalance() > msg.amount, "insufficient balance");
        require(self.balance >= msg.amount, "insufficient balance");

        send(SendParameters{
            to: msg.recipient,
            value: msg.amount,
            bounce: true,
            mode: 0,
            body: "success withdraw".asComment()
        }); 

        self.balance -= msg.amount;
    }

    receive(msg: RemoveCampaign) {
        require(msg.parent == self.parent, "you are not parent");

        send(SendParameters{
            to: self.owner, 
            value: 0,
            mode: SendRemainingBalance | SendDestroyIfZero, 
            bounce: true,
            body: "success delete campaign".asComment()
        });
    }
}
