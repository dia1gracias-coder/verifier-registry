import "@stdlib/deploy";
import "@stdlib/ownable";
import "@stdlib/stoppable";

message Claim {
    queryId: Int as uint64;
}

message Transfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Airdrop with Deployable, Ownable, Stoppable {
    owner: Address;
    tokenAddress: Address;
    claimAmount: Int as coins;
    stopped: Bool;
    
    init(owner: Address, tokenAddress: Address, claimAmount: Int) {
        self.owner = owner;
        self.tokenAddress = tokenAddress;
        self.claimAmount = claimAmount;
        self.stopped = false;
    }

    receive("Deploy") {
        // This function is called when the contract is deployed
    }

    receive(msg: Claim) {
        self.requireNotStopped();
        let sender: Address = context().sender;
        
        // Create the transfer message
        let transferMsg: Transfer = Transfer{
            queryId: msg.queryId,
            amount: self.claimAmount,
            destination: sender,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: 0,
            forwardPayload: emptySlice()
        };

        // Send the transfer message to the token contract
        send(SendParameters{
            to: self.tokenAddress,
            value: 0,
            mode: SendIgnoreErrors,
            body: transferMsg.toCell()
        });
    }

    get fun getTokenAddress(): Address {
        return self.tokenAddress;
    }

    get fun getClaimAmount(): Int {
        return self.claimAmount;
    }

    get fun isStopped(): Bool {
        return self.stopped;
    }
}