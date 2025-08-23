// Since v1.6.0, Tact has a contract parameters syntax that can supersede
// lazy initialization by init() for all contracts that do not require specific on-chain
// deployment logic that must be run only once in the `init()` function.
//
// Note that the empty parameter list above is still a parameter list,
// meaning that the contract won't have an implicit or explicit `init(){:tact}` function
// and will enjoy storage write optimizations and use less gas overall.
//
// See: https://docs.tact-lang.org/book/contracts/#parameters

import "@stdlib/deploy";
import "@stdlib/ownable";

message SetMyJettonWallet{
    jettonWallet: Address;
}

message(0x7362d09c) JettonTransferNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    sender: Address;
    forwardPayload: Slice as remaining;
}

contract DzTonV3 with Deployable, Ownable {
    // Empty receiver for the deployment,
    // which expects the `null` message body
    owner: Address;
    myJettonWallet: Address;
    myJettonAmount: Int as coins = 0;

    init() {
        self.owner = sender();
        self.myJettonWallet = newAddress(0, 0);
    }


    receive() {
        // Forward the remaining value in the
        // incoming message back to the sender
        cashback(sender());
    }

    receive(msg: SetMyJettonWallet) {
        self.requireOwner();
        self.myJettonWallet = msg.jettonWallet;
    }

    receive(msg: JettonTransferNotification) {
        require(
            sender() == self.myJettonWallet,
            "Notification not from your jetton wallet!",
        );

        self.myJettonAmount += msg.amount;

        // Forward excesses
        self.forward(msg.sender, null, false, null);
    }


}
