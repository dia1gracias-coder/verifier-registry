import "./interfaces/types/store";
import "./gas";

contract Store {
    isUsed: Bool =  false;
    owner: Address; // The owner is the bridge contract address
    hash: Int as int257; // The hash of the request, used to identify the request
    
    init(hash: Int, owner: Address) {
        require(owner == sender(), "Store: provided sender is not the same as the contract sender");
        self.owner = owner;
        self.hash = hash;
    }

    get fun isUsed(): Bool {
        return self.isUsed;
    }

    receive(msg: MsgIsUsed) {
        require(context().value >= COMPUTATION_FEE,"Store: insufficient value for response" );
        require(sender() == self.owner, "Store: only owner can call this function");

        let responseMessage = MsgIsUsedResponse {
            destinationPayload: msg.destinationPayload,
            isUsed: self.isUsed,
            requestHash: msg.hash,
            messageType: msg.messageType,
            sender: msg.sender,
        };
        // The call back to must send some amount of TON to the destination. The user need to handle the amount
        send(
            SendParameters{
                to: msg.destination,
                value: context().value - COMPUTATION_FEE,
                body: responseMessage.toCell(),
                bounce: true,
            }
        );
      
        self.isUsed = true;    
    }
}