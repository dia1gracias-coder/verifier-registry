import "@stdlib/deploy";
import "./mosaic_deal_contract.tact";
import "./messages.tact";

contract MosaicDealFactory with Deployable {
    id: Int as uint32;
    init(){
        self.id = 0;
    }

    /**
    @dev Creates a deal and deploys a child contract.
    @param msg Struct CreateDeal, containing the details of the new deal.
    **/
    receive(msg: DealDetails){
        require(context().value >= ton("0.05"), "Insufficient value to create a deal");
        self.id = self.id + 1;
        let init: StateInit = initOf MosaicDealContract(self.id, msg.admin, msg.amount, msg.customer, msg.freelancer);
        send(SendParameters{
                to: contractAddress(init),
                value: context().value,
                mode: SendIgnoreErrors,
                code: init.code,
                data: init.data
            }
        );
    }

    /**
    @dev Returns the number of created child contracts.
    @return Number of child contracts (last id).
    **/
    get fun numberOfChildren(): Int {
        return self.id;
    }

    /**
    @dev Returns the address of a child contract based on the deal id.
    @param dealId The id of the deal.
    @return Address of the child contract.
    **/

    get fun addressOfChildren(msg: Info): Address {
        let init: StateInit = initOf MosaicDealContract(msg.id, msg.admin, msg.amount, msg.customer, msg.freelancer);
        return contractAddress(init);
    }
}