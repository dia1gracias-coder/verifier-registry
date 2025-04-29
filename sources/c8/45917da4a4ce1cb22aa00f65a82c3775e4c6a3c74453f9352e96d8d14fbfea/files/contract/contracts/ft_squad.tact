import "@stdlib/deploy";

import "./messages.tact";


contract FtSquad with Deployable {
    const minTonsForStorage: Int = ton("0.04");
    master: Address;
    owner: Address;
    canCreateUntil: Int as uint256 = 0;

    init(owner: Address, master: Address) {
        self.master = master;
        self.owner = owner;
    }

    receive(msg: PayForSquadCreation) {
        nativeThrowUnless(132, sender() == self.master);
        nativeReserve(self.minTonsForStorage, 0);

        self.canCreateUntil = now() + 604800;

        send(SendParameters{
            to: msg.receiver,
            value: msg.price,
            mode: SendPayFwdFeesSeparately,
            body: "PaymentForSquadCreation".asComment()
        });

        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance,
            body: "Excesses".asComment()
        });
    }

    get fun canCreate(): Bool {
        if (now() > self.canCreateUntil) {
            return false;
        } 
        return true;
    }

    get fun balance(): Int {
        return myBalance();
    }
}
