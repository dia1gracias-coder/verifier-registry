import "@stdlib/deploy";
import "@stdlib/ownable";


const RequiredClaimFee: Int = ton("0.1");
const JettonTransferGas: Int = ton("0.04");

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell? = null;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message Claim {
    queryId: Int as uint64;
    JettonWalletAddress: Address;
    claimAmount: Int as coins;
}

message SendOwner {
    newOwner: Address;
}

contract Airdropsg with Deployable, Ownable {
    owner: Address;

    init(owner: Address) {
        self.owner = owner;
    }

    receive(msg: Claim) {


        let sender: Address = context().sender;
        let value: Int = context().value;

        // Check if the sent amount is at least 0.1 TON
        require(value >= RequiredClaimFee, "Insufficient funds: Please send at least 0.1 TON");

        // Send the 0.1 TON fee to the fee collector
        send(SendParameters{
            to: self.owner,
            value: RequiredClaimFee,
            mode: SendIgnoreErrors
        });

        // Send the Jetton transfer
        send(SendParameters{
            to: msg.JettonWalletAddress,
            value: JettonTransferGas, 
            body: JettonTransfer{
                queryId: msg.queryId,
                amount: msg.claimAmount,
                destination: sender,
                responseDestination: sender,
                customPayload: null,
                forwardTonAmount: ton("0"),
                forwardPayload: rawSlice("0")
            }.toCell(),
        });
    }

    receive(msg: SendOwner) {
        self.requireOwner();
        self.owner = msg.newOwner;
    }

    get fun getOwner(): Address {
        return self.owner;
    }
}