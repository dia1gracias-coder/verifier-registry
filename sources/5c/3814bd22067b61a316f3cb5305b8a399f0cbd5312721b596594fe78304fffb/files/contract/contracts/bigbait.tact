import "@stdlib/deploy";
import "@stdlib/ownable";

message BuyInfo {
    amount: Int;
    itemId: Int;
    telegramId: Int;
}

message BuyEvent {
    user: Address;
    amount: Int;
    itemId: Int;
    telegramId: Int;
}

message AdminAddress {
    newAdmin: Address;
}

message Withdraw {
    user: Address;
    amount: Int;
}

contract Bigbait with Deployable, OwnableTransferable {
    ID: Int as uint32;
    owner: Address;
    admin: Address;

    init (id: Int, owner: Address, admin: Address) {
        self.ID = id;
        self.owner = owner;
        self.admin = admin;
    } 

    receive (_details : BuyInfo) {
        let fee = ton("0.01");
        require(context().value >= _details.amount + fee, "Insufficient funds sent");
        let amount: Int = _details.amount;
        let itemId: Int = _details.itemId; 
        let telegramId: Int = _details.telegramId;
        
        // Send the specified amount to the owner
        send(SendParameters{
            to: self.admin,
            value: amount,
            mode: SendIgnoreErrors
        });

        // Calculate the amount to refund
        let refundAmount = context().value - _details.amount - fee;
        // Refund excess amount if any
        if (refundAmount > 0) {
            send(SendParameters{
                to: context().sender,
                value: refundAmount,
                mode: SendIgnoreErrors
            });
        }

        // Emit the BuyEvent
        emit(BuyEvent{
            user: context().sender,
            amount: amount,
            itemId: itemId,
            telegramId: telegramId
        }.toCell());
    }

    receive(msg: AdminAddress){
        require(context().sender == self.owner, "Only owner can set admin");
        self.admin = msg.newAdmin;
    }

    receive(msg: Withdraw) {
        require(context().sender == self.owner, "Not owner");
        send(SendParameters{
            to: msg.user,
            value: msg.amount,
            mode: SendIgnoreErrors
        });
    }
}